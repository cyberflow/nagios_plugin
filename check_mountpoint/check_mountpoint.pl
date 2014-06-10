#!/usr/bin/perl -w
#
# check_mountpoint
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of GNU general public license (gpl) version 3.
# See the LICENSE file for details.

use strict;
use feature qw(say);
#use LWP::UserAgent;

our $VERSION = '0.1';

use Nagios::Plugin::Getopt;
#use Nagios::Plugin::Threshold;
#use Nagios::Plugin::Config;
use Nagios::Plugin;

use vars qw(
  $plugin
  $options 
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
        say $message;
    }

    return;
}

sub run {
     $plugin = Nagios::Plugin->new( shortname => 'CHECK_MOUNTPOINT' );

     my $usage = <<'EOT';
check_mountpoint [-m|--mountpoint <path>]
EOT
        
     $options = Nagios::Plugin::Getopt->new(
        usage   => $usage,
        version => $VERSION,
        blurb   => 'Check mountpoint'
     );

     $options->arg(
        spec     => 'mountpoint|m=s',
        help     => 'Path',
        required => 1,
     );
    
     $options->arg(
        spec     => 'debug',
        help     => 'debugging output',
        required => 0,
     );
     
     $options->getopts();
    
	 system("mountpoint", "-q", $options->mountpoint);
	 if ( $? == 0 ) {
	 	$plugin->nagios_exit( $?, "OK")
	 } else {
	 	$plugin->nagios_exit( 'CRITICAL', $options->mountpoint." is not a mountpoint")
	 }
}