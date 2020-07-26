### Macros indicating package inclusion
# Will always be assumed to take one extra parameter which is the list of
# packages. Macro handling rule indicates parameters ignored prior to that.
# Gets added to TeXmacro. After that, values are not used, only membership.
# Handling is otherwise hard-coded rather than rule based.
my %TeXpackageinc;
add_keys_to_hash(\%TeXpackageinc,['[','ignore','specialargument'],'\usepackage','\RequirePackage');

### Macros that are counted within the preamble
# The preamble is the text between \documentclass and \begin{document}.
# Text and macros in the preamble is ignored unless specified here. The
# value is the states (1=text, 2=header, etc.) they should be interpreted as.
# Note that only the first unit (token or {...} block) is counted.
# Gets added to TeXmacro. Is used within preambles only.
my %TeXpreamble;
add_keys_to_hash(\%TeXpreamble,['header'],'\title');
add_keys_to_hash(\%TeXpreamble,['other'],'\thanks');
add_keys_to_hash(\%TeXpreamble,['xxx','xxx'],'\newcommand','\renewcommand');
add_keys_to_hash(\%TeXpreamble,['xxx','xxx','xxx'],'\newenvironment','\renewenvironment');

### In floats: include only specific macros
# Macros used to identify caption text within floats.
# Gets added to TeXmacro. Is used within floats only.
my %TeXfloatinc=('\caption'=>['otherword']);

### How many tokens to gobble after macro
# Each macro is assumed to gobble up a given number of
# tokens (or {...} groups), as well as options [...] before, within
# and after. The %TeXmacro hash gives a link from a macro
# (or beginNAME for environment with no the backslash)
# to either an integer giving the number of tokens to ignore
# or to an array (specified as [rule,rule,...]) of length N where
# N is the number of parameters to be read with the macro. The
# array values tell how each is to be interpreted (see the parser state
# keywords for valid values). Thus specifying a number N is
# equivalent to specifying an array of N 'ignore' rules.
#
# For macros not specified here, the default value is 0: i.e.
# no tokens are excluded, but [...] options are.
my %TeXmacro=(%TeXpreamble,%TeXfloatinc,%TeXpackageinc);
add_keys_to_hash(\%TeXmacro,['text'],
    '\textnormal','\textrm','\textit','\textbf','\textsf','\texttt','\textsc','\textsl','\textup','\textmd',
    '\makebox','\mbox','\framebox','\fbox','\uppercase','\lowercase','\textsuperscript','\textsubscript',
    '\citetext');
add_keys_to_hash(\%TeXmacro,['[','text'],
    '\item');
add_keys_to_hash(\%TeXmacro,['[','ignore'],
    '\linebreak','\nolinebreak','\pagebreak','\nopagebreak');
add_keys_to_hash(\%TeXmacro,0,
    '\maketitle','\indent','\noindent',
    '\centering','\raggedright','\raggedleft','\clearpage','\cleardoublepage','\newline','\newpage',
    '\smallskip','\medskip','\bigskip','\vfill','\hfill','\hrulefill','\dotfill',
    '\normalsize','\small','\footnotesize','\scriptsize','\tiny','\large','\Large','\LARGE','\huge','\Huge',
    '\normalfont','\em','\rm','\it','\bf','\sf','\tt','\sc','\sl',
    '\rmfamily','\sffamily','\ttfamily','\upshape','\itshape','\slshape','\scshape','\mdseries','\bfseries',
    '\selectfont',
    '\tableofcontents','\listoftables','\listoffigures');
add_keys_to_hash(\%TeXmacro,1,
    '\begin','\end',
    '\documentclass','\documentstyle','\hyphenation','\pagestyle','\thispagestyle',
    '\author','\date',
    '\bibliographystyle','\bibliography','\pagenumbering','\markright',
    '\includeonly','\includegraphics','\special',
    '\label','\ref','\pageref','\bibitem',
    '\eqlabel','\eqref','\hspace','\vspace','\addvspace',
    '\newsavebox','\usebox', 
    '\newlength','\newcounter','\stepcounter','\refstepcounter','\usecounter',
    '\fontfamily','\fontseries',
    '\alph','\arabic','\fnsymbol','\roman','\value',
    '\typeout', '\typein','\cline');
add_keys_to_hash(\%TeXmacro,2,
    '\newfont','\newtheorem','\sbox','\savebox','\rule','\markboth',
    '\setlength','\addtolength','\settodepth','\settoheight','\settowidth','\setcounter',
    '\addtocontents','\addtocounter',
    '\fontsize');
add_keys_to_hash(\%TeXmacro,3,'\addcontentsline');
add_keys_to_hash(\%TeXmacro,6,'\DeclareFontShape');
add_keys_to_hash(\%TeXmacro,['[','text','ignore'],
    '\cite','\nocite','\citep','\citet','\citeauthor','\citeyear','\citeyearpar',
    '\citealp','\citealt','\Citep','\Citet','\Citealp','\Citealt','\Citeauthor');
add_keys_to_hash(\%TeXmacro,['ignore','text'],'\parbox','\raisebox');
add_keys_to_hash(\%TeXmacro,['otherword'],'\marginpar','\footnote','\footnotetext');
add_keys_to_hash(\%TeXmacro,['header'],
    '\title','\part','\chapter','\section','\subsection','\subsubsection','\paragraph','\subparagraph');
add_keys_to_hash(\%TeXmacro,['xxx','xxx','text'],'\multicolumn');
add_keys_to_hash(\%TeXmacro,['xxx','xxx'],'\newcommand','\renewcommand');
add_keys_to_hash(\%TeXmacro,['xxx','xxx','xxx'],'\newenvironment','\renewenvironment');

### Environments
# The %TeXenvir hash provides content parsing rules (parser states).
# Environments that are not defined will be counted as the surrounding text.
#
# Parameters taken by the \begin{environment} are defined in %TeXmacro.
#
# Note that some environments may only exist within math-mode, and
# therefore need not be defined here: in fact, they should not as it
# is not clear if they will be in inlined or displayed math.
my %TeXenvir;
add_keys_to_hash(\%TeXenvir,'ignore',
    'titlepage','tabbing','tabular','tabular*','thebibliography','lrbox');
add_keys_to_hash(\%TeXenvir,'text',
    'document','letter','center','flushleft','flushright',
    'abstract','quote','quotation','verse','minipage',
    'description','enumerate','itemize','list',
    'theorem','thm','lemma','definition','corollary','example','proof','pf');
add_keys_to_hash(\%TeXenvir,'inlinemath',
    'math');
add_keys_to_hash(\%TeXenvir,'displaymath',
    'displaymath','equation','equation*','eqnarray','eqnarray*','align','align*','array');
add_keys_to_hash(\%TeXenvir,'float',
    'float','picture','figure','figure*','table','table*');
add_keys_to_hash(\%TeXenvir,'xall',
    'verbatim','tikzpicture','comment');

# Environment parameters
my $PREFIX_ENVIR='begin'; # Prefix used for environment names
add_keys_to_hash(\%TeXmacro,1,
    'beginthebibliography','beginlrbox','beginminipage','beginarray');
add_keys_to_hash(\%TeXmacro,2,
    'beginlist');
add_keys_to_hash(\%TeXmacro,['ignore'],
    'beginletter');
add_keys_to_hash(\%TeXmacro,['xxx'],
    'begintabular');
add_keys_to_hash(\%TeXmacro,['ignore','xxx'],
    'begintabular*');
add_keys_to_hash(\%TeXmacro,['[','text'],
    'begintheorem','beginthm','beginlemma','begindefinition','begincorollary','beginexample','beginproof','beginpf');
add_keys_to_hash(\%TeXmacro,['nooptions'],
    'beginverbatim');

### Macros that should be counted as one or more words
# Macros that represent text may be declared here. The value gives
# the number of words the macro represents.
my %TeXmacrocount=('\LaTeX'=>1,'\TeX'=>1,'beginabstract'=>['header','headerword']);

### Macros for including tex files
# Allows \macro{file} to include file; or \macro file if of type 'input'.
# Main types are 'input' for \input, 'texfile' which adds '.tex', and
# 'file' which adds '.tex' if missing.
my %TeXfileinclude=('\input'=>'input','\include'=>'texfile');

### Convert state keys to codes
convert_hash(\%TeXpreamble,\&keyarray_to_state);
convert_hash(\%TeXpackageinc,\&keyarray_to_state);
convert_hash(\%TeXfloatinc,\&keyarray_to_state);
convert_hash(\%TeXmacro,\&keyarray_to_state);
convert_hash(\%TeXmacrocount,\&keyarray_to_cnt);
convert_hash(\%TeXenvir,\&key_to_state);
