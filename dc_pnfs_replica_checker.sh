#!/bin/bash

#################################################################
# dc_pnfs_replica_checker.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2007-12-20
#
# $Id$
#################################################################

DATE=`date +%Y%m%d-%H%M`

########## DEFAULTS #################
dbg=1
resdir=ns_consistency-${DATE}
bunchsize=1000
#####################################

usage() {
    cat <<EOF
Synopsis: dc_pnfs_replica_checker.sh [options] pnfs-path
          dc_pnfs_replica_checker.sh [options] -l pnfs-namelist-file

Description:
          This tool will collect information on all regular files below the given
          pnfs path or on all files of a given list file with pnfs names. It will locate
          pnfs entries with no mapped IDs and also entries with no replicates on any pool.
          All results will be written to a results directory.

          Note that you will have to have pnfs mounted, if you want to use the
          invocation recursing through a pnfs-path.

          The sript will carry out its operations on bunches of files (number can be
          defined by the -b option), in order to not overwhelm the shell.

Options:
          -r directory       : specifies the results directory name [$resdir]
          -l filename        : specify a list of pnfs names instead of using a base pnfs path
          -b integer         : process the list in bunches of this size [$bunchsize]          
EOF
}

pnfsCachereport() {
local pnfslist=$1

if test x"$pnfslist" = x; then
   echo "Error: pnfsCachereport called with no listfile given"
   exit 1
fi
if test ! -r "$pnfslist"; then
   echo "Error: Cannot read listfile $pnfslist"
   exit 1
fi
 
local IDpnfslist=${pnfslist%.lst}_IDpnfs.lst
local noIDlist=${pnfslist%.lst}_noID_pnfs.lst
local IDlist=${pnfslist%.lst}_ID.lst
local cachelist=${pnfslist%.lst}_cacheinfo.lst
local norepllist=${pnfslist%.lst}_noreplicate_ID.lst
local noreplpnfslist=${pnfslist%.lst}_noreplicate_pnfs.lst

local numfiles=`wc -l $pnfslist|awk '{print $1}'`
echo -n "mapping to IDs... "
starttimer
dc_get_ID_from_pnfsnamelist.sh $pnfslist > $IDpnfslist
if test $? -ne 0; then
   echo "failed"
   exit 1
fi
t=`gettimer`
echo "OK  ($numfiles files took $t seconds)"

grep "Error:Missing" $IDpnfslist > $noIDlist
num_noID=`wc -l $noIDlist|awk '{print $1}'`
if test $num_noID -gt 0; then
   echo "WARNING: $num_noID entries lack a corresponding ID!"
fi

grep -v "Error:Missing" $IDpnfslist| cut -f1 -d' ' > $IDlist
num_ID=`wc -l $IDlist|awk '{print $1}'`


echo -n "getting replica information (cacheinfo)... "
dc_get_cacheinfo_from_IDlist.sh $IDlist > $cachelist
if test $? -ne 0; then
   echo "failed"
   exit 1
fi
t=`gettimer`
echo "OK  ($num_ID entries took $t seconds)"


rm -f $norepllist
while read id cache; do
   if test x"$cache" = x
      then echo $id >> $norepllist
   fi
done < $cachelist

rm -f  $noreplpnfslist

if test -r "$norepllist"; then
   num_norepl=`wc -l $norepllist|awk '{print $1}'`
   echo "WARNING: $num_norepl entries lack a replicate!"

   for id in `cat $norepllist`; do
      grep $id $IDpnfslist >>  $noreplpnfslist
   done
fi

}

TEMP=`getopt -o b:hl:r: --long help -n 'dc_pnfs_replica_checker.sh' -- "$@"`
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
            bunchsize="$2"
            shift 2
            ;;
        -l)
            pnfs_srclist="$2"
            shift 2
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

mkdir $resdir
if test $? -ne 0; then
   echo "failed to create results directory $resdir" >&2
   exit 1
fi
cwd=`pwd`
cd $resdir
resdir=`pwd`
cd $cwd

##### result file definitions
pnfslist=$resdir/pnfs.lst
IDpnfslist=$resdir/IDpnfs.lst
noIDlist=$resdir/noID_pnfs.lst
IDlist=$resdir/ID.lst
cachelist=$resdir/cacheinfo.lst
norepllist=$resdir/noreplicate_ID.lst
noreplpnfslist=$resdir/noreplicate_pnfs.lst
workdir=$resdir/work
#####

if test ! -r $DCACHE_SHELLUTILS/dc_utils_lib.sh; then
    echo "ERROR: Env Var DCACHE_SHELLUTILS must point to directory containing dc_utils_lib.sh" >&2
    exit
fi
source $DCACHE_SHELLUTILS/dc_utils_lib.sh

echo "All results will be written to directory $resdir"

if test x"$pnfs_srclist" = x; then
   if test x"$pnfs_basepath" = x; then
      usage
      echo "Error: No basepath specified" >&2
      exit 1
   fi

   if test ! -d $pnfs_basepath; then
      echo "Error: No such directory: $pnfs_basepath"
   fi
   echo $pnfs_basepath > $resdir/basepath

   echo -n "Finding the files under $pnfs_basepath..."
   starttimer
   find $pnfs_basepath -type f > $pnfslist
   if test $? -ne 0; then
      echo "failed"
      exit 1
   fi
   t=`gettimer`
   numfiles=`wc -l $pnfslist|awk '{print $1}'`
   echo "OK  ($numfiles files took $t seconds)"
else
   cp $pnfs_srclist $pnfslist
   numfiles=`wc -l $pnfslist|awk '{print $1}'`
   echo "src list file contains $pnfs_srclist $numfiles entries"
fi

mkdir $workdir
cd $workdir
# here I split the large list into smaller lists
split -l $bunchsize $pnfslist part_pnfslist_
num_parts=`ls part_pnfslist_*|wc -l |awk '{print $1}'`

counter=0
for lst in `ls part_pnfslist_*`;do
   counter=$((counter + 1))
   echo "#######################################"
   echo "processing ${lst} ($counter/$num_parts)..."
   pnfsCachereport $lst
done

# merging of result files
echo "#############################################################"
echo -n "Merging the results...."
cat $workdir/*_ID.lst > $IDlist
cat $workdir/*_IDpnfs.lst > $IDpnfslist
cat $workdir/*_cacheinfo.lst > $cachelist
cat $workdir/*_noID_pnfs.lst > $noIDlist 2>/dev/null
cat $workdir/*_noreplicate_ID.lst > $norepllist 2>/dev/null
cat $workdir/*_noreplicate_pnfs.lst > $noreplpnfslist 2>/dev/null
echo "OK  (processed a total of $numfiles entries)"

num_noID=`wc -l $noIDlist|awk '{print $1}'`
if test $num_noID -gt 0; then
   echo "WARNING: $num_noID entries lack a corresponding ID!"
fi
num_norepl=`wc -l $norepllist|awk '{print $1}'`
if test $num_norepl -gt 0; then
   echo "WARNING: $num_norepl entries lack a replicate!"
fi

exit 0

