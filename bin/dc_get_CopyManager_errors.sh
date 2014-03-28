#!/bin/bash

if test x"$1" = x-r; then
    raw=1
    shift
fi
copyname=$1

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

if test x"$copyname" = x; then
   echo "Error: you need to provide a copy manager name" >&2
   exit 1
fi


cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi
cat > $cmdfile <<EOF
cd $copyname
ls -e
..
logoff
EOF

execute_cmdfile -f $cmdfile retfile
rm -f $cmdfile

if test x"$raw" != x1; then
    sed -i -ne 's/^\(0[0-9A-Z]*\).*/\1/p' $retfile
fi

cat $retfile
rm -f $retfile
