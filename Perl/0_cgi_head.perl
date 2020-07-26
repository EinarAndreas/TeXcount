#! /local/bin/perl -wT
use strict;
use utf8;
use Encode;
use CGI ':standard';
use CGI::Carp qw(warningsToBrowser fatalsToBrowser set_message); 
set_message('Please send information about this error to einarro@ifi.uio.no together with the text or file that caused it.');

###[[VERSIONINFO]]
