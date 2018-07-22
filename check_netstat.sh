#!/bin/bash
#
# Version 0.0.1 - Jul/20011
#

netstat=`which netstat 2>/dev/null`

function help {
echo -e "\n\tThis plugin shows the I/O usage of the network card, using the netstat external program.\n Use check_netstat.sh -d <dev> -w warn_ierrs,warn_oerrs,warn_collins,warn_queue -c crit_ierrs,crit_oerrs,crit_collins,crit_queue\n"
	exit -1
}

# Ensuring we have the needed tools:
( [ ! -f $netstat ] ) && \
	( echo "ERROR: You must have netstat installed in order to run this plugin" && exit -1 )

# Getting parameters:
while getopts "d:w:c:h" OPT; do
	case $OPT in
		"d") device=$OPTARG;;
		"w") warning=$OPTARG;;
		"c") critical=$OPTARG;;
		"h") help;;
	esac
done

( [ -z $device ] ) && \
	( echo "ERROR: You must specify the device." && exit -1 )

# Adjusting the three warn and crit levels:
crit_ierrs=`echo $critical | cut -d, -f1`
warn_ierrs=`echo $warning | cut -d, -f1`
crit_oerrs=`echo $critical | cut -d, -f2`
warn_oerrs=`echo $warning | cut -d, -f2`
crit_collis=`echo $critical | cut -d, -f3`
warn_collis=`echo $warning | cut -d, -f3`
crit_queue=`echo $critical | cut -d, -f4`
warn_queue=`echo $warning | cut -d, -f4`

# Doing the actual check:
output=`$netstat -i | grep $device`
lc=`echo "$output" | wc -l | awk '{print $1}'`
if ( [[ -z $output ]] || [[ $lc -ne 1 ]] ); then 
	echo -e "Error in device"
	exit -1
fi


ipkts=`echo $output | awk '{print $5}'`
ierrs=`echo $output | awk '{print $6}'`
opkts=`echo $output | awk '{print $7}'`
oerrs=`echo $output | awk '{print $8}'`
collis=`echo $output | awk '{print $9}'`
queue=`echo $output | awk '{print $10}'`

if ( ( [ -n "$crit_ierrs" ] && [[ "$ierrs" -gt "$crit_ierrs" ]] ) || \
	( [ -n "$crit_oerrs"  ] && [[ "$oerrs" -gt "$crit_oerrs" ]] ) || \
	( [ -n "$crit_collis"  ] && [[ "$collis" -gt "$crit_collis" ]]) || \
	( [ -n "$crit_queue"  ] && [[ "$collis" -gt "$crit_queue" ]]) ); then
	msg="CRITICAL"
	status=2
else 
	if ( ( [ -n "$warn_ierrs"  ] && [[ "$ierrs" -gt "$warn_ierrs" ]] ) || \
		( [ -n "$warn_oerrs"  ] && [[ "$oerrs" -gt "$warn_oerrs" ]] ) || \
		( [ -n "$warn_collis"  ] && [[ "$collis" -gt "$warn_collis" ]]) || \
		( [ -n "$warn_queue"  ] && [[ "$collis" -gt "$warn_queue" ]]) ); then
		msg="WARNING"
		status=1
	else
		msg="OK"
		status=0
	fi
fi

echo "netstat $msg - | ipkts=$ipkts ierrs=$ierrs;$warn_ierrs;$crit_ierrs opkts=$opkts oerrs=$oerrs;$warn_oerrs;$crit_oerrs collis=$collis;$warn_collis;$crit_collis queue=$queue;$warn_queue;$crit_queue"

# Bye!
exit $status
