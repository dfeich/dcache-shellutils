#!/bin/bash

usage() {
    cat <<EOF
Synopsis:
          rep_rm_list.sh [-f] poolname listfile
Description:
          The listfile must contain a list of pnfsIDs ro remove from the
          pool with name "poolname".
          the -f flag will run the "rep rm" commands with the -force flag
          appended
          If listfile is omitted, the input will be read from stdin
EOF
}

if test x"$1" = x-h; then
   usage
   exit 0
fi

force=""
if test x"$1" = x-f; then
    force=" -force"
    shift
fi

poolname=$1
listfile=$2

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

toremove=""
if test x"$listfile" = x; then
   listfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
   while read line; do
      echo "$line" >> $listfile
   done
   toremove="$toremove $listfile"
fi
if test ! -r $listfile; then
    echo "Error: Cannot read list file: $listfile" >&2
    exit 1
fi

check_poolname $poolname
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolname" >&2
    rm -f $toremove
    exit 1
fi

cmdfile=`mktemp /tmp/rep_rm-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi
toremove="$toremove $cmdfile"

echo "cd $poolname" >>$cmdfile
for n in `cat $listfile`;do
    echo "rep rm $n$force" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

execute_cmdfile $cmdfile retfile
toremove="$toremove $retfile"

cat $retfile
rm -f $toremove
