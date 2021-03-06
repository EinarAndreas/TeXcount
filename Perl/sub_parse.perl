#::::
#::: Routines for parsing LaTeX code
#::
#: Routines for external access:
#:   >2_*_main
#:     parse($tex)   Parse LaTeX document
#:   >sub_cmd
#:

# Parse LaTeX document
sub parse {
  my ($tex)=@_;
  if ($htmlstyle && $printlevel>0) {print "<div class='parse'><p>\n";}
  parse_all($tex);
  if ($htmlstyle && $printlevel>0) {print "</p></div>\n";}
}

# Parse until end
sub parse_all {
  my ($tex,$state)=@_;
  if (!defined $state) {$state=$STATE_TEXT;}
  while (!($tex->{'eof'})) {
    _parse_unit($tex,$state);
  }
}

# Parse one block/unit with given state until end token
# If end token is set to $_PARAM_, unit is assumed to be a parameter
# and words parsed as individual letters (simple_token is set)
sub _parse_unit {
  my ($tex,$state,$end)=@_;
  my $simple_token=0;
  (  assert(defined $state,$tex,'Undefined parser state!','BUG')
  && assert(!ref($state),$tex,'Invalid parser state of type '.ref($state).'!','BUG')
  ) || exit;
  $state=transition_to_content_state($tex,$state);
  _set_printstate($tex,$state,$end);
  if (defined $end && $end eq $_PARAM_) {
    $end=undef;
    $simple_token=1;
  }
  my $next;
  my @specarg;
  while (defined ($next=next_token($tex,$simple_token))) {
    # Parse next token until token matches $end
    set_style($tex,'ignore');
    if ($state==$STATE_MATH) {set_style($tex,'math');}
    if ((defined $end) && ($end eq $next)) {return @specarg;}
    # Determine how token should be interpreted
    if ($state==$STATE_PREAMBLE && $next eq '\begin' && $tex->{'line'}=~/^\{\s*document\s*\}/) {
      # \begin{document}
      $state=$STATE_TEXT;
    }
    # Pick the first matching interpretation:
    if ($state==$STATE_EXCLUDE_ALL) {
      # ignore everything
    } elsif ($tex->{'type'}==$TOKEN_SPACE) {
      # space or other code that should be passed through without styling
      flush_next($tex,' ');
    } elsif ($next eq '{') {
      # {...} group
      set_style($tex,'ignore');
      push @specarg,_parse_unit($tex,$state,'}');
      set_style($tex,'ignore');
    } elsif ($next eq '}') {
      error($tex,'Encountered } without corresponding {.');
    } elsif ($tex->{'type'}==$TOKEN_TC) {
      # parse TC instructions
      _parse_tc($tex,$next);
    } elsif ($state==$STATE_SPECIAL_ARGUMENT) {
      set_style($tex,'specarg');
      push @specarg,$next;
    } elsif ($tex->{'type'}==$TOKEN_WORD) {
      # word
      my $st=_wordtype_state($tex,$state,$next);
      if (my $cnt=state_text_cnt($st)) {
        _process_word($tex,$next,$st);
        inc_count($tex,$cnt);
        set_style($tex,state_to_style($st));
      }
    } elsif ($state==$STATE_EXCLUDE_STRONGER) {
      # ignore remaining tokens
      set_style($tex,'ignore');
    } elsif ($next eq '\documentclass') {
      # defines document class and starts preamble
      set_style($tex,'document');
      _parse_documentclass_params($tex);
      while (!($tex->{'eof'})) {
        push @specarg,_parse_unit($tex,$STATE_PREAMBLE);
      }
    } elsif ($tex->{'type'}==$TOKEN_MACRO) {
      # macro call
      _parse_macro($tex,$next,$state);
    } elsif ($next eq '$') {
      # math inline
      _parse_math($tex,$state,$CNT_COUNT_INLINEMATH,'$');
    } elsif ($next eq '$$') {
      # math display (unless already in inlined math)
      if (!(defined $end && $end eq '$')) {
        _parse_math($tex,$state,$CNT_COUNT_DISPLAYMATH,'$$');
      }
    } elsif ($simple_token) {
      #DELETE: simple tokens should be handled properly
      #print STDERR '<',$next,'>',"\n";
      # handle as parameter that should not be counted
      set_style($tex,'ignore');
    }
    if (!defined $end) {return @specarg;}
  }
  defined $end && error($tex,'Reached end of file while waiting for '.$end.'.');
  return @specarg;
}

# Print state
sub _set_printstate {
  my ($tex,$state,$end)=@_;
  my $ps=':'.state_to_text($state).(defined $end?'>'.$end:'').':';
  print_style($ps,'state');
  #$tex->{'printstate'}=$ps;
  #flush_next($tex);
}

# State: get modified state if word of special word type
sub _wordtype_state {
  my ($tex,$st,$word)=@_;
  if (defined $word) {
    if (defined $wordtype2state{$st}) {
      for my $rc (@{$wordtype2state{$st}}) {
        my ($reg,$wtst)=@{$rc};
        if ( $word =~ /$reg/) {
          print_style(state_to_text($wtst).':','state');
          return $wtst;
        }
      }
    }
  }
  return $st;
}

# Process word with a given state (>0, i.e. counted)
sub _process_word {
  my ($tex,$word,$state)=@_;
  $WordFreq{$word}++;
}

# Parse unit when next token is a macro
sub _parse_macro {
  my ($tex,$next,$state)=@_;
  my $substat;
  my @macro=($next);
  if (my $label=$BreakPoints{$next}) {
    if ($tex->{'line'}=~ /^[*]?(\s*\[.*?\])*\s*\{((.|\{.*\})*)\}/ ) {
      $label=$label.': '.$2;
    }
    next_subcount($tex,$label);
  }
  if ($state==$STATE_MATH) {set_style($tex,'mathcmd');}
  elsif ($state==$STATE_SPECIAL_ARGUMENT) {set_style($tex,'specarg');}
  else {set_style($tex,state_is_text($state)?'cmd':'exclcmd');}
  if ($next eq '\begin' && state_inc_envir($state)) {
    _parse_envir($tex,$state);
    push @macro,'<envir>';
  } elsif ($next eq '\end' && state_inc_envir($state)) {
    error($tex,'Encountered \end without corresponding \begin');
    push @macro,$STRING_ERROR;
  } elsif ($next eq '\verb') {
    _parse_verb_region($tex,$state);
  } elsif (state_is_parsed($state) && defined (my $substat=$TeXpackageinc{$next})) {
    # Parse macro parameters, use _parse_include_argument to process package list
    set_style($tex,'document');
  	push @macro,__gobble_macro_parms($tex,$substat,$__STATE_NULL,\&_parse_include_argument);
    push @macro,'<package>';
  } elsif (state_is_parsed($state) && defined (my $def=$TeXfileinclude{$next})) {
    # include file (merge in or queue up for parsing)
    set_style($tex,'cmd');
    if (defined ($substat=$TeXmacro{'@pre'.$next})) {__gobble_macro_parms($tex,$substat,$state);}
    __count_macrocount($tex,$next,$state);
    _parse_include_file($tex,$state,$def);
    push @macro,'<filespec>';
    if (defined ($substat=$TeXmacro{'@post'.$next})) {__gobble_macro_parms($tex,$substat,$state);}
  } elsif (($state==$STATE_FLOAT) && ($substat=$TeXfloatinc{$next})) {
    # text included from float
    set_style($tex,'cmd');
    push @macro,__gobble_macro_parms($tex,$substat,$__STATE_NULL);
  } elsif ($state==$STATE_PREAMBLE && defined ($substat=$TeXpreamble{$next})) {
    # parse preamble include macros
    set_style($tex,'cmd');
    __count_macrocount($tex,$next,$STATE_TEXT);
    push @macro,__gobble_macro_parms($tex,$substat,$__STATE_NULL);
  } elsif (state_is_exclude($state)) {
   # ignore
    push @macro,__gobble_options($tex),'/*ignored*/';
  } elsif ($next eq '\(') {
    # math inline
    _parse_math($tex,$state,$CNT_COUNT_INLINEMATH,'\)');
  } elsif ($next eq '\[') {
    # math display
    _parse_math($tex,$state,$CNT_COUNT_DISPLAYMATH,'\]');
  } elsif ($next=~/^\\(def|edef|gdef|xdef)$/) {
    # ignore \def...
    $tex->{'line'} =~ s/^([^\{]*)\{/\{/;
    flush_next($tex);
    print_style($1,'ignore');
    _parse_unit($tex,$STATE_EXCLUDE_STRONG);
    push @macro,'<macro>',$STRING_PARAMETER;
  } elsif (defined ($substat=$TeXmacro{$next})) {
    # macro: exclude options
    __count_macrocount($tex,$next,$state);
    push @macro,__gobble_macro_parms($tex,$substat,$state);
  } elsif (defined __count_macrocount($tex,$next,$state)) {
    # count macro as word (or a given number of words)
  } elsif ($next =~ /^\\[^\w\_]$/) {
    # handle \<symbol> as single symbol macro
    push @macro,__gobble_options($tex),'/*symbol*/';
  } else {
    push @macro,__gobble_options($tex),'/*defaultrule*/';
  }
  $MacroUsage{join('',@macro)}++;
}

# Parse TC instruction
sub _parse_tc {
  my ($tex,$next)=@_;
  set_style($tex,'tc');
  flush_next($tex);
  assert($next=~s/^\%+TC:\s*(\w+)\s*//i,$tex,'TC command should have format %TC:instruction [[parameters]]')
  || return;
  my $instr=$1;
  $instr=~tr/[A-Z]/[a-z]/;
  if ($instr eq 'break') {next_subcount($tex,$next);
  } elsif ($instr=~/^(incbib|includebibliography)$/) {
    $includeBibliography=1;
    apply_include_bibliography();
  } elsif ($instr eq 'ignore') {__gobble_tc_ignore($tex);
  } elsif ($instr eq 'endignore') {error($tex,'%TC:endignore without corresponding %TC:ignore.');
  } elsif ($instr eq 'newtemplate') {$outputtemplate='';
  } elsif ($instr eq 'template') {$outputtemplate.=$next;
  } elsif ($instr eq 'usepackage') {
    assert($next=~/[\w\s,]+/,'Expected list of packaches: %TC:usepackage {packages}');
    foreach (split(/[\s,]+/,$next)) {
      include_package($_,$tex);
    }
  } elsif ($instr eq 'insert') {
    $tex->{'line'}="\n".$next.$tex->{'line'};
  } elsif ($instr eq 'subst') {
    if ($next=~/^(\S+)\s*(\S.*)?$/) {
      my $from=$1;
      my $to=$2;
      $substitutions{$from}=$to;
      apply_substitution_rule($tex,$from,$to);
    } else {
      error($tex,'Invalid %TC:subst format.');
    }
  } elsif ($instr eq 'newcounter') {
    assert($next=~s/^(\w+)(=(\w+))?\s*//,$tex,'Expected format: %TC:newcounter {key}[={like-key}] {description}')
    || return;
    my $key=$1;
    my $like=$3;
    if ($next eq '') {$next=$key;}
    add_new_counter($key,$next,$like);
  } elsif ($instr eq 'wordtype') {
    assert($next=~s/^(\w+)\s+(\w+)\s+(\w+)\s*$//,$tex,'Expected format: %TC:wordtype {parse-state} {wordtype} {count-state}')
    || return;
    assert(my $st=$key2state{$1},$tex,"Invalid parse state: $1") || return;
    assert(my $reg=$wordtype{$2},$tex,"Invalid word type: $2") || return;
    assert(my $wtst=$key2state{$3},$tex,"Invalid count state: $3") || return;
    if (!defined $wordtype2state{$st}) {$wordtype2state{$st}=[];}
    push @{$wordtype2state{$st}},[$reg,$wtst];
  } elsif ($instr eq 'log') {
    assert($next=~s/^(.*)$//,$tex,'Expected format: %TC:log {text or template}') || return;
    note($tex,1,$1);
  } elsif ($instr eq 'assert') {
    assert($next=~s/^(\d+(,\d+)*)(\s+(.*))?$//,$tex,'Expected format: %TC:assert count+count+... {text or template}')
    || return;
    my $template=$4 || 'Words counted: {w} in text, {hw} in headers, {ow} other.';
    assertion_note($tex,$1,$template);
  } elsif ($next=~/^([\\]*\S+)\s+([^\s]+)(\s+(-?\w+))?/) {
    # %TC:instr macro param option
    my $macro=$1;
    my $param=$2;
    my $option=$4;
    tc_macro_param_option($tex,$instr,$macro,$param,$option);
  } else {
    error($tex,'Invalid TC command: '.$instr);
  }
}

# Parse math formulae
sub _parse_math {
  my ($tex,$state,$cnt,$end)=@_;
  my $localstyle;
  if (state_is_text($state)) {
    $localstyle='mathgroup';
    inc_count($tex,$cnt);
  } else {
    $localstyle='exclmath';
  }
  set_style($tex,$localstyle);
  _parse_unit($tex,$STATE_MATH,$end);
  set_style($tex,$localstyle);
}

# Parse \verb region
sub _parse_verb_region {
 my ($tex,$state)=@_;
 #flush_next($tex);
 __gobble_macro_modifier($tex);
 set_style($tex,'ignore');
 assert($tex->{'line'} =~ s/^([^\s])//,$tex,'Invalid \verb: delimiter required.')
 || return;
 my $dlm=$1;
 print_style($dlm,'cmd');
 assert($tex->{'line'}=~s/^([^\Q$dlm\E]*)(\Q$dlm\E)//
   ,$tex,'Invalid \verb: could not find ending delimiter ('.$dlm.').')
 || return;
 print_style($1,'ignore');
 print_style($2,'cmd');
}

# Parse environment
sub _parse_envir {
  my ($tex,$state)=@_;
  my $localstyle=state_is_text($state) ? 'envir' : 'exclenv';
  flush_next_gobble_space($tex,$localstyle,$state);
  my ($envirname,$next,$substat);
  if ($tex->{'line'} =~ s/^\{([^\{\}\s]+)\}[ \t\r\f]*//) {
    # gobble environment name
    $envirname=$1;
    my @macro=('<envir:'.$envirname.'>');
    print_style('{'.$1.'}',$localstyle);
    $next=$PREFIX_ENVIR.$envirname;
    __count_macrocount($tex,$next,$state);
    if (($state==$STATE_FLOAT) && ($substat=$TeXfloatinc{$next})) {
      $state = $__STATE_NULL;
      $localstyle = 'envir';
      push @macro,__gobble_macro_parms($tex,$substat,$__STATE_NULL);
    } elsif (defined ($substat=$TeXmacro{$next})) {
      push @macro,__gobble_macro_parms($tex,$substat,$__STATE_NULL);
    } else {
      push @macro,__gobble_options($tex);
    }
    $MacroUsage{join('',@macro)}++;
  } else {
    $envirname='???'; $next='???';
    error($tex,'Encountered \begin without environment name provided.');
  }
  # find new parsing state (or leave unchanged)
  $substat=$TeXenvir{$1};
  if (!defined $substat) {
    $substat=$state;
    if ($strictness>=1) {
      warning($tex,'Using default rule for environment '.$envirname);
    }
  } else {
    $substat=__new_state($substat,$state);
  }
  if (state_inc_envir($substat)) {
    # Parse until \end arrives, and check that it matches
    _parse_unit($tex,$substat,'\end');
    flush_next_gobble_space($tex,$localstyle,$state);
    if ($tex->{'line'} =~ s/^\{([^\{\}\s]+)\}[ \t\r\f]*//) {
      # gobble environment name
      print_style('{'.$1.'}',$localstyle);
      assert($envirname eq $1,$tex,"Environment \\begin{$envirname} ended with \\end{$1}.");
    } else {
      error($tex,"Environment ended while waiting for \end{$envirname}.");
    }  
  } else {
    # Keep parsing until appropriate \end arrives ignoring all else
    while (!$tex->{'eof'}) {
      _parse_unit($tex,$substat,'\end');
      if ($tex->{'line'} =~ s/^(\s*)(\{\Q$envirname\E\})[ \t\r\f]*//) {
        # gobble \end parameter and end environment
        flush_next($tex,$localstyle,$state);
        print_style($1,$localstyle);
        print_style($2,$localstyle);
        return;
      }
    }
  }
}

# Parse and process file inclusion
sub _parse_include_file {
  my ($tex,$state,$includetype)=@_;
  my $include=state_is_parsed($state);
  my $style=$include?'fileinc':'ignore';
  my $file;
  my %params;
  flush_next($tex);
  $params{'<type>'}=$includetype;
  $params{'SUFFICES'}=[''];
  if ($includetype eq '<bbl>') {
    _parse_include_bbl($tex,$state,\%params);
    return;
  }
  elsif ($includetype eq 'input') {
    $tex->{'line'} =~ s/^(\s*\{([^\{\}\s]+)\})//
    || $tex->{'line'} =~ s/^(\s*([^\{\}\%\\\s]+))//
    || $tex->{'line'} =~ s/^(\s*\{(.+?)\})//
    || BLOCK {
      error($tex,'Failed to identify file name.');
      return;
    };
    print_style($1,$style);
    $file=$2;
    if (!($file=~/\.tex$/i)) {$params{'SUFFICES'}=['.tex',''];}
  }
  else {
    foreach my $param (split(/\s+|,/,$includetype)) {
      if ($param=~/^<.*>$/) {next;}
      $tex->{'line'} =~ s/(\s*\{)([^\{\}\%]*)(\})//|| BLOCK {
        error($tex,"Failed to identify file parameter {$param}.");
        return;
      };
      print_style($1,'ignore');
      print_style($2,$style);
      print_style($3,'ignore');
      if ($param eq 'file') {
        $file=$2;
        if (!($file=~/\.tex$/i)) {$params{'SUFFICES'}=['.tex',''];}
      } elsif ($param eq 'texfile') {
        $file=$2.'.tex';
      } else {$params{$param}=$2;}
    }
  }
  if (!defined $file) {
    error($tex,'Undefined file name.');
  }
  elsif ($includeTeX && $include) {
    include_file($tex,$state,$file,\%params);
  }
}

# Parse and process bibliography file
sub _parse_include_bbl {
  my ($tex,$state,$params)=@_;
  if ($includeBibliography && state_is_text($state)) {
    my $filename=$tex->{'filename'};
    $filename=~s/(\.tex)?$/\.bbl/i;
    include_file($tex,$state,$filename,$params);
  }
}

# Parse and process package inclusion
sub _parse_include_package {
  my ($tex)=@_;
  set_style($tex,'document');
  if ( $tex->{'line'}=~s/^\{(([\w\-]+)(\s*,\s*[\w\-]+)*)\}// ) {
    print_style("{$1}",'document');
    foreach (split(/\s*,\s*/,$1)) {
      $MacroUsage{"<package:$_>"}++;
      include_package($_,$tex);
    }
  } else {
    _parse_unit($tex,$STATE_IGNORE);
    error($tex,'Could not recognise package list, ignoring it instead.');
  }
}

# Extract package names from token list and include packages
sub _parse_include_argument {
  my $tex=shift @_;
  my $args=join('',@_);
  set_style($tex,'document');
  foreach (split(/\s*,\s*/,$args)) {
    $MacroUsage{"<package:$_>"}++;
    include_package($_,$tex);
  }
}

# Parse \documentclass parameters and include rules
sub _parse_documentclass_params {
  my ($tex)=@_;
  my $options=__gobble_option($tex);
  if ( $tex->{'line'}=~s/^(\{\s*([^\{\}\s]+)\s*\})// ) {
    print_style("$1",'document');
    $MacroUsage{"<documentclass:$2>"}++;
    include_package("class%$2",$tex);
  } else {
    _parse_unit($tex,$STATE_IGNORE);
    error($tex,'Could not identify document class.');
  }
}

# Count macrocount using given state
sub __count_macrocount {
  my ($tex,$next,$state)=@_;
  my $def=$TeXmacrocount{$next};
  my $cnt;
  if (!defined $def) {return undef;}
  elsif (ref($def) eq 'ARRAY') {
    # TODO: Is this an appropriate style to use?
    set_style($tex,state_to_style($state));
    flush_next($tex);
    foreach $cnt (@{$def}) {
      if ($cnt==$CNT_WORDS_TEXT) {$cnt=state_text_cnt($state);}
      inc_count($tex,$cnt);
    }
  }
  elsif ($cnt=state_text_cnt($state)) {
    set_style($tex,state_to_style($state));
    flush_next($tex);
    inc_count($tex,$cnt,$def);
  }
  return $def;
}

# Gobble next option, return option or undef if none
sub __gobble_option {
  my $tex=shift @_;
  flush_next_gobble_space($tex);
  if ($tex->{'line'}=~s/^($MacroOptionPattern)//) {
    print_style($1,'option');
    return $1;
  }
  return undef;
}

# Gobble all options, return the number of gobble options 
sub __gobble_options {
  my $n=0;
  while (__gobble_option(@_)) {$n++}
  return ($STRING_GOBBLED_OPTION)x$n;
}

# Gobble macro modifyer (e.g. following *)
sub __gobble_macro_modifier {
  my $tex=shift @_;
  flush_next($tex);
  if ($tex->{'line'} =~ s/^(\*)//) {
    print_style($1,'option');
    return $1;
  }
  return;
}

# Gobble macro parameters as specified in parm plus options
sub __gobble_macro_parms {
  my ($tex,$parm,$oldstat,$specarghandler)=@_;
  my $n;
  my @ret;
  if (ref($parm) eq 'ARRAY') {
    $n=scalar @{$parm};
  } else {
    $n=$parm;
    $parm=[($STATE_IGNORE)x$n];
  }
  # TODO: Optionally gobble macro modifier?
  if ($n>0) {push @ret,__gobble_macro_modifier($tex);}
  my $auto_gobble_options=1;
  for (my $j=0;$j<$n;$j++) {
    my $p=$parm->[$j];
    if ($p==$_STATE_OPTION) {
      # Parse macro option
      $p=$parm->[++$j];
      if ($tex->{'line'}=~s/^(\s*\[)//) {
        flush_next_gobble_space($tex);
        print_style($1,'optparm');
        push @ret,$STRING_OPTIONAL_PARAM;
        _parse_unit($tex,__new_state($p,$oldstat),']');
        set_style($tex,'optparm');
      }
    } elsif ($p==$_STATE_NOOPTION) {
      $auto_gobble_options=0;
    } elsif ($p==$_STATE_AUTOOPTION) {
      $auto_gobble_options=1;
    } else {
      # Parse macro parameter
      if ($auto_gobble_options) {push @ret,__gobble_options($tex);}
      push @ret,$STRING_PARAMETER;
      my @specarg=_parse_unit($tex,__new_state($p,$oldstat),$_PARAM_);
      if ($p==$STATE_SPECIAL_ARGUMENT && defined $specarghandler) {
        &$specarghandler($tex,@specarg);
      }
    }
  }
  #TODO: Drop default gobbling of option at end?
  if ($auto_gobble_options) {push @ret,__gobble_options($tex);}
  return @ret;
}

# Parse through ignored LaTeX code
sub __gobble_tc_ignore {
  my ($tex)=@_;
  set_style($tex,'ignore');
  _parse_unit($tex,$STATE_EXCLUDE_ALL,'%TC:endignore');
  set_style($tex,'tc');
  flush_next($tex);
}

# Return new parsing state given old and substate
sub __new_state {
  my ($substat,$oldstat)=@_;
  if (!defined $oldstat) {return $substat;}
  foreach my $st (@STATE_FIRST_PRIORITY) {
    if ($oldstat==$st || $substat==$st) {return $st;}
  }
  foreach my $st (@STATE_MID_PRIORITY) {
    if ($substat==$st) {return $st;}
  }
  foreach my $st (@STATE_MID_PRIORITY) {
    if ($oldstat==$st) {return $st;}
  }
  foreach my $st (@STATE_LAST_PRIORITY) {
    if ($oldstat==$st || $substat==$st) {return $st;}
  }
  error($Main,'Could not determine new state in __new_state!','BUG');
  return $oldstat;
}

