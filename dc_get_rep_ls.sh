#!/bin/bash
#################################################################
# get_rep_ls.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2007-08-27
#
# $Id:$
#################################################################

lopt=""
raw=""

usage(){
    cat <<EOF
Synopsis:
          get_rep_ls.sh [option] poolname
          get_rep_ls.sh [-r] poolname listfile
Description:
          lists files in a pool. If listfile is given, only the files whose pnfsIDs are
          found in the listfile will be returned.

          -r      : displays raw output
          -l str  : adds a format option -l=str to the "rep ls"-command    : 
EOF
}

TEMP=`getopt -o hl:r --long help -n 'get_rep_ls.sh' -- "$@"`
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
	    raw=1
	    shift
            ;;
        -l)
	    lopt=$2
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

if test ! -r $DCACHEUTILS/dc_utils_lib.sh; then
    echo "ERROR: Env Var DCACHEUTILS must point to directory containing dc_utils_lib.sh" >&2
    exit
fi
source $DCACHE_SHELLUTILS/dc_utils_lib.sh


poolname=$1
if test x"$2" != x; then
   if test ! -r "$2"; then
      echo "Error: Cannot read ID list: $2"
      exit 1
   fi
   if test x"$lopt" != x; then
       echo "Error: cannot use -l flag together with an ID list file"
       exit 1
   fi
   idlist=$2
fi

if test x"$poolname" = x; then
   echo "Error: you need to provide a pool name" >&2
   exit 1
fi
check_poolname $poolname
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolname" >&2
    exit 1
fi


#outfile=reperrors-$poolname-`date +%Y%m%d`.lst
cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

option=" -l=$lopt"
if test x"$idlist" = x; then
   cat > $cmdfile <<EOF
cd $poolname
rep ls$option
..
logoff
EOF
else
   echo "cd $poolname" >> $cmdfile
   for n in `cat $idlist`; do
      echo "rep ls $n" >> $cmdfile
   done
   echo ".." >> $cmdfile
   echo "logoff" >> $cmdfile
fi

execute_cmdfile -f $cmdfile retfile
rm -f $cmdfile

if test x"$raw" != x1; then
    sed -i -ne 's/^\(0[0-9A-Z]*\).*/\1/p' $retfile
fi

cat $retfile
rm -f $retfile
