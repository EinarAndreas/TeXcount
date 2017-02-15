#::::
#::: Routines for handling word counts
#::
#:   Routines for general external access:
#:     new_count($title)
#:     update_count_size($count)
#:     inc_count($tex,$cnt,$value)
#:     get_count($count,$cnt)
#:     get_sum_count($count)
#:     number_of_subcounts($count)
#:     next_subcount($tex,$title)
#:     add_to_total($total,$count)
#:


## Make new count object
# The "count object" is a hash containing:
#  - title: the title of the count (name of file, section, ...)
#  - counts: a list of numbers (the counts: files, text words, ...)
#  - subcounts: list of count objects (used by the TeX object)
#  - warnings: list of warnings produced
# The elements are specified by the $CONT_* constants.
sub new_count {
  my ($title)=@_;
  my @cnt=(0) x $SIZE_CNT;
  my %count=('counts'=>\@cnt,'title'=>$title,'subcounts'=>[],'errorcount'=>0,'warnings'=>{});
  return \%count;
}

# Ensure the count array is of the right size
sub update_count_size {
  my $count=shift @_;
  my $counts=$count->{'counts'};
  while (scalar @{$counts}<$SIZE_CNT) {push @$counts,0;}
}

# Increment TeX count for a given count type
sub inc_count {
  my ($tex,$cnt,$value)=@_;
  my $count=$tex->{'subcount'};
  if (!defined $value) {$value=1;}
  ${$count->{'counts'}}[$cnt]+=$value;
}

# Get count value for a given count type
sub get_count {
  my ($count,$cnt)=@_;
  my $counts=$count->{'counts'};
  if ($cnt<scalar @{$counts}) {return ${$counts}[$cnt];}
  else {return 0;}
}

# Compute sum count for a count object
sub get_sum_count {
  my $count=shift @_;
  my $sum=0;
  for (my $i=scalar(@sumweights);$i-->1;) {
    if ($sumweights[$i]) {
      #DEBUG: print "Count($i) = ",get_count($count,$i),"\n";
      #DEBUG: print "Weight($i) = ",$sumweights[$i],"\n";	
      $sum+=get_count($count,$i)*$sumweights[$i];
    }
  }
  return $sum;
}

# Returns the number of subcounts
sub number_of_subcounts {
  my $count=shift @_;
  if (my $subcounts=$count->{'subcounts'}) {
    return scalar(@{$subcounts});
  } else {
    return 0;
  }
}

# Returns the number of warnings (not distinct)
sub number_of_warnings {
  my $count=shift @_;
  my $n=0;
  foreach my $m (values %{$count->{'warnings'}}) {$n+=$m;}
  return $n;
}

# Returns the number of distinct warnings
sub number_of_distinct_warnings {
  my $count=shift @_;
  return scalar keys %{$count->{'warnings'}};
}

# Is a null count? (counts 1-7 zero, title starts with _)
sub _count_is_null {
  my $count=shift @_;
  if (!$count->{'title'}=~/^_/) {return 0;}
  for (my $i=1;$i<$SIZE_CNT;$i++) {
    if (get_count($count,$i)>0) {return 0;}
  }
  if (scalar keys %{$count->{'warnings'}}) {return 0;}
  if ($count->{'errorcount'}) {return 0;}
  return 1;
}

# Add one count to another
sub _add_to_count {
  my ($a,$b)=@_;
  update_count_size($a);
  update_count_size($b);
  for (my $i=0;$i<$SIZE_CNT;$i++) {
   ${$a->{'counts'}}[$i]+=${$b->{'counts'}}[$i];
  }
  while (my ($text,$n)=each %{$a->{'warnings'}}) {
    $a->{'warnings'}->{$text}+=$n;
  }
  $a->{'errorcount'}+=$b->{'errorcount'};
}

# Add subcount to sum count and prepare new subcount
sub next_subcount {
  my ($tex,$title)=@_;
  add_to_total($tex->{'countsum'},$tex->{'subcount'});
  $tex->{'subcount'}=new_count($title);
  return $tex->{'countsum'};
}

# Add count to total as subcount
sub add_to_total {
  my ($total,$count)=@_;
  _add_to_count($total,$count);
  if (_count_is_null($count)) {return;}
  push @{$total->{'subcounts'}},$count;
  $count->{'parentcount'}=$total;
}
