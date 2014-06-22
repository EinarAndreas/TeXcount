#::::
#::: TeXcode object for referencing TeX code and counts
#::
#:   >1__setup
#:     getMain()
#:   >2_cgi_main, sub_cmd_filehandle
#:     TeXcode($texcode,[$filename],[$title])
#:   >sub_parse
#:     more_texcode($tex)
#:     apply_substitution_rule($tex,$from,$to)
#:   >sub_count
#:     prepend_code($tex,$latexcode)
#:
#:   Routines for general external access:
#:     get_texsize($tex)
#:


# Return object capable of capturing errors for use when
# no TeXcode object is available.
sub getMain {
  my %main=();
  $main{'errorcount'}=0;
  $main{'errorbuffer'}=[];
  $main{'warnings'}={};
  return \%main;
}


## Make TeX handle for LaTeX code: the main TeXcount object
# The "TeX object" is a data containser: a hash containing
#  - filepath: path of LaTeX file being parsed
#  - filename: file name of LaTeX file
#  - dirpath: path to directory containing LaTeX file
#  - PATH: array of paths to search for included files
#  - countsum: count object with total count (incl. subcounts)
#  - subcount: count object for subcount (to be added to countsum)
#  - subcounts: list of subcounts
#  - errorcount: the number of errors reported
# plus following elements used for the processing the LaTeX code 
#  - line: the LaTeX paragraph being processed
#  - texcode: what remains of LaTeX code to process (after line)
#  - texlength: length of LaTeX code
#  - next: the next token, i.e. the one being processed
#  - type: the type of the next token
#  - style: the present output style (for verbose output)
#  - printstate: present parsing state (for verbose output only)
#  - eof: set once the end of the input is reached
# which are passed to methods by passing the TeX object. It is used when parsing
# the LaTeX code, and discarded once the parsing is done. During parsing, counts
# are added to the subcount element; whenever a break point is encountered, the
# subcount is added to the countsum (next_subcount) and a new subcount object
# prepared. Note that this requires that the last subcount object be added to
# the countsum once the end of the document is reached.
sub TeXcode {
  my ($bincode,$file,$title)=@_;
  my $tex=_TeXcode_blank($file,$title);
  _TeXcode_setcode($tex,$bincode);
  more_texcode($tex);
  return $tex;
}

# Return a blank TeXcode object
sub _TeXcode_blank {
  my ($file,$title)=@_;
  if (defined $title) {}
  elsif (defined $file) {$title='File: '.$file;}
  else {$title='Word count';}
  my %TeX=();
  $TeX{'errorcount'}=0;
  $TeX{'warnings'}={};
  $TeX{'filepath'}=$file;
  if (!defined $file) {}
  elsif ($file=~/^<.+>$/) {$TeX{'filename'}=$file;}
  elsif ($file=~/^(.*[\\\/])([^\\\/]+)$/) {
    $TeX{'dirpath'}=$1; $TeX{'filename'}=$2;
  }
  else {$TeX{'dirpath'}=''; $TeX{'filename'}=$file;}
  $TeX{'PATH'}=[];
  $TeX{'line'}='';
  $TeX{'next'}=undef;
  $TeX{'type'}=undef;
  $TeX{'style'}=undef;
  $TeX{'printstate'}=undef;
  $TeX{'eof'}=0;
  my $countsum=new_count($title);
  $TeX{'countsum'}=$countsum;
  $countsum->{'TeXcode'}=\%TeX;
  my $count=new_count('_top_');
  $TeX{'subcount'}=$count;
  inc_count(\%TeX,$CNT_FILE);
  return \%TeX;
}

# Set the texcode element of the TeXcount object
sub _TeXcode_setcode {
  my ($tex,$bincode)=@_;
  $tex->{'texcode'}=_prepare_texcode($tex,$bincode);
  $tex->{'texlength'}=length($tex->{'texcode'});
}

# Decode and return TeX/LaTeX code
sub _prepare_texcode {
  my ($tex,$texcode)=@_;
  $texcode=_decode_texcode($tex,$texcode);
  foreach my $key (keys %substitutions) {
    my $value=$substitutions{$key};
    $texcode=~s/(\w)\Q$key\E/$1 $value/g;
    $texcode=~s/\Q$key\E/$value/g;
  }
  return $texcode;
}

# Return text decoder
sub _decode_texcode {
  my ($tex,$texcode)=@_;
  my $decoder;
  if (defined $encoding) {
    $decoder=find_encoding($encoding);
    eval {$texcode=$decoder->decode($texcode);};
    if ($@) {
      error($tex,'Decoding file/text using the '.$decoder->name.' encoding failed.');
    }
  } else {
    ($texcode,$decoder)=_guess_encoding($texcode);
    if (!ref($decoder)) {
      error($tex,'Failed to identify encoding or incorrect encoding specified.');
      $tex->{'encoding'}='[FAILED]';
      return $texcode;
    }
  }
  __set_encoding_name($tex,$decoder->name);
  $texcode =~ s/^\x{feff}//; # Remove BOM (relevant for UTF only)
  if ($texcode =~/\x{fffd}/ ) {
    error($tex,'File/text was not valid '.$decoder->name.' encoded.');
  }
  return $texcode;
}

# Guess the right encoding to use
sub _guess_encoding {
  my ($texcode)=@_;
  foreach my $enc (@encodingGuessOrder) {
    my $dec=find_encoding($enc);
    if (ref($dec)) {
      eval {
        $texcode=$dec->decode($texcode,Encode::FB_CROAK)
      };
      if (!$@) {return $texcode,$dec;}
    }
  }
  return $texcode,undef;
}

# Set name of current encoding
sub __set_encoding_name {
  my ($tex,$enc)=@_;
  my $cur=$tex->{'encoding'};
  if (!defined $enc) {$enc='[FAILED]';} # Shouldn't happen here though...
  if (!defined $cur) {}
  elsif ($enc eq 'ascii') {$enc=$cur;}
  elsif ($cur eq 'ascii') {}
  elsif ($cur ne $enc) {
    error($tex,"Mismatching encodings: $cur versus $enc.");
  }
  $tex->{'encoding'}=$enc;
}

# Apply substitution rule
sub apply_substitution_rule {
  my ($tex,$from,$to)=@_;
  $tex->{'line'}=~s/(\w)\Q$from\E\b\s*/$1 $to/g;
  $tex->{'line'}=~s/\Q$from\E\b\s*/$to/g;
  $tex->{'texcode'}=~s/(\w)\Q$from\E\b\s*/$1 $to/g;
  $tex->{'texcode'}=~s/\Q$from\E\b\s*/$to/g;
}

## Get more TeX code from texcode buffer if possible, return 1 if done
sub more_texcode {
  my ($tex)=@_;
  if ($tex->{'texcode'} eq '') {return 0;}
  if ( $optionFast && $tex->{'texcode'} =~ s/^(.*?(\r{2,}|\n{2,}|(\r\n){2,}))//s ) {
    $tex->{'line'}.=$1; # $1 ~ ${^MATCH}
    return 1;
  }
  $tex->{'line'}.=$tex->{'texcode'};
  $tex->{'texcode'}='';
  return 1;
}

## Prepend LaTeX code to TeXcode object
sub prepend_code {
  my ($tex,$code,$filename)=@_;
  my $prefix="\n% --- Start of included file $filename\n";
  my $suffix="\n% --- End of included file $filename\n";
  $code=_decode_texcode($tex,$code);
  $tex->{'length'}+=length($code);
  $tex->{'texcode'}=$prefix.$code.$suffix.$tex->{'line'}.$tex->{'texcode'};
  $tex->{'line'}='';
  more_texcode($tex);
}

# Save and return TeXcode state, and replace with new text
sub texcode_insert_text {
  my ($tex,$code,$filename,@path)=@_;
  my %texstate=(
      'texcode'=>$tex->{'line'}.$tex->{'texcode'},
      'eof'=>$tex->{'eof'},
      'PATH'=>$tex->{'PATH'});
  my $prefix="\n% --- Start of included file $filename\n";
  my $suffix="\n% --- End of included file $filename\n";
  $code=_decode_texcode($tex,$code);
  $tex->{'length'}+=length($code);
  $tex->{'texcode'}=$prefix.$code.$suffix;
  $tex->{'line'}='';
  more_texcode($tex);
  return \%texstate;
}

# Restore TeXcode state
sub texcode_restore_state {
  my ($tex,$texstate)=@_;
  while (my ($key,$value)=each %$texstate) {
    $tex->{$key}=$value;
  }
}

## Returns size of TeX code in bytes
sub get_texsize {
  my $tex=shift @_;
  return $tex->{'texlength'}
}

