#!/bin/bash

#################################################################
# dc_get_storageinfo_from_IDlist.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2007-08-26
#
# $Id$
#################################################################

myname=$(basename $0)
flag_raw=0

usage() {
    cat <<EOF
Synopsis:
          $myname listfile
Description:
          The listfile must contain either a list of pnfsIDs or pnfsNAMEs for which
          the storage info entries will be retrieved. If listfile is omitted, the input will be read from stdin

EOF
}

source $DCACHE_SHELLUTILS/dc_utils_lib.sh
if test x"$1" = x-h; then
   usage
   exit 0
fi

if test x"$1" = x-r; then
   flag_raw=1
   shift
   echo $@
fi

listfile=$1

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

echo "\c PnfsManager" >>$cmdfile
for n in `cat $listfile | cut -f1 -d " "`;do
    echo "storageinfoof $n" >>$cmdfile
done
echo "\q" >>$cmdfile

toremove="$toremove $cmdfile"

execute_cmdfile -f $cmdfile resfile
toremove="$toremove $resfile"

sed -i -e 's/.*storageinfoof *\(0[0-9A-Z]*\)/\1/' -e 's/^ *//' $resfile

if test $flag_raw -eq 1; then
   cat $resfile >&2
   #rm -f $toremove
   #exit 0
fi

# remove empty lines
sed '/^\s*$/d' -i $resfile

paste $listfile $resfile | awk {' print$1,$2}'
# # collect id and info on single lines
# state=id
# cat $resfile|while read line
# do
#    if test $state = id; then
#       a=$(expr "$line" : '00[0-9A-Z]*')
#       if test 0$a -gt 0; then
# 	 id=$line
# 	 state=storageinfo
#       fi
#    elif test $state = storageinfo; then
#       #line=$(echo $line|sed -e 's/ /,/g')
#       a=$(expr "$line" : '.*storageinfoof failed : path .* not found')
#       if test 0$a -gt 0; then
#          line="Error:Missing"
#       fi
#       echo "$id $line"
#       state=id
#    fi
# done

rm -f $toremove
