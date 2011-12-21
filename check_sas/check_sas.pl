#!/usr/bin/perl -w
#
# nrpe plugin to monitoring io on sas
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

my $sas_descr;
my $sas_speed;
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
    "d|disk=s"     => \$sas_descr,
    'r'            => \$o_noreg,
    "u|units=s"    => \$units,
    "M|max=i"      => \$max_value
    );

sub print_usage {
	print <<EOU;
    Usage: check_sas.pl -d disk

    Options:

    -d --disk STRING
        disk Name

EOU

	exit( $STATUS_CODE{"UNKNOWN"} );
}

if ( $status == 0 ) {
    print_help();
    exit $STATUS_CODE{'OK'};
}

if  ( !$sas_descr ) {
	print_usage();
}

# get sas disk

my @sas_disks = `sudo /sbin/multipath -l | grep $sas_descr | cut -d" " -f2`;
if ( ! @sas_disks ){
        exit $STATUS_CODE{"UNKNOWN"};
}
chomp(@sas_disks);

open F, "</proc/diskstats" or die "Can't open /proc/diskstats: $!";
my @f = <F>;
close F;

my %perf_data;

foreach my $sas_disk (@sas_disks) { 
   foreach (@f) {
        if ($_ =~ /${sas_disk}/){
	        $_ =~ s/\s+/ /g;
                @splitLine=split (/ /,$_);
                $perf_data{$sas_disk} = [ $splitLine[6],$splitLine[10] ];
                last;
                #Interface found, exiting loop
        }
   }
}

# end io statistics gathering

# Starting calculations

my $row;
my $last_check_time  = time - 1;
my $last_read_bytes;
my $last_write_bytes;
my $sas_disk;
my %last_perf_data = %perf_data;

if (
    open( FILE,
          "<" . $IO_FILE . $sas_descr
    )
)
{
    while ( $row = <FILE> ) {
        ( $sas_disk, $last_check_time, $last_read_bytes, $last_write_bytes ) = split( ":", $row );
        if ( (! $last_read_bytes) || (! $last_write_bytes) || ($last_read_bytes !~ m/\d/) || ($last_write_bytes !~ m/\d/) ) {
                %last_perf_data = %perf_data;
                exit;
        }
        $last_perf_data{$sas_disk} = [ $last_read_bytes, $last_write_bytes ];
    }
    close(FILE);
}


# save current statistics

open( FILE, ">" . $IO_FILE . $sas_descr )
  or die "Can't open $IO_FILE for writing: $!";

my $update_time = time;

for my $sas_disk ( keys %perf_data ) {
    printf FILE (  "%s:%s:%.0ld:%.0ld\n", $sas_disk, $update_time, $perf_data{$sas_disk}[0], $perf_data{$sas_disk}[1] );
}

close(FILE);

# generic request

my $exit_status = "OK";

my $output_pd;
my $total_read = 0;
my $total_write = 0;

for my $sas_disk ( keys %perf_data ) {
    $output_pd .=  " read_$sas_disk=".sprintf("%.2lf",( (@{ $perf_data{$sas_disk} }[0] - @{ $last_perf_data{$sas_disk} }[0])/ ( time - $last_check_time ) )).";;;;; "."write_$sas_disk=".sprintf("%.2lf",( ( @{ $perf_data{$sas_disk} }[1] - @{ $last_perf_data{$sas_disk} }[1])/ ( time - $last_check_time ))).";;;;";
    $total_read += ( (@{ $perf_data{$sas_disk} }[0] - @{ $last_perf_data{$sas_disk} }[0])/ ( time - $last_check_time ) );
    $total_write += ( (@{ $perf_data{$sas_disk} }[1] - @{ $last_perf_data{$sas_disk} }[1])/ ( time - $last_check_time ) );
}

my $output = "Averege total : ".sprintf("%.2lf",$total_read)." read, ".sprintf("%.2lf",$total_write)." write | total_read=".sprintf("%.2lf",$total_read).";;;; total_write=".sprintf("%.2lf",$total_write).";;;; ".$output_pd."\n";

print $output;
