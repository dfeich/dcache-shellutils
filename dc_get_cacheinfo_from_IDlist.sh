#!/bin/bash
#################################################################
# dc_get_cacheinfo_from_IDlist.sh
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
          pnfs filenames will be produced
          If listfile is omitted, the input will be read from stdin

EOF
}

listfile=$1



source $DCACHE_SHELLUTILS/dc_utils_lib.sh
if test x"$1" = x-h; then
   usage
   exit 0
fi

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
for n in `cat $listfile|cut -f1 -d " "`;do
    echo "cacheinfoof $n" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile
toremove="$toremove $cmdfile"

execute_cmdfile -f $cmdfile resfile
toremove="$toremove $resfile"

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
	 state=poolname
      fi
   elif test $state = poolname; then
      line=$(echo $line|sed -e 's/ /,/g')
      echo "$id $line"
      state=id
   fi
done

rm -f $toremove
