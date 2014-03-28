#!/bin/bash
#################################################################
# dc_get_pool_movers.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
# $Id$
#################################################################

debug=0
beautify=0
timestamp=0

usage(){
    cat <<EOF
Synopsis: 
      dc_get_pool_movers.sh [pool-listfile]
Options:
      -b       :   beautify. Print only pnfsID and poolname. This can be directly
                   piped into commands working on the pnfs IDs
      -k           generate a list that can be filtered and piped to the dc_kill_pool_movers
                   command (includes pnfs filenames. may take slightly longer)
      -q queue :   list only movers for the named mover queue
      -d       :   debug. Show what commands are executed. The output will
                   be sent to stderr to not contaminate stdout.
      -t       :   append a timestamp (tagged with ts=) to each output line
                   only affects raw default output

Description:
      Shows all movers of the respective pools. The listing matches exactly
      the output of 'movers ls' given in a pool cell, but with the name of
      the pool inserted at the beginning of the line.
      When no pool-listfile is given, the pool list is expected on stdin

      Note: querying a large number of pools can take some time

Examples:
      dc_get_pool_movers.sh cmspools.lst
      cat cmspools.lst | dc_get_pool_movers.sh
      dc_get_pool_list.sh | dc_get_pool_movers.sh
EOF
}

##############################################################
TEMP=`getopt -o bdhkq:t --long help -n 'dc_replicate_IDlist.sh' -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        -b)
            beautify=1
            shift
            ;;
        -d)
            debug=1
            shift
            ;;
        -k)
            beautify=2
            shift
            ;;
        -q)
            queue=$2
            shift 2
            ;;
        -t)
            timestamp=1
            shift
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

listfile=$1
shift


if test x"$queue" != x; then
   qstr="-queue=$queue"
fi

toremove=""
if test x"$listfile" = x; then
   listfile=`mktemp /tmp/dc_generic-$USER.XXXXXXXX`
   while read line; do
      echo "$line" >> $listfile
   done
   toremove="$toremove $listfile"
fi
if test ! -r $listfile; then
    echo "Error: Cannot read ID list file: $listfile" >&2
    exit 1
fi

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

tmpresfile=`mktemp /tmp/dc_utils-gpmr-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a temporary result file" >&2
    exit 1
fi

myts=""
toremove="$toremove $resfile"
for pool in `cat $listfile`; do
   cmdfile=`mktemp /tmp/dc_utils-gpm-$USER.XXXXXXXX`
   if test $? -ne 0; then
       echo "Error: Could not create a cmdfile" >&2
       exit 1
   fi
   cat >> $cmdfile <<EOF
cd $pool
mover ls $qstr
..
logoff
EOF
   if test x"$debug" = x1; then
      cat $cmdfile >&2
   fi
   if test x"$timestamp" = x1; then
      myts=" ts=$(date +%s)"
   fi
   execute_cmdfile -f $cmdfile resfile
   sed -ne "s/^\([0-9][0-9]*  *.*\)$/$pool \1$myts/p" $resfile  >> $tmpresfile
   rm -f $cmdfile $resfile
done

if test x"$beautify" = x1; then
   sed -e 's/^\([^ ][^ ]*\).* \([0-9A-F][0-9A-F]*\) .*/\2 \1/' $tmpresfile
elif test x"$beautify" = x2; then
   tmpnamefile=`mktemp /tmp/dc_utils-$USER.XXXXXXXX`
   if test $? -ne 0; then
       echo "Error: Could not create a temporary result file" >&2
       rm -f $toremove
       exit 1
   fi
   toremove="$toremove $tmpnamefile"
   awk '{print $6}' $tmpresfile| dc_get_pnfsname_from_IDlist.sh > $tmpnamefile
   paste <(awk '{print $1,$2,$3,$4, $5}' $tmpresfile) $tmpnamefile
else
   cat $tmpresfile
fi

rm -f $toremove

