#!/bin/bash
#################################################################
# dc_get_poollist.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
# $Id$
#################################################################

myname=$(basename $0)

# DEFAULTS
condition=""
raw=0
############

usage(){
    cat <<EOF
Synopsis:
          $myname

Description:
          lists all pools

          -r           : displays raw,long output
          -o condition : only list pools with the given condition (simple text match done in
                         the raw pool list output. It's more correctly a filter)
                               -o ro   (short for rdOnly=True)
                               -o d    (short for mode=disabled)
          -d           : debug
EOF
}

##############################################################
TEMP=`getopt -o dro: --long help -n "$myname" -- "$@"`
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
            dbg=1
            shift
            ;;
        -r)
            raw=1
            shift
            ;;
        -o)
            condition="$2"
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

case "$condition" in
   ro)
      condition="rdOnly=true"
      ;;
    d)
      condition="mode=disabled"
      ;;
esac

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

toremove=""
cmdfile=`mktemp /tmp/${USER}-${myname}.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

cat > $cmdfile <<EOF
cd PoolManager
psu ls pool -l
..
logoff
EOF

toremove="$toremove $cmdfile"

execute_cmdfile -f $cmdfile retfile
toremove="$toremove $retfile"

if test x"$dbg" = x1; then
   cat $cmdfile
   echo "---------------------"
   cat $retfile
   echo "--------------------"
fi

if test x"$condition" != x; then
   sed -i -ne "/$condition/p" $retfile
fi

if test $raw -eq 0 ; then
   #sed -i -e '/(.*)/d' -e '/^ *$/d' $retfile
   sed -i -ne 's/^\([^ ]*\).*enabled.*/\1/p' $retfile
fi
cat $retfile

rm -f $toremove

