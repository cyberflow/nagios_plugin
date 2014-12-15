#!/usr/bin/perl -w
#
# check_memusage
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of GNU general public license (gpl) version 3.
# See the LICENSE file for details.

use strict;
use Data::Dumper;

our $VERSION = '0.1';

use Monitoring::Plugin;

use vars qw(
  $plugin
  $options
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
  $plugin = Monitoring::Plugin->new(
    shortname => 'CHECK_MEMUSAGE',
    usage => "Usage: %s [-c|--critical <value>] [-w|--warning <value>] "
      . "[-h|--help] [-V|--version] [--usage] [--debug] [--verbose]");

  $plugin->add_arg(
    spec     => 'debug',
    help     => 'debugging output',
    required => 0,
  );

  $plugin->add_arg(
    spec     => 'critical|c=s',
    help     => 'Critical value of free memory in percent. Default 10',
    default  => '10:',
    required => 0,
  );

  $plugin->add_arg(
    spec     => 'warning|w=s',
    help     => 'Wrning value of free memory in percent. Default 20',
    default  => '20:',
    required => 0,
  );

  $plugin->getopts();

  my %metrics;
  open FILE, '/proc/meminfo' or $plugin->plugin_die("Can't open /proc/meminfo");
  while (my $line = <FILE>) {
    chomp($line);
    $line =~ s/\s+//;
    my @item = split(/:| /, $line, 3);
    $metrics{$item[0]} .= $item[1];
  }
  close FILE or warn $! ? $plugin->plugin_die("Error closing sort pipe: $!") :
                          $plugin->plugin_die("Exit status $? from sort");

  my $res = ((($metrics{'MemFree'}+$metrics{'SwapFree'}+$metrics{'Cached'}+$metrics{'Buffers'}-$metrics{'Shmem'})/($metrics{'MemTotal'}+$metrics{'SwapTotal'}))*100);
  $code = $plugin->check_threshold(
    check => $res
  );
  $plugin->nagios_exit( $code, "Free memory is $res percent" );
}
