#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

package main;

# 
# check_file_change is a Nagios plugin to ptovide the 
# monitoring chanches file timestamp (last modified)
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of GNU general public license (gpl) version 3.
# See the LICENSE file for details.

use strict;
use POSIX;
use File::stat;
use File::Basename;

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
     $plugin = Nagios::Plugin->new( shortname => 'CHECK_FILE_CHANGE' );

     my $usage = <<'EOT';
check_file_chenge.pl --file=/path/to/file
             [-h/--help] [--version] [--usage] [--debug] [--verbose]

EOT

     $options = Nagios::Plugin::Getopt->new(
	usage   => $usage,
	version => $VERSION,
	blurb   => 'Monitoring file change'
     );

     $options->arg(
	spec     => 'file|f=s',
	help     => 'file name for monitoring',
	required => 1,
     );

     $options->getopts();
     
     my $file = $options->file();
     my $file_nm = basename $file;

     my $st = stat($file) or $plugin->nagios_exit( UNKNOWN,
                "no such file: $file" );
    
     my $currenttime = $st->mtime;

     ## get cache timestamp
     my $file_cache;
     my $time_changed;
     open FILE, "</tmp/".$file_nm.".cache";
        while (defined ($file_cache = <FILE>)) {
	    if ($file_cache != $currenttime) {
		 $time_changed=1;
	    }
	}
     close FILE; 

     ## write timestamp to cache
     open FILE, ">/tmp/".$file_nm.".cache";
     print FILE "$currenttime";
     close FILE;

     if ($time_changed) { 
	 $plugin->nagios_exit( CRITICAL,
                "Timestamp changed for $file" );
     } else {
	 $plugin->nagios_exit( OK,
                "OK. $file is not changed" ); 
     }
     
}


