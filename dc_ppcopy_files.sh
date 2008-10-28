#!/bin/bash

#################################################################
# dc_ppcopy_files.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2008-03-04
#
# $Id$
#################################################################

poolnameSRC=$1
poolnameDST=$2
idlist=$3

usage() {
cat <<EOF
Synopsis:
          dc_ppcopy_files.sh src-pool dest-pool ID-listfile
Description:
          Copies files from the src-pool to the dest-pool. The files are given
          through a list of pnfsIDs in ID-listfile
EOF
}

if test x"$idlist" = x;then
    usage
    echo "Error: No ID list given" >&2
    exit 1
fi
if test ! -r "$idlist"; then
      echo "Error: Cannot read ID list: $idlist" >&2
      exit 1
fi

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

check_poolname $poolnameSRC
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolnameSRC" >&2
    exit 1
fi
check_poolname $poolnameDST
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolnameDST" >&2
    exit 1
fi


cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

echo "cd $poolnameDST" >> $cmdfile
for n in `cat $idlist| cut -f1 -d " "`; do
    echo "pp get file $n $poolnameSRC" >> $cmdfile
done
echo ".." >> $cmdfile
echo "logoff" >> $cmdfile

execute_cmdfile $cmdfile retfile
rm -f $cmdfile

cat $retfile
rm -f $retfile
