#!/bin/sh
cat fb*.tsv | perl -ne'@_ = split "\t"; system "curl http://osl.umbc.edu/sga/fb/$_[0] | elinks -dump 1 -dump-width 50000 | perl sga-fb-single.pl $_[0] \"$_[3]\""' > financeBoard.json
