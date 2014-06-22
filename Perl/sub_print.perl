#::::
#::: Routines for printing and output formating
#::
#:   Routines for general use
#:     formatprint($text,$tag,$class)
#:     linebreak()
#:   >sub_print_log
#:     print_with_style($text,$style,$colour)
#:

# Print text using given style/colour
sub print_with_style {
  my ($text,$style,$colour)=@_;
  if ($style eq $NOSTYLE) {
    print text_to_print($text);
  } elsif ($htmlstyle) {
    print "<span class='$style'>",text_to_print($text),'</span>';
  } else {
    ansiprint(text_to_print($text),$colour);
    if ($style=~/$separatorstyleregex/) {print $separator;}
  }
}

# Prepare text string for print: convert special characters
sub text_to_print {
  my $text=join('',@_);
  if ($htmlstyle) {
    $text=~s/&/&amp;/g;
    $text=~s/</&lt;/g;
    $text=~s/>/&gt;/g;
    $text=~s/[ \t]{2}/\&nbsp; /g;
  } elsif ($texcodeoutput) {
    $text=~s/\\/\\textbackslash¤/g;
    $text=~s/([%{}])/\\$1/g;
    $text=~s/¤/{}/g;
  }
  return $text;
}

# Return &#xxx; code for character ;
sub convert_to_charcode {
  my $ch=shift @_;
  return '&#'.ord($ch).';';
}

# Convert special characters to charcodes to make it printable ;
sub text_to_printable {
  my $text=shift @_;
  $text=~s/([^[:print:]])/convert_to_charcode($1)/gse;
  return $text;
}

# Print text, using appropriate tags for HTML
sub formatprint {
  my ($text,$tag,$class)=@_;
  my $break=($text=~s/(\r\n?|\n)$//);
  if ($htmlstyle && defined $tag) {
    print '<'.$tag;
    if ($class) {print " class='$class'";}
    print '>'.text_to_print($text)."</$tag>";
  } else {
    print text_to_print($text);
  }
  if ($break) {print "\n";}
}

# Add a line break to output
sub linebreak {
  if ($htmlstyle) {print "<br>\n";} else {print "\n";}
}
