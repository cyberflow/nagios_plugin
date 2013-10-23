#!/usr/bin/perl -w
#
# check_diskusage
# 
# This module is free software; you can redistribute it and/or modify it
# under the terms of GNU general public license (gpl) version 3.
# See the LICENSE file for details.

use strict;
use LWP::Simple;
use JSON::XS;

our $VERSION = '0.1';

use Nagios::Plugin::Getopt;
use Nagios::Plugin::Threshold;
use Nagios::Plugin;

use vars qw(
  $plugin
  $options
  $message
  $code  
);

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
     $plugin = Nagios::Plugin->new( shortname => 'CHECK_DISKUSAGE' );

     my $usage = <<'EOT';
check_device_mounted [-H/--host <host>] [-p/--port] [-c/--critical=value] [-w/--warning=value]
             [-h/--help] [--version] [--usage] [--debug] [--verbose]
EOT
             
     $options = Nagios::Plugin::Getopt->new(
        usage   => $usage,
        version => $VERSION,
        blurb   => 'Check disks usage on swift server'
     );
       
     $options->arg(
        spec     => 'host|H=s',
        help     => 'hostname swift server',
        required => 1,
     );

     $options->arg(
        spec     => 'port|p=s',
        help     => 'port swift server (default: 6000)',
	default  => '6000',
        required => 0,
     );

     $options->arg(
        spec     => 'critical|c=i',
        help     => 'critical device usage percent (default: 90)',
	default  => 90,
        required => 0,
     );
        
     $options->arg(
        spec     => 'warning|w=i',
        help     => 'warning device usage percent (default: 70)',
	default  => 70,
        required => 0,
     );

     $options->arg(
        spec     => 'debug',
        help     => 'debugging output',
        required => 0,
     );
        
     $options->getopts();
        
     my $url = 'http://'.$options->host.':'.$options->port.'/recon/diskusage';
     
     my $get_device = get $url
     	 or $plugin->nagios_die( "Could not get device" );

     my $json_data = JSON::XS::decode_json($get_device);

     foreach my $dev (@$json_data) {
	 my $usage = $dev->{used}/$dev->{size}*100;
	 $code = $plugin->check_threshold(
	     check => $usage,
	     warning => $options->warning(),
	     critical => $options->critical(),
	 );
	 verbose "$dev->{device}: $usage - $code \n";
	 $plugin->add_message($code, critical => $dev->{device}. ': usage ' . $usage . '%; ') if $code == CRITICAL;
	 $plugin->add_message($code, warning => $dev->{device}. ': usage ' . $usage . '%; ') if $code == WARNING;
	 ($code, $message) = $plugin->check_messages(join_all => ' ');
     }

     $plugin->nagios_exit( $code, "Devices: $message " ) if $code != OK;

     $plugin->nagios_exit( OK, "ALL OK" );
}
     
