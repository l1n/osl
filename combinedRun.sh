#!/bin/sh
sh orgListGen.sh
sh singleOrg.sh
join -t '	' orgList.tsv orgList2.tsv > combined.tsv
echo 'CREATE TABLE IF NOT EXISTS organizations_canonical (id INTEGER PRIMARY KEY ASC, name TEXT, category TEXT, description TEXT, organization_group TEXT, website TEXT, facebook TEXT, twitter TEXT, email TEXT, mailbox TEXT, cabinet TEXT);' | sqlite3 osl.sqlite -batch
echo 'CREATE TABLE IF NOT EXISTS officers (organization_id INTEGER, name TEXT, position TEXT, email TEXT);' | sqlite3 osl.sqlite -batch
cat combined.tsv | perl -ne'chomp; s/'\''/'\'\''/g; print "-- $_\n"; @t = split "\t"; @{$t[4]} = split ", ", $t[4]; print qq{INSERT OR REPLACE INTO organizations_canonical (id, name, category, description, organization_group, website, facebook, twitter, email, mailbox, cabinet) VALUES ('\''$t[0]'\'', '\''$t[1]'\'', '\''$t[2]'\'', '\''$t[3]'\'', '\''$t[5]'\'', '\''$t[6]'\'', '\''$t[7]'\'', '\''$t[8]'\'', '\''$t[9]'\'', '\''$t[10]'\'', '\''$t[11]'\'');\n}; foreach (@{$t[4]}) {/^(.*?): "(.*)" <(.*)>$/;print qq{INSERT OR REPLACE INTO officers (organization_id, name, position, email) VALUES ('\''$t[0]'\'', '\''$2'\'', '\''$1'\'', '\''$3'\'');\n}}' | tee orgs.sql | sqlite3 osl.sqlite -batch
