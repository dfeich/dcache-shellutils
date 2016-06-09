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
          $myname "cert-DN" "VOMS_FQAN1,... ,VOMS_FQANX"

Options:
         -h/--help   : this help text

Description:
          Outputs the gPlazma mapping of the cert/voms info to a local
          dcache user

Example:
   dc_get_usermapping.sh someDN   "/ops,/ops/NGI,/ops/NGI/Germany"

      someDN/ops mapped as: opsuser 800 [800] /
      someDN/ops/NGI mapped as: null
      someDN/ops/NGI/Germany mapped as: opsuser 800 [800] /

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

if test x"$1" == x -o x"$2" == x; then
   echo "Error: need two arguments" >&2
   usage
   exit 1
fi
certdn=$1
vomsfqan=$2


source $DCACHE_SHELLUTILS/dc_utils_lib.sh


cmdfile=`mktemp /tmp/get_usermapping-$USER.XXXXXXXX`
toremove="$toremove $cmdfile"
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi

# [t3dcachedb03] (gPlazma@t3dcachedb03-Domain-gPlazma) admin > test login dn:"/DC=EU/DC=EGI/C=CH/O=People/O=Paul-Scherrer-Institut (PSI)/CN=Fabio Martinelli" fqan:"/cms/"
# Login[martinelli_f,2980:[500],[HomeDirectory[/], RootDirectory[/]]]

cat > $cmdfile <<EOF
\c gPlazma
test login dn:"${certdn}" fqan:"${vomsfqan}"
\q
EOF

execute_cmdfile -f $cmdfile retfile
toremove="$toremove $retfile"

egrep -i login $retfile

rm -f $toremove
