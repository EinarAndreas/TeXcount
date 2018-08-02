### Options and states

# Outer object (for error reports not added by a TeX object)
my $Main=getMain();

# Global options and settings
my $htmlstyle=$HTML_NONE; # Flag to print HTML
my $texcodeoutput=0; # Flag to convert output to valid TeX text
my $encoding=undef; # Selected input encoding (default will be guess)
my @encodingGuessOrder=qw/ascii utf8 latin1/; # Encoding guessing order
my $outputEncoding; # Encoding used for output
my @AlphabetScripts=qw/Digit Is_alphabetic/; # Letters minus logograms: defined later
my @LogogramScripts=qw/Ideographic Katakana Hiragana Thai Lao Hangul/; # Scripts counted as whole words

# Parsing rules options
my $includeTeX=$INCLUDE_NONE; # Flag to parse included files
my $includeBibliography=0; # Flag to include bibliography
my %substitutions; # Substitutions to make globally
my %IncludedPackages; # List of included packages

# Counting options
my @sumweights; # Set count weights for computing sum
my $optionWordFreq=0; # Count words of this frequency, or don't count if 0
my $optionWordClassFreq=0; # Count words per word class (language) if set
my $optionMacroStat=0; # Count macro, environment and package usage

# Parsing details options
my $strictness=0; # Flag to check for undefined environments 
my $defaultVerbosity='0'; # Specification of default verbose output style
my $defaultprintlevel=0; # Flag indicating default level of verbose output
my $printlevel=undef; # Flag indicating level of verbose output
my $showstates=0; # Flag to show internal state in verbose log
my $showcodes=1; # Flag to show overview of colour codes (2=force)
my $showsubcounts=0; # Write subcounts if #>this, or not (if 0)
my $separatorstyleregex='^word'; # Styles (regex) after which separator should be added
my $separator=''; # Separator to add after words/tokens

# Final summary output options
my $showVersion=0; # Indicator that version info be included (1) or not (-1)
my $totalflag=0; # Flag to write only total summary
my $briefsum=0; # Flag to set brief summary
my $outputtemplate; # Output template
my $finalLineBreak=1; # Add line break at end

# Global settings
my $optionFast=1; # Flag inticating fast method 

# Global variables and internal states (for internal use only)
my $blankline=0; # Number of blank lines printed
my $errorcount=0; # Number of errors in parsing
my %warnings=(); # Warnings
my %WordFreq; # Hash for counting words
my %MacroUsage; # Hash for counting macros, environments and packages

# External sources
my $HTMLfile; # HTML file to use as HTML output template
my $CSSfile; # CSS file to use with HTML output
my $CSShref; # CSS reference to use with HTML output
my @htmlhead; # Lines to add to the HTML header
my $htmlopen; # text used to open the HTML file
my $htmlclose; # text used to close the HTML file

# String data storage
my $STRINGDATA;

# Other constants
my $_PARAM_='<param>'; # to identify parameter to _parse_unit
my $STRING_PARAMETER='{_}'; # used to log macro parameters
my $STRING_OPTIONAL_PARAM='[_]'; # used to log optional parameter
my $STRING_GOBBLED_OPTION='[]'; # used to log gobbled macro option
my $STRING_ERROR='<error>'; # used to log errors causing parsing to stop
my $REGEX_NUMBER=qr/^\d+$/; # regex to recognize a number
