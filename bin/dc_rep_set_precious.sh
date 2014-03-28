#!/bin/bash

usage() {
    cat <<EOF
Synopsis:
          rep_set_precious.sh [-f] poolname listfile
Description:
          The listfile must contain a list of pnfsIDs to be set to status "precious"
          in the pool with name "poolname".
          the -f flag will run the commands with the -force flag
          appended
EOF
}

force=""
if test x"$1" = x-f; then
    force=" -force"
    shift
fi

poolname=$1
listfile=$2

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

if test x"$listfile" = x; then
    usage
    echo "Error: no listfile  given" >&2
    exit 1
fi
if test ! -r $listfile; then
    echo "Error: Cannot read list file: $listfile" >&2
    exit 1
fi

check_poolname $poolname
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolname" >&2
    exit 1
fi

cmdfile=`mktemp /tmp/rep_rm-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

echo "cd $poolname" >>$cmdfile
for n in `cat $listfile`;do
    echo "rep set precious $n$force" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

execute_cmdfile $cmdfile retfile
rm -f $cmdfile
cat $retfile
rm -f $retfile
