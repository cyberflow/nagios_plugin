#! /usr/bin/perl
use Net::Jabber qw(Client);
use strict;
# Announce resources
my %resource = (
    online => "/announce/online",
);
# default options
my %option = (
    server => "im.jabber.net:5222",
    user => "monitoring",
    pass => "password",
    type => "online",
);
# Connect to Jabber server
my ($host, $port) = split(":", $option{server}, 2);
my $c = new Net::Jabber::Client;
$c->Connect(
    hostname => $host,
    port => $port,
) or die "Cannot connect to Jabber server at $option{server}\n";
my @result;
eval {
    @result = $c->AuthSend(
	username => $option{user},
	password => $option{pass},
	resource => "Monitoring",
    );
};
die "Cannot connect to Jabber server at $option{server}\n" if $@;
if ($result[0] ne "ok") {
    die "Authorisation failed ($result[1]) for user $option{user} on $option{server}\n";
}
#Sending message
my $xml .= qq[<subject>] .
($option{type} eq "online" ? "Admin Message" : "MOTD") .
qq[</subject>];
    my $to = $ARGV[0];
    $xml .= qq[<message to="$to">];
    $xml .= qq[<body>];
    my $message = $ARGV[1];
$xml .= XML::Stream::EscapeXML($message);
    $xml .= qq[</body>];
    $xml .= qq[</message>];
    $c->SendXML($xml);

