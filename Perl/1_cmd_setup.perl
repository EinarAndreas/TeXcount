## Preset command line options
# List of options (stings) separated by comma,
# e.g. ('-inc','-v') to parse included files and
# give verbose output by default.
my @StartupOptions=();

# CMD specific global variables
my @filelist; # List of files to parse
my $globalworkdir='./'; # Overrules workdir (default=present root)
my $workdir; # Current directory (default=taken from filename)
my $auxdir; # Directory for auxilary files, e.g. bbl (default=$workdir)
my $fileFromSTDIN=0; # Flag to set input from STDIN
my $_STDIN_='<STDIN>'; # File name to represent STDIN (must be '<...>'!)

# CMD specific settings
$Text::Wrap::columns=76; # Page width for wrapped output
