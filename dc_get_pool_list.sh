#!/bin/bash

if test x"$1" = x-l -o x"$1" = x-a; then
    opt=" $1"
    shift
fi

if test x"$1" = x-d; then
    dbg=1
    shift
fi

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

cat > $cmdfile <<EOF
cd PoolManager
psu ls pool$opt
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
   sed -i -e '/(.*)/d' -e '/^ *$/d' $retfile
fi

cat $retfile
rm -f $retfile

