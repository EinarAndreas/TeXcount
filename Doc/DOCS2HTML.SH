#!/bin/bash
TARGET="/var/www/texcount/Source"

doc2html() {
  echo "Converting $1 to $2"
  ./doc2html.pl $1 > $TARGET/$2
}

doc2html sub_options.tex options.inc
doc2html sub_tc_other.tex tc_other.inc
doc2html sub_addrules.tex addrules.inc

