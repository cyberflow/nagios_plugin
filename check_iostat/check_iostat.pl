#!/usr/bin/perl -w
#
# nrpe plugin to monitoring io
# Create by Dmitry Ryobryshkin
# dmitry.r@cyberflow.net
#
# v0.1
#
#

use strict;

use Getopt::Long;
&Getopt::Long::config('bundling');

use Data::Dumper;

my $disk_descr;
my $disk_speed;
my $opt_h;
my $units;
my $line;
my $error;
my $max_value;
my $max_bytes;

my @splitLine;

# Path to tmp file
my $IO_FILE = "/tmp/iotraffic";

# chanches 
my %STATUS_CODE = ( 'UNKNOWN' => '3', 'OK' => '0', 'WARNING' => '1', 'CRITICAL' => '2' );

# default values;
my ( $ior, $iow ) = 0;
my $warn_usage = 85;
my $crit_usage = 98;
my $o_noreg    = undef;

my $status = GetOptions(
    "h|help"       => \$opt_h,
    "w|warning=s"  => \$warn_usage,
    "c|critical=s" => \$crit_usage,
    "d|disk=s"     => \$disk_descr,
    'r'            => \$o_noreg,
    "u|units=s"    => \$units,
    "M|max=i"      => \$max_value
    );

sub print_usage {
	print <<EOU;
    Usage: check_iostat.pl -d disk [ -w warn ] [ -c crit ]

    Options:

    -d --disk STRING
        disk Name
    -u --units STRING
        gigabits/s,m=megabits/s,k=kilobits/s,b=bits/s.
    -w --warning INTEGER
    -c --critical INTEGER
    -M --max INTEGER

EOU

	exit( $STATUS_CODE{"UNKNOWN"} );
}

if ( $status == 0 ) {
    print_help();
    exit $STATUS_CODE{'OK'};
}

if  ( !$disk_descr ) {
	print_usage();
}

my $disk_pr = $disk_descr;
$disk_pr =~ s/!/\//;

open F, "</proc/diskstats" or die "Can't open /proc/diskstats: $!";
my @f = <F>;
close F;

foreach (@f) {
        if ($_ =~ /${disk_pr}/){
                $line=$_;
                last;
                #Interface found, exiting loop
        }
}

open F, "</sys/block/$disk_descr/queue/hw_sector_size" or die "Can't open /sys/block/$disk_descr/queue/hw_sector_size: $!";
my $sector_sz = <F>;
close F;

$line =~ s/\s+/ /g;
@splitLine=split (/ /,$line);

my $read_bytes=$splitLine[6]*$sector_sz;
my $write_bytes=$splitLine[10]*$sector_sz;

# end io statistics gathering

# Starting calculations

my $row;
my $last_check_time  = time - 1;
my $last_read_bytes  = $read_bytes;
my $last_write_bytes = $write_bytes;

if (
    open( FILE,
	  "<" . $IO_FILE . "_dev" . $disk_descr
    )
)
{
    while ( $row = <FILE> ) {
	( $last_check_time, $last_read_bytes, $last_write_bytes ) = split( ":", $row );
	if ( ! $last_read_bytes  ) { $last_read_bytes=$read_bytes;   }
	if ( ! $last_write_bytes ) { $last_write_bytes=$write_bytes; }

	if ($last_read_bytes !~ m/\d/) { $last_read_bytes=$read_bytes;    }
	if ($last_write_bytes !~ m/\d/) { $last_write_bytes=$write_bytes; }
    }
    close(FILE);
}

my $update_time = time;

open( FILE, ">" . $IO_FILE . "_dev" . $disk_descr )
  or die "Can't open $IO_FILE for writing: $!";

printf FILE ( "%s:%.0ld:%.0ld\n", $update_time, $read_bytes, $write_bytes );
close(FILE);

my $db_file;

$read_bytes = counter_overflow( $read_bytes, $last_read_bytes, $max_bytes );
$write_bytes = counter_overflow( $write_bytes, $last_write_bytes, $max_bytes );

my $read_traff = sprintf( "%.2lf",
			  ( $read_bytes - $last_read_bytes ) / ( time - $last_check_time ) );
my $write_traff = sprintf( "%.2lf",
			  ( $write_bytes - $last_write_bytes ) / ( time - $last_check_time ) );

my $exit_status = "OK";

my $output = "Average traffic : $read_traff read" . ", $write_traff write.";

$output .= "| read=$read_traff;;;; write=$write_traff;;;;\n";

print $output;


sub counter_overflow {
    my ($bytes, $last_bytes, $max_bytes ) = @_;

    $bytes += $max_bytes if ( $bytes < $last_bytes );
    $bytes = $last_bytes if ( $bytes < $last_bytes );
    return $bytes;
}
