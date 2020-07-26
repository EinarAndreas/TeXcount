#::::
#::: Routines for handling and applying options
#::
#: Routines for external access:
#:   >2_*_main
#:     Apply_Options()
#:     set_language_option($language)
#:     set_script_options($scriptset,$str)
#:   >2_*_main, sub_parse
#:     tc_macro_param_option($tex,$instr,$macro,$param,$option)
#:   >sub_parse
#:     apply_include_bibliography
#:

# Apply options to set values
sub Apply_Options {
  apply_encoding_options();
  if ($htmlstyle==$HTML_FULL) {html_head();}
  flush_errorbuffer($Main);
  apply_language_options();
  apply_include_default_packages();
  if ($includeBibliography) {apply_include_bibliography();}
  if ($showcodes>1 && !($STYLE{'<printlevel>'})) {%STYLE=%{$STYLES{'All'}};} 
  if ($showstates) {set_verbosity_options('+States');}
  if (!@sumweights) {set_verbosity_options('-Sums');}
  (defined $printlevel)
   || (defined ($printlevel=$STYLE{'<printlevel>'}))
   || ($printlevel=$defaultprintlevel);
}

# Set or add styles included in the verbose output
sub set_verbosity_options {
  my $verb=shift @_;
  my $st;
  if ($defaultprintlevel<1) {$defaultprintlevel=1;}
  if ( $verb=~s/^([0-4])// || $verb=~s/^=([0-4])?// ) {
    my $key=$1;
    if (!defined $key) {%STYLE=(%{$STYLES{'<core>'}});}
    elsif ($st=$STYLES{$key}) {%STYLE=(%$st);}
    else {
      error($Main,"Unknown verbosity option '$key'.");
      %STYLE=(%{$STYLES{'<core>'}});
    }
  }
  while ($verb=~s/^([\+\-]?)(\w+)//) {
    my $add=!($1 eq '-');
    my $key=$2;
    if ($st=$STYLES{$key}) {
      if ($add) {@STYLE{keys %$st}=values %$st;}
      else {delete @STYLE{keys %$st};}
    } elsif ($st=$STYLES{'All'}->{$key}) {
      if ($add) {$STYLE{$key}=$st;}
      elsif ($STYLE{$key}) {delete $STYLE{$key};}
    } else {
      error($Main,"Unknown verbosity option '$key'.");
    }
  }
  if ($verb ne '') {
    error($Main,"Unknown verbosity option format: $verb");
  }
}

# Set or add scripts to array of scripts
sub set_script_options {
  my ($scriptset,$str)=@_;
  if ($str=~s/^\+//) {} else {splice(@$scriptset,0,scalar $scriptset);}
  my @scripts=split(/[+,]/,$str);
  foreach my $scr (@scripts) {
    $scr=~tr/_/ /;
    if ($scr eq 'Alphabetic') {
      warning($Main,'Using alphabetic instead of Unicode class Alphabetic');
      $scr='alphabetic';
    }
    if ($scr=~/^[a-z]/) {$scr='Is_'.$scr;}
    if (_is_property_valid($scr)) {push @$scriptset,$scr;}
    else {error($Main,"Unknown script $scr ignored.");}
  }
}

sub _is_property_valid {
  my $script=shift @_;
  if (! $script=~/^\w+$/) {return 0;}
  eval {' '=~/\p{$script}/};
  if ($@) {return 0;} else {return 1;}
}

# Set language option, return language if applied, undef if not
sub set_language_option {
  my $language=shift @_;
  if ($language=~/^(count\-?)all$/) {
    @AlphabetScripts=qw/Digit Is_alphabetic/;
    @LogogramScripts=qw/Ideographic Katakana Hiragana Thai Lao Hangul/;
  } elsif ($language=~/^words(-?only)?$/) {
    @LogogramScripts=();
  } elsif ($language=~/^(ch|chinese|zhongwen)(-?only)?$/) {
    @LogogramScripts=qw/Han/;
    if (defined $2) {$LetterPattern=undef;}
    @encodingGuessOrder=@{$NamedEncodingGuessOrder{'chinese'}};
    return 'chinese';
  } elsif ($language=~/^(jp|japanese)(-?only)?$/) {
    @LogogramScripts=qw/Han Hiragana Katakana/;
    if (defined $2) {$LetterPattern=undef;}
    @encodingGuessOrder=@{$NamedEncodingGuessOrder{'japanese'}};
    return 'japanese';
  } elsif ($language=~/^(kr|korean)(-?only)?$/) {
    @LogogramScripts=qw/Han Hangul/;
    if (defined $2) {$LetterPattern=undef;}
    @encodingGuessOrder=@{$NamedEncodingGuessOrder{'korean'}};
    return 'korean';
  } elsif ($language=~/^(kr|korean)-?words?(-?only)?$/) {
    if (defined $2) {
      @AlphabetScripts=qw/Hangul/;
      @LogogramScripts=qw/Han/;
    } else {
      @AlphabetScripts=qw/Digit Is_alphabetic Hangul/;
      @LogogramScripts=qw/Han Katakana Hiragana Thai Lao/;
    }
    @encodingGuessOrder=@{$NamedEncodingGuessOrder{'korean'}};
    return 'korean-words';
  } elsif ($language=~/^(char|character|letter)s?(-?only)?$/) {
    @WordPatterns=($NamedWordPattern{'letters'});
    if (defined $2) {@LogogramScripts=();}
    $countdesc[1]='Letters in text';
    $countdesc[2]='Letters in headers';
    $countdesc[3]='Letters in captions';
    return 'letter';
  } elsif ($language=~/^all-nonspace-(char|character|letter)s?$/) {
    @WordPatterns=($NamedWordPattern{'letters'});
    @AlphabetScripts=qw/Digit Is_alphabetic Is_punctuation/;
    $countdesc[1]='Characters in text';
    $countdesc[2]='Characters in headers';
    $countdesc[3]='Characters in captions';
    return 'nonspace-characters';
  } else {
    return undef;
  }
}

# Set encoding based on encoding options, guess encoding if not set
sub apply_encoding_options {
  if (defined $encoding && $encoding eq 'guess') {$encoding=undef;}
  if (!defined $encoding) {
  } elsif (ref(find_encoding($encoding))) {
    if (!$htmlstyle) {$outputEncoding=$encoding;}
  } else {
    error($Main,"Unknown encoding $encoding ignored.");
    error_details($Main,'Valid encodings are: '.wrap('','',join(', ',Encode->encodings(':all'))));
    $encoding=undef;
  }
  if (!defined $outputEncoding) {$outputEncoding='utf8';}
  binmode STDIN;
  binmode STDOUT,':encoding('.$outputEncoding.')';
}

# Apply language options
sub apply_language_options {
  my @tmp;
  if (defined $LetterPattern && @AlphabetScripts && scalar @AlphabetScripts>0) {
    @tmp=@AlphabetScripts;
    foreach (@tmp) {$_='\\p{'.$_.'}';}
    my $letterchars='['.join('',@tmp).']';
    my $letter=$LetterPattern;
    $letter=~s/@/$letterchars/g;
    @WordPatterns=map { s/\@/$letter/g ; qr/$_/ } @WordPatterns;
  } else {
    @WordPatterns=();
  }
  if (@LogogramScripts && scalar @LogogramScripts>0) {
    @tmp=@LogogramScripts;
    foreach (@tmp) {$_='\\p{'.$_.'}';}
    push @WordPatterns,'['.join('',@tmp).']';
  }
  if (scalar @WordPatterns==0) {
    error($Main,'No script (alphabets or logograms) defined. Using fallback mode.');
    push @WordPatterns,'\\w+';
  }
  $WordPattern=join '|',@WordPatterns;
}

# Apply default package inclusion
sub apply_include_default_packages {
  foreach (@DefaultPackages) {
    print STDERR "Default include: $_\n";
    include_package($_);
  }
}

# Apply incbib rule
sub apply_include_bibliography {
  include_package('%incbib');
}

# Process TC instruction, return 1 if applied, 0 if not (e.g. error)
sub tc_macro_param_option {
  my ($tex,$instr,$macro,$param,$option)=@_;
  if (!defined $param) {
    error($tex,'%TC:'.$instr.' requires parameter rule specification.');
    return 0;
  }
  elsif ($instr eq 'macro') {
    if (!($macro=~/^\\/)) {
      warning($tex,'%TC:macro '.$macro.': should perhaps be \\'.$macro.'?');
    }
    return _tc_macro_set_param($tex,\%TeXmacro,$instr,$macro,$param);
  }
  elsif ($instr eq 'exclude') {
    warning($tex,'%TC:exclude is deprecated. Use %TC:macro instead.');
    return _tc_macro_set_param($tex,\%TeXmacro,$instr,$macro,$param);
  }
  elsif ($instr eq 'header') {
    warning($tex,'%TC:header is deprecated. Instead use e.g. %TC:macro \\name [header].');
    $TeXmacrocount{$macro}=[$CNT_COUNT_HEADER];
    return _tc_macro_set_param($tex,\%TeXmacro,$instr,$macro,$param);
  }
  elsif ($instr eq 'preambleinclude') {
    return _tc_macro_set_param($tex,\%TeXpreamble,$instr,$macro,$param);
  }
  elsif ($instr eq 'floatinclude') {
    return _tc_macro_set_param($tex,\%TeXfloatinc,$instr,$macro,$param);
  }
  elsif ($instr=~/^(group|envir)$/) {
    if (!defined $option) {
      error($tex,'TC:'.$instr.' requires contents rule specification.');
      return 0;
    }
    defined ($option=key_to_state($option,$tex)) || return 0;
    $TeXenvir{$macro}=$option;
    return _tc_macro_set_param($tex,\%TeXmacro,$instr,$PREFIX_ENVIR.$macro,$param);
  }
  elsif ($instr=~/^(macrocount|macroword)$/) {
    return _tc_macro_set_param($tex,\%TeXmacrocount,$instr,$macro,$param,\&key_to_cnt,$REGEX_NUMBER);
  }
  elsif ($instr eq 'fileinclude') {
    # No parameter checking here, just pass on; errors reported when used instead.
    $param=~s/^\[(.*)\]$/$1/;
    $param=~s/,/ /g;
    assert($param=~/^\w+(\s\w+)*$/||0,$tex,'Invalid %TC:fileinclude parameter: '.$param)
    || return 0;
    $TeXfileinclude{$macro}=$param;
  }
  elsif ($instr eq 'breakmacro') {$BreakPoints{$macro}=$param;}
  else {
    error($tex,'Unknown TC command: '.$instr);
    return 0;
  }
  return 1;
}

# Convert TC command parameters and add to hash
sub _tc_macro_set_param {
  my ($tex,$hash,$instr,$macro,$param,$keymap,$validregex)=@_;
  if (!defined $keymap) {$keymap=\&key_to_state; $validregex=$REGEX_NUMBER;}
  $param=__interpret_tc_parameter($tex,$param,$keymap,$validregex);
  if (!defined $param) {return 0;}
  $hash->{$macro}=$param;
  return 1;
}

# Convert [...] into array of states, optionally return value if a valid pattern
sub __interpret_tc_parameter {
  my ($tex,$param,$keymap,$validregex)=@_;
  if ((defined $validregex) && ($param=~$validregex)) {
    return $param;
  } elsif ($param=~/^\[([0-9a-zA-Z,:]*)\]$/) {
    my @params;
    my $value;
    foreach my $key (split(',',$1)) {
      if ($key=~/^(\w*):(\w+)$/) {
        defined ($value=$keymap->($PREFIX_PARAM_OPTION.$1,$tex)) || return undef;
        push @params,$value;
        $key=$2;
      }
      defined ($value=$keymap->($key,$tex)) || return undef;
      push @params,$value;
    }
    return [@params];
  }
  error($tex,'Invalid TC command parameter: '.$param);
  return undef;
}

