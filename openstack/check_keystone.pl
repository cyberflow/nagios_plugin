#!/usr/bin/perl -w
#
# check_keystone
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of GNU general public license (gpl) version 3.
# See the LICENSE file for details.

use strict;
use LWP::UserAgent;

our $VERSION = '0.1';

use Nagios::Plugin::Getopt;
use Nagios::Plugin::Threshold;
use Nagios::Plugin::Config;
use Nagios::Plugin;

use vars qw(
  $np
  $options
  $user
  $password
  $tenant
);

if ( !caller ) {
    run();
}

sub verbose {

    # arguments
    my $message = shift;
    my $level   = shift;

    if ( !defined $message ) {
        $np->nagios_exit( UNKNOWN,
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
     $np = Nagios::Plugin->new( shortname => 'CHECK_KEYSTONE' );

     my $usage = <<'EOT';
check_keystone.pl [-a|--auth_url <url>] [-P|--port] [-u|--username <username>] [-T|--tenant <tenant>]  [-p|--password <password>] [-C|--config <path/to/config>] [-k|--sslnocheck]
                  [-h|--help] [-V|--version] [--usage] [--debug] [--verbose]
EOT
        
     $options = Nagios::Plugin::Getopt->new(
        usage   => $usage,
        version => $VERSION,
        blurb   => 'Check an OpenStack Keystone Server'
     );

     $options->arg(
        spec     => 'auth_url|a=s',
        help     => 'Keystone URL',
        required => 1,
     );

     $options->arg(
        spec     => 'port|P=s',
        help     => 'TCP port of keystone server (default: 5000)',
        default  => '5000',
        required => 0,
     );

     $options->arg(
        spec     => 'username|u=s',
        help     => 'username to use for authentication',
        required => 0,
     );

     $options->arg(
        spec     => 'passward|p=s',
        help     => 'password to use for authentication',
        required => 0,
     );

     $options->arg(
        spec     => 'tenant|T=s',
        help     => 'tenant name to use for authentication',
        required => 0,
     );

     $options->arg(
        spec     => 'config|C=s',
        help     => qq{'Config file with user and password like plugin.ini file. 
        Example:
          [client]
          user=username
          tenant=tenant
          password=supersecretpass'},
        required => 0,
     );

     $options->arg(
        spec     => 'debug',
        help     => 'debugging output',
        required => 0,
     );

     $options->arg(
        spec     => 'sslnocheck',
        help     => 'insecure ssl',
        required => 0,
     );

     
     $options->getopts();

     if ($options->config) {
	 my $Config = Nagios::Plugin::Config->read( $options->config )
	     or $np->nagios_die("Cannot read config file " . $options->config);
	 $user = $Config->{client}->{user}[0];
	 $password = $Config->{client}->{password}[0];
	 $tenant = $Config->{client}->{tenant}[0];
	 verbose "user: $user;\ntenant: $tenant;\npassword: $password;\n";
     } elsif (($options->username) && ($options->password) && ($options->tenant)) {
	 $user = $options->username;
	 $password = $options->password;
	 $tenant = $options->tenant;
	 verbose "user: $user;\ntenant: $tenant;\npassword: $password;\n";
     } else {
	 $np->nagios_die("One of arguments need definition: [-u <user> -p <passwd> -t <tenant>] | [-C config.ini]");
     }

     my $code = 0;
     my $message = "Keystone Server OK";

     my $ua = LWP::UserAgent->new;
     if ($options->sslnocheck) {
	 $ua->ssl_opts(verify_hostname => 0);
     }
     my $url = 'https://' . $options->auth_url . ':' . $options->port . '/v2.0/tokens';
     verbose "URL: $url\n"; 

     my $req = HTTP::Request->new(POST => $url);
     $req->header('content-type' => 'application/json');

     my $post_data = '{"auth":{"tenantName": "'. $tenant .'","passwordCredentials":{"username": "' . $user . '", "password":"'. $password .'"}}}';
     verbose "Data: $post_data\n";
     $req->content($post_data);

     my $resp = $ua->request($req);
     if ($resp->is_success) {
	 my $message = $resp->decoded_content;
	 verbose "Received reply: $message\n";
     }
     else {
	 $code = 2;
	 $message = $resp->message;
	 verbose "HTTP POST error code: ", $resp->code, "\n";
	 verbose "HTTP POST error message: ", $resp->message, "\n";
     }
          
     $np->nagios_exit( $code, "$message" );
}
