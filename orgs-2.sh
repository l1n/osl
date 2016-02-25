#!/bin/sh
[ -f orgList2.tsv ] && rm orgList2.tsv; cat orgList.tsv | cut -f 1 | xargs -P 8 -n 4 -I{} sh -c '[[ -f {} ]] && unlink {}; while : ; do curl -s --retry 4 http://osl.umbc.edu/orgs/detail/{} -o {}; [[ `grep 403\ Forbidden {} | wc -l` -gt 0 ]] || break; done && cat {} | perl orgs-single.pl {} >> orgList2.tsv && rm {} || echo {}' && sort -s -n -k 1,1 orgList2.tsv > t && mv t orgList2.tsv
