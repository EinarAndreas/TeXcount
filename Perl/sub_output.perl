#::: Routines for presenting results
#::
#: Routines for external access:
#:   >2_*_main
#:     Close_Output()
#:     Report_Errors()
#:   >2_cmd_main
#:     print_word_freq()
#:

# Close the output (STDOUT), e.g. adding HTML tail
sub Close_Output {
  if ($htmlstyle>1) {
    html_tail();
  }
  close STDOUT;
}

# Report if there were any errors occurring during parsing
sub Report_Errors {
  if (defined $outputtemplate) {return;}
  if ( !$briefsum && !$totalflag && $printlevel>=0 ) {
    foreach (keys %warnings) {formatprint($_,'p','nb');print "\n";}
  }
  if ($errorcount==0) {return;}
  if ($briefsum && $totalflag) {print ' ';}
  if ($htmlstyle) {
    print "<div class='error'><p>\n";
    print "There were $errorcount error(s) reported!\n";
    print "</p></div>\n";
  } elsif ($briefsum && $totalflag) {
    print "(errors:$errorcount)";
  } else {
    print "(errors:$errorcount)\n";
  }
}

# Print word frequencies (as text only)
sub print_word_freq {
  my ($word,$wd,$freq,%Freq,%Word,%Class);
  my %regs;
  foreach my $cg (@AlphabetScripts,@LogogramScripts) {
    $regs{$cg}=qr/\p{$cg}/;
  }
  my $sum=0;
  for $word (keys %WordFreq) {
    $wd=lc $word;
    $Freq{$wd}+=$WordFreq{$word};
    $sum+=$WordFreq{$word};
    $Word{$wd}=__lc_merge($word,$Word{$wd});
  }
  if ($htmlstyle) {print "<table class='stat'>\n<thead>\n";}
  __print_word_freq('Word','Freq','th');
  if ($htmlstyle) {print "</thead>\n";}
  if ($optionWordClassFreq>0) {
    for $word (keys %Freq) {$Class{__word_class($word,\%regs)}+=$Freq{$word};}
    __print_sorted_freqs('langstat',\%Class);
  }
  if ($htmlstyle) {print "<tbody class='sumstat'>\n";}
  __print_word_freq('All words',$sum,'td','sum');
  if ($htmlstyle) {print "</tbody>\n";}
  if ($optionWordFreq>0) {__print_sorted_freqs('wordstat',\%Freq,\%Word,$optionWordFreq);}
  if ($htmlstyle) {print "</table>\n";}
}

# Merge to words which have the same lower case
sub __lc_merge {
  my ($word,$w)=@_;
  if (defined $w) {
    for (my $i=length($word);$i-->0;) {
      if (substr($word,$i,1) ne substr($w,$i,1)) {
        substr($word,$i,1)=lc substr($word,$i,1);
      }
    }
  }
  return $word;
}

# Return the word class based on script groups it contains
sub __word_class {
  my ($wd,$regs)=@_;
  my @classes;
  $wd=~s/\\\w+({})?/\\{}/g;
  foreach my $name (keys %{$regs}) {
    if ($wd=~$regs->{$name}) {push @classes,$name;}
  }
  my $cl=join('+',@classes);
  if ($cl) {}
  elsif ($wd=~/\\/) {$cl='(macro)';}
  else {$cl='(unidentified)';} 
  return $cl;
}

# Print table body containing word frequencies
sub __print_sorted_freqs {
  my ($class,$Freq,$Word,$min)=@_;
  my $sum=0;
  my ($word,$wd,$freq);
  if (!defined $min) {$min=0;}
  if ($htmlstyle) {print "<tbody class='$class'>\n";}
  else {print "---\n";}
  for $wd (sort {$Freq->{$b} <=> $Freq->{$a}} keys %{$Freq}) {
    if (defined $Word) {$word=$Word->{$wd};} else {$word=$wd;}
    $freq=$Freq->{$wd};
    if ($freq>=$min) {
      $sum+=$freq;
      __print_word_freq($word,$freq);
    }
  }
  if ($min>0) {__print_word_freq('Sum of subset',$sum,'td','sum');}
  if ($htmlstyle) {print "</tbody>\n";}
}

# Print one word freq line
sub __print_word_freq {
  my ($word,$freq,$tag,$class)=@_;
  if (!defined $tag) {$tag='td';}
  if (defined $class) {$class=" class='$class'";} else {$class='';}
  if ($htmlstyle) {
    print "<tr$class><$tag>$word</$tag><$tag>$freq</$tag></tr>\n";
  } else {
    print $word,': ',$freq,"\n";
  }
}

# Print macro usage statistics
sub print_macro_stat {
  if ($htmlstyle) {print "<table class='stat'>\n<thead>\n";}
  __print_word_freq('Macro/envir','Freq','th');
  if ($htmlstyle) {print "</thead>\n";}
  if ($htmlstyle) {print "<tbody class='macrostat'>\n";}
  foreach my $name (sort keys %MacroUsage) {
    my $freq=$MacroUsage{$name};
    $name=text_to_printable($name);
    $name=text_to_print($name);
    if ($htmlstyle) {
      print "<tr><td>$name</td><td>$freq</td></tr>\n";
    } else {
      print $name,': ',$freq,"\n";
    }
  }
  if ($htmlstyle) {print "</tbody>\n";}
  if ($htmlstyle) {print "</table>\n";}
}

