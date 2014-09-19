@echo off
set tc=D:\Store\Git\TeXcount\TeXcount.pl -showver -sub -sum -v -merge
set tempdoc=%temp%\parse.html
%tc% -utf8 -html -dir %* > %tempdoc%
rem start firefox %tempdoc%
rem start chrome %tempdoc%
start %tempdoc%
