#!/bin/bash
# Plugin for Nagios/Icinga
# Written by D. Ryobryshkin (dmitry.r@cyberflow.net)
# Last Modified: 2012-11-30
#
# Description:
#
# This plugin will check degrade status for software raid

# Don't change anything below here

# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

# normal contains device in raid
NRAID=2

PROGNAME=$(basename $0)

# print_usage() {
# 	echo "Usage: $PROGNAME "
# 	echo ""
# }

# print_help() {
# 	print_usage
# 	echo ""
# 	echo "This plugin will check howmany software reid in degrade status"
# 	echo ""
# 	exit 0
# }

exitstatus=$STATE_UNKNOWN #default
COUNT=0
MESSAGE="All OK"

for i in `grep 1 -l /sys/block/md*/md/degraded | awk -F\/ '{print $4}'`; do
   if [ `cat /sys/block/$i/md/raid_disks` -eq 2 ]
   then
      exitstatus=$STATE_WARNING; 
      COUNT=$[$COUNT+1]
      MESSAGE="Node there are $COUNT raids in degraded state"
   fi     
done

echo $MESSAGE
exit $exitstatus