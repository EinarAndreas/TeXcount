#::::
#::: Routines for reading TeX files
#::
#: Routines for external access:
#:   >2_cmd_main
#:     TeXfile($filename)
#:   >sub_cmd
#:     read_binary($filename)
#:

# Read LaTeX file into TeX object
sub TeXfile {
  my ($filename,$title)=@_;
  my ($header,$bincode);
  if ($filename eq $_STDIN_) {
    $header='File from STDIN';
    $bincode=_read_stdin();
  } else {
    defined ($bincode=read_binary($filename)) || return undef;
    $header='File: '.$filename;
  }
  if ($printlevel>0) {
    formatprint($header."\n",'h2');
    $blankline=0;
  }
  my $tex=TeXcode($bincode,$filename,$title);
  return $tex;
}

# Read file to string without regard for encoding
sub read_binary {
  my $filename=shift @_;
  open(FH,$filename) || return undef;
  binmode(FH);
  my $bincode;
  read(FH,$bincode,-s FH);
  close(FH);
  return $bincode;
}

# Read file from STDIN
sub _read_stdin {
  my @text=<STDIN>;
  my $latexcode=join('',@text);
  return $latexcode;
}
