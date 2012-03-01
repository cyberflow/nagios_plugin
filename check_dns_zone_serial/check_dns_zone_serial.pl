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

our $VERSION = '0.1';

use Nagios::Plugin::Getopt;
use Nagios::Plugin::Threshold;
use Nagios::Plugin;
use Data::Validate::Domain;

use vars qw(
  $plugin
  $options
);

if ( !caller ) {
    run();
}

sub run {
    $plugin = Nagios::Plugin->new( shortname => 'CHECK_DNS_ZONE_SERIAL' );

    my $usage = <<'EOT';
check_dns_zone_serial -z/--zone=zonename
                      [-h/--help] [--version] [--usage]
EOT

    $options = Nagios::Plugin::Getopt->new(
	usage   => $usage,
#	extra   => $extra,
	version => $VERSION,
	blurb   => 'Monitoring DNS Zone Serial number'
    );

    $options->arg(
	spec     => 'zone|z=s@',
	help     => 'zone name (e.g. example.com)',
	required => 1,
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

    my $res   = Net::DNS::Resolver->new;
    my $query = $res->query( @{ $options->zone() }, "NS");
    my @ns;
    my @serials;

    if ($query) {
	#print (grep { $_->type eq 'NS' } $query->answer)->nsdname;
       foreach my $rr (grep { $_->type eq 'NS' } $query->answer) {
           push (@ns, $rr->nsdname);
	   push (@serials, qrsoa($rr->nsdname,@{ $options->zone() }))
       }
    }
    else {
       $plugin->nagios_exit( CRITICAL, "query failed: ".$res->errorstring."\n");
    }

#    print "@serials";

}

sub qrsoa {
    my $host = shift;
    my $zone = shift;
    my $res   = Net::DNS::Resolver->new(nameservers => [$host]);
    my $query = $res->query( $zone, "SOA");
    if ($query) {
	return $query ? ($query->answer)[0]->serial : -1;
    } else {
	$plugin->nagios_exit( CRITICAL, "Unknown error" );
    }
}
