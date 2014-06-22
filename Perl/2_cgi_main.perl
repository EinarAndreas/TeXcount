#::::
#::: The main CGI script
#::
#: No routines for external use.
#:

###################################################

MAIN();
exit; # Just to make sure it ends here...

###################################################


#########
######### Main routines
#########

# MAIN ROUTINE: Handle options, then parse LaTeX code
sub MAIN {
  print "Content-Type: text/html\n\n";
  Set_Options();
  Apply_Options();
  conditional_print_style_list();
  my $tex;
  if (my $bincode=param('latexcode')) {
    $tex=TeXcode($bincode);
  } elsif (my $latexfile=param('latexfile')) {
    print "\n<h2>LaTeX file: $latexfile</h2>\n";
    $tex=get_latex_file($latexfile);
  } else {
    print '<p class=warning>File name or LaTeX code required.</p>';
    Close_Output();
    exit;
  }
  parse($tex);
  print "\n";
  my $filecount=next_subcount($tex);
  print_count($filecount);
  Report_Errors();
  if ($optionWordFreq || $optionWordClassFreq) {print_word_freq();}
  Close_Output();
  if ( (defined $LOGfilename) && open(my $LOG,">>$LOGfilename") ) {
    print $LOG join("\t",$versionnumber,scalar localtime,get_texsize($tex),$ENV{'REMOTE_ADDR'}),"\n";
    close($LOG);
  }
  if ( (defined $MacroUsageLogFile) && (open my $LOG,">>$MacroUsageLogFile") ) {
    print $LOG join("\t",$versionnumber,scalar localtime,get_texsize($tex),$ENV{'REMOTE_ADDR'});
    foreach my $key (sort keys %MacroUsage) {
      my $name=text_to_printable($key);
      print $LOG "\t$key=$MacroUsage{$key}";
    }
    print $LOG "\n";
    close($LOG);
  }
}

# Get LaTeX code from submitted file
sub get_latex_file {
  my ($latexfile)=@_;
  if (my $fh=upload('latexfile')) {
    my @lines=<$fh>;
    my $bincode=join('',@lines);
    return TeXcode($bincode,$latexfile);
  } else {
    print '<p>ERROR: '.cgi_error."\n";
    Close_Output();
    exit;
  }
}

# Set options based on CGI parameters
sub Set_Options {
  $htmlstyle=2;
  if (param('latexcode')) {$encoding='utf8';}
  else {$encoding=GetParam('fileencoding','guess');}
  set_verbosity_options(GetParam('verbosity','3','[0-4]'));
  if (my $option=$BreakPointsOptions{GetParam('subcounts','default')}) {
    %BreakPoints=%{$option};
  }
  if (my $wordruleoption=HasParam('wordrule','normal','relaxed|restricted')) {
    $MacroOptionPattern=$NamedMacroOptionPattern{$wordruleoption};
    $LetterPattern=$NamedLetterPattern{$wordruleoption};
  }
  my $sumoption=GetParam('sum','0','[01]+');
  if ($sumoption=~/^0*$/) {
    @sumweights=();
  } elsif ($sumoption=~/^([01])+$/) {
    @sumweights=(0,split(//,$sumoption));
  }
  set_language_option(GetParam('language','count-all'));
  $optionWordFreq=GetParam('wordfreq',$optionWordFreq,'\d+');
  if ($optionWordFreq>0 || HasParam('wordfreq','0','stat')) {$optionWordClassFreq=1;}
  $showVersion=GetParam('showversion',$showVersion,'[01]');
  $includeBibliography=GetParam('incbib',0);
  if (!GetParam('macrousagelog',0)) {$MacroUsageLogFile=undef;}
}

# Get CGI parameter, replace by default if lacking (or validates pattern)
sub GetParam {
  my ($name,$default,$pattern)=@_;
  my $value=param($name);
  if (!defined $value) {return $default;}
  if (!defined $pattern) {$pattern='[-_0-9a-zA-Z]*'}
  if (!($value=~/^($pattern)$/)) {return $default;}
  return $value;
}

# Get CGI parameter, return undef if default or lacking (or invalid)
sub HasParam {
  my ($name,$default,$pattern)=@_;
  my $value=GetParam(@_);
  if ($value eq $default) {return undef;}
  return $value;
}

