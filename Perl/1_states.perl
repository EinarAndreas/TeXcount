#::::
#::: State and identifier code and keyword definitions
#::
#:
#:

### Counter indices from 0 to $SIZE_CNT-1
#   0: Number of files
#   1: Text words
#   2: Header words
#   3: Caption words
#   4: Number of headers
#   5: Number of floating environments
#   6: Number of inlined math
#   7: Number of displayed math
my $SIZE_CNT=8;
my $SIZE_CNT_DEFAULT=8;
my $CNT_FILE=0;
my $CNT_WORDS_TEXT=1;
my $CNT_WORDS_HEADER=2;
my $CNT_WORDS_OTHER=3;
my $CNT_COUNT_HEADER=4;
my $CNT_COUNT_FLOAT=5;
my $CNT_COUNT_INLINEMATH=6;
my $CNT_COUNT_DISPLAYMATH=7;

# Labels used to describe the counts
my @countkey=('file','word','hword','oword','header','float','inmath','dsmath');
my @countdesc=('Files','Words in text','Words in headers',
      'Words outside text (captions, etc.)','Number of headers','Number of floats/tables/figures',
      'Number of math inlines','Number of math displayed');

# Map keywords to counters
my %key2cnt;
add_keys_to_hash(\%key2cnt,$CNT_FILE,0,'file');
add_keys_to_hash(\%key2cnt,$CNT_WORDS_TEXT,1,'text','word','w','wd');
add_keys_to_hash(\%key2cnt,$CNT_WORDS_HEADER,2,'headerword','hword','hw','hwd');
add_keys_to_hash(\%key2cnt,$CNT_WORDS_OTHER,3,'otherword','other','oword','ow','owd');
add_keys_to_hash(\%key2cnt,$CNT_COUNT_HEADER,4,'header','heading','head');
add_keys_to_hash(\%key2cnt,$CNT_COUNT_FLOAT,5,'float','table','figure');
add_keys_to_hash(\%key2cnt,$CNT_COUNT_INLINEMATH,6,'inline','inlinemath','imath','eq');
add_keys_to_hash(\%key2cnt,$CNT_COUNT_DISPLAYMATH,7,'displaymath','dsmath','dmath','ds');


### Token types
# Set in $tex->{'type'} by call to _next_token
my $TOKEN_SPACE=-1;
my $TOKEN_COMMENT=0;
my $TOKEN_WORD=1; # word (or other form of text or text component)
my $TOKEN_SYMBOL=2; # symbol (not word, e.g. punctuation)
my $TOKEN_MACRO=3; # macro (\name)
my $TOKEN_BRACE=4; # curly braces: { }
my $TOKEN_BRACKET=5; # brackets: [ ]
my $TOKEN_MATH=6;
my $TOKEN_LINEBREAK=9; # line break in file
my $TOKEN_TC=666; # TeXcount instructions (%TC:instr)
my $TOKEN_END=999; # end of line or blank line


### Parsing states
#
## States for regions that should not be counted
#   IGNORE = exclude from count
#   FLOAT = float (exclude, but include captions)
#   EXCLUDE_STRONG = strong exclude, ignore environments
#   EXCLUDE_STRONGER = stronger exclude, do not parse macro parameters
#   EXCLUDE_ALL = ignore everything except end marker: even {
#   PREAMBLE = preamble (between \documentclass and \begin{document})
## States for regions in which words should be counted
#   TEXT = text
#   TEXT_HEADER = header text
#   TEXT_FLOAT = float text
## State change: not used in parsing, but to switch state then ignore contents
#   TO_INLINEMATH = switch to inlined math
#   TO_DISPLAYMATH = switch to displayed math
## Other states
#   _NULL = default state to use if none other is defined
#   _OPTION = state used to indicate that the next parameter is an option
#   _EXCLUDE_ = cutoff, state <= this represents excluded text
## NB: Presently, it is assumed that additional states is added as 8,9,...,
## e.g. that states added through TC:newcounter correspond to the added counters.
#
my $STATE_IGNORE=-1;
my $STATE_MATH=-2;
my $STATE_FLOAT=-10;
my $STATE_EXCLUDE_STRONG=-20;
my $STATE_EXCLUDE_STRONGER=-30;
my $STATE_EXCLUDE_ALL=-40;
my $STATE_SPECIAL_ARGUMENT=-90;
my $STATE_PREAMBLE=-99;
my $STATE_TEXT=1;
my $STATE_TEXT_HEADER=2;
my $STATE_TEXT_FLOAT=3;
my $STATE_TO_HEADER=4;
my $STATE_TO_FLOAT=5;
my $STATE_TO_INLINEMATH=6;
my $STATE_TO_DISPLAYMATH=7;
my $__STATE_EXCLUDE_=-10;
my $__STATE_NULL=1;
my $_STATE_OPTION=-1000;
my $_STATE_NOOPTION=-1001;
my $_STATE_AUTOOPTION=-1002;

# Counter key mapped to STATE
my $PREFIX_PARAM_OPTION=' '; # Prefix for parameter options/modifiers
my %key2state;
add_keys_to_hash(\%key2state,$STATE_TEXT,1,'text','word','w','wd');
add_keys_to_hash(\%key2state,$STATE_TEXT_HEADER,2,'headertext','headerword','hword','hw','hwd');
add_keys_to_hash(\%key2state,$STATE_TEXT_FLOAT,3,'otherword','other','oword','ow','owd');
add_keys_to_hash(\%key2state,$STATE_TO_HEADER,4,'header','heading','head');
add_keys_to_hash(\%key2state,$STATE_TO_FLOAT,5,'float','table','figure');
add_keys_to_hash(\%key2state,$STATE_TO_INLINEMATH,6,'inline','inlinemath','imath','eq');
add_keys_to_hash(\%key2state,$STATE_TO_DISPLAYMATH,7,'displaymath','dsmath','dmath','ds');
add_keys_to_hash(\%key2state,$STATE_IGNORE,0,'ignore','x');
add_keys_to_hash(\%key2state,$STATE_MATH,'ismath');
add_keys_to_hash(\%key2state,$STATE_FLOAT,-1,'isfloat');
add_keys_to_hash(\%key2state,$STATE_EXCLUDE_STRONG,-2,'xx');
add_keys_to_hash(\%key2state,$STATE_EXCLUDE_STRONGER,-3,'xxx');
add_keys_to_hash(\%key2state,$STATE_EXCLUDE_ALL,-4,'xall');
add_keys_to_hash(\%key2state,$STATE_SPECIAL_ARGUMENT,'specarg','spescialarg','specialargument');
add_keys_to_hash(\%key2state,$_STATE_OPTION,'[',' option',' opt',' optional');
add_keys_to_hash(\%key2state,$_STATE_NOOPTION,'nooption','nooptions','noopt','noopts');
add_keys_to_hash(\%key2state,$_STATE_AUTOOPTION,'autooption','autooptions','autoopt','autoopts');

# When combining two states, use the first one; list must be complete!
my @STATE_FIRST_PRIORITY=(
    $STATE_EXCLUDE_ALL,
    $STATE_EXCLUDE_STRONGER,
    $STATE_EXCLUDE_STRONG,
    $STATE_SPECIAL_ARGUMENT,
    $STATE_FLOAT,
    $STATE_MATH,
    $STATE_IGNORE,
    $STATE_PREAMBLE,
    $STATE_TO_FLOAT,
    $STATE_TO_HEADER,
    $STATE_TO_INLINEMATH,
    $STATE_TO_DISPLAYMATH);
my @STATE_MID_PRIORITY=();
my @STATE_LAST_PRIORITY=(
    $STATE_TEXT_FLOAT,
    $STATE_TEXT_HEADER,
    $STATE_TEXT);

# Map state to corresponding word counter
my %state2cnt=(
    $STATE_TEXT        => $CNT_WORDS_TEXT,
    $STATE_TEXT_HEADER => $CNT_WORDS_HEADER,
    $STATE_TEXT_FLOAT  => $CNT_WORDS_OTHER);

# Transition state mapped to content state and counter
my %transition2state=(
    $STATE_TO_HEADER      => [$STATE_TEXT_HEADER,$CNT_COUNT_HEADER],
    $STATE_TO_INLINEMATH  => [$STATE_MATH       ,$CNT_COUNT_INLINEMATH],
    $STATE_TO_DISPLAYMATH => [$STATE_MATH       ,$CNT_COUNT_DISPLAYMATH],
    $STATE_TO_FLOAT       => [$STATE_FLOAT      ,$CNT_COUNT_FLOAT]);

# Parsing state descriptions (used for macro rule help)
my %state2desc=(
    $STATE_IGNORE           => 'ignore: do not count',
    $STATE_MATH             => 'math/equation contents',
    $STATE_FLOAT            => 'float (figure, etc.): ignore all but special macros',
    $STATE_EXCLUDE_STRONG   => 'strong exclude: ignore environments',
    $STATE_EXCLUDE_STRONGER => 'stronger exclude: ignore environments and macro paramters',
    $STATE_EXCLUDE_ALL      => 'exlude all: even {, only scan for end marker',
    $STATE_PREAMBLE         => 'preamble: from \documentclass to \begin{document}',
    $STATE_TEXT             => 'text: count words',
    $STATE_TEXT_HEADER      => 'header text: count words as header words',
    $STATE_TEXT_FLOAT       => 'float text: count words as float words (e.g. captions)',
    $STATE_TO_HEADER        => 'header: count header, then count words as header words',
    $STATE_TO_FLOAT         => 'float: count float, then count words as float/other words',
    $STATE_TO_INLINEMATH    => 'inline math: count as inline math/equation',
    $STATE_TO_DISPLAYMATH   => 'displayed math: count as displayed math/equation');

# Parsing state presentation style
my %state2style=(
    $STATE_TEXT        => 'word',
    $STATE_TEXT_HEADER => 'hword',
    $STATE_TEXT_FLOAT  => 'oword',
    );

# State: is a text state..."include state" is more correct
sub state_is_text {
  my $st=shift @_;
  return ($st>=$STATE_TEXT);
}

# State: is a parsed/included region, text or preamble
sub state_is_parsed {
  my $st=shift @_;
  return ($st>=$STATE_TEXT || $st==$STATE_PREAMBLE);
}

# State: get CNT corresponding to text state (or undef)
sub state_text_cnt {
  my $st=shift @_;
  return $state2cnt{$st};
}

# State: is an exclude state
sub state_is_exclude {
  my $st=shift @_;
  return ($st<=$__STATE_EXCLUDE_);
}

# State: \begin and \end should be processed
sub state_inc_envir {
  my $st=shift @_;
  return ($st>$STATE_EXCLUDE_STRONG);
}

# State as text (used with printstate)
# TODO: Should do a conversion based on STATE values.
sub state_to_text {
  my $st=shift @_;
  return $st;
}

# Style to use with text state
sub state_to_style {
  return $state2style{shift @_};
}

# Add new counter with the given key and description
sub add_new_counter {
  my ($key,$desc,$like)=@_;
  my $state=$SIZE_CNT;
  my $cnt=$SIZE_CNT;
  $key=lc($key);
  if (!defined $like){$like=$CNT_WORDS_OTHER;}
  $key2cnt{$key}=$cnt;
  push @countkey,$key;
  push @countdesc,$desc;
  if (defined $sumweights[$like]) {$sumweights[$cnt]=$sumweights[$like];}
  $key2state{$key}=$state;
  $state2cnt{$state}=$cnt;
  $state2style{$state}='altwd';
  push @STATE_MID_PRIORITY,$state;
  $SIZE_CNT++;
}
