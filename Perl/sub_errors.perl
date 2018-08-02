#::: Routines for handling errors, warnings, and notifications
#::
#: Routines for external access:
#:   >*
#:     warning($tex,$text)
#:     error($tex,$text)
#:     error_details($tex,$text)
#:   >sub_parse
#:     note($tex,$level,$text,$prefix,$style)
#:     assertion_note($tex,$checktext,$template)
#:   >sub_options
#:     flush_errorbuffer($source)
#:

# Print note to output
sub note {
  my ($tex,$level,$text,$prefix,$style)=@_;
  if ($printlevel>=$level) {
    $prefix=(defined $prefix)?$prefix:'%NOTE: ';
    $style=(defined $style)?$style:'note';
    $text=count_in_template($tex->{'subcount'},$text);
    flush_next($tex);
    line_return(0,$tex);
    print_style($prefix.$text,$style);
    flush_next($tex);
    $blankline=-1;    
  }
}

# Compare count with expected and note if assertion fails
sub assertion_note {
  my ($tex,$checktext,$template)=@_;
  my $count=$tex->{'subcount'};
  my @check=split(/,/,$checktext);
  my @actual;
  for (my $i=scalar @check;$i>0;$i--) {$actual[$i-1]=get_count($count,$i);}
  for (my $i=scalar @check;$i>0;$i--) {
    if ($check[$i-1] ne $actual[$i-1]) {
      my $msg=$template.' [expected:'.join('+',@check).'; found: '.join('+',@actual).']';
      note($tex,0,$msg,'%ASSERTION FAILED: ','error');
      return 1;
    }
  }
  return 0;
}

# Add warning to list of registered warnings (optionally to be reported at the end)
sub warning {
  my ($tex,$text)=@_;
  $warnings{$text}++;
  # TODO: should only add warnings to subcount, not to TeXcode object
  $tex->{'warnings'}->{$text}++;
  if (my $count=$tex->{'subcount'}) {$count->{'warnings'}->{$text}++};
}

# Register error and print error message
sub error {
  my ($tex,$text,$type)=@_;
  if (defined $type) {$text=$type.': '.$text;}
  $errorcount++;
  $tex->{'errorcount'}++;
  if (my $count=$tex->{'subcount'}) {$count->{'errorcount'}++};
  if (my $err=$tex->{'errorbuffer'}) {push @$err,$text;}
  else {print_error($text);}
}

# Print error details
sub error_details {
  my ($tex,$text)=@_;
  print STDERR $text,"\n";
}

# Make assertion: i.e. report error if not true and return truthfullness
sub assert {
  my $assertion=shift @_;
  if ($assertion) {return 1;}
  error(@_);
  return 0;
}

# Print error message
sub print_error {
  my $text=shift @_;
  line_return(1);
  if ($printlevel<0) {
    print STDERR 'ERROR: ',$text,"\n";
  } elsif ($htmlstyle) {
    print STDERR 'ERROR: ',$text,"\n";
    print_style($text,'error');
  } else {
    print_style("!!! $text !!!",'error');
  }
  line_return(1);
}

# Print errors in buffer and delete errorbuffer
sub flush_errorbuffer {
  my $source=shift @_;
  my $err=$source->{'errorbuffer'} || return;
  foreach (@$err) {print_error($_);}
  $source->{'errorbuffer'}=undef;
}
