#!/usr/bin/perl -w
#
# check_device_mounted
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
     $plugin = Nagios::Plugin->new( shortname => 'CHECK_DEVICE_MOUNTED' );

     my $usage = <<'EOT';
check_device_mounted [-H/--host <host>] [-p/--port] [-c/--critical=value] [-w/--warning=value]
             [-h/--help] [--version] [--usage] [--debug] [--verbose]
EOT
             
     $options = Nagios::Plugin::Getopt->new(
        usage   => $usage,
        version => $VERSION,
        blurb   => 'Check swift unmounted device'
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
        help     => 'critical number of device (default: 1)',
	default  => 1,
        required => 0,
     );
        
     $options->arg(
        spec     => 'warning|w=i',
        help     => 'warning number of device (default 0)',
	default  => 0,
        required => 0,
     );

     $options->arg(
        spec     => 'debug',
        help     => 'debugging output',
        required => 0,
     );
        
     $options->getopts();
        
     my $url = 'http://'.$options->host.':'.$options->port.'/recon/unmounted';
     
     my $get_device = get $url
	 or $plugin->nagios_die( "Could not get device" );

     #my $get_device = '[{"device": "sata2", "mounted": false}, {"device": "sata1", "mounted": false}]';
     my $json_data = JSON::XS::decode_json($get_device);
     my $unmounted_device = @$json_data; 
     
     if ($unmounted_device > 0) {
	 $message = '';
	 foreach my $dev (@$json_data) {
	     $message = $message . $dev->{device} . ' ';
	 }
     }

     my $code = $plugin->check_threshold(
	 check => $unmounted_device,
	 warning => $options->warning(),
	 critical => $options->critical(),
	 );
     $plugin->nagios_exit( $code, "UNMOUNDET $unmounted_device devices: $message;" ) if $code != OK;

     $plugin->nagios_exit( OK, "ALL Device mounted" );
}
     
