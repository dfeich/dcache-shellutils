#!/bin/bash

usage() {
    cat <<EOF
Synopsis:
          set_precious.sh poolname IDlistfile
Description:
          The files in the IDlist will be set to precious in the given pool
EOF
}

poolname=$1
listfile=$2



source $DCACHE_SHELLUTILS/dc_utils_lib.sh

if test x"$poolname" = x; then
    usage
    echo "Error: no poolname given" >&2
    exit 1
fi
check_poolname $poolname
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolname" >&2
    exit 1
fi

if test x"$listfile" = x; then
    usage
    echo "Error: no listfile  given" >&2
    exit 1
fi
if test ! -r $listfile; then
    echo "Error: Cannot read list file: $listfile" >&2
    exit 1
fi

cmdfile=`mktemp /tmp/set_precious-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

echo "cd $poolname" >>$cmdfile
for n in `cat $listfile`;do
    echo "rep set precious $n -force" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

execute_cmdfile -f $cmdfile resfile
rm -f $cmdfile
#cat $resfile
rm -f $resfile
