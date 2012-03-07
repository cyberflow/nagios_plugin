#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

package main;

# 
# check_uptime is a Nagios plugin to monitor the 
# uptime of server and notifying than uptime large of value
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of GNU general public license (gpl) version 3.
# See the LICENSE file for details.

use strict;
use POSIX;

our $VERSION = '0.1';

use Nagios::Plugin::Getopt;
use Nagios::Plugin::Threshold;
use Nagios::Plugin;

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
     $plugin = Nagios::Plugin->new( shortname => 'CHECK_UPTIME' );

     my $usage = <<'EOT';
check_uptime [-c/--critical=value] [-w/--warning=value]
             [-h/--help] [--version] [--usage] [--debug] [--verbose]
	     [--noperfdata]
EOT

     $options = Nagios::Plugin::Getopt->new(
	usage   => $usage,
	version => $VERSION,
	blurb   => 'Monitoring Uptime'
     );

     $options->arg(
	spec     => 'critical|c=i',
	help     => 'critical number of day',
	required => 0,
     ); 

     $options->arg(
	spec     => 'warning|w=i',
	help     => 'warning number of day',
	required => 0,
     );

     $options->arg(
        spec     => 'debug',
        help     => 'debugging output',
        required => 0,
     );
     
     $options->arg(
        spec     => 'noperfdata|n',
        help     => 'no perfdata to output',
        required => 0,
     );

     $options->getopts();

     if ( !-r '/proc/uptime' ) {
            $plugin->nagios_exit( UNKNOWN, '/proc/uptime not readable' );
     }
     
     my $uptimeday = floor(uptime()/3600/24);

     verbose "Uptime days: $uptimeday\n";

     if (!$options->noperfdata()){
	 $plugin->add_perfdata(
	     label     => "UPTIME",
	     value     => sprintf( '%.0f', $uptimeday ),
	 );
     }

     if ($options->warning() || $options->critical()) {
	my $code = $plugin->check_threshold(
	    check => $uptimeday,
	    warning => $options->warning(),
	    critical => $options->critical(),
	);
	$plugin->nagios_exit( $code, "UPTIME $uptimeday days large then value" ) if $code != OK;
     }

     $plugin->nagios_exit( OK, "UPTIME $uptimeday days" );

}

sub uptime {
	# Read the uptime in seconds from /proc/uptime, skip the idle time...
	open FILE, "< /proc/uptime" or die return ("Cannot open /proc/uptime: $!");
		my ($uptime, undef) = split / /, <FILE>;
	close FILE;
	return ($uptime);
}

