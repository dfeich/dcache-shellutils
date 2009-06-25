#!/bin/bash

#################################################################
# dc_ppcopy_files.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2008-03-04
#
# $Id$
#################################################################

myname=$(basename $0)

usage() {
cat <<EOF
Synopsis:
          $myname src-pool dest-pool ID-listfile

Options:
         -f          : force. Do not query before executing the admin shell commands
                       (optional, but needed if you redirect from stdin)
         -h/--help   : this help text

Description:
          Copies files from the src-pool to the dest-pool. The files are given
          through a list of pnfsIDs in ID-listfile. The files will end up as
          "cached" copies of the original files, and you may have to make
          them precious or pinned, if they should persist.

          If no ID-listfile is given, input is expected on stdin
EOF
}


##############################################################
TEMP=`getopt -o dfhp:r: --long help -n "$myname" -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit 0
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


poolnameSRC=$1
poolnameDST=$2
listfile=$3

if test x"$listfile" = x;then
   listfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
   while read line; do
      echo "$line" >> $listfile
   done
   toremove="$toremove $listfile"
fi

if test ! -r "$listfile"; then
      usage
      echo "Error: Cannot read ID list: $listfile" >&2
      exit 1
fi

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

check_poolname $poolnameSRC
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolnameSRC" >&2
    exit 1
fi
check_poolname $poolnameDST
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolnameDST" >&2
    exit 1
fi


cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
toremove="$toremove $cmdfile"
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi

echo "cd $poolnameDST" >> $cmdfile
for n in `cat $listfile| cut -f1 -d " "`; do
    echo "pp get file $n $poolnameSRC" >> $cmdfile
done
echo ".." >> $cmdfile
echo "logoff" >> $cmdfile

execute_cmdfile $force $cmdfile retfile
toremove="$toremove $retfile"

cat $retfile

rm -f $toremove
