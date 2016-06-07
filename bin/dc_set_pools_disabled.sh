#!/bin/bash

usage() {
    cat <<EOF
Synopsis:
          dc_set_pools_disabled [-n] listfile
Description:
          The listfile must contain a list of poolnames.
          If you specify the -n flag, all pools will be set to enabled
EOF
}

option="disable"
if test x"$1" = x-n; then
    option="enable"
    shift
fi

listfile=$1

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

cmdfile=`mktemp /tmp/rep_rm-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

for n in `cat $listfile`;do
    echo "\c $n" >>$cmdfile
    echo "pool $option" >>$cmdfile
done
echo "\q" >>$cmdfile


execute_cmdfile $cmdfile retfile
rm -f $cmdfile
cat $retfile
rm -f $retfile
