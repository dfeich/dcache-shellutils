#!/bin/bash

usage() {
    cat <<EOF
Synopsis:
          get_cacheinfo_from_IDlist.sh listfile
Description:
          The listfile must contain a list of pnfsIDs for which
          pnfs filenames will be produced
EOF
}

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

cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

echo "cd PnfsManager" >>$cmdfile
for n in `cat $listfile`;do
    echo "cacheinfoof $n" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

execute_cmdfile -f $cmdfile resfile
rm -f $cmdfile


#sed -i -ne '/\/pnfs\/\|pathfinder 0/p' $resfile
sed -i -e 's/.*cacheinfoof *\(0[0-9A-Z]*\)/\1/' -e 's/^ *//' $resfile


# collect id and poolnames on single lines
state=id
cat $resfile|while read line
do
if test $state = id; then
    a=$(expr "$line" : '00[0-9A-Z]*')
    if test 0$a -gt 0; then
	id=$line
	state=poolnames
    fi
elif test $state = poolnames; then
    line=$(echo $line|sed -e 's/ /,/g')
    echo "$id $line"
    state=id
fi
done

rm -f $resfile
