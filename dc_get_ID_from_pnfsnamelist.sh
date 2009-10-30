#!/bin/bash
#################################################################
# dc_get_ID_from_pnfsnamelist.sh
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
          The listfile must contain a list of pnfs filenames for which
          pnfsIDs will be produced
          If listfile is omitted, the input will be read from stdin
EOF
}

if test x"$1" = x-h; then
   usage;
   exit 0
fi

listfile=$1



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

cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi

echo "cd PnfsManager" >>$cmdfile
for n in `cat $listfile`;do
    echo "pnfsidof $n" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile
toremove="$toremove $cmdfile"

execute_cmdfile -f $cmdfile resfile

sed -i -ne '/^0[0-9A-Z]*\|pnfsidof/p' $resfile
#sed -i -e 's/.*pnfsidof *\(\/pnfs\/[^ ]*\)/\1/' $resfile
toremove="$toremove $resfile"

# collect id and pnfs filename pairs
state=pnfs
while read line
do
  a=$(expr "$line" : '.*admin  *>  *pnfsidof  *\(.*\)')
  if test x"$a" != x; then
      if test $state = id; then
	  echo "Error:Missing $name"
      fi
      name=$a
      state=id
  elif test $state = id; then
      findfail=$(expr "$line" : '.*pnfsidof failed.*not found')
      if test 0$findfail -gt 0; then
         line="Error:Missing"
      fi
      echo "$line $name"
      state=pnfs
  else
      echo "ERROR:state=$state  namematch=$a  line=$line" >&2
      rm -f $toremove
      exit
  fi
done < $resfile
# print the last incomplete entry
if test $state = id; then
    echo "Error:Missing $name"
fi

rm -f $toremove
