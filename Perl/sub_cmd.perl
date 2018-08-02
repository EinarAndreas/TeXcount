#::::
#::: CMD specific implementations
#::
#: Routines for external access:
#:   >2_cmd_main
#:     option_ansi_colours($flag)
#:     conditional_print_total()
#:   >sub_parse
#:     include_file($tex,$state,$file,\%parms)
#:

# Add file to list of files scheduled for parsing
sub include_file {
  my ($tex,$state,$file,$refparam)=@_;
  my %params=%$refparam;
  my $type=$params{'<type>'};
  my @paths=@{$tex->{'PATH'}};
  if ($type eq '<bbl>' && defined $auxdir) {
    $auxdir=~s/([\\\/])*$/\//;
    if (defined $globalworkdir) {@paths=[$auxdir];}
    elsif ($auxdir=~/^(\w:)?[\\\/]/) {@paths=[$auxdir];}
    else {@paths=[$workdir.$auxdir]}
  }
  foreach my $key (split(/\s+/,$type)) {
    my $value=$params{$key};
    if ($key eq 'dir') {unshift @paths,$workdir.$value;}
    elsif ($key eq 'subdir') {unshift @paths,$paths[0].$value;}
  }
  # Decide full file path
  my $filepath;
  if ($file=~/^(\w:)?[\\\/]/) {$filepath=$file;}
  else {
    $filepath=_find_file_in_path($tex,$file,\@paths,$params{'SUFFICES'}) || BLOCK {
      error($tex,'File '.$file.' not found in path ['.join(';',@paths).'].');
      return;
    };
  }
  if ($includeTeX==$INCLUDE_MERGE) {
    my $bincode=read_binary($filepath) || BLOCK {
      error($tex,"File $filepath not readable.");
      return;
    };
    flush_next($tex);
    line_return(0,$tex);
    my $texstate=texcode_insert_text($tex,$bincode,$filepath,@paths);
    parse_all($tex,$state);
    texcode_restore_state($tex,$texstate);
  } else {
    push @filelist,[$filepath,@paths];
  }
}

# Seach path list to find file
sub _find_file_in_path {
  my ($tex,$file,$paths,$suffices)=@_;
  foreach my $suffix (@{$suffices}) {
    foreach my $path (@{$paths}) {
      if ($path && $path!~/[\\\/]$/) {$path.='/';}
      my $filepath=$path.$file.$suffix;
      if (-e $filepath && ! -d $filepath) {return $filepath;}
      # DELETE: elsif ($filepath=~/\.tex$/i) {}
      # DELETE: elsif (-e $filepath.'.tex') {return $filepath.'.tex';}
    }
  }
  return undef;
}

# Print count (total) if conditions are met
sub conditional_print_total {
  my $sumcount=shift @_;
  if ($totalflag || number_of_subcounts($sumcount)>1) {
    if ($totalflag && $briefsum && @sumweights) {
      print get_sum_count($sumcount),"\n";
    } elsif ($htmlstyle) {
      print "<div class='sumgroup'>\n";
      formatprint('Total word count','h2');
      print_count($sumcount,'sumcount');
      print "</div>\n";
    } else {
      print_count($sumcount,'sumcount');
    }
  }
}

# Set or unset use of ANSI colours
sub option_ansi_colours {
  my $flag=shift @_;
  $ENV{'ANSI_COLORS_DISABLED'} = $flag?undef:1;
}

# Print text using ANSI colours
sub ansiprint {
  my ($text,$colour)=@_;
  print Term::ANSIColor::colored($text,$colour);
}
