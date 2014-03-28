#!/bin/bash

#################################################################
# dc_set_max_movers
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2008-03-04
#
# $Id$
#################################################################

myname=$(basename $0)

usage() {
    cat <<EOF
Synopsis:
          $myname listfile [-q queuename] value
Description:
          Sets the maximum number of active client transfers to
          "value" on all pools found in the list file. Only sets the
          value for the particular queue if queuename is given.  The
          listfile must contain a list of poolnames

Examples:
          dc_set_max_movers.sh mylistfile -q default 100
          echo t3fs07_cms | dc_set_max_movers.sh -q default 101


EOF
}

flag_dbg=0

##############################################################
TEMP=`getopt -o dq: --long help -n "$myname" -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        -d)
            flag_dbg=1
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

echo $#
if test $# -ge 2; then
   listfile=$1
   value=$2
else
   value=$1
fi

source $DCACHE_SHELLUTILS/dc_utils_lib.sh


toremove=""
if test x"$listfile" = x; then
   listfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
   while read line; do
      echo "$line" >> $listfile
   done
   toremove="$toremove $listfile"
fi
if test ! -r $listfile; then
    echo "Error: Cannot read list file: $listfile" >&2
    exit 1
fi

option=""
if test x"$queue" != x; then
    option=" -queue=$queue"
fi

cmdfile=`mktemp /tmp/rep_rm-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi
toremove="$toremove $cmdfile"

for n in `cat $listfile`;do
    echo ".." >>$cmdfile
    echo "cd $n" >>$cmdfile
    echo "mover set max active ${value}${option}" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

if test $flag_dbg -ne 1; then
   force="-f"
fi
execute_cmdfile $force $cmdfile retfile
cat $retfile

rm -f $toremove