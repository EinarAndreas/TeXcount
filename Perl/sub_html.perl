#::::
#::: Routines for HTML output
#::
#: Routines for external access:
#:   >sub_options
#:     html_head()    print HTML header
#:   >sub_print
#:     html_tail()    print HTML ending
#:

# Print HTML header
sub html_head {
  if (defined $HTMLfile) {
    if (open(FH,$HTMLfile)) {
      my $text=join('',<FH>);
      close FH;
      if ( $text=~/^(.*)<!--+\s*texcount\s*--+>(.*)$/is
        || $text=~/^(.*)\$\{texcount\}(.*)$/is
        || $text=~/^(.*)(<\/body.*)$/is
        ) {
        $htmlopen=$1;
        $htmlclose=$2;
      } else {
        error($Main,"Invalid HTML template format.");
      }
    } else {
      error($Main,"HTML template file not found: $HTMLfile");
    }
  }
  if (defined $htmlopen) {
    $htmlopen=~s/\$\{encoding\}/\Q$outputEncoding\E/g;
    $htmlopen=~s/\$\{version\}/@{[_html_version()]}/g;
    print $htmlopen;
    $htmlopen=undef;
  } else {
    print "<html>\n<head>\n";
    print "<meta http-equiv='content-type' content='text/html; charset=$outputEncoding'>\n";
    _print_html_style();
    foreach (@htmlhead) {print $_,"\n";}
    print "</head>\n\n<body>\n";
    print "\n<h1>LaTeX word count";
    if ($showVersion>0) {print ' (version ',_html_version(),')'}
    print "</h1>\n";
  }
}

# Print HTML tail
sub html_tail {
  if (defined $htmlclose) {
    print $htmlclose;
    $htmlclose=undef;
  } else {
    print "</body>\n\n</html>\n";
  }
}

# Return version number using HTML
sub _html_version {
  my $htmlver=$versionnumber;
  $htmlver=~s/\b(alpha|beta)\b/&$1;/g;
  return $htmlver;
}

# Print HTML STYLE element
sub _print_html_style {
if (defined $CSShref) {
  print "<link rel='stylesheet' href='$CSShref' type='text/css'>\n";
  return;
}
if (defined $CSSfile) {
  if (open(FH,$CSSfile)) {
    print "<style>\n<!---\n",<FH>,"-->\n</style>\n";
    close(FH);
    return;
  } else {
    error($Main,"CSS file not found: $CSSfile");
  }
}
print <<END
###[[INCLUDE:text_html_style.txt]]
END
}
