#!/bin/sh
#
#
# License : GPL
#
# by Dmitry Rebryshkin
#
#
# Requirements :
# Traceroute command and permisions.
#
# Version 0.1 : 17/02/2012 
# Initial release.
#
#
################################################################################

# Nagios return codes
STATE_OK=0;
STATE_WARNING=1;
STATE_CRITICAL=2;
STATE_UNKNOWN=3;
STATE_DEPENDENT=4;

PROGNAME=$(basename $0);

exitstatus=$STATE_UNKNOWN;

print_usage() {
	echo "Usage: $PROGNAME";
	echo "";
	echo "Options:";
	echo "-h  --help";	
	echo "-H  Hostname or IP address of the server to check."
	echo "-j  The number of jump to evaluate."
}

print_help() {
	print_usage
	echo "";
	echo "This plugin will check specific number of jump to host";
	echo "";
	exit 0;
}

volumegroup=
while test -n "$1"; do
    case "$1" in
	--help)
	    print_help
	    exit $STATE_OK
	    ;;
	-h)
	    print_help
	    exit $STATE_OK
	    ;;
	-H)
	    host_name=$2
	    shift
	    ;;
	-j)
	    def_jumps=$2
	    shift
	    ;;
    esac
    shift
done

[ -z ${host_name} ] && print_help;

JUMPS=$(traceroute -n -q1 -w1 -t8 $host_name | tail -n+2 | wc -l);

#[ -z ${def_jumps} ] && def_jumps=${JUMPS};
[ -z ${def_jumps} ] && {
    [ -f /tmp/${host_name}.* ] && {
	def_jumps=$(ls /tmp/${host_name}* | awk -F\. '{print $5}');
    } || {
	def_jumps=${JUMPS};
	touch /tmp/${host_name}.${def_jumps};
    }
}


case "${JUMPS}" in
    30)
	echo "CRITICAL: No route to host"
	exit $STATE_CRITICAL;
	;;
    *)
        [ ${JUMPS} -gt ${def_jumps} ] && echo "WARNING: Jumps is greater than default." && exit $STATE_WARNING;
esac

echo "OK: Route to host is OK - ${JUMPS} jumps" && exit $STATE_OK;