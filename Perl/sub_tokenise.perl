#::::
#::: Routines for tokenising LaTeX code
#::
#: Routines for external access:
#:   >sub_parse
#:     next_token
#:
#:

# Get next token skipping comments and flushing output buffer
sub next_token {
  my ($tex,$simple_token)=@_;
  if (!defined $simple_token) {$simple_token=0;}
  my ($next,$type);
  my $style=$tex->{'style'};
  if (defined $tex->{'next'}) {print_style($tex->{'next'},$tex->{'style'});}
  $tex->{'style'}=undef;
  while (defined ($next=_get_next_token($tex,$simple_token))) {
    $type=$tex->{'type'};
    if ($type==$TOKEN_COMMENT) {
      print_style($next,'comment');
    } elsif ($type==$TOKEN_LINEBREAK) {
      if ($printlevel>0) {line_return(-1,$tex);}
    } else {
      return $next;
    }
  }
  return $next;
}

# Read, interpret and return next token
# If simple_token is set, words cannot form tokens
sub _get_next_token {
  my ($tex,$simple_token)=@_;
  my $next;
  my $ch;
  while (!$tex->{'eof'}) {
    $ch=substr($tex->{'line'},0,1);
    if ($ch eq '') {
      if (!more_texcode($tex)) {$tex->{'eof'}=1;}
      next;
    } elsif ($ch=~/^[ \t\f]/) {
      $tex->{'line'}=~s/^([ \t\f]+)//;
      return __set_token($tex,$1,$TOKEN_SPACE);
    } elsif ($ch eq "\n" || $ch eq "\r") {
      $tex->{'line'}=~s/^(\r\n?|\n)//;
      return __set_token($tex,$1,$TOKEN_LINEBREAK);
    } elsif (!$simple_token && $tex->{'line'}=~s/^($WordPattern)//o) {
      return __set_token($tex,$1,$TOKEN_WORD);
    } elsif ($simple_token && $tex->{'line'}=~s/^(\w)//) {
      # When parsing simple tokens (not words), only include single characters
      # TODO: the handling of simple tokens should be improved
      my $match=$1;
      if ($match=~/^$WordPattern$/) {return __set_token($tex,$match,$TOKEN_WORD);}
      else {return __set_token($tex,$match,$TOKEN_SYMBOL);}
    } elsif ($ch eq '\\') {
      if ($tex->{'line'}=~s/^(\\[{}%])//) {return __set_token($tex,$1,$TOKEN_SYMBOL);}
      if ($tex->{'line'}=~s/^(\\([a-zA-Z@]+|[^a-zA-Z@[:^print:]]))//) {return __set_token($tex,$1,$TOKEN_MACRO);}
      return __get_chtoken($tex,$ch,$TOKEN_END);
    } elsif ($ch eq '$') {
      $tex->{'line'}=~s/^(\$\$?)//;
      return __set_token($tex,$1,$TOKEN_MATH);
    } elsif ($ch eq '{' || $ch eq '}') {
      return __get_chtoken($tex,$ch,$TOKEN_BRACE);
    } elsif ($ch eq '[' || $ch eq ']') {
      return __get_chtoken($tex,$ch,$TOKEN_BRACKET);
    } elsif ($ch=~/^['"`:.,()[]!+-*=\/^_@<>~#&]$/) {
      return __get_chtoken($tex,$ch,$TOKEN_SYMBOL);
    } elsif ($ch eq '%') {
      if ($tex->{'line'}=~s/^(\%+TC:\s*endignore\b[^\r\n]*)//i) {
        __set_token($tex,$1,$TOKEN_TC);
        return "%TC:endignore";
      }
      if ($tex->{'line'}=~s/^(\%+[tT][cC]:[^\r\n]*)//) {return __set_token($tex,$1,$TOKEN_TC);}
      if ($tex->{'line'}=~s/^(\%+[^\r\n]*)//) {return __set_token($tex,$1,$TOKEN_COMMENT);}
      return __get_chtoken($tex,$ch,$TOKEN_COMMENT);
    } else {
      return __get_chtoken($tex,$ch,$TOKEN_END);
    }
  }
  return undef;
}

# Set next token and its type
sub __set_token {
  my ($tex,$next,$type)=@_;
  $tex->{'next'}=$next;
  $tex->{'type'}=$type;
  return $next;
}

# Set character token and remove from line
sub __get_chtoken {
  my ($tex,$ch,$type)=@_;
  $tex->{'line'}=substr($tex->{'line'},1);
  $tex->{'next'}=$ch;
  $tex->{'type'}=$type;
  return $ch;
}

