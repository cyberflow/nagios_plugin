#!/usr/bin/perl -w
# 
# check_dns_zone_serial is a Nagios plugin to monitor the 
# serial number of zone in all NS servers
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of GNU general public license (gpl) version 3.
# See the LICENSE file for details.

use strict;
use Net::DNS;

our $VERSION = '0.2';

use Nagios::Plugin::Getopt;
use Nagios::Plugin;
use Data::Validate::Domain;
use List::Util qw(max min);

use vars qw(
  $plugin
  $options
);

# the script is declared as a package so that it can be unit tested
# but it should not be used as a module
if ( !caller ) {
    run();
}

sub verbose {

    # arguments
    my $message = shift;
    my $level   = shift;

    if ( !defined $message ) {
        $plugin->nagios_exit( UNKNOWN,
            q{Internal error: not enough parameters for 'verbose'} );
    }

    if ( !defined $level ) {
        $level = 0;
    }

    if ( $options->debug() ) {
        print '[DEBUG] ';
    }

    if ( $level < $options->verbose() || $options->debug() ) {
        print $message;
    }

    return;
}


sub run {
    $plugin = Nagios::Plugin->new( shortname => 'CHECK_DNS_ZONE_SERIAL' );

    my $usage = <<'EOT';
check_dns_zone_serial [-z|--zone=zonename] [--ns=ns1,ns2]
                      [-h/--help] [--version] [--usage] [--debug] [--verbose]
EOT

    $options = Nagios::Plugin::Getopt->new(
	usage   => $usage,
	version => $VERSION,
	blurb   => 'Monitoring DNS Zone Serial number'
    );

    $options->arg(
	spec     => 'zone|z=s@',
	help     => 'zone name (e.g. example.com)',
	required => 1,
    );

    $options->arg(
	spec     => 'ns=s',
	help     => 'specify ns server by comma delimetr (e.g. ns1.domain.com,ns2.domain.com)',
    );

    $options->arg(
	spec     => 'debug',
	help     => 'debugging output',
        required => 0,
    );

    $options->getopts();

    ################################################################################
    # Sanity checks

    if ( ! is_domain( @{ $options->zone() } ) ) {
	 $plugin->nagios_exit( UNKNOWN,
			       'Zone name validation fail');
    }   

    ############################
    # Nameservers get soa serial

    my $res = Net::DNS::Resolver->new;
    my @serials;

    if (! $options->ns) {
	my $query = $res->query( @{ $options->zone() }, "NS")
	    or $plugin->nagios_die(CRITICAL, "query failed: " . $res->errorstring. "\n");
	foreach my $rr (grep { $_->type eq 'NS' } $query->answer) {
	    push (@serials, qrsoa($rr->nsdname,@{ $options->zone() }));
	    verbose('NS Server: ' . $rr->nsdname . ' have serial: ' . qrsoa($rr->nsdname,@{ $options->zone() }) . "\n");
	}
    }
    else {
	foreach my $ns (split(",",$options->ns)) {
	    if ( ! is_domain( $ns ) ) {
		$plugin->nagios_exit( UNKNOWN,
			       'NS name ' . $ns . ' validation fail');
	    }
	    push (@serials, qrsoa($ns,@{ $options->zone() }));
	    verbose('NS Server: ' . $ns . ' have serial: ' . qrsoa($ns,@{ $options->zone() }) . "\n");
	}
    }

    if ( ( max @serials ) == ( min @serials ) ){
	$plugin->nagios_exit( OK, "Serial number is match");
    } else {
	$plugin->nagios_exit( WARNING, "Serial number isn't match");
    }

}

sub qrsoa {
    my $host = shift;
    my $zone = shift;
    my $res   = Net::DNS::Resolver->new(nameservers => [$host]);
    my $query = $res->query( $zone, "SOA");
    if ($query) {
	return $query ? ($query->answer)[0]->serial : $plugin->nagios_exit( CRITICAL, "Can't get serial in query from $host" );
    } else {
	$plugin->nagios_exit( CRITICAL, "Can't get query from $host. err:".$res->errorstring."/n" );
    }
}
