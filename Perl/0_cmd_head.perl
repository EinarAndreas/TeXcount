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
    Win32::Console::ANSI::->import();
  };
  if ($@) {
    option_ansi_colours(0);
    print STDERR 'Package Win32::Console::ANSI required for colour coded output.';
  }
}