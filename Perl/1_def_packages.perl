### Package rule definitions

my %PackageTeXpreamble=(); # TeXpreamble definitions per package
my %PackageTeXpackageinc=(); # TeXpackageinc definitions per package
my %PackageTeXfloatinc=(); # TeXfloatinc definitions per package
my %PackageTeXmacro=(); # TeXmacro definitions per package
my %PackageTeXmacrocount=(); # TeXmacrocount definitions per package
my %PackageTeXenvir=(); # TeXenvir definitions per package
my %PackageTeXfileinclude=(); # TeXfileinclude definitions per package
my %PackageSubpackage=(); # Subpackages to include (listed in array [...])


# Rules for bibliography inclusion
$PackageTeXmacrocount{'%incbib'}={'beginthebibliography'=>['header','hword']};
$PackageTeXmacro{'%incbib'}={'\bibliography'=>1};
$PackageTeXenvir{'%incbib'}={'thebibliography'=>'text'};
$PackageTeXfileinclude{'%incbib'}={'\bibliography'=>'<bbl>'};

# Rules for package alltt
$PackageTeXenvir{'alltt'}={
    'alltt'=>'xall'};

# Rules for package babel
# NB: Only core macros implemented, those expected found in regular documents
$PackageTeXenvir{'babel'}={
    'otherlanguage'=>'text','otherlanguage*'=>'text'};
$PackageTeXmacro{'babel'}={
    '\selectlanguage'=>1,'\foreignlanguage'=>['ignore','text'],
    'beginotherlanguage'=>1,'beginotherlanguage*'=>1};

# Rules for package comment
$PackageTeXenvir{'comment'}={
    'comment'=>'xxx'};

# Rules for package color
$PackageTeXmacro{'color'}={
    '\textcolor'=>['ignore','text'],'\color'=>1,'\pagecolor'=>1,'\normalcolor'=>0,
    '\colorbox'=>['ignore','text'],'\fcolorbox'=>['ignore','ignore','text'],
    '\definecolor'=>3,\'DefineNamedColor'=>4};

# Rules for package endnotes
$PackageTeXmacro{'endnotes'}={'\endnote'=>['oword'],'\endnotetext'=>['oword'],'\addtoendnotetext'=>['oword']};

# Rules for package etoolbox
$PackageTeXmacro{'etoolbox'}={'\apptocmd'=>['xxx','ignore','ignore','ignore'],
    '\pretocmd'=>['xxx','ignore','ignore','ignore'],
    '\patchcmd'=>['xxx','xxx','xxx','ignore','ignore']};

# Rules for package fancyhdr
$PackageTeXmacro{'fancyhdr'}={
    '\fancyhf'=>1,'\lhead'=>1,'\chead'=>1,'\rhead'=>1,'\lfoot'=>1,'\cfoot'=>1,'\rfoot'=>1};

# Rules for package geometry
$PackageTeXmacro{'geometry'}={
    '\geometry'=>1,'\newgeometry'=>1,'\restoregeometry'=>0,,'\savegeometry'=>1,'\loadgeometry'=>1};

# Rules for package graphicx
$PackageTeXmacro{'graphicx'}={
    '\DeclareGraphicsExtensions'=>1,'\graphicspath'=>1,
    '\includegraphics'=>['[','ignore','ignore'],
    '\includegraphics*'=>['[','ignore','[','ignore','[','ignore','ignore'],
    '\rotatebox'=>1,'\scalebox'=>1,'\reflectbox'=>1,'\resizebox'=>1};

# Rules for package hyperref (urls themselves counted as one word)
# NB: \hyperref[label]{text} preferred over \hyperref{url}{category}{name}{text}
# NB: Macros for use in Form environments not implemented
$PackageTeXmacro{'hyperref'}={
    '\hyperref'=>['[','ignore','text'],
    '\url'=>1,'\nolinkurl'=>1,'\href'=>['ignore','text'],
    '\hyperlink'=>['ignore','text'],'\hypertarget'=>['ignore','text'],
    '\hyperbaseurl'=>1,'\hyperimage'=>['ignore','text'],'\hyperdef'=>['ignore','ignore','text'],
    '\phantomsection'=>0,'\autoref'=>1,'\autopageref'=>1,
    '\hypersetup'=>1,'\urlstyle'=>1,
    '\pdfbookmark'=>2,'\currentpdfbookmark'=>2,'\subpdfbookmark'=>2,'\belowpdfbookmark'=>2,
    '\pdfstringref'=>2,'\texorpdfstring'=>['text','ignore'],
    '\hypercalcbp'=>1,'\Acrobatmenu'=>2};
$PackageTeXmacrocount{'hyperref'}={
    '\url'=>1,'\nolinkurl'=>1};

# Rules for package import
$PackageTeXfileinclude{'import'}={
    '\import'=>'dir file','\subimport'=>'subdir file',
    '\inputfrom'=>'dir file','\subinputfrom'=>'subdir file',
    '\includefrom'=>'dir file','\subincludefrom'=>'subdir file'};

# Rules for package inputenc
$PackageTeXmacro{'inputenc'}={
    '\inputencoding'=>1};

# Rules for package listings
$PackageTeXenvir{'listings'}={'lstlisting'=>'xall'};
$PackageTeXmacro{'listings'}={'\lstset'=>['ignore'],'\lstinputlisting'=>['ignore']};

# Rules for package psfig
$PackageTeXmacro{'psfig'}={'\psfig'=>1};

# Rules for package sectsty
$PackageTeXmacro{'sectsty'}={
    '\allsectionsfont'=>1,'\partfont'=>1,'\chapterfont'=>1,'\sectionfont'=>1,
    '\subsectionfont'=>1,'\subsubsectionfont'=>1,'\paragraphfont'=>1,'\subparagraphfont'=>1,
    '\minisecfont'=>1,'\partnumberfont'=>1,'\parttitlefont'=>1,'\chapternumberfont'=>1,
    '\chaptertitlefont'=>1,'\nohang'=>0};

# Rules for package setspace
$PackageTeXenvir{'setspace'}={
    'singlespace'=>'text','singlespace*'=>'text','onehalfspace'=>'text','doublespace'=>'text',
    'spacing'=>'text'};
$PackageTeXmacro{'setspace'}={
    'beginspacing'=>1,
    '\singlespacing'=>0,'\onehalfspacing'=>0,'\doublespacing'=>0,
    '\setstretch'=>1,'\SetSinglespace'=>1};

# Rules for package subfiles
$PackageTeXfileinclude{'subfiles'}={
    '\subfile'=>'file'};

# Rules for package url
# NB: \url|...| variant not implemented, only \url{...}
# NB: \urldef{macro}{url} will not be counted
$PackageTeXmacro{'url'}={
    '\url'=>1,'\urldef'=>2,'\urlstyle'=>1,'\DeclareUrlCommand'=>['ignore','xxx']};
$PackageTeXmacro{'setspace'}={
    '\url'=>1};

# Rules for package wrapfig
$PackageTeXenvir{'wrapfig'}={
    'wrapfigure'=>'float','wraptable'=>'float'};
$PackageTeXmacro{'wrapfig'}={
    'beginwrapfigure'=>2,'beginwraptable'=>2};

# Rules for package xcolor (reimplements the color package)
# NB: only main macros (mostly from package color) included
$PackageTeXmacro{'xcolor'}={
    '\textcolor'=>['ignore','text'],'\color'=>1,'\pagecolor'=>1,'\normalcolor'=>0,
    '\colorbox'=>['ignore','text'],'\fcolorbox'=>['ignore','ignore','text'],
    '\definecolor'=>3,\'DefineNamedColor'=>4,
    '\colorlet'=>2};

# Rules for package xparse
$PackageSubpackage{'xparse'}=['etoolbox'];
