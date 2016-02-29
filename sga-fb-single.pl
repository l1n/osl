#!/usr/bin/perl
use if -d 'perl5', local::lib => 'perl5';
use DBI;
use Data::Dumper;
my $dbh = DBI->connect("dbi:SQLite:dbname=osl.sqlite","","");

$dbh->do('CREATE TABLE IF NOT EXISTS request ( id integer PRIMARY KEY ASC, legislation_id text, submitted date, organization text, legislation_introduced date, legislation_author text, abstained integer, favored integer, opposed integer, absent integer, legislation_voted date, name text, date_from date, date_to date, location text, outside_funding text, cosponsor text, approved date, description text, officer_phone text, officer_email text, officer_name text, officer_position text, attendees_other integer, attendees_umbc integer, charge_other integer, charge_umbc integer);');
$dbh->do('CREATE TABLE IF NOT EXISTS ledger (request_id integer, category text, amount text, approved text);');

$dbh->begin_work;
my $ledger = $dbh->prepare('INSERT OR REPLACE INTO ledger (request_id, category, amount, approved) VALUES (?, ?, ?, ?);');
$dbh->commit;

my %req = (
    "officer"   => {},
    "attendees" => {},
    "charge"    => {},
    "legislation"    => {},
    "budget"    => {
        "requested" => {},
        "approved"  => {},
    },
    "id"        => $ARGV[0],
    "cosponsor" => [],
);
while (<STDIN>) {
    if (/\s*(.+?)\s+\Q$ARGV[1]\E \$ ([\d.]+)$/) {
        $req{"eventName"} = $1;
        $req{"preTotal"} = $2;
        next;
    }
    if (/Officer Name: (.+?)$/) {
        $req{"officer"}{"name"} = $1;
        next;
    }
    if (/Email: (.+?)$/) {
        $req{"officer"}{"email"} = $1;
        next;
    }
    if (/Position: (.+?)$/) {
        $req{"officer"}{"position"} = $1;
        next;
    }
    if (/Phone: (.+?)$/) {
        $req{"officer"}{"phone"} = $1;
        next;
    }
    if (/\[(\d*)\]View Legislation$/) {
        $pdf = $1;
        next;
    }
    if (/Date of Organization Approval: (.*)$/) {
        $req{"approval"} = $1;
        next;
    }
    if (/Type of request: (.*)$/) {
        $req{"type"} = $1;
        next;
    }
    if (/This event (has (?:not)?) happened before$/) {
        $req{"firstTime"} = $1 eq "has not" ? "yes" : "no";
        next;
    }
    if ($req{"eventName"} && m/\Q$req{"eventName"}\E will be held from (\d+:\d+ [AP]M) on\s*(\d+\/ ?\d+\/\d+) to (\d+:\d+ [AP]M) on\s*(\d+\/ ?\d+\/\d+) in (.*)\.$/) {
        $req{"from"}    = [$1, $2];
        $req{"to"}      = [$3, $4];
        $req{"where"}   = $5;
        next;
    }
    if (/Co-Sponsors:$/) {
        # COSPONSOR MODE ENGAGED
        <STDIN>;
        {
            $_ = <STDIN>;
            if (/• (.+)$/) {
                push @{$req{"cosponsor"}}, $1;
                redo;
            }
        }
        next;
    }
    if (/Event Description$/) {
        # DESCRIPTION SUCKER
        <STDIN>;
        {
            $_ = <STDIN>;
            unless (/Attendance Estimations$/) {
                $req{"description"}.=$_;
                redo;
            }
        }
        $req{"description"} =~ s/^\s*//;
        $req{"description"} =~ s/\s*$//;
        next;
    }
    if (/Total Attendance: (\d+)$/) {
        $req{"attendees"}{"total"} = $1;
        next;
    }
    if (/UMBC Attendance: (\d+)$/) {
        $req{"attendees"}{"umbc"} = $1;
        next;
    }
    if (/The charge for UMBC students will be \$([\d.]+)$/) {
        $req{"charge"}{"umbc"} = $1;
        next;
    }
    if (/The charge for others will be \$([\d.]+)$/) {
        $req{"charge"}{"other"} = $1;
        next;
    }
    if (/Are there other sources of funding: (.*)$/) {
        $req{"outsideFunding"} = $1;
        next;
    }
    if (/Budget$/) {
        # BUDGET WRANGLER
        $_ = <STDIN>;
        {
            $_ = <STDIN>;
            unless (/Availability$/) {
                if (/^\s+\d*?\s+(.+?)\s+\$([\d.]+)$/) {
                    $req{"budget"}{"requested"}{$1} = $2;
                }
                redo;
            }
        }
        next;
    }
    if ($pdf && m[\Q$pdf\E\. file://(.*)]) {
        open PDF, '-|', 'curl -s http://osl.umbc.edu'.$1.' | pdftotext - -';
        while (<PDF>) {
            if (/FBL ([\d-]+)$/) {
                $req{"legislation"}{"id"} = $1;
                next;
            }
            if (/Date of Introduction: (.+)$/) {
                $req{"legislation"}{"introduced"} = $1;
                next;
            }
            if (/Author: (.+)$/) {
                $req{"legislation"}{"author"} = $1;
                next;
            }
            if (/requested:$/) {
                while (<PDF>) {
                    if (/^Total \$([\d.]+)$/) {
                        $req{"budget"}{"approved"}{"Total"} = $1;
                        last;
                    } else {
                        if (/^\d+\. (.+) \$([\d.]+)$/) {
                            $req{"budget"}{"approved"}{$1} = $2;
                        }
                    }
                }
                next;
            }
            if (m{Representatives For:$}) {
                do {
                    $_ = <PDF>;
                } until (/^\d/);
                chomp;
                $req{"legislation"}{"for"} = $_;
                do {
                    $_ = <PDF>;
                } until (/^\d/);
                chomp;
                $req{"legislation"}{"opposed"} = $_;
                do {
                    $_ = <PDF>;
                } until (/^\d/);
                chomp;
                $req{"legislation"}{"abstaining"} = $_;
                do {
                    $_ = <PDF>;
                } until (/^\d/);
                chomp;
                $req{"legislation"}{"absent"} = $_;
                while (<PDF>) {
                    if (/,/) {
                        chomp;
                        /: (.*)$/;
                        $req{"legislation"}{"voted"} = $1 || $_;
                        last;
                    }
                }
            }
        }
        close PDF;
        next;
    }
    if ($req{"attendees"}{"umbc"} && $req{"attendees"}{"total"}) {
        $req{"attendees"}{"other"} = $req{"attendees"}{"total"} - $req{"attendees"}{"umbc"};
        delete $req{"attendees"}{"total"};
        next;
    }
}

$dbh->begin_work;
$dbh->do('UPDATE request SET legislation_id = ?, legislation_introduced = ?, legislation_author = ?, abstained = ?, favored = ?, opposed = ?, absent = ?, legislation_voted = ?, name = ?, date_from = ?, date_to = ?, location = ?, outside_funding = ?, cosponsor = ?, approved = ?, description = ?, officer_phone = ?, officer_email = ?, officer_name = ?, officer_position = ?, attendees_other = ?, attendees_umbc = ?, charge_other = ?, charge_umbc = ? WHERE id = ?', undef, $req{"legislation"}{"id"}, $req{"legislation"}{"introduced"}, $req{"legislation"}{"author"}, $req{"legislation"}{"abstaining"}, $req{"legislation"}{"for"}, $req{"legislation"}{"opposed"}, $req{"legislation"}{"absent"}, $req{"legislation"}{"voted"}, $req{"eventName"}, join(',', @{$req{"from"}}), join(',', @{$req{"to"}}), $req{"where"}, $req{"outsideFunding"}, join(',', @{$req{"cosponsor"}}), $req{"approval"}, $req{"description"}, $req{"officer"}{"phone"}, $req{"officer"}{"email"}, $req{"officer"}{"name"}, $req{"officer"}{"position"}, $req{"attendees"}{"other"}, $req{"attendees"}{"umbc"}, $req{"charge"}{"other"}, $req{"charge"}{"umbc"}, $req{"id"});

$dbh->do('DELETE FROM ledger WHERE request_id = ?', undef, $req{"id"});

$ledger->execute($req{"id"}, $_, $req{"budget"}{"requested"}{$_}, 0) foreach keys %{$req{"budget"}{"requested"}};
$ledger->execute($req{"id"}, $_, $req{"budget"}{"approved"}{$_}, 1)  foreach keys %{$req{"budget"}{"approved"}};
$dbh->commit;
$dbh->{AutoCommit} = 1;

print Dumper(\%req);
