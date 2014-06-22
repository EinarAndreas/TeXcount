#::::
#::: CGI specific implementations
#::
#: Routines for external access:
#:   >sub_parse
#:     include_file($tex,$state,$fname)
#:   >sub_print
#:     ansiprint($text,$colour)
#:

# Dummy implementation for adding included file to parsing list
sub include_file {
  my ($tex,$state,$file)=@_;
  error($tex,'Cannot include file when using web service');
}

# Print text using ANSI colours
sub ansiprint {
  my ($text,$colour)=@_;
  print $text;
}
