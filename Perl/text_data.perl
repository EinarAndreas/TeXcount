###:
##: Routines to interpret and format text data
#:
#:   >sub_cmd_help
#:     wprintstringdata($name,[@lines])


# Return the STRINGDATA hash (lazy instantiation)
sub STRINGDATA {
  if (!defined $STRINGDATA) {
    my @DATA=<DATA>;
    foreach (@DATA) {
      $_=~s/\$\{(\w+)\}/__apply_globaldata($1)/ge;
    }
    $STRINGDATA=splitlines(':{3,}\s*(\w+)?',\@DATA);
  }
  return $STRINGDATA;
}

# Return value from STRINGDATA hash
sub StringData {
  my $name=shift @_;
  return STRINGDATA()->{$name};
}

# Insert value from GLOBALDATA
sub __apply_globaldata {
  my $name=shift @_;
  if (my $value=$GLOBALDATA{$name}) {
    return $value;
  }
  return '[['.$name.']]';
}

# Print value from STRINGDATA using wprintlines
sub wprintstringdata {
  my $name=shift @_;
  my $data=StringData($name);
  if (!defined $data) {
    error($Main,"No StringData $name.",'BUG');
    return;
  }
  wprintlines(@_,@$data);  
}

# Divide array of lines by identifying headers
sub splitlines {
  my ($pattern,$lines)=@_;
  if (!defined $lines) {return;}
  my $id=undef;
  my %hash;
  foreach my $line (@$lines) {
    if ($line=~/^$pattern$/) {
      $id=$1;
      if (defined $id) {
        $hash{$id}=[];
        if (defined $2) {push @{$hash{$id}},$2;}
      }
    } elsif (defined $id) {
      chomp $line;
      push @{$hash{$id}},$line;
    }
  }
  return \%hash;
}

# Print string with word wrapping and indentation using
# wprintlines.
sub wprint {
  my $text=shift @_;
  my @lines=split(/\n/,$text);
  wprintlines(@lines);
}

# Print with word wrapping and indentation. A line with
# @  -    :
# sets two column tabs. A tab or multiple spaces is taken
# to indicate indentation. If the first column value is
# only a single '|', this is just an indication to skip
# one tab.
sub wprintlines {
  my @lines=@_;
  my $ind1=2;
  my $ind2=6;
  my $i;
  foreach my $line (@lines) {
    if ($line=~s/^@/ /) {
      $ind1=index($line,'-');
      $ind2=index($line,':');
      if ($ind1<1) {$ind1=$ind2;}
      next;
    }
    my $firstindent=0;
    if ($line=~s/^(\t|\s{2,})(\S)/$2/) {$firstindent=$ind1;}
    my $indent=$firstindent;
    if ($line=~/^(.*?\S)(\t|\s{2,})(.*)$/) {
      $indent=$ind2;
      if ($1 eq '|') {$line=' ';}
      else {$line=$1.'   ';}
      $i=$indent-$firstindent-length($line);
      if ($i>0) {$line.=' ' x $i;}
      $line.=$3; # $3~${^POSTMATCH}
    }
    print wrap(' ' x $firstindent,' ' x $indent,$line)."\n";
  }
}


########################################
##### TEXT DATA

__DATA__
