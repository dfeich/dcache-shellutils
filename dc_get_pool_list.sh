#!/bin/bash
#################################################################
# dc_get_poollist.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
# $Id$
#################################################################

usage(){
    cat <<EOF
Synopsis:
          dc_get_pool_list [-l]

Description:
          lists all pools

          -l      : displays raw,long output
          -d      : debug
EOF
}

if test x"$1" = x-l ; then
    opt=" $1"
    shift
fi

if test x"$1" = x-d; then
    dbg=1
    shift
fi

if test x"$1" != x; then
    usage
    exit 0
fi


source $DCACHE_SHELLUTILS/dc_utils_lib.sh

cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
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

execute_cmdfile -f $cmdfile retfile
if test x"$dbg" = x1; then
   cat $cmdfile
   echo "---------------------"
   cat $retfile
   echo "--------------------"
fi

rm -f $cmdfile


if test x"$opt" = x; then
   #sed -i -e '/(.*)/d' -e '/^ *$/d' $retfile
   sed -nie 's/^\([^ ]*\).*enabled.*/\1/p' $retfile
fi

cat $retfile
rm -f $retfile

