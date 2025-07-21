#! /usr/bin/env perl
use strict;
use warnings;

# Paths
my $path="Perl/";
my $logfile="Perl/_build_.log";
my $versionfile="Perl/version.dat";
my $datverfile="Perl/_version_.dat";
my $execverfile="Perl/_version_.bat";

# Parameters
my $versionnumber=getVersion();

# Global variables
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my ($sec,$min,$hour,$day,$month,$year) = localtime();
$year+=1900;
my $date=sprintf("%4u",$year)." ".$months[$month]." ".sprintf("%02u",$day);
my $datetime=$date.", ".sprintf("%02u",$hour).":".sprintf("%02u",$min).":".sprintf("%02u",$sec);

# Replace #[[KEY]]# with value
my %global_replace = ('YEAR'=>$year);

##########

my $name=shift @ARGV;
if (!defined $name) {
  $name="texcount.".$versionnumber;
  $name=~s/\./_/g;
}
print "Building TeXcount version ".$versionnumber."\n";
print $datetime."\n";
Build_Main($name.".pl");
Build_CGI($name.".cgi");
open(LOG,">>".$logfile) || die "Cannot write to log file.";
print LOG "Built: version ".$versionnumber." on ".$datetime."\n";
close(LOG);

########## Main routines

sub Build_Main {
  my $file = shift @_;
  Build($file, 'cmd');
}

sub Build_CGI {
  my $file = shift @_;
  Build($file, 'cgi');
}

sub Build {
  my ($file,$opt) = @_;
  my $OPT = uc $opt;
  SetOutFile($file);
  if ($opt eq 'cmd') {
  } elsif ($opt eq 'cgi') {
  } else {
    die "No build option: $opt\n";
  }
  AppendFile("0_${opt}_head.perl");
  AppendFile("1__constants.perl","Set global constants and names");
  AppendFile("1__setup.perl","Set global settings and variables");
  AppendFile("1_${opt}_setup.perl","Set ${OPT} specific settings and variables");
  AppendFile("1_states.perl","Set state identifiers and methods");
  AppendFile("1_definitions.perl","Set global definitions");
  AppendFile("1_def_word.perl","Define what a word is and language options");
  AppendFile("1_def_alphabet.perl","Define character classes (alphabets)");
  AppendFile("1_def_rules.perl","Define core rules");
  AppendFile("1_def_packages.perl","Define package specific rules");
  AppendFile("2_${opt}_main.perl","Main ${OPT} script");
  BigComment("Subroutines");
  AppendFile("sub_${opt}.perl","${OPT} specific implementations");
  AppendFile("sub_options.perl","Option handling");
  AppendFile("sub_rules.perl","Macro rules handling");
  AppendFile("sub_texcode.perl","TeX code handle");
  if ($opt eq 'cmd') {
    AppendFile("sub_cmd_filehandle.perl","TeX file reader");
  }
  if ($opt eq 'cgi') {
    AppendFile("sub_cgi_crypto.perl","Encryption routines");
  }
  AppendFile("sub_errors.perl","Error handling");
  AppendFile("sub_parse.perl","Parsing routines");
  AppendFile("sub_tokenise.perl","Tokenisation routines");
  AppendFile("sub_count.perl","Count handling routines");
  AppendFile("sub_output.perl","Result output routines");
  AppendFile("sub_print.perl","Printing routines");
  AppendFile("sub_print_count.perl","Routines for printing count summary");
  AppendFile("sub_print_log.perl","Routines for printing parsing details");
  AppendFile("sub_print_help.perl","Print help on style/colour codes");
  if ($opt eq 'cmd') {
    AppendFile("sub_cmd_help.perl","Help routines");
  }
  AppendFile("sub_html.perl","HTML routines");
  if ($opt eq 'cmd') {
    AppendFile("text_data.perl","Read text data");
    AppendFile("text_help.txt"); # Help text
  }
  CloseOutFile();
}


########## Subroutines

sub SetOutFile {
  my $file=shift @_;
  open(FH,">".$file);
  binmode FH;
}

sub CloseOutFile {
  close(FH);
}

sub AppendVersion {
  AppendStrings(
  '##### Version information',
  'my $versionnumber="'.$versionnumber.'";',
  'my $versiondate="'.$date.'";');
}

sub AppendFile {
  my ($file,$description)=@_;
  if (defined $description) {
    Comment($description);
  }
  open(INFILE,"<".$path.$file) or die("Could not open ".$file);
  binmode INFILE;
  foreach my $line (<INFILE>) {
    $line=~s/\r\n/\n/;
    if ($line=~/^\s*#+:+/) {}
    elsif ($line=~/^\s*#+DEBUG(.*):/) {}
    elsif ($line=~/^\s*#{3,}\[\[VERSIONINFO\]\]$/) {AppendVersion();}
    elsif ($line=~/^\s*#{3,}\[\[INCLUDE:(.*)\]\]$/) {print FH IncludeFile($1);}
    else {
      $line=~s/#\[\[(\w+)\]\]#/replace_value($1)/ge;
      print FH $line;
    }
  }
  print FH "\n\n";
  close(INFILE);
}

sub IncludeFile {
  my ($file)=@_;
  open(INCFILE,"<".$path.$file) or die("Could not open ".$file);
  binmode INCFILE;
  my @lines=<INCFILE>;
  close(INCFILE);
  foreach (@lines) {s/\r\n/\n/;}
  return join("",@lines,'');
}

sub AppendStrings {
  foreach my $line (@_) {
    print FH $line."\n";
  }
  print FH "\n";
}

sub AppendString {
  foreach my $line (@_) {
    print FH $line."\n";
  }
}

sub Comment {
  my $comment=shift @_;
  AppendStrings('###### '.$comment);
}

sub BigComment {
  my $comment=shift @_;
  AppendStrings('######','###### '.$comment,'######');
}

sub getVersion {
  my $file=$versionfile;
  open (VERSION,"<".$file) || die "No version file!";
  my $version=<VERSION> || die "No version information in version file!";
  close(VERSION);
  chomp $version;
  my $ver=$version;
  if ($ver=~/^(-?\d+)$/) {
    $ver=$ver.".0.0.0";
  } elsif ($ver=~/^(-?\d+\.)(-?\d+)$/) {
    $ver=$ver.".0.0";
  } elsif ($ver=~/^(-?\d+\.){2}(-?\d+)$/) {
    $ver=$ver.".0";
  } elsif ($ver=~/^((-?\d+\.){3})(-?\d+)$/) {
    $ver=$1.($3+1);
    $version=$ver;
  }
  open (VERSION,">".$file) || die "Cannot write to version file!";
  print VERSION $ver;
  close (VERSION);
  $version=~s/-1/beta/g;
  $version=~s/-2/alpha/g;
  $ver=$version;
  $ver=~s/\./_/g;
  open (FH,">".$execverfile) || die "Cannot write to execute version file.";
  print FH "set version=".$ver."\n";
  close (FH);
  open (FH,">".$datverfile) || die "Cannot write to version file.";
  print FH $ver;
  close (FH);
  return $version;
}

sub replace_value {
  my $key = shift @_;
  return $global_replace{$key};
}
