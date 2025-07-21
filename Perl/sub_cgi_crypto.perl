### Encryption routines

sub Int {
  my $x = shift @_;
  return Math::BigInt->new($x);
}

sub RndInt {
  my $N = shift @_;
  my $m = Int(0);
  my $RND = '.' x (length($N->as_hex()) >> 1);
  if (open my $R, "<:raw", "/dev/urandom") {
    read $R, $RND, length($RND);
    close $R;
    $RND =~ s/(.)/sprintf("%02X",ord($1))/egs;
    $m = Int("0x".$RND);
  } else {
    while ($m < $N) {
      $m = ($m<<32) + rand();
    }
  }
  $m = $m % $N;
  return $m;
}

sub ECCadd {
  my ($P,$Q) = @_;
  if ($P eq $EC0) {return $Q;}
  if ($Q eq $EC0) {return $P;}
  if ($P->[0] != $Q->[0]) {
      my ($s, $t);
      $s = ($P->[1])-($Q->[1]);
      $t = (($P->[0])-($Q->[0]))->bmodinv($ECN);
      $s = ($s*$t) % $ECN; # s = slope
      my $x = (($s*$s)-($ECC->[0])-($P->[0])-($Q->[0])) % $ECN;
      my $y = (-(($P->[1])+$s*($x-($P->[0])))) % $ECN;
      return [$x,$y];
  } elsif ($P->[1] eq $Q->[1]) {
    return ECCdup($P);
  } else {
    return  $EC0;
  }
}

sub ECCdup {
  my $P = shift @_;
  if ($P eq $EC0) {return $EC0;}
  my ($x,$y) = @{$P};
  if ($y eq 0) {return $EC0;}
  my ($s, $t);
  $s = (3*$x**2 + 2*($ECC->[0])*$x + ($ECC->[1])) % $ECN;
  $t = (2*($P->[1]))->bmodinv($ECN);
  $s = ($s*$t) % $ECN; # s = slope
  my $xx = ($s*$s-($ECC->[0])-2*$x) % $ECN;
  my $yy = (-($y+$s*($xx-$x))) % $ECN;
  return [$xx,$yy];
}

sub ECCmul {
  my ($P,$m) = @_;
  my $Q = $EC0;
  while ($m>0) {
    if ($m%2 eq 1) {
      $Q = ECCadd($Q,$P);
    }
    $m = $m>>1;
    $P = ECCdup($P);
  }
  return $Q;
}

sub Encrypt {
  #my $txt = encode('UTF-8',join(";",@_));
  my $txt = compress(join(";",@_));
  my $m = RndInt($ECN);
  my $mP = ECCmul($ECP,$m);
  my $mQ = ECCmul($ECQ,$m);
  my @enc;
  push @enc, $mP->[0]->as_hex(16),";";
  my ($R,$r,$i,$b) = $EC0,0,0;
  foreach (split(//,$txt)) {
    if (--$i<=0) {
      $R = ECCadd($R,$mQ);
      $r = $R->[0];
      $i = 8;
    }
    $b = $r & 0xFF;
    $r = $r>>8;
    push @enc,sprintf("%02x",ord($_)^$b);
  }
  return join('',@enc);
}
