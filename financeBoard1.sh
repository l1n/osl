#!/bin/sh
curl http://osl.umbc.edu/sga/fb/ | grep reqDate\" -A 4 | perl -ne'BEGIN {$/ = "--"; $\ = "\n"; $" = "\t"} s/^\s*<td.*?>/\t/mg; s/<\/td>\n//g; s/--$//; s/^([^<]*)<a href="fb\/(\d*)">([^\t]*)<\/a>/$2$1$3/g; print' > fbPending.tsv
curl http://osl.umbc.edu/sga/heard | grep reqDate\" -A 4 | perl -ne'BEGIN {$/ = "--"; $\ = "\n"; $" = "\t"} s/^\s*<td.*?>/\t/mg; s/<\/td>\n//g; s/--$//; s/^([^<]*)<a href="fb\/(\d*)">([^\t]*)<\/a>/$2$1$3/g; print' > fbHeard.tsv
curl http://osl.umbc.edu/sga/tabled | grep reqDate\" -A 4 | perl -ne'BEGIN {$/ = "--"; $\ = "\n"; $" = "\t"} s/^\s*<td.*?>/\t/mg; s/<\/td>\n//g; s/--$//; s/^([^<]*)<a href="fb\/(\d*)">([^\t]*)<\/a>/$2$1$3/g; print' > fbTabled.tsv
