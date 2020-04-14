#!/bin/bash

#################################################################
# dc_get_cells.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2020-04-14
#
#################################################################

myname=$(basename $0)
domain="System@dCacheDomain"
filter=""
mode="route"

usage() {
cat <<EOF
Synopsis:
          $myname

Options:
         -f          : filter for cell names
         -h/--help   : this help text

Description:
	 Shows the well defined cells
         (corresponds to \l command in admin shell)
EOF
}


##############################################################
TEMP=`getopt -o f:h --long help -n "$myname" -- "$@"`
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
            filter=$2
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

source $DCACHE_SHELLUTILS/dc_utils_lib.sh


cmdfile=`mktemp /tmp/get_cells-$USER.XXXXXXXX`
toremove="$toremove $cmdfile"
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi

echo "\l $filter" >> $cmdfile
echo "\q" >> $cmdfile

execute_cmdfile -f $cmdfile retfile
toremove="$toremove $retfile"

cat $retfile |  sed '/^[[:space:]]*$/d'

rm -f $toremove
