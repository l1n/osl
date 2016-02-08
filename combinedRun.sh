#!/bin/sh
sh orgListGen.sh
sh singleOrg.sh || sh singleOrg.sh || sh singleOrg.sh
join orgList*.tsv > combined.tsv
