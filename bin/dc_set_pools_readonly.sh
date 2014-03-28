#!/bin/bash
#################################################################
# dc_set_pools_readonly
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
# $Id$
#################################################################

myname=$(basename $0)

# DEFAULTS ####
option="rdonly"
force=""
###############

usage() {
    cat <<EOF
Synopsis:
          $myname [options] [listfile]
Description:
          Sets pools into readonly mode or back from readonly mode by changing
          the PoolManager configuration (so, this affects only the routing of
          requests).
          The listfile must contain a list of poolnames. If no listfile is given
          input is expected on stdin.

Options:
          -n      :  reverse the logic and set the pools to (n)ot readonly
          -f      :  force. Do not prompt before actual execution of the admin shell script
                     (optional, but needed if you redirect from stdin)

EOF
}


##############################################################
TEMP=`getopt -o hfn --long help -n "$myname" -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        -f)
            force="-f"
            shift
            ;;
        -n)
            option="notrdonly"
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

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

for p in $(cat $listfile); do
   check_poolname $p
   if test $? -ne 0; then
       echo "Error: No such pool: $p" >&2
       exit 1
   fi
done



cmdfile=`mktemp /tmp/rep_rm-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

echo "cd PoolManager" >>$cmdfile
for n in `cat $listfile`;do
    echo "psu set pool $n $option" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile
toremove="$toremove $cmdfile"

execute_cmdfile $force $cmdfile retfile
toremove="$toremove $retfile"

cat $retfile
rm -f $toremove
