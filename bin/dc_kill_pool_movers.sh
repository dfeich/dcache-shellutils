#!/bin/bash
#################################################################
# dc_get_pool_movers.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
# $Id$
# $URL:$
#################################################################

debug=0
beautify=0

usage(){
    cat <<EOF
Synopsis: 
      dc_kill_pool_movers.sh [options] listfile
Options:
      -f       :   force. Do not prompt for execution

Description:
      Kills the movers on the respective pool cells. The listfile must contain
      two columns of data with "poolname moverID" pairs:

          t3fs08_cms   13761
          t3fs08_cms_1 13701
          t3fs09_cms_1 13771

Examples:
EOF
}

##############################################################
TEMP=`getopt -o fd: --long help -n 'dc_replicate_IDlist.sh' -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        -d)
            debug=1
            shift
            ;;
        -f)
            force="-f"
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

#cat $listfile
cmdfile=`mktemp /tmp/dc_utils-gpm-$USER.XXXXXXXX`
toremove="$toremove $cmdfile"
while read pool moverid crap; do
   if test $? -ne 0; then
       echo "Error: Could not create a cmdfile" >&2
       exit 1
   fi
   cat >> $cmdfile <<EOF
\c $pool
mover kill $moverid
EOF
done < $listfile

echo "\q" >>$cmdfile


#cat $cmdfile
execute_cmdfile $force $cmdfile resfile
toremove="$toremove $resfile"
cat $resfile

rm -f $toremove

