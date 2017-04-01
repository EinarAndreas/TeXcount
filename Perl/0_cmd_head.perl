#! /usr/bin/env perl
use strict;
use warnings;
use utf8; # Because the script itself is UTF-8 encoded
use Encode;
use Text::Wrap;
use Term::ANSIColor;

# Conditional package inclusion
if ($^O=~/^MSWin/) {
  eval {
    require Win32::Console::ANSI;
    import Win32::Console::ANSI;
  };
  if ($@) {
    option_ansi_colours(0);
    print STDERR "NOTE: Package Win32::Console::ANSI required for colour coded output.\n";
  }
}

# Terminal width
my $terminalwidth;
defined $terminalwidth || eval {
  require Term::ReadKey;
  import Term::ReadKey;
  ($terminalwidth)=GetTerminalSize();
};
if (!defined $terminalwidth) {$terminalwidth=76;}
elsif ($terminalwidth<60) {$terminalwidth=60;}
elsif ($terminalwidth>120) {$terminalwidth=120;}
