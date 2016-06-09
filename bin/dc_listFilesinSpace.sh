#!/bin/bash

#################################################################
# dc_listFilesinSpace.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2008-03-04
#
# $Id$
#################################################################

myname=$(basename $0)

usage() {
    cat <<EOF
Synopsis:
          $myname spaceTokenID
Description:
          Calls the SrmSpaceManager's listFilesInSpace command on the given
          spaceTokenID
EOF
}

stID=$1


source $DCACHE_SHELLUTILS/dc_utils_lib.sh
if test x"$1" = x-h; then
   usage
   exit 0
fi

toremove=""
if test x"$stID" = x; then
    echo "Error: Need to specify a space token ID" >&2
    exit 1
fi

cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi

echo "\c SrmSpaceManager"     >>$cmdfile
echo "listFilesInSpace $stID" >>$cmdfile
echo "\q"                     >>$cmdfile

toremove="$toremove $cmdfile"
execute_cmdfile -f $cmdfile resfile

#sed -i -ne '/\/pnfs\/\|pathfinder 0/p' $resfile
#sed -i -e 's/.*pathfinder *\(0[0-9A-Z]*\)/\1/' $resfile

sed -i -ne '/^[0-9][0-9]*/p' $resfile
cat $resfile
toremove="$toremove $resfile"


rm -f $toremove

