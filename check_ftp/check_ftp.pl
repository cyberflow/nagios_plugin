#!/usr/bin/perl -w
#
# check_device_mounted
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of GNU general public license (gpl) version 3.
# See the LICENSE file for details.

use strict;
use Net::FTP;

our $VERSION = '0.1';

use Nagios::Plugin::Getopt;
use Nagios::Plugin::Threshold;
use Nagios::Plugin::Config;
use Nagios::Plugin;

use vars qw(
  $plugin
  $options
  $user
  $passwd
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
     $plugin = Nagios::Plugin->new( shortname => 'CHECK_FTP' );

     my $usage = <<'EOT';
check_device_mounted [-H|--host <host>] [-P|--port] [-u|--user] [-p|--passwd] [-C|--config <path/to/config>] [-t|--timeout] [--passive]
             [-h|--help] [-V|--version] [--usage] [--debug] [--verbose]
EOT
        
     $options = Nagios::Plugin::Getopt->new(
        usage   => $usage,
        version => $VERSION,
        blurb   => 'Check ftp server'
     );

     $options->arg(
        spec     => 'host|H=s',
        help     => 'Name or IP address of host to check',
        required => 1,
     );

     $options->arg(
        spec     => 'port|P=s',
        help     => 'TCP port of ftp server (default: 21)',
        default  => '21',
        required => 0,
     );

     $options->arg(
        spec     => 'user|u=s',
        help     => 'FTP user name',
        required => 0,
     );

     $options->arg(
        spec     => 'passwd|p=s',
        help     => 'FTP user password',
        required => 0,
     );

     $options->arg(
        spec     => 'config|C=s',
        help     => qq{'Config file with user and password like plugin.ini file. 
        Example:
          [fpt]
          user=username
          password=supersecretpass'},
        required => 0,
     );

     $options->arg(
        spec     => 'debug',
        help     => 'debugging output',
        required => 0,
     );
     
     $options->getopts();

     if ($options->config) {
	 my $Config = Nagios::Plugin::Config->read( $options->config );
	 $user = $Config->{ftp}->{user}[0];
	 $passwd = $Config->{ftp}->{password}[0];
	 verbose "FTP user: $user;\nFTP passwd: $passwd;\n";
     }

     my $ftp = Net::FTP->new( $options->host, Debug => $options->debug, Port => $options->port, Timeout => '30', Passive => '0' ) 
	 or $plugin->nagios_die( "Cannot conect to ". $options->host, CRITICAL );

     $ftp->login("$user","$passwd")
	 or $plugin->nagios_die( "Cannot login: Server says: " . $ftp->message, WARNING);

     $ftp->ls()
	 or $plugin->nagios_die( "Cannot ls: Server says: " . $ftp->message, WARNING);

     $ftp->quit;
     my $code = 0;
     my $message = "FTP Server OK";
     
     $plugin->nagios_exit( $code, "$message" );
}
