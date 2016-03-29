#!/bin/sh
curl http://osl.umbc.edu/orgs/list/ | grep orgs/detail -aA 6 | perl -ne'BEGIN {$/ = "--\n"}' -e'm{detail/(\d*)"}; print $1, "\t";' -e'm{-name">([^\0]*?)\s*</span>$}m; chomp $1; print $1, "\t";' -e'm{-cat">(.*)</span>$}m; print $1, "\n";' | sort -s -n -k 1,1
