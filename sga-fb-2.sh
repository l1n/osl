#!/bin/sh
cat fb*.tsv | perl -ne'@_ = split "\t"; print "curl -sb jar https://osl.umbc.edu/sga/fb/$_[0] | elinks -dump 1 -dump-width 50000 | perl sga-fb-single.pl $_[0] \"$_[3]\"\0"' | xargs -0t -I {} -n 1 -P 2 sh -c '{}'
