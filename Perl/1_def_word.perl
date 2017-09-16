#:::: 
#::: Definitions related to word recognition and languages
#::
#: Character groups of letters used to form words are stored
#: in @AlphabetScripts, while character groups that represent
#: logograms (i.e. each character should be counted as a word)
#: is stored in @LogogramScripts. 
#:
#: Letter patterns to use, and hash with alternatives:
#:   $LetterPattern  <-- %NamedLetterPattern
#: The @ character is later replaced by a letter pattern based
#: on letters in @AlphabetScripts.
#:
#: Word patterns to use, and hash with alternatives: 
#:   $WordPattern = join('|',@WordPatterns) <-- %NamedWordPattern
#:

# Patters matching a letter. Should be a single character or
# ()-enclosed regex for substitution into word pattern regex.
my @LetterMacros=qw/ae AE o O aa AA oe OE ss
   alpha beta gamma delta epsilon zeta eta theta iota kappa lamda
   mu nu xi pi rho sigma tau upsilon phi chi psi omega
   Gamma Delta Theta Lambda Xi Pi Sigma Upsilon Phi Psi Omega 
   /;
my $specialchars='\\\\('.join('|',@LetterMacros).')(\{\}|\s+|\b)';
my $modifiedchars='\\\\[\'\"\`\~\^\=](@|\{@\})';
my %NamedLetterPattern;
$NamedLetterPattern{'restricted'}='@';
$NamedLetterPattern{'default'}='('.join('|','@',$modifiedchars,$specialchars).')';
$NamedLetterPattern{'relaxed'}=$NamedLetterPattern{'default'};
my $LetterPattern=$NamedLetterPattern{'default'};

# List of regexp patterns that should be analysed as words.
# Use @ to represent a letter, will be substituted with $LetterPattern.
# Named patterns may replace or be appended to the original patterns.
# Apply_Options() results in a call to apply_language_options() which
# constructs $WordPattern based on $LetterPattern, @WordPatterns and
# alphabet/logogram settings.
my %NamedWordPattern;
$NamedWordPattern{'letters'}='@';
$NamedWordPattern{'words'}='(@+|@+\{@+\}|\{@+\}@+)([\-\'\.]?(@+|\{@+\}))*';
my @WordPatterns=($NamedWordPattern{'words'});
my $WordPattern; # Regex matching a word (defined in apply_language_options())

### Macro option regexp list
# List of regexp patterns to be gobbled as macro option in and after
# a macro.
my %NamedMacroOptionPattern;
$NamedMacroOptionPattern{'default'}='\[[^\[\]\n]*\]';
$NamedMacroOptionPattern{'relaxed'}='\[\n?([^\[\]\n]\n?)*\]';
$NamedMacroOptionPattern{'restricted'}='\[(\w|[,\-\s\~\.\:\;\+\?\*\_\=])*\]';
my $MacroOptionPattern=$NamedMacroOptionPattern{'default'};

### Alternative language encodings
my %NamedEncodingGuessOrder;
$NamedEncodingGuessOrder{'chinese'}=[qw/utf8 gb2312 big5/];
$NamedEncodingGuessOrder{'japanese'}=[qw/utf8 euc-jp iso-2022-jp jis shiftjis/];
$NamedEncodingGuessOrder{'korean'}=[qw/utf8 euc-kr iso-2022-kr/];

