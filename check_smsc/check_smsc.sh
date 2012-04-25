#!/bin/bash

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

PROGNAME=`basename $0`
VERSION="Version 0.1,"
AUTHOR="2012, Dmitry Ryobryshkin (http://cyberflow.github.com/)"

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

print_version() {
    echo "$VERSION $AUTHOR"
}

print_help() {
    print_version $PROGNAME $VERSION
    echo ""
    echo "$PROGNAME is a Nagios plugin to check a balance for smsc.ru."
    echo "You must provide username and md5hash password from account smsc.ru."
    echo "Plugin return balance of account. You may provide warning and critical options."
    echo ""
    echo "$PROGNAME -l login -p password [-w 200] [-c 100]"
    echo ""
    echo "Options:"
    echo "  -l/--login)"
    echo "     You need to provide a login for smsc.ru"
    echo "  -p/--pass)"
    echo "     You need to provide md5hash password for smsc.ru"
    echo "     You may use plain text password too, but it not secure"
    echo "  -w/--warning)"
    echo "     Defines a warning level for a target which is explained"
    echo "     below. Default is: off"
    echo "  -c/--critical)"
    echo "     Defines a critical level for a target which is explained"
    echo "     below. Default is: off"
    exit $ST_UK
}

while test -n "$1"; do
    case "$1" in 
	--help|-h)
	    print_help
	    exit $ST_UK
	    ;;
	--version|-v)
	    print_version $PROGNAME $VERSION
            exit $ST_UK
	    ;;
	--login|-l)
	    login=$2
	    shift
	    ;;
	--pass|-p)
	    pass=$2
	    shift
	    ;;
	--warning|-w)
	    warning=$2
	    shift
	    ;;
	--critical|-c)
	    critical=$2
	    shift
	    ;;
	*)
	    echo  "Unknown argument: $1"
            print_help
            exit $ST_UK
            ;;
        esac
    shift
done

get_wcdiff() {
    if [ ! -z "$warning" -a ! -z "$critical" ]
    then
        wclvls=1
        if [ ${critical} -gt ${warning} ]
        then
            wcdiff=1
        fi
    elif [ ! -z "$warning" -a -z "$critical" ]
    then
        wcdiff=2
    elif [ -z "$warning" -a ! -z "$critical" ]
    then
        wcdiff=3
    fi
}

val_wcdiff() {
    if [ "$wcdiff" = 1 ]
    then
        echo "Please adjust your warning/critical thresholds. The warning \
must be lower than the critical level!"
        exit $ST_UK
    elif [ "$wcdiff" = 2 ]
    then
        echo "Please also set a critical value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    elif [ "$wcdiff" = 3 ]
    then
        echo "Please also set a warning value when you want to use \
warning/critical thresholds!"
        exit $ST_UK
    fi
}

get_params() {
    if [ -z "$login" -o -z "$pass" ]
    then
	echo "Please provide login and password options!"
	exit $ST_UK
    fi
}

get_vals() {
    balance=`curl -s "http://smsc.ru/sys/balance.php?login=${login}&psw=${pass}&fmt=0"`

    if [[ ${balance} =~ ^ERROR* ]]
    then
	echo "CRITICAL - API return error"
	exit $ST_CR
    fi
}

do_output() {	
	output="Balance: ${balance}"
}

do_perfdata() {
	perfdata="'balance'=${balance}"
}

# Here we go!
get_wcdiff
val_wcdiff
get_params

get_vals
do_output
do_perfdata

if [ -n "$warning" -a -n "$critical" ]
then
    if [ ${balance/\.*} -lt ${warning} -a ${balance/\.*} -ge ${critical} ]
    then
	echo "WARNING - ${output} | ${perfdata}"
	exit $ST_WR
    elif [ ${balance/\.*} -lt ${critical} ]
    then
	echo "CRITICAL - ${output} | ${perfdata}"
	exit $ST_CR
    else
	echo "OK - ${output} | ${perfdata}"
	exit $ST_OK
    fi
else
    echo "OK - ${output} | ${perfdata}"
    exit $ST_OK
fi