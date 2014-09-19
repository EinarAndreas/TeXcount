#::::
#::: Routines for printing and styling output
#::
#: Routines for external access:
#:   >sub_parse
#:     flush_next($tex[,$style])
#:     set_style($tex,$style)
#:     print_style($tex,$style[,$state])
#:     line_return($blank[,$tex])
#:

# Print next token
sub flush_next {
  my ($tex,$style)=@_;
  my $ret=undef;
  if (defined $style) {set_style($tex,$style);}
  if (defined $tex->{'next'}) {
    $ret=print_style($tex->{'next'},$tex->{'style'},$tex->{'printstate'});
  }
  $tex->{'printstate'}=undef;
  $tex->{'style'}=$STYLE_BLOCK;
  return $ret;
}

# Print next token and gobble following spaces (incl. line break and comments)
sub flush_next_gobble_space {
  my ($tex,$style,$state)=@_;
  my $ret=flush_next($tex,$style);
  if (!defined $ret) {$ret=0;}
  if (!defined $state) {$state=$STATE_IGNORE;}
  my $prt=($printlevel>0);
  while (1) {
    if ($tex->{'line'}=~s/^([ \t\f]*)(\r\n|\r|\n)([ \t\f]*)//) {
      if (!$prt) {
      } elsif ($printlevel>1 || $ret) {
        print $1;
        line_return(-1,$tex);
        my $space=$3;
        if ($htmlstyle) {$space=~s/  /\&nbsp;/g;}
        print $space;
        $ret=0;
      } else {
        line_return(0,$tex);
      }
    } elsif ($tex->{'line'}=~s/^([ \t\f]+)//) {
      if ($prt) {print $1;}
    }
    if ($tex->{'line'}=~/^\%TC:/i) {return;}
    if ($tex->{'line'}=~s/^(\%+[^\r\n]*)//) {
      print_style($1,'comment');
      $ret=1;
    } else {return;}
  }
}

# Set presentation style
sub set_style {
  my ($tex,$style)=@_;
  if (!(defined $tex->{'style'} && $tex->{'style'} eq $STYLE_BLOCK)) {$tex->{'style'}=$style;}
}

# Print text using the given style, and log state if given
sub print_style {
  my ($text,$style,$state)=@_;
  (($printlevel>=0) && (defined $text) && (defined $style)) || return 0;
  my $colour;
  ($colour=$STYLE{$style}) || return;
  if (defined $colour && $colour ne '-') {
    print_with_style($text,$style,$colour);
    if (defined $state) {print_style($state,'state');}
    if ($style ne 'cumsum') {$blankline=-1;}
    return 1;
  } else {
    return 0;
  }
}

# Conditional line return
sub line_return {
  my ($blank,$tex)=@_;
  if ($blank<0 && $printlevel<2) {$blank=1;}
  if ($blank<0 || $blank>$blankline) {
    if ((defined $tex) && @sumweights) {
      my $num=get_sum_count($tex->{'subcount'});
      print_style(" [$num]",'cumsum');
    }
    linebreak();
    $blankline++;
  }
}
