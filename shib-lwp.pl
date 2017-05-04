#!/usr/bin/perl
use strict;
use warnings;

use WWW::Mechanize;
use HTTP::Cookies::Netscape;

my $browser = WWW::Mechanize->new('autocheck' => 0, 'cookie_jar' => HTTP::Cookies::Netscape->new('file' => 'jar', 'ignore_discard' => "TRUE"));

$browser->get( 'https://osl.umbc.edu/sga/fb/' );
my $user = shift @ARGV or die 'No username provided';
my $pass = shift @ARGV or die 'No password provided';
$browser->submit_form(
    'form_name'   => 'upass',
    'fields'    => {
        'name'  => $user,
        'password'  => $pass
    });
$browser->submit_form();
$browser->get( 'https://osl.umbc.edu/sga/fb/' );
$browser->dump_headers if $ARGV[0];
print $browser->content if $ARGV[0];

&save($browser->cookie_jar);
print $browser->cookie_jar->as_string, "\n" if $ARGV[0];

sub save($)
{
    my $self = $_[0];
    my $file ||= $self->{'file'} || return;
    open(my $fh, '>', $file) || return;
    # Use old, now broken link to the old cookie spec just in case something
    # else (not us!) requires the comment block exactly this way.
    print {$fh} <<EOT;
# Netscape HTTP Cookie File
# http://www.netscape.com/newsref/std/cookie_spec.html
# This is a generated file!  Do not edit.
EOT
    my $now = time - $HTTP::Cookies::EPOCH_OFFSET;
    $self->scan(sub {
        my ($version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expires, $discard, $rest) = @_;
        # return if $discard && !$self->{ignore_discard};
        $expires = $expires ? $expires - $HTTP::Cookies::EPOCH_OFFSET : 0;
        # return if $now > $expires;
        $secure = $secure ? "TRUE" : "FALSE";
        my $bool = $domain =~ /^\./ ? "TRUE" : "FALSE";
        print {$fh} join("\t", $domain, $bool, $path, $secure, $expires, $key, $val), "\n";
    });
    1;
}

