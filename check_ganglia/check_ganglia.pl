#!/usr/bin/perl

##########
# FILE: check_ganglia.pl
# 
# SYNOPSIS: check the XML tree from a host gmond or server gmetad port, parse
# + for host info and get down and dirty with host metrics. Useful both as a 
# + host check and service check in nagios if targeting a host (less XML pull that way).
# LICENSE: GPL, Copyright 2006 Eli Stair <estair {at} ilm {dot} com>
#
##########

#use strict;
use IO::Socket;
use Switch;
use Cache::File;
# ^^^^ TODO
use XML::Parser;
use DateTime::Format::Epoch::Unix;
use Data::Dumper;
#^^^ Debug only

our $VERSION = '0.1';

use Nagios::Plugin::Getopt;
#use Nagios::Plugin::Threshold;
# ^^^^ Need this?
#use Nagios::Plugin::Config;
# ^^^^ DELETE ME
use Nagios::Plugin;

use vars qw(
  $np
  $options
  $prefix
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
     $np = Nagios::Plugin->new( shortname => 'CHECK_GANGLIA' );

     my $usage = <<'EOT';
check_ganglia.pl [-H|--host <host>] [-P|--port <port>] [-T|--target <target_host>] [-m|--metric] [-C|--cache <path/to/cache_file>] [-t|--timeout] 
    [-h|--help] [-V|--version] [--usage] [--debug] [--verbose]
EOT
             
     $options = Nagios::Plugin::Getopt->new(
        usage   => $usage,
        version => $VERSION,
        blurb   => 'Check ganglia host/metric'
     );
        
     $options->arg(
        spec     => 'host|H=s',
        help     => 'hostname/IP: of host to connect to gmetad/gmond on',
        required => 1,
     );

     $options->arg(
        spec     => 'targethost|T=s',
        help     => 'Targethost: when hostcheck, the host to pull data for',
        required => 1,
     );

     $options->arg(
        spec     => 'metric|m=s',
        help     => 'Metric: the gmetric defined value to return exclusively',
        required => 0,
     );

     $options->arg(
        spec     => 'port|P=s',
        help     => 'Port: to connect to and retrieve XML (default: 8651)',
        default  => '8651',
        required => 0,
     );

     $options->arg(
        spec     => 'timeout|t=s',
        help     => 'TCP timeout (default: 10)',
        default  => '10',
        required => 0,
     );

     $options->arg(
        spec     => 'debug',
        help     => 'debugging output',
        required => 0,
     );

     $options->getopts();

     my $parser = new XML::Parser( Style => "Subs" );


     my $socket = IO::Socket::INET->new(Timeout=>$options->timeout, Proto=>"tcp", PeerAddr=>$options->host, PeerPort=>$options->port)
	 or $np->nagios_die("Can't open socket to host=" . $options->host . " and port=" . $options->port . ": $! \n ");

     eval { $parser->parse($socket); };
     if (  $@ !=~ m{^ok} ) { 
	 $np->nagios_die("Can't parse XML stream: $@");
     }

}

### FUNC: GRID
sub GRID {
    my ($expat, $element, %attrs) = @_;
    my(%grid);

    if (defined $options->debug) {
	@test = keys(%grid);
	print "GRID attrs array = @test ","\n";
    }

    if (%attrs) {
       $grid{NAME}= $attrs{NAME};
    }
# Create Reference ($rclusters) to clusters Array; This is where all clusters are stored.
# At this point the array @clusters is empty and thus $rclusters point to an empty array.
    $rclusters = \@clusters;
}
### /FUNC: GRID

### FUNC: CLUSTER
sub CLUSTER {
    my ($expat, $element, %attrs) = @_;
    my(%cluster);

    if (defined $options->debug) {
	@test = keys(%attrs);
	print "CLUSTER attrs array = @test ","\n";
	print "LOCALTIME: $attrs{LOCALTIME}","\n";
    }

    if (%attrs) {
      $cluster{OWNER} = $attrs{OWNER};
      $cluster{NAME} = $attrs{NAME};
      $cluster{LOCALTIME} = $attrs{LOCALTIME};
    }
    $rcluster = \%cluster;
    my(@hosts);
    $rhosts = \@hosts;
}
### /FUNC: CLUSTER

### FUNC: HOST
sub HOST {
    my ($expat, $element, %attrs) = @_;
    my(%host);

    if (defined $options->debug) {
	@test = keys(%attrs);
	print "HOST attrs array = @test ","\n";
    }

# add values declared at the cluster level to the host array:
    if (%attrs) {
        $host{NAME} = $attrs{NAME};
        $host{IP}   = $attrs{IP};
        $host{REPORTED}   = $attrs{REPORTED};
    }
# Create a Reference to hash %host.
# The hash %host will run out of scope at the end of the subroutine
# but the reference to %host ($rhost) will still exist. 
    $rhost = \%host; # Reference to Hash host
}
### /FUNC: HOST

### FUNC: HOST_
sub HOST_ {
    push ( @$rhosts,$rhost );
}
### /FUNC: HOST_

### FUNC: METRIC
sub METRIC {
    my ($expat, $element, %attrs) = @_;

    if (defined $options->debug) {
	@test = keys(%attrs);
	print "METRIC attrs array = @test ","\n";
    }

    $$rhost{$attrs{NAME}}=$attrs{VAL};
}
### /FUNC: METRIC

### FUNC: CLUSTER_
sub CLUSTER_ {
    $$rcluster{HOSTS}=$rhosts;      

# If reference $rclusters is defined, then we have a GRID Element in the XML
# and thus we are quering an GMETAD Server. We should push the info
# for each cluster in @$rclusters

    if (defined $rclusters) {
        verbose "### IN CLUSTER_: push (@$rclusters, $rcluster) \n ";
        push (@$rclusters, $rcluster);
    } else {
	&hostcheck_output($rcluster);
    }

}
### /FUNC: CLUSTER_

### FUNC: GRID_
sub GRID_ {
    my ($rcluster);

    foreach $rcluster (@$rclusters) {
	&hostcheck_output($rcluster);
    }
    # host was NOT found, exit with an error now:
    #exit $ERRORS{'CRITICAL'}
    #print "UNKNOWN: HOST ($targethost) not found in XML! \n";
    #exit $ERRORS{'UNKNOWN'}
    $np->nagios_exit(UNKNOWN, "HOST (" . $options->targethost . ") not found in XML! \n")
}
### /FUNC: GRID_

### FUNC: hostcheck_output
sub hostcheck_output {
    my($ref) = shift @_;
    my($ref_array)=$$ref{HOSTS};
    my($localtime)=$$ref{LOCALTIME};
    my($cluster)=$$ref{NAME};
    my($hostname);

    verbose "### In hostcheck_output: TARGETHOST == " . $options->targethost . " \n";

    foreach $hostkey (@$ref_array) {
        $hostname = $hostkey->{NAME};
        verbose "### HOSTNAME == $hostname \n";
    	if ("$hostname" eq $options->targethost) {

	    verbose "##### HOST FOUND IN XML \n";
            # populate a new hash with metric elements pulled from the array:
            while (my($key, $value) = each(%$hostkey) ) {
              $host_metrics{$key} = "$value";
            } # /while

            # Calculate times:
            my $checkin = $host_metrics{REPORTED};
            $host_metrics{checkin_long} = (DateTime::Format::Epoch::Unix->parse_datetime( $host_metrics{REPORTED} ));
            $host_metrics{localtime_long} = (DateTime::Format::Epoch::Unix->parse_datetime( $localtime ));
            $host_metrics{host_downtime} = (($localtime - $checkin) / 60 );
            $host_metrics{host_uptime} = (($host_metrics{REPORTED} - $host_metrics{boottime}) / 60 );

            # calculate host_state (UP/DOWN):
            unless ($host_metrics{host_downtime} <= 1) {
              $host_metrics{host_state} = "DOWN";
	      $code = 'CRITICAL';
            } else {
              $host_metrics{host_state} = "UP";
	      $code = 'OK';
            } #/unless host_state
            
	    verbose "##### HOST STATE: " . $host_metrics{host_state} . " \n";

          # Check for running mode, if single metric check skip the pretty phase:
          unless ($options->metric) {
            # pretty-print a header:
            print "#========= CLUSTER :           $cluster \n";
            print "#========= HOSTNAME:           $hostname \n";
            print "#========= METRIC:             ==>     VALUE: \n";
            foreach $metric (sort keys %host_metrics) {
              printf "%11s%-20s%3s%5s%-80s\n", "", "$metric", "=>", "", "$host_metrics{$metric}";
            } # /foreach
             # formatted output of host state:
             print "#========= Calculated runtime metrics:","\n";
             printf "%11s%-20s%3s%5s%-80s\n", "", "local_time", "=>", "", "$host_metrics{localtime_long}";
             printf "%11s%-20s%3s%5s%-80s\n", "", "host_checkin", "=>", "", "$host_metrics{checkin_long}";
             printf "%11s%-20s%3s%5s%-80.1f\n", "", "host_uptime", "=>", "", "$host_metrics{host_uptime}";
             printf "%11s%-20s%3s%5s%-5s%3s%-15s%-10.1f%-10s\n", "", "host_state", "=>", "", "$host_metrics{host_state}", "", "(checkin_delta:", "$host_metrics{host_downtime}", "minutes)";
	    $np->nagios_exit (OK, '');
          } else { # unless ($metric)
             if (!defined $host_metrics{$options->metric}) {
               print "UNKNOWN: ($metric) not found in host XML! ","\n";
               exit $ERRORS{'UNKNOWN'}
             } else {
		 if ($options->metric eq 'host_state') {
		     $np->nagios_exit( $code, "host_downtime = " . $host_metrics{host_downtime} . " \n" );
		 }
             }
          } # /unless ($metric)

        } else {# /if ($hostname eq)
	    #$np->nagios_exit( UNKNOWN, "TARGETHOST == " . $options->targethost . " not found in XML \n");
        } # /if hostname loop through hash.  We've exhausted input data, exit now:
     } # /foreach $hostkey

# don't exit here, create exit at end of all arrays to be searched (after function exits searching the last hash)
     
} 
### /FUNC: hostcheck_output
