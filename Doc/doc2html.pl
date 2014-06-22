#!/usr/bin/perl
use strict;

my $file=shift @ARGV;

open(FH,'<'.$file) || die 'Cannot open file '.$file;
my @lines=<FH>;
my $text=join('',@lines);
close FH;

my $macros='item|option';
my %tagTrans=('textit'=>'i','code'=>'tt','emph'=>'em','parm'=>'i','opt'=>'i','alt'=>'i','alts'=>'i');
my $alttags='alt|opt';
my $altstags='alts';
my $tags=join('|',keys %tagTrans);
my $rxparm='\{([^\\\}]*)\}';

while ( $text=~/\\begin\{(description)\}(.*?)\\end\{\1\}/s ) {
  $text=$';
  print "<dl class='syntax'>\n";
  printlist($2);
  print "</dl>\n";
}

#######################################################################

sub printlist {
  my $group=shift @_;
  $group=~s/^(.*?\s)(\\($macros))/$2/s;
  $group=~s/\\([#%])/$1/g;
  $group=~s/\\ldots/.../g;
  $group=~s/\\bs\{(.*?)\}/&\/;$1/g;
  $group=~s/\\\{/&\(;/g;
  $group=~s/\\\}/&\);/g;
  $group=~s/\\(TeX|LaTeX|TeXcount)(\{\})?/$1/g;
  $group=~s/\$([^\s]+)\$/<i>$1<\/i>/g;
  while ($group=~s/\\($tags)$rxparm/tag($1,$2)/gse) { }
  while ( $group=~s/^.*?\\(item|option)(\[(.*?)\])(.*?)\s*(\\($macros)|$)/$5/s ) {
    my $dt=$3;
    my $dd=$4;
    print " <dt>".code2html($3)."</dt>\n";
    print "  <dd>".code2html($4)."</dd>\n";
  }
}

sub code2html {
  my $code=shift @_;
  $code=~s/^\s*//;
  $code=~s/&\(;/\{/g;
  $code=~s/&\);/\}/g;
  $code=~s/&<;/[/g;
  $code=~s/&>;/]/g;
  $code=~s/&\/;/\\/g;
  return $code;
}

sub tag {
  my ($tag,$text)=@_;
  if ($tag=~/^($alttags)$/) {$text='&<;'.$text.'&>;';}
  if ($tag=~/^($altstags)$/) {$text='&<;&<;'.$text.'&>;&>;';}
  my $htmltag = $tagTrans{$tag} || $tag;
  return "<$htmltag class='$tag'>$text</$htmltag>";
}


