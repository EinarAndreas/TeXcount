#::::
#::: The main CMD script
#::
#: No routines for external use.
#:


###################################################

MAIN(@ARGV);
exit; # Just to make sure it ends here...

###################################################


#########
######### Main routines
#########

# MAIN ROUTINE: Handle arguments, then parse files
sub MAIN {
  my @args;
  push @args,@StartupOptions;
  push @args,@_;
  Initialise();
  Check_Arguments(@args);
  my @toplevelfiles=Parse_Arguments(@args);
  Apply_Options();
  if (scalar @toplevelfiles>0 || $fileFromSTDIN) {
    if ($showVersion && !$htmlstyle && !($briefsum && $totalflag)) {
      print "\n=== LaTeX word count (TeXcount version $versionnumber) ===\n\n";
    }
    conditional_print_style_list();
    my $totalcount=Parse_file_list(@toplevelfiles);
    conditional_print_total($totalcount);
    Report_Errors();
    if ($optionWordFreq || $optionWordClassFreq) {print_word_freq();}
    if ($optionMacroStat) {print_macro_stat();}
  } elsif ($showcodes>1) {
    conditional_print_style_list();
  } else {
    error($Main,'No files specified.');
  }
  Close_Output();
}

# Initialise, overrule initial settings, etc.
sub Initialise {
  _option_subcount();
  # Windows settings
  if ($^O eq 'MSWin32') {
  } elsif ($^O=~/^MSWin/) {
    #DELETE: do not overrule colour setting
    option_ansi_colours(0);
  }
}

# Check arguments, exit on exit condition
sub Check_Arguments {
  my @args=@_;
  if (!@args) {
    print_version();
    print_short_help();
    exit;
  }
  for my $arg (@args) {
    $arg=~s/^(--?(h|\?|help)|\/(\?|h))\b/-h/;
    $arg=~s/[=:]/=/;
    if ($arg=~/^-h$/) {
      print_short_help();
      exit;
    } elsif ($arg=~/^-h=(.*)$/) {
      print_help_on_rule($1);
      exit;
    } elsif ($arg=~/^-(h-)?(man|manual)$/) {
      print_help();
      exit;
    } elsif ($arg=~/^-h-?(opt|options?)$/) {
      print_syntax();
      exit;
    } elsif ($arg=~/^-h-?(opt|options?)=(.*)$/) {
      print_syntax_subset($2);
      exit;
    } elsif ($arg=~/^-h-?(styles?)$/) {
      print_help_on_styles();
      exit;
    } elsif ($arg=~/^-h-?(styles?)=(\w+)$/) {
      print_help_on_styles($2);
      exit;
    } elsif ($arg=~/^--?(ver|version)$/) {
      print_version();
      exit;
    } elsif ($arg=~/^--?(lic|license|licence)$/) {
      print_license();
      exit;
    }
  }
  return 1;
}

# Parse arguments, set options (global) and return file list
sub Parse_Arguments {
  my @args=@_;
  my @files;
  foreach my $arg (@args) {
    if ($arg=~/^\-/) {
      $arg=~s/[=:]/=/;
      if (parse_option($arg)) {next;}
      print "Invalid option $arg \n\n";
      print_short_help();
      exit;
    } elsif ($arg=~/^@\-/) { # ignored option
      next;
    } 
    $arg=~s/\\/\//g;
    push @files,$arg;
  }
  return @files;
}

# Parse individual option parameters
sub parse_option {
  my $arg=shift @_;
  return parse_options_preset($arg) 
  || parse_options_parsing($arg)
  || parse_options_counts($arg)
  || parse_options_output($arg)
  || parse_options_format($arg)
  ;
}

# Parse presetting options
sub parse_options_preset {
  my $arg=shift @_;
  if ($arg=~/^-(opt|option|options|optionfile)=(.*)$/) {
    _parse_optionfile($2);
  }
  else {return 0;}
  return 1;
}

# Parse parsing options
sub parse_options_parsing {
  my $arg=shift @_;
  if    ($arg eq '-') {$fileFromSTDIN=1;}
  elsif ($arg eq '-merge') {$includeTeX=2;}
  elsif ($arg eq '-inc') {$includeTeX=1;}
  elsif ($arg eq '-noinc') {$includeTeX=0;}
  elsif ($arg =~/^-(includepackage|incpackage|package|pack)=(.*)$/) {include_package($2);}
  elsif ($arg eq '-incbib') {$includeBibliography=1;}
  elsif ($arg eq '-nobib') {$includeBibliography=0;}
  elsif ($arg eq '-dir') {$globalworkdir=undef;}
  elsif ($arg=~/^-dir=(.*)$/) {
    $globalworkdir=$1;
    $globalworkdir=~s:([^\/\\])$:$1\/:;
  }
  elsif ($arg eq '-auxdir') {$auxdir=undef;}
  elsif ($arg=~/^-auxdir=(.*)$/) {
    $auxdir=$1;
    $auxdir=~s:([^\/\\])$:$1\/:;
  }
  elsif ($arg =~/^-(enc|encode|encoding)=(.+)$/) {$encoding=$2;}
  elsif ($arg =~/^-(utf8|unicode)$/) {$encoding='utf8';}
  elsif ($arg =~/^-(alpha(bets?)?)=(.*)$/) {set_script_options(\@AlphabetScripts,$3);}
  elsif ($arg =~/^-(logo(grams?)?)=(.*)$/) {set_script_options(\@LogogramScripts,$3);}
  elsif ($arg =~/^-([-a-z]+)$/ && set_language_option($1)) {}
  elsif ($arg eq '-relaxed') {
    $MacroOptionPattern=$NamedMacroOptionPattern{'relaxed'};
    $LetterPattern=$NamedLetterPattern{'relaxed'};
  }
  elsif ($arg eq '-restricted') {
    $MacroOptionPattern=$NamedMacroOptionPattern{'restricted'};
    $LetterPattern=$NamedLetterPattern{'restricted'};
  }
  else {return 0;}
  return 1;
}

# Parse count and summation options
sub parse_options_counts {
  my $arg=shift @_;
  if    ($arg =~/^-sum(=(.+))?$/) {_option_sum($2);}
  elsif ($arg =~/^-nosum/) {@sumweights=();}
  elsif ($arg =~/^-(sub|subcounts?)(=(.+))?$/) {_option_subcount($3);}
  elsif ($arg =~/^-(nosub|nosubcounts?)/) {$showsubcounts=0;}
  elsif ($arg eq '-freq') {$optionWordFreq=1;}
  elsif ($arg =~/^-freq=(\d+)$/) {$optionWordFreq=$1;}
  elsif ($arg eq '-stat') {$optionWordClassFreq=1;}
  elsif ($arg =~/^-macro-?(stat|freq)$/) {$optionMacroStat=1;}
  else {return 0;}
  return 1;
}

# Apply sum option
sub _option_sum {
  my $arg=shift @_;
  if (!defined $arg) {
    @sumweights=(0,1,1,1,0,0,1,1);
  } elsif ($arg=~/^(\d+(\.\d*)?([,+]\d+(\.\d*)?){0,6})$/) {
    @sumweights=(0,split(/[,+]/,$arg));
    print STDERR "SUMWEIGHTS: ",join(', ',@sumweights),"\n";
  } else {
    print STDERR "Warning: Option value $arg not valid, ignoring option.\n";
  }
}

# Apply subcount options
sub _option_subcount {
  my $arg=shift @_;
  $showsubcounts=2;
  if (!defined $arg) {
    %BreakPoints=%{$BreakPointsOptions{'default'}};
  } elsif (my $option=$BreakPointsOptions{$arg}) {
    %BreakPoints=%{$option};
  } else {
    print STDERR "Warning: Option value $arg not valid, using default instead.\n";
    %BreakPoints=%{$BreakPointsOptions{'default'}};
  }
}

# Parse output and verbosity options
sub parse_options_output {
  my $arg=shift @_;
  if    ($arg eq '-strict') {$strictness=1;}
  elsif ($arg eq '-v') {set_verbosity_options('3');}
  elsif ($arg =~/^-v([0-4=+\-].*)/) {set_verbosity_options($1);}
  elsif ($arg =~/^-showstates?$/ ) {$showstates=1;}
  elsif ($arg =~/^-(q|quiet)$/ ) {$printlevel=-1;}
  elsif ($arg =~/^-(template)=(.*)$/ ) {_set_output_template($2);}
  elsif ($arg eq '-split') {$optionFast=1;}
  elsif ($arg eq '-nosplit') {$optionFast=0;}
  elsif ($arg eq '-showver') {$showVersion=1;}
  elsif ($arg eq '-nover') {$showVersion=-1;}
  elsif ($arg =~/^-nosep(arator)?s?$/ ) {$separator='';}
  elsif ($arg =~/^-sep(arator)?s?=(.*)$/ ) {$separator=$2;}
  elsif ($arg =~/^-out=(.*)/ ) {
    close STDOUT;
    open STDOUT,'>',$1 or die "Could not open out file for writing: $1";
  }
  elsif ($arg =~/^-out-stderr/ ) {select STDERR;}
  else {return 0;}
  return 1;
}

# Set output template
sub _set_output_template {
  my $template=shift @_;
  $outputtemplate=$template;
  if ($template=~/\{(SUM)[\?\}]/i && !@sumweights) {
    @sumweights=(0,1,1,1,0,0,1,1);
  }
  if ($template=~/\{SUB\?/i && !$showsubcounts) {
    _option_subcount();
  }
}

# Parse output formating options
sub parse_options_format {
  my $arg=shift @_;
  if    ($arg eq '-brief') {$briefsum=1;}
  elsif ($arg eq '-total') {$totalflag=1;}
  elsif ($arg eq '-0') {$briefsum=1;$totalflag=1;$printlevel=-1;$finalLineBreak=0;}
  elsif ($arg eq '-1') {$briefsum=1;$totalflag=1;$printlevel=-1;}
  elsif ($arg eq '-htmlcore' ) {option_ansi_colours(0);$htmlstyle=1;}
  elsif ($arg eq '-html' ) {option_ansi_colours(0);$htmlstyle=2;}
  elsif ($arg eq '-tex' ) {option_ansi_colours(0);$texcodeoutput=1;}
  elsif ($arg =~/^\-(nocol|nc$)/) {option_ansi_colours(0);}
  elsif ($arg =~/^\-(col)$/) {option_ansi_colours(1);}
  elsif ($arg eq '-codes') {$showcodes=2;}
  elsif ($arg eq '-nocodes') {$showcodes=0;}
  elsif ($arg =~/^-htmlfile=(.+)$/) {$HTMLfile=$1;}
  elsif ($arg =~/^-cssfile=(.+)$/) {$CSSfile=$1;}
  elsif ($arg =~/^-css=file:(.+)$/) {$CSSfile=$1;}
  elsif ($arg =~/^-css=(.+)$/) {$CSShref=$1;}
  else {return 0;}
  return 1;
}

# Include options from option file
sub _parse_optionfile {
  my $filename=shift @_;
  open(FH,'<',$filename)
    || die "Option file not found: $filename\n";
  my @options=<FH>;
  close(FH);
  s/^\s*(#.*|)//s for @options;
  my $text=join('',@options);
  $text=~s/(\n|\r|\r\n)\s*\\//g;
  @options=split("\n",$text);
  foreach my $arg (@options) {
    __optionfile_tc($arg)
      || parse_option($arg)
      || die "Invalid option $arg in $filename.\n";
  }
}

# Parse option file TC options
sub __optionfile_tc {
  my $arg=shift @_;
  $arg=~s/^\%\s*// || return 0;
  if ($arg=~/^subst\s+(\\\w+)\s+(.*)$/i) {
    $substitutions{$1}=$2;
  } elsif ($arg=~/^(\w+)\s+([\\]*\w+)\s+([^\s\n]+)(\s+(\-?[0-9]+|\w+))?/i) {
    tc_macro_param_option($Main,$1,$2,$3,$5) || die "Invalid TC option: $arg\n";
  } else {
    print "Invalid TC option format: $arg\n";
    return 0;
  }
  return 1;
}

# Parse file list and return total count
sub Parse_file_list {
  my @files=@_;
  my $listtotalcount=new_count('Total');
  foreach (@files) {
    $_='"'.$_.'"'
  }
  #DEBUG: print STDERR "FILES: ",join(' + ',@files),"\n";
  if (@files) {
    @files=<@files>; # For the sake of Windows: expand wildcards!
    #DEBUG: print STDERR "<FILES>: ",join(' + ',@files),"\n";
    for my $file (@files) {
      #DEBUG: print STDERR "FILE: ",$file,"\n";
      my $filetotalcount=parse_file($file);
      add_to_total($listtotalcount,$filetotalcount);
    }
  }
  if ($fileFromSTDIN) {
    my $filetotalcount=parse_file($_STDIN_);
    add_to_total($listtotalcount,$filetotalcount);
  }
  return $listtotalcount;
}

# Parse file and included files, and return total count
sub parse_file {
  my $file=shift @_;
  if (defined ($workdir=$globalworkdir)) {}
  elsif ($file eq $_STDIN_) {$workdir='';}
  else {
    $workdir=$file;
    $workdir =~ s/^((.*[\\\/])?)[^\\\/]+$/$1/;
  }
  if ($htmlstyle && ($printlevel>0 || !$totalflag)) {print "\n<div class='filegroup'>\n";}
  my $filetotalcount=new_count('File(s) total: '.$file);
  @filelist=();
  _add_file($filetotalcount,[$file,$workdir],'File: '.$file);
  foreach my $f (@filelist) {
    _add_file($filetotalcount,$f,'Included file: '.$f->[0]);
  }
  if (!$totalflag && get_count($filetotalcount,$CNT_FILE)>1) {
    if ($htmlstyle) {formatprint("Sum of files: $file\n",'h2');}
    print_count($filetotalcount,'sumcount');
  }
  if ($htmlstyle && ($printlevel>0 || !$totalflag)) {print "</div>\n\n";}
  return $filetotalcount;
}

# Parse single file, included files will be appended to @filelist.
sub _add_file {
  my ($filetotalcount,$pathfile,$title)=@_;
  my @paths=@$pathfile;
  my $file=shift @paths;
  my $tex=TeXfile($file,$title);
  if (!defined $tex) {
    error($Main,'File not found or not readable: '.$file);
    return;
  }
  $tex->{'PATH'}=\@paths;
  parse($tex);
  my $filecount=next_subcount($tex);
  if (!$totalflag) {print_count($filecount);}
  add_to_total($filetotalcount,$filecount);
}
