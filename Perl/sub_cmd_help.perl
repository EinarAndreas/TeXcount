#::::
#::: Routines for printing help text
#::
#: Routines for external access:
#:   >2_cmd_main
#:     print_help()
#:     print_short_help()
#:     print_help_on_rule()
#:     print_help_on_styles()
#:     print_license()
#:     print_reference()
#:     print_syntax()
#:     print_version()
#:

# Print TeXcount version
sub print_version {
  wprintstringdata('Version');
}

# Print TeXcount reference text
sub print_reference {
  wprintstringdata('Reference');
}

# Print TeXcount licence text
sub print_license {
  wprintstringdata('License');
}

# Print short TeXcount help
sub print_short_help {
  wprintstringdata('ShortHelp');
}

# Print TeXcount options list
sub print_syntax {
  wprintstringdata('OptionsHead');
  wprintstringdata('Options','@ -          :');
}

# Prinst TeXcount options containing substring
sub print_syntax_subset {
  my $pattern=shift @_;
  my $data=StringData('Options');
  if (!defined $data) {
    error($Main,'No StringData Options.','BUG');
    return;
  }
  my @options;
  foreach (@$data) {
    if (/^\s*([^\s]+\s)*[^\s]*\Q$pattern\E/) {push @options,$_;}
  }
  if (scalar(@options)==0) {print "No options contained $pattern.\n";}
  else {
    print "Options containing \"$pattern\":\n\n";
    wprintlines('@ -          :',@options);
  }
}

# Print complete TeXcount help
sub print_help {
  print_help_title();
  print_syntax();
  print_help_text();
  print_reference();
}

# Print help title 
sub print_help_title {
  wprintstringdata('HelpTitle');
}

# Print help text
sub print_help_text {
  wprintstringdata('HelpText');
  wprintstringdata('TCinstructions');
}

# Print help on specific macro or environment
sub print_help_on_rule {
  my $arg=shift @_;
  my $def;
  my %rules=(
    '\documentclass' => 'Initiates LaTeX document preamble.',
    '\begin' => 'Treatmend depends on environment handling rules.',
    '\def' => 'Excluded from count.',
    '\verb' => 'Strong exclude for enclosed region.',
    '$'    => 'Opens or closes inlined equation',
    '$$'   => 'Opens or closes displayed equation.',
    '\('   => 'Opens inlined equation.',
    '\)'   => 'Closes inlined equation initiated by \(.',
    '\['   => 'Opens displayed equation.',
    '\]'   => 'Closes displayed equation initiated by \[.');
  if (!defined $arg || $arg=~/^\s*$/) {
    print "\nSpecify macro or environment name after the -h= option.\n";
    return;
  }
  if ($arg=~/^[\w\-\%]+:/) {
    remove_all_rules();
    %rules=();
    while ($arg=~s/^([\w\-\%]+)://) {include_package($1);}
  }
  if ($def=$rules{$arg}) {
    print "\nSpecial rule (hard coded) for $arg\n";
    print $def."\n";
  } elsif ($arg=~/^\\/) {
    my $hasrule=0;
    print "\nRule(s) for macro $arg\n";
    if ($def=$TeXmacrocount{$arg}) {
      $hasrule=1;
    }
    if ($def=$TeXfileinclude{$arg}) {
      $hasrule=1;
      print "Takes file name as parameter which is included in document.\n";
    }
    if ($def=$TeXmacro{$arg}) {
      $hasrule=1;
      _print_rule_macro($arg,$def);
    }
    if ($def=$TeXfloatinc{$arg}) {
      $hasrule=1;
      print "\nIncluded inside floats:\n";
      _print_rule_macro($arg,$def);
    }
    if (!$hasrule) {
      print "\nNo macro rule defined for $arg.\nParameters treated as surrounding text.\n";
    }
  } else {
    if ($def=$TeXenvir{$arg}) {
      print "\nRule for environment $arg\n";
      _print_rule_macrocount($PREFIX_ENVIR.$arg);
      _print_rule_envir($arg,$def);
    } else {
      print "\nNo default environment rule defined for $arg.\nContent handled as surrounding text.\n";
    }
  }
}

# Print macro handling rule
sub _print_rule_macro {
  my ($arg,$def)=@_;
  if (ref($def) eq 'ARRAY') {
    my $optionflag=0;
    print "Takes the following parameter(s):\n";
    foreach my $state (@{$def}) {
      if ($state==$_STATE_OPTION) {$optionflag=1;}
      elsif ($optionflag) {
        $optionflag=0;
        print " - Optional [] containing $state2desc{$state}\n";
      } else {
        print " - $state2desc{$state}\n";
      }
    }
  } else {
    print "Takes $def parameter(s): content ignored, i.e. not included in counts.\n";
  }
}

# Print environment handling rule
sub _print_rule_envir {
  my ($arg,$def)=@_;
  print "Contents parsed as $state2desc{$def}\n";
  if ($def=$TeXmacro{$PREFIX_ENVIR.$arg}) {
    _print_rule_macro($def);
  }
}

# Print macrocount rule, return rule
sub _print_rule_macrocount {
  my $arg=shift @_;
  my $def=$TeXmacrocount{$arg};
  if (!defined $def) {return undef;}
  if (ref($def) eq 'ARRAY') {
    my @wd=@$def;
    foreach (@wd) {$_=$countdesc[$_];}
    print 'Increments the following counters: ',join('; ',@wd),".\n";
  } else {
    print "Counted as $def word(s).\n";
  }
}

# Print style or style category summary
sub print_help_on_styles {
  my $style=shift @_;
  if (defined $style) {
    if (my $def=$STYLES{$style}) {
      _print_help_on_style_category($style);
      print wrap('','    ',"$style = ".join(', ',grep(/^\w+$/,sort keys %$def))),".\n";
    } elsif ($def=$STYLE_DESC{$style}) {
      print $style,' = ',$def,"\n";
    } else {
      print "Unknown style or style category: $style.\n";
    }
  } else {
    print wrap('','   ','Styles: '.join(', ',@STYLE_LIST)),".\n\n";
    print wrap('','   ','Style categories: '.join(', ',sort grep(/^\w+$/,keys %STYLES))),".\n\n";
    print "Use -help-style={style} to get help on particular style or style category.\n";
  }
}

# Print help on a particular style category (optional prefix and indentation)
sub _print_help_on_style_category {
  my ($cat,$prefix,$indent)=@_;
  if (!defined $prefix) {$prefix='';}
  if (!defined $indent) {$indent='   ';}
}
