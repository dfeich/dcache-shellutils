#!/bin/bash

cell=$1
shift

listfile=$1
shift

command=$@

if test x"$cell" = x ; then
    echo "Error: Need a Cell name" >&2
    exit 1
fi
if test x"$listfile" = x ; then
    echo "Error: Need a list file name" >&2
    exit 1
fi


source $DCACHE_SHELLUTILS/dc_utils_lib.sh

cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

echo "cd $cell" > $cmdfile
for n in `cat $listfile`; do
    echo "$command $n" >> $cmdfile
done

cat >> $cmdfile <<EOF
..
logoff
EOF


execute_cmdfile $cmdfile retfile
rm -f $cmdfile

#if test x"$opt" = x; then
#   sed -i -e '/(.*)/d' -e '/^ *$/d' $retfile
#fi

cat $retfile
rm -f $retfile

