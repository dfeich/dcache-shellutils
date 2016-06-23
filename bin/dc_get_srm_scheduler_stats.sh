#!/bin/bash
#################################################################
# dc_get_srm_scheduler_stats.sh
#
# Author: Johan Guldmyr <johan.guldmyr@csc.fi>
#
# $Id$
#################################################################

myname=$(basename $0)

# DEFAULTS
#
##########

usage(){
    cat <<EOF
Synopsis: 
      $myname [options] cellname
Options:
         -n                    :  metric format

Description:
      print SRM info in a format machine readable format

Example:
      dc_get_srm_scheduler_stats.sh -n collectd SRM-storage01

EOF
}

##############################################################
TEMP=`getopt -o hn: --long help -n "$myname" -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        -n)
            numopt=" $2"
            shift 2
            ;;
        --)
            shift;
            break;
            ;;
        *)
            echo "Internal error!"
            usage
            exit 1
            ;;
    esac
done

cell=$1
shift


if test x"$cell" = x ; then
    echo "Error: Need a Cell name" >&2
    exit 1
fi

toremove=""

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

cmdfile=`mktemp /tmp/dc_generic-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

cat > $cmdfile <<EOF
\c $cell 
info
\q
EOF
toremove="$toremove $cmdfile"

execute_cmdfile -f $cmdfile resfile
toremove="$toremove $resfile"

###

# output from \s SRM-door info
#--- scheduler-get (Scheduler for GET operations) ---
#    Queued ............................     0     [Queued]
#    In progress (max 1000) ............     0     [InProgress]
#    Queued for transfer ...............     0     [RQueued]
#    Waiting for transfer (max 50000) ..     0     [Ready]
#    ------------------------------------------
#    Total requests (max 50000) ........     0
#

## Collectd format
# PUTVAL hostname/dcache.srm.RESERVE-SPACE.In_progress/counter interval=60 N:0

OLDIFS=$IFS
IFS=","
FORMAT="collectd"
HOSTI="$(hostname -s)"
HIERARCHY="$HOSTI/dcache"

schedulers="bringonline,copy,get,ls,put,reserve-space"
metrics="Queued \.,In progress,Queued for transfer,Waiting for transfer"

for scheduler in $schedulers; do
  for metric in $metrics; do
    # metric_stripped is the metric value without the \. at the end
    metric_stripped="$(echo $metric|sed -e 's/\s/_/g')"
    metric_stripped="$(echo $metric_stripped|sed -e 's/_\\\.//g')"
    queued=0
    in_progress=0
    total_requests=0
    # grep for the output of each scheduler, grep for each metric, then use a multiple space delimiter and finally strip spaces
    value=$(cat $resfile|grep -A7 "\-\-\- scheduler-$scheduler"|grep $metric|awk -F "    " '{print $3}'|sed -e 's/\s//')
    if [ "$value" != "" ]; then
      if [ "$FORMAT" == "collectd" ]; then
        echo -e "PUTVAL $HIERARCHY.srm.$scheduler.$metric_stripped/counter interval=60 N:$value"
      else
        echo "$scheduler $metric_stripped: $value"
      fi
    fi
  done
done
IFS=$OLDIFS

###

rm -f $toremove
