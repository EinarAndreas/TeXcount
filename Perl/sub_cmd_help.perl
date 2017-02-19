#::::
#::: Routines for printing help text
#::
#: Routines for external access:
#:   >2_cmd_main
#:     print_version() : Version
#:     print_license() : License
#:     print_help() : ShortHelp
#:     print_help_man() : HelpTitle + HelpText + Reference
#:     print_help_on_rule(name) : Help on particular macro/environment
#:     print_help_on_styles([style]) : Help on styles
#:     print_help_tcinst() : Help on TC-instructions 
#:     print_help_options() : Help on options
#:     print_help_options_subset(pattern) : Help on options, subset by pattern
#:

# Print TeXcount version
sub print_version {
  wprintstringdata('Version');
}

# Print TeXcount licence text
sub print_license {
  wprintstringdata('License');
}

# Print short TeXcount help
sub print_help {
  wprintstringdata('ShortHelp');
}

# Print main TeXcount help
sub print_help_man {
  wprintstringdata('HelpTitle');
  wprintstringdata('HelpText');
  wprintstringdata('Reference');
}

# Print help on TC instructions
sub print_help_tcinst {
  wprintstringdata('TCinstructions');
}

# Print TeXcount options list
sub print_help_options {
  wprintstringdata('OptionsHead');
  wprintstringdata('Options',StringDatum('OptionsFormat'));
}

# Print TeXcount options containing substring
sub print_help_options_subset {
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
    wprintlines(StringDatum('OptionsFormat'),@options);
  }
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
  if (!defined $def) {
    print "Takes no parameter(s).\n";
  } elsif (ref($def) eq 'ARRAY') {
    my $optionflag=0;
    print "Takes has the following parameters and parameter rules:\n";
    foreach my $state (@{$def}) {
      if ($state==$_STATE_OPTION) {$optionflag=1;}
      elsif ($state==$_STATE_NOOPTION) {print " - no [] options permitted here\n";}
      elsif ($state==$_STATE_AUTOOPTION) {}
      elsif ($optionflag) {
        $optionflag=0;
        print " + optional [] containing $state2desc{$state}\n";
      } else {
        print " + $state2desc{$state}\n";
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
    _print_rule_macro($arg,$def);
  } else {
    print "Takes no parameter(s).\n";
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
