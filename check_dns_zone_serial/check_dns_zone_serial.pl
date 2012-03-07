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
use List::Util qw(max min);

use vars qw(
  $plugin
  $options
);

# the script is declared as a package so that it can be unit tested
# but it should not be used as a module
#if ( !caller ) {
    run();
#}

sub run {
    $plugin = Nagios::Plugin->new( shortname => 'CHECK_DNS_ZONE_SERIAL' );

    my $usage = <<'EOT';
check_dns_zone_serial -z/--zone=zonename
                      [-h/--help] [--version] [--usage] [--debug]
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

    my $res   = Net::DNS::Resolver->new;
    my $query = $res->query( @{ $options->zone() }, "NS");
    my @ns;
    my %ns_serials;
    my @serials;
    my $check_s;

    if ($query) {
       foreach my $rr (grep { $_->type eq 'NS' } $query->answer) {
           push (@ns, $rr->nsdname);
	   push (@serials, qrsoa($rr->nsdname,@{ $options->zone() }));
	   if ( $options->debug() ) {
	       push @{ $ns_serials{$rr->nsdname} }, qrsoa($rr->nsdname, @{ $options->zone() });
	   }
       }
    }
    else {
       $plugin->nagios_exit( CRITICAL, "query failed: ".$res->errorstring."\n");
    }

    if ( $options->debug() ) {
	foreach my $key (sort keys %ns_serials) {
	    print "$key: $ns_serials{$key}[0]\n";
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
	$plugin->nagios_exit( CRITICAL, "Can't get query from $host. err:".$res->errorstring." answersize".$res->answersize."/n" );
    }
}
