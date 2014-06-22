#::::
#::: Routines for handling macro rules
#::
#: Routines for external access:
#:   >2_*_main, sub_options, sub_parse
#:     include_package($incpackage)
#:   >sub_parse
#:     transition_to_content_state($tex,$state)
#:   >1_state
#:     add_keys_to_hash($hash,$value[[,key]])
#:   >1_def_rules
#:     convert_hash($hash,$convert[[,options]])
#:     key_to_state($key,$tex)
#:     keyarray_to_state($keyarray,$tex)
#:

# Takes hash, value, list of keys and adds mappings to hash
sub add_keys_to_hash {
  my $hash=shift @_;
  my $value=shift @_;
  foreach (@_) {
    $hash->{$_}=$value;
  }
}

# Add source hash to target hash, optionally converting values
sub __add_to_hash {
  my $target=shift @_;
  my $source=shift @_;
  my $convert=shift @_;
  if (!defined $convert) {$convert=&__dummy;}
  while (my ($key,$val)=each(%$source)) {
    $target->{$key}=$convert->($val,@_);
  }
}

# Convert hash by applying function to all values
sub convert_hash {
  my $hash=shift @_;
  my $convert=shift @_;
  while (my ($key,$val)=each(%$hash)) {
    $hash->{$key}=$convert->($val,@_);
  }
}

# Convert key to parser state constant
sub key_to_state {
  my ($key,$tex)=@_;
  return key_convert(lc($key),$tex,\%key2state,'Unknown state key {key} replaced by IGNORE.',$STATE_IGNORE);
}

# Convert key array to parser state constants
sub keyarray_to_state {
  my ($array,$tex)=@_;
  return keyarray_convert($array,$tex,\&key_to_state);
}

# Convert key to counter constant
sub key_to_cnt {
  my ($key,$tex)=@_;
  return key_convert(lc($key),$tex,\%key2cnt,'Unknown counter key {key} ignored.');
}

# Convert key array to counter constants
sub keyarray_to_cnt {
  my ($array,$tex)=@_;
  return keyarray_convert($array,$tex,\&key_to_cnt);
}

# Convert key to value using map
sub key_convert {
  my ($key,$tex,$map,$error,$default)=@_;
  my $value=$map->{$key};
  if (!defined $value) {
    if (!defined $tex) {$tex=$Main;}
    $error=~s/\{key\}/$key/g;
    error($tex,$error);
    return $default;
  }
  return $value;
}

# Convert state keys to state nos for arrays
sub keyarray_convert {
  my ($array,$tex,$conv)=@_;
  if (ref($array) eq 'ARRAY') {
    my @ar;
    foreach my $key (@$array) {
      if (defined (my $cnt=$conv->($key,$tex))) {push @ar,$cnt;}
    }
    $array=\@ar;
  }
  return $array;
}

# Convert transition state to parsing state, and increment counter
sub transition_to_content_state {
  my ($tex,$state)=@_;
  my $tr=$transition2state{$state};
  if (defined $tr) {
    if (my $cnt=$tr->[1]) {inc_count($tex,$tr->[1]);}
    return $tr->[0];
  }
  return $state;
}

# Remove all rules
sub remove_all_rules {
  %TeXpackageinc=();
  %TeXpreamble=();
  %TeXfloatinc=();
  %TeXmacro=();
  %TeXmacrocount=();
  %TeXenvir=();
  %TeXfileinclude=();
  %IncludedPackages=();
}

# Process package inclusion
sub include_package {
  my ($incpackage,$tex)=@_;
  if (defined $IncludedPackages{$incpackage}) {return;}
  $IncludedPackages{$incpackage}=1;
  # Add rules for package, preamble and float inclusion, and add to macro rules
  _add_package(\%TeXpackageinc,\%PackageTeXpackageinc,$incpackage,\&__dummy,$tex);
  _add_package(\%TeXpreamble,\%PackageTeXpreamble,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXfloatinc,\%PackageTeXfloatinc,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXmacro,\%PackageTeXpackageinc,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXmacro,\%PackageTeXpreamble,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXmacro,\%PackageTeXfloatinc,$incpackage,\&keyarray_to_state,$tex);
  # Add regular rules
  _add_package(\%TeXmacro,\%PackageTeXmacro,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXmacrocount,\%PackageTeXmacrocount,$incpackage,\&keyarray_to_cnt,$tex);
  _add_package(\%TeXenvir,\%PackageTeXenvir,$incpackage,\&key_to_state,$tex);
  _add_package(\%TeXfileinclude,\%PackageTeXfileinclude,$incpackage,\&__dummy,$tex);
  if (my $subpackages=$PackageSubpackage{$incpackage}) {
    foreach my $sub (@{$subpackages}) {
      include_package($sub,$tex);
    }
  }
}

# Add package rules if defined
sub _add_package {
  my ($target,$source,$name,$convert,$tex)=@_;
  my $sub;
  if ($sub=$source->{$name}) {
    __add_to_hash($target,$sub,$convert);
  }
}

# Dummy conversion function: returns arguments unchanged
sub __dummy {
  return shift @_;
}
