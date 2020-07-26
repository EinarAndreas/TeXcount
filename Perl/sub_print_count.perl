#::::
#::: Routines for printing count summary
#::
#:   >2_*_main,sub_cmd
#:     print_count($count[,$class])
#:   >2_sub_errors
#:     count_in_template($count,$template)
#:

# Print count summary for a count object
sub print_count {
  my ($count,$class,$title)=@_;
  line_return(0);
  if ($htmlstyle) {print "<div class='".($class||'count')."'>\n";}
  if (defined $title) {formatprint($title."\n",'h2');}
  if ($outputtemplate) {
    _print_count_template($count,$outputtemplate);
  } elsif ($briefsum && @sumweights) {
    _print_sum_count($count);
  } elsif ($briefsum) {
    if ($htmlstyle) {print "<p class='count'>";}
    _print_count_brief($count);
    if ($htmlstyle) {print "</p>\n";}
  } else {
    _print_count_details($count);
  }
  if ($htmlstyle) {print "</div>\n";}  
}

# Return count,header,... list filling in header if missing
sub __count_and_header {
  my $count=shift @_;
  my $header=__count_header($count);
  return $count,$header,@_;
}

# Return count title or '' if missing
sub __count_header {
  my $count=shift @_;
  return $count->{'title'}||'Word count';
}

# Print total count (sum) for a given count object
sub _print_sum_count {
  my ($count,$header)=__count_and_header(@_);
  if ($htmlstyle) {print "<p class='count'>".text_to_print($header).": ";}
  print get_sum_count($count);
  if ($htmlstyle) {print "</p>\n";}
  else {print ": ".text_to_print($header);}
  print "\n";
}

# Print brief summary of count object
sub _print_count_brief {
  my ($count,$header,$tag1,$tag2)=__count_and_header(@_);
  my @cnt=@{$count->{'counts'}};
  if ($htmlstyle && $tag1) {print '<',$tag1,'>';}
  print $cnt[$CNT_WORDS_TEXT],'+',$cnt[$CNT_WORDS_HEADER],'+',$cnt[$CNT_WORDS_OTHER];
  for (my $i=$SIZE_CNT_DEFAULT;$i<$SIZE_CNT;$i++) {
    if ($cnt[$i]) {print '+',$cnt[$i],$countkey[$i];}
  }
  print ' (',$cnt[$CNT_COUNT_HEADER],'/',$cnt[$CNT_COUNT_FLOAT],
      '/',$cnt[$CNT_COUNT_INLINEMATH],'/',$cnt[$CNT_COUNT_DISPLAYMATH],')';
  if ($htmlstyle && $tag2) {
    print '</',$tag1,'><',$tag2,'>';
    $tag1=$tag2;
  } else {print ' ';}
  print text_to_print($header);
  if ($htmlstyle && $tag1) {print '</',$tag1,'>';}
  if ($finalLineBreak) {print "\n";}
}

# Print detailed summary of count object
sub _print_count_details {
  my ($count,$header)=__count_and_header(@_);
  if ($htmlstyle) {print "<ul class='count'>\n";}
  if ($header) {formatprint($header."\n",'li','header');}
  if (my $tex=$count->{'TeXcode'}) {
    if (!defined $encoding) {formatprint('Encoding: '.$tex->{'encoding'}."\n",'li');}
  }
  if (@sumweights) {formatprint('Sum count: '.get_sum_count($count)."\n",'li');}
  for (my $i=1;$i<$SIZE_CNT;$i++) {
    formatprint($countdesc[$i].': '.get_count($count,$i)."\n",'li');
  }
  if (get_count($count,$CNT_FILE)>1) {
    formatprint($countdesc[$CNT_FILE].': '.get_count($count,$CNT_FILE)."\n",'li');
  }
  my $subcounts=$count->{'subcounts'};
  if ($showsubcounts && defined $subcounts && scalar(@{$subcounts})>=$showsubcounts) {
    formatprint("Subcounts:\n",'li');
    if ($htmlstyle) {print "<span class='subcount'>\n";}
    formatprint("  text+headers+captions (#headers/#floats/#inlines/#displayed)\n",'li','fielddesc');
    foreach my $subcount (@{$subcounts}) {
      print '  ';
      _print_count_brief($subcount,'li');
    }
    if ($htmlstyle) {print "</span>\n";}
  }
  if ($htmlstyle) {print "</ul>\n";} else {print "\n";}
}

# Print summary of count object using template
sub _print_count_template {
  my ($count,$header,$template)=__count_and_header(@_);
  $template=~s/\\n/\n/g;
  if ($htmlstyle) {$template=~s/\n/<br>/g;}
  my ($subtemplate,$posttemplate);
  while ($template=~/^(.*)\{SUB\?((.*?)\|)?(.*?)(\|(.*?))?\?SUB\}(.*)$/is) {
    __print_count_using_template($count,$1); # $1 ~ ${^PREMATCH}
    if (number_of_subcounts($count)>1) {
      if (defined $3) {print $3;}
      __print_subcounts_using_template($count,$4);
      if (defined $6) {print $6;}
    }
    $template=$7; # $7 ~ ${^POSTMATCH}
  }
  __print_count_using_template($count,$template);
}

# Return string with counts based on template
sub count_in_template {
  my ($count,$template)=@_;
  while (my ($key,$cnt)=each %key2cnt) {
    $template=__process_template($template,$key,get_count($count,$cnt));
  }
  $template=~s/\{VER\}/\Q$versionnumber\E/gi;
  $template=__process_template($template,'WARN|WARNING|WARNINGS',number_of_distinct_warnings($count));
  $template=__process_template($template,'NWARN|NWARNING|NWARNINGS',number_of_warnings($count));
  $template=__process_template($template,'ERR|ERROR|ERRORS',$count->{'errorcount'});
  $template=__process_template($template,'SUM',get_sum_count($count));
  $template=__process_template($template,'TITLE',$count->{'title'}||'');
  $template=__process_template($template,'SUB',number_of_subcounts($count));
  $template=~s/\{([\w\d\+\-\*]+)\}/__template_expression($1,$count)/ge;
  $template=~s/\a//gis;
  return $template;
}

# Process template expressions: {counter+2*counter-counter...}
sub __template_expression {
  my ($exp,$count)=@_;
  my $sum=0;
  while ( $exp=~s/^([\+\-]?)((\d+)\*)?(\w+)// ) {
    if (defined (my $cnt=$key2cnt{$4})) {
      my $num = get_count($count,$cnt);
      if ( $1 eq '-' ) {$num=-$num;}
      if (defined $2) {$num*=$3;}
      $sum+=$num;
    } else {
      print_error("Unknown counter: $2");
    }
  }
  return $sum;
}

# Print counts using template
sub __print_count_using_template {
  print count_in_template(@_);
}

# Print subcounts using template
sub __print_subcounts_using_template {
  my ($count,$template)=@_;
  my $subcounts=$count->{'subcounts'};
  if ($template && defined $subcounts && scalar(@{$subcounts})>=$showsubcounts) {
    foreach my $subcount (@{$subcounts}) {
      __print_count_using_template($subcount,$template);
    }
  }
}

# Process template for specific label
sub __process_template {
  my ($template,$label,$value)=@_;
  if ($value) {
    $template=~s/\{($label)\?([^\?\{\}]+?)\}/\{$label\}/gis;
    $template=~s/\{($label)\?(.*?)(\|(.*?))?\?(\1)\}/$2/gis;
  } else {
    $template=~s/\{($label)\?([^\?\{\}]+?)\}/$2/gis;
    $template=~s/\{($label)\?(.*?)\|(.*?)\?(\1)\}/$3/gis;
    $template=~s/\{($label)\?(.*?)\?(\1)\}//gis;
  }
  if (!defined $value) {$value='';}
  $template=~s/\{($label)\}/$value\a/gis;
  return $template;
}

