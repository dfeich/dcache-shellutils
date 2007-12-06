#!/bin/bash

usage() {
    cat <<EOF
Synopsis:
          get_ID_from_pnfsnamelist.sh listfile
Description:
          The listfile must contain a list of pnfs filenames for which
          pnfsIDs will be produced
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
    echo "pnfsidof $n" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

execute_cmdfile -f $cmdfile resfile
rm -f $cmdfile

sed -i -ne '/^0[0-9A-Z]*\|pnfsidof/p' $resfile
sed -i -e 's/.*pnfsidof *\(\/pnfs\/[^ ]*\)/\1/' $resfile

# collect id and pnfs filename pairs
state=pnfs
while read line
do
  #a=$(expr "$line" : '00[0-9A-Z]*')
  a=$(expr "$line" : '\/pnfs\/')
  if test 0$a -gt 0; then
      if test $state = id; then
	  echo "Error:Missing $name"
      fi
      name=$line
      state=id
  elif test $state = id; then
      echo "$line $name"
      state=pnfs
  else
      echo "ERROR:state=$state   line=$line" >&2
      exit
  fi
done < $resfile
# print the last incomplete entry
if test $state = id; then
    echo "Error:Missing $name"
fi

rm -f $resfile
