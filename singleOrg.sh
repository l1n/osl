#!/bin/sh
rm orgList2.tsv; cat orgList.tsv | cut -f 1 | xargs -P 8 -n 4 -I{} sh -c 'curl --retry 4 -s http://osl.umbc.edu/orgs/detail/{} | perl singleOrg.pl {} >> orgList2.tsv' && sort -s -n -k 1,1 orgList2.tsv > t && mv t orgList2.tsv
