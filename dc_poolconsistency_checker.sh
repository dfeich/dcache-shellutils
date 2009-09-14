#!/bin/bash
#################################################################
# dc_poolconsistency_checker.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2007-12-20
#
# $Id$
#################################################################

dbg=1

usage() {
    cat <<EOF
Synopsis: dc_poolconsistency_checker.sh poolname

Description:
          This tool will check a pool for files with error states and
          will locate files with missing pnfs entries
          The result files will be saved to a subdirectory named
          consistency-\${poolname}-\${DATE}
EOF
}


TEMP=`getopt -o h --long help -n 'dc_poolconsistency_checker.sh' -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
#        -r)
#	    raw=1
#	    shift
#            ;;
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

poolname=$1

if test ! -r $DCACHE_SHELLUTILS/dc_utils_lib.sh; then
    echo "ERROR: Env Var DCACHE_SHELLUTILS must point to directory containing dc_utils_lib.sh" >&2
    exit
fi
source $DCACHE_SHELLUTILS/dc_utils_lib.sh

check_poolname $poolname
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolname" >&2
    exit 1
fi



DATE=`date +%Y%m%d-%H%M`

resdir=consistency-${poolname}-${DATE}
mkdir $resdir
if test $? -ne 0; then
   echo "failed to create results directory $resdir" >&2
   exit 1
fi

errlist=$resdir/${poolname}-errors.lst
echo -n "Getting pool errors..."
$DCACHE_SHELLUTILS/dc_get_rep_ls-errors.sh $poolname > $errlist
if test $? -ne 0; then
   echo "failed"
   exit 1
fi
echo "OK ($errlist)"

idlist=$resdir/${poolname}-ID.lst
echo -n "Getting pool file IDs..."
starttimer
$DCACHE_SHELLUTILS/dc_get_rep_ls.sh $poolname >  $idlist
if test $? -ne 0; then
   echo "failed"
   exit 1
fi
t=`gettimer`
numfiles=`wc -l $idlist|awk '{print $1}'`
echo "OK ($idlist, $numfiles files took $t seconds)"

idpnfslist=$resdir/${poolname}-IDpnfs.lst
starttimer
echo -n "Mapping to pnfs names..."
$DCACHE_SHELLUTILS/dc_get_pnfsname_from_IDlist.sh $idlist > $idpnfslist
if test $? -ne 0; then
   echo "failed"
   exit 1
fi
t=`gettimer`
echo "OK ($idpnfslist, took $t seconds)"

missingPnfslist=$resdir/${poolname}-missingPnfs.lst
echo -n "Extracting ID's for files with missing pnfs entry..."
grep "Error:Missing" $idpnfslist |cut -f1 -d" " > $missingPnfslist
echo "OK ($missingPnfslist)"


