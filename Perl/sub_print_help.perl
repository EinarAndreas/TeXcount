#::::
#::: Routines for printing help on output styles
#::
#: Routines for external access:
#:   >2_*_main
#:     conditional_print_style_list()
#:

# Print output style codes if conditions are met
sub conditional_print_style_list {
  if ($showcodes) {_print_style_list();}
  return $showcodes;
}

# Print help on output styles
sub _print_style_list {
  if ($printlevel<=0) {return;}
  if ($htmlstyle) {print '<div class="stylehelp"><p>';}
  formatprint('Format/colour codes of verbose output:','h2');
  print "\n\n";
  foreach my $style (@STYLE_LIST) {
    my $desc=$STYLE_DESC{$style};
    if ($desc=~/^(.*):\s+(.*)$/) {
      _help_style_line($1,$style,$2); # $1~${^PREMATCH}, $2~${^POSTMATCH}
    } else {
      _help_style_line($desc,$style);
    }
  }
  if ($htmlstyle) {print '</p></div>';}
  print "\n\n";
}

# Print one line of help
sub _help_style_line {
  my ($text,$style,$comment)=@_;
  if (!defined $comment) {$comment='';}
  if ($htmlstyle) {$comment='&nbsp;&nbsp;....&nbsp;&nbsp;'.text_to_print($comment);}
  else {$comment=' .... '.$comment;}
  if (print_style($text,$style)) {
    print $comment;
    linebreak();
  }
}
