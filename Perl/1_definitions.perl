#::::
#::: Definitions used in the verbose output
#::
#:
#:

### Break points
# Definition of macros that define break points that start a new subcount.
# The values given are used as labels.
my %BreakPointsOptions;
$BreakPointsOptions{'none'}={};
$BreakPointsOptions{'part'}={%{$BreakPointsOptions{'none'}},'\part'=>'Part'};
$BreakPointsOptions{'chapter'}={%{$BreakPointsOptions{'part'}},'\chapter'=>'Chapter'};
$BreakPointsOptions{'section'}={%{$BreakPointsOptions{'chapter'}},'\section'=>'Section'};
$BreakPointsOptions{'subsection'}={%{$BreakPointsOptions{'section'}},'\subsection'=>'Subsection'};
$BreakPointsOptions{'default'}=$BreakPointsOptions{'subsection'};
my %BreakPoints=%{$BreakPointsOptions{'none'}};

### Print styles
# Definition of different print styles: maps of class labels
# to ANSI codes. Class labels are as used by HTML styles.
my %STYLES;
my $STYLE_EMPTY=' ';
my $STYLE_BLOCK='-';
my $NOSTYLE=' ';
$STYLES{'Errors'}={'error'=>'bold red'};
$STYLES{'Words'}={'word'=>'blue','hword'=>'bold blue','oword'=>'blue','altwd'=>'blue'};
$STYLES{'Macros'}={'cmd'=>'green','fileinc'=>'bold green','special'=>'bold red','specarg'=>'red'};
$STYLES{'Options'}={'option'=>'yellow','optparm'=>'green'};
$STYLES{'Ignored'}={'ignore'=>'cyan','math'=>'magenta'};
$STYLES{'Excluded'}={'exclcmd'=>'yellow','exclenv'=>'yellow','exclmath'=>'yellow','mathcmd'=>'yellow'};
$STYLES{'Groups'}={'document'=>'bold red','envir'=>'red','mathgroup'=>'magenta'};
$STYLES{'Comments'}={'tc'=>'bold yellow','comment'=>'yellow'};
$STYLES{'Sums'}={'cumsum'=>'yellow'};
$STYLES{'States'}={'state'=>'cyan underline'};
$STYLES{'<core>'}={%{$STYLES{'Errors'}},$STYLE_EMPTY=>$NOSTYLE,'<printlevel>'=>1};
$STYLES{0}={%{$STYLES{'Errors'}},'<printlevel>'=>0};
$STYLES{1}={%{$STYLES{'<core>'}},%{$STYLES{'Words'}},%{$STYLES{'Groups'}},%{$STYLES{'Sums'}}};
$STYLES{2}={%{$STYLES{1}},%{$STYLES{'Macros'}},%{$STYLES{'Ignored'}},%{$STYLES{'Excluded'}}};
$STYLES{3}={%{$STYLES{2}},%{$STYLES{'Options'}},%{$STYLES{'Comments'}},'<printlevel>'=>2};
$STYLES{4}={%{$STYLES{3}},%{$STYLES{'States'}}};
$STYLES{'All'}=$STYLES{4};
my %STYLE=%{$STYLES{$defaultVerbosity}};

my @STYLE_LIST=('error','word','hword','oword','altwd',
  'ignore','document','special','cmd','exclcmd',
  'option','optparm','envir','exclenv','specarg',
  'mathgroup','exclmath','math','mathcmd','comment','tc','fileinc','state','cumsum');
my %STYLE_DESC=(
  'error'       => 'ERROR: TeXcount error message',
  'word'        => 'Text which is counted: counted as text words',
  'hword'       => 'Header and title text: counted as header words',
  'oword'       => 'Caption text and footnotes: counted as caption words',
  'altwd'       => 'Words in user specified counters: counted in separate counters',
  'ignore'      => 'Ignored text or code: excluded or ignored',
  'document'    => '\documentclass: document start, beginning of preamble',
  'special'     => 'Special macros, eg require special handling or have side-effects',
  'cmd'         => '\macro: macro not counted, but parameters may be',
  'exclcmd'     => '\macro: macro in excluded region',
  'option'      => '[Macro options]: not counted',
  'optparm'     => '[Optional parameter]: content parsed and styled as counted',
  'specarg'     => 'Special argument, eg with side-effects',
  'envir'       => '\begin{name}  \end{name}: environment',
  'exclenv'     => '\begin{name}  \end{name}: environment in excluded region',
  'mathgroup'   => '$  $: counted as one equation',
  'exclmath'    => '$  $: equation in excluded region',
  'math'        => '2+2=4: maths (inside $...$ etc.)',
  'mathcmd'     => '$\macro$: macros inside maths',
  'comment'     => '% Comments: not counted',
  'tc'          => '%TC:TeXcount instructions: not counted',
  'fileinc'     => 'File to include: not counted but file may be counted later',
  'state'       => '[state]: internal TeXcount state',
  'cumsum'      => '[cumsum]: cumulative sum count');
