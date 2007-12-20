#!/bin/bash

#################################################################
# dc_pnfs_replica_checker.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2007-12-20
#
# $Id:$
#################################################################

DATE=`date +%Y%m%d-%H%M`

########## DEFAULTS #################
dbg=1
resdir=ns_consistency-${DATE}
#####################################

usage() {
    cat <<EOF
Synopsis: dc_pnfs_replica_checker.sh [options] pnfs-path

Description:
          This tool will collect information on all regular files below the given
          pnfs path. It will locate pnfs entries with no IDs and also entries with
          no replicates. All results will be written to a results directory 
Options:
          -r directory       : specifies the results directory name [$resdir]
EOF
}


TEMP=`getopt -o hr: --long help -n 'dc_pnfs_replica_checker.sh' -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        -r)
	    resdir="$2"
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

pnfs_basepath=$1


if test ! -r $DCACHE_SHELLUTILS/dc_utils_lib.sh; then
    echo "ERROR: Env Var DCACHE_SHELLUTILS must point to directory containing dc_utils_lib.sh" >&2
    exit
fi
source $DCACHE_SHELLUTILS/dc_utils_lib.sh

if test x"$pnfs_basepath" = x; then
   usage
   echo "Error: No basepath specified" >&2
   exit 1
fi

if test ! -d $pnfs_basepath; then
   echo "Error: No such directory: $pnfs_basepath"
fi

mkdir $resdir
if test $? -ne 0; then
   echo "failed to create results directory $resdir" >&2
   exit 1
fi

echo "All results will be written to directory $resdir"

echo $pnfs_basepath > $resdir/basepath

echo -n "Finding the files under $pnfs_basepath..."
pnfslist=$resdir/pnfs.lst
starttimer
find $pnfs_basepath -type f > $pnfslist
if test $? -ne 0; then
   echo "failed"
   exit 1
fi
t=`gettimer`
numfiles=`wc -l $pnfslist|awk '{print $1}'`
echo "OK  ($numfiles files took $t seconds)"


echo -n "mapping to IDs... "
IDpnfslist=$resdir/IDpnfs.lst
starttimer
dc_get_ID_from_pnfsnamelist.sh $pnfslist > $IDpnfslist
if test $? -ne 0; then
   echo "failed"
   exit 1
fi
t=`gettimer`
echo "OK  ($numfiles files took $t seconds)"

noIDlist=$resdir/noID_pnfs.lst
grep "Error:Missing" $IDpnfslist > $noIDlist
num_noID=`wc -l $noIDlist|awk '{print $1}'`
if test $num_noID -gt 0; then
   echo "WARNING: $num_noID entries lack a corresponding ID!"
fi

IDlist=$resdir/ID.lst
grep -v "Error:Missing" $IDpnfslist| cut -f1 -d' ' > $IDlist
num_ID=`wc -l $IDlist|awk '{print $1}'`


cachelist=$resdir/cacheinfo.lst
echo -n "getting replica information (cacheinfo)... "
dc_get_cacheinfo_from_IDlist.sh $IDlist > $cachelist
if test $? -ne 0; then
   echo "failed"
   exit 1
fi
t=`gettimer`
echo "OK  ($num_ID entries took $t seconds)"


norepllist=$resdir/noreplicate_ID.lst
rm -f $norepllist
while read id cache; do
   if test x"$cache" = x
      then echo $id >> $norepllist
   fi
done < $cachelist

noreplpnfslist=$resdir/noreplicate_pnfs.lst
rm -f  $noreplpnfslist
num_norepl=`wc -l $norepllist|awk '{print $1}'`
if test $num_norepl -gt 0; then
   echo "WARNING: $num_norepl entries lack a replicate!"

   for id in `cat $norepllist`; do
      grep $id $IDpnfslist >>  $noreplpnfslist
   done
fi
