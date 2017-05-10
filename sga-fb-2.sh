#!/bin/sh
cat fb*.tsv | perl -ne'@_ = split "\t"; print "curl -sb jar -c jar https://osl.umbc.edu/sga/fb/$_[0] -Om 15 || sh auth.sh curl -sb jar -c jar https://osl.umbc.edu/sga/fb/$_[0] -Om 15; cat $_[0] | elinks -dump 1 -dump-width 50000 | perl sga-fb-single.pl $_[0] \"$_[3]\"; rm $_[0]\0"' | xargs -0 -I {} -n 1 -P 2 sh -c '{}'
