#!/bin/bash

#################################################################
# dc_set_max_movers
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2008-03-04
#
# $Id$
#################################################################

usage() {
    cat <<EOF
Synopsis:
          dc_set_max_movers value listfile [queuename]
Description:
          Sets the maximum number of active client transfers to
          "value" on all pools found in the list file. Only sets the
          value for the particular queue if queuename is given.  The
          listfile must contain a list of poolnames
EOF
}


value=$1
listfile=$2
queue=$3

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

option=""
if test x"$queue" != x; then
    option=" -queue=$queue"
fi

cmdfile=`mktemp /tmp/rep_rm-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

for n in `cat $listfile`;do
    echo ".." >>$cmdfile
    echo "cd $n" >>$cmdfile
    echo "mover set max active ${value}${option}" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

execute_cmdfile $cmdfile retfile
rm -f $cmdfile
cat $retfile
rm -f $retfile
