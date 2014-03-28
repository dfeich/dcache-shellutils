#!/bin/bash
#################################################################
# dc_get_active_transfers.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
#################################################################

debug=0

usage(){
    cat <<EOF
Synopsis: 
      dc_get_active_transfers.sh

Options:

Description:
      Shows all active transfers seen by the TransferObserver

EOF
}

##############################################################
TEMP=`getopt -o dh --long help -n 'dc_get_active_transfers.sh' -- "$@"`
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

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

toremove="$toremove $resfile"

cmdfile=`mktemp /tmp/dc_utils-gpm-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi
cat >> $cmdfile <<EOF
cd TransferObserver
ls iolist
..
logoff
EOF
if test x"$debug" = x1; then
    cat $cmdfile >&2
fi

# resfile=`mktemp /tmp/dc_utils-gpmr-$USER.XXXXXXXX`
# if test $? -ne 0; then
#     echo "Error: Could not create a temporary result file" >&2
#     exit 1
# fi

toremove="$toremove $resfile"

execute_cmdfile -f $cmdfile resfile

# clean up starter and end lines
sed -i -e '/^\[.*\]/d' -e '/^ *dCache Admin.*/d' -e '/^ *$/d' -e '/^ *\r *$/d' $resfile
cat $resfile

rm -f $toremove

