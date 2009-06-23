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

usage(){
    cat <<EOF
Synopsis: 
      dc_get_pool_movers.sh [pool-listfile]
Options:
      -b       :   beautify. Print only pnfsID and poolname. This can be directly
                   piped into commands working on the pnfs IDs
      -q queue :   list only movers for the named mover queue
      -d       :   debug. Show what commands are executed. The output will
                   be sent to stderr to not contaminate stdout.

Description:
      Shows all movers of the respective pools. The listing matches exactly
      the output of 'movers ls' given in a pool cell, but with the name of
      the pool inserted at the beginning of the line.
      When no pool-listfile is given, the pool list is expected on stdin

      Note: querying a large number of pools can take some time

Examples:
      dc_get_pool_movers.sh cmspools.lst
      echo cmspools.lst | dc_get_pool_movers.sh
      dc_get_pool_list.sh | dc_get_pool_movers.sh
EOF
}

##############################################################
TEMP=`getopt -o bdhq: --long help -n 'dc_replicate_IDlist.sh' -- "$@"`
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
        -q)
            queue=$2
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
   execute_cmdfile -f $cmdfile resfile
   sed -ne "s/^\([0-9][0-9]*  *.*\)$/$pool \1/p" $resfile >> $tmpresfile
   rm -f $cmdfile $resfile
done

if test x"$beautify" = x1; then
   sed -e 's/^\([^ ][^ ]*\).* \([0-9A-F][0-9A-F]*\) .*/\2 \1/' $tmpresfile
else
   cat $tmpresfile
fi

rm -f $toremove

