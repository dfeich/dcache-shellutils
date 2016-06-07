#!/bin/bash
#################################################################
# dc_get_pinboard.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
# $Id$
#################################################################

myname=$(basename $0)

# DEFAULTS
#
##########

usage(){
    cat <<EOF
Synopsis: 
      $myname [options] cellname
Options:
         -n                    :  number of pinboard lines to show

Description:
      The pinboard is the log that cells keep. Not every cell has a pinboard.
      The most useful ones are (some names may differ on different dcache 
      installations):
           gPlazma
           PnfsManager
           PinManager
           SRM-storage01
           SrmSpaceManager
           Door cells: e.g. GFTP-se07, DCap-se22
           Pool Cells
           billing

Example:
      dc_get_pinboard.sh -n 100 gPlazma

EOF
}

##############################################################
TEMP=`getopt -o hn: --long help -n "$myname" -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        -n)
            numopt=" $2"
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

cell=$1
shift


if test x"$cell" = x ; then
    echo "Error: Need a Cell name" >&2
    exit 1
fi

toremove=""

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

cmdfile=`mktemp /tmp/dc_generic-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

cat > $cmdfile <<EOF
\c $cell 
show pinboard ${numopt}
\q
EOF
toremove="$toremove $cmdfile"

execute_cmdfile -f $cmdfile resfile
toremove="$toremove $resfile"

cat $resfile

rm -f $toremove
