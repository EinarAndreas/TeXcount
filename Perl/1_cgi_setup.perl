# Overrule default options and states for CGI use
$outputEncoding='utf8';
$showsubcounts=1;
$strictness=1;

# CGI specific global variables
my $LOGfilename='LOG/texcount.log'; # Log file
my $MacroUsageLogFile='LOG/macrousage.log'; # Log file for macro usage

# Unset log file if called from a test page
if (my $ref=referer()) {
  if ($ref=~/\/online_test\.\w+$/) {
    $LOGfilename=undef;
    $MacroUsageLogFile=undef;
  }
}

