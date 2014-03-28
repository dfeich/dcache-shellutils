#!/bin/bash
#################################################################
# dc_get_pnfsname_from_IDlist.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
# $Id$
#################################################################

myname=$(basename $0)

usage() {
    cat <<EOF
Synopsis:
          $myname listfile
Description:
          The listfile must contain a list of pnfsIDs for which
          pnfs filenames will be produced and written to file $outfile
          If listfile is omitted, the input will be read from stdin
EOF
}

listfile=$1


source $DCACHE_SHELLUTILS/dc_utils_lib.sh
if test x"$1" = x-h; then
   usage
   exit 0
fi

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

cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi

echo "cd PnfsManager" >>$cmdfile
for n in `cat $listfile| cut -f1 -d " "`;do
    echo "pathfinder $n" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

toremove="$toremove $cmdfile"
execute_cmdfile -f $cmdfile resfile

sed -i -ne '/\/pnfs\/\|pathfinder 0/p' $resfile
sed -i -e 's/.*pathfinder *\(0[0-9A-Z]*\)/\1/' $resfile
toremove="$toremove $resfile"

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
      rm -f $toremove
      exit
  fi
done < $resfile
# print the last incomplete entry
if test $state = pnfs; then
    echo "$id Error:Missing"
fi

rm -f $toremove
