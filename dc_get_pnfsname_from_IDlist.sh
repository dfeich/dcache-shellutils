#!/bin/bash

usage() {
    cat <<EOF
Synopsis:
          get_pnfsname_from_IDlist.sh listfile
Description:
          The listfile must contain a list of pnfsIDs for which
          pnfs filenames will be produced and written to file $outfile
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
    echo "pathfinder $n" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

execute_cmdfile -f $cmdfile resfile
rm -f $cmdfile

sed -i -ne '/\/pnfs\/\|pathfinder 0/p' $resfile
sed -i -e 's/.*pathfinder *\(0[0-9A-Z]*\)/\1/' $resfile

# collect id and pnfs filename pairs
state=id
while read line
do
  a=$(expr "$line" : '00[0-9A-Z]*')
  if test 0$a -gt 0; then
      if test $state = pnfs; then
	  echo "$id Error:Missing"
      fi
      id=$line
      state=pnfs
  elif test $state = pnfs; then
      echo "$id $line"
      state=id
  else
      echo "ERROR:state=$state   line=$line" >&2
      exit
  fi
done < $resfile
# print the last incomplete entry
if test $state = pnfs; then
    echo "$id Error:Missing"
fi

rm -f $resfile
