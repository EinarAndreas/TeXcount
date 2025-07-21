# Overrule default options and states for CGI use
$outputEncoding='utf8';
$showsubcounts=1;
$strictness=1;

# CGI specific global variables
my $EncryptedLogFile='LOG/texcount.enc'; # Encrypted log file

# Log encryption parameters
my $ECN = Int('0x1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7');
my $ECC = [Int('0x100000C'), Int('0x1'), Int('0x0')];
my $EC0 = [0];
my $ECP = [Int('0x1A4A4D7569399A726305537A33F2093BBE7F'),
           Int('0x2FD7EF49E4345D50B3E3DB9F8218683B900')];
my $ECQ = [Int('0xC1543B5C76FD9A4F85899876FCAB801E180'),
           Int('0xE2DE17838410F02B66C2ACEEE452F9C25B2')];
