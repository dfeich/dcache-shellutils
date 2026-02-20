#!/bin/bash

#################################################################
# dc_get_routes.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2008-03-04
#
# $Id$
#################################################################

myname=$(basename $0)
domain="dCacheDomain"
mode="route"

usage() {
cat <<EOF
Synopsis:
          $myname "cert-DN" ["VOMS_FQAN1,... ,VOMS_FQANX"]

Options:
         -h/--help   : this help text

Description:
          Outputs the gPlazma explanation and mapping of the cert/voms
          info to the internal dCache user and the final system user.
          Based on admin shells "explain login" command.

Example:
   dc_get_usermapping.sh someDN  "/cms"
   dc_get_usermapping.sh someDN 

EOF
}


##############################################################
TEMP=`getopt -o h --long help -n "$myname" -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit 0
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

if test x"$1" == x ; then
    echo "Error: need at least one argument" >&2
    usage
    exit 1
fi
certdn=$1
vomsfqan=$2

arg_str=" dn:\"${certdn}\""
[ -n "$vomsfqan" ] && arg_str="${arg_str} fqan:\"${vomsfqan}\""

source $DCACHE_SHELLUTILS/dc_utils_lib.sh


cmdfile=`mktemp /tmp/get_usermapping-$USER.XXXXXXXX`
toremove="$toremove $cmdfile"
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi

cat > $cmdfile <<EOF
\c gPlazma
explain login $arg_str
\q
EOF

execute_cmdfile -f $cmdfile retfile
toremove="$toremove $retfile"

# egrep -i login $retfile
cat $retfile

rm -f $toremove
