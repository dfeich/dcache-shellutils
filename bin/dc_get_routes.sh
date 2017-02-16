#!/bin/bash

#################################################################
# dc_get_routes.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2008-03-04
#
# $Id$
#################################################################

myname=$(basename $0)
domain="System@dCacheDomain"
mode="route"

usage() {
cat <<EOF
Synopsis:
          $myname

Options:
         -d          : cell domain name [$domain]
         -p          : display "ps -f" cell list instead of routes
         -h/--help   : this help text

Description:
          By default, this command will show all the defined routes of
          a domain (obtained by running "route" in the domain).
          If the -p flag is specified, the output of "ps -ef" is used
          instead

EOF
}


##############################################################
TEMP=`getopt -o d:hp --long help -n "$myname" -- "$@"`
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
            domain=$2
            shift 2
            ;;
       -p)
            mode="ps"
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


cmdfile=`mktemp /tmp/get_route-$USER.XXXXXXXX`
toremove="$toremove $cmdfile"
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi

echo "\c $domain" >> $cmdfile
if test x"$mode" = xps; then
   echo "ps -f" >> $cmdfile
else
   echo "route" >> $cmdfile
fi
echo "\q" >> $cmdfile

execute_cmdfile -f $cmdfile retfile
toremove="$toremove $retfile"

cat $retfile
echo

rm -f $toremove
