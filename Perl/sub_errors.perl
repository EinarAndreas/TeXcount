#::::
#::: Routines for error handling
#::
#: Routines for external access:
#:   >*
#:     warning($tex,$text)
#:     error($tex,$text)
#:     error_details($tex,$text)
#:   >sub_options
#:     flush_errorbuffer($source)
#:

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
