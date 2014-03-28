#!/bin/bash
#################################################################
# dc_get_pending_requests.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
# $Id$
#################################################################

myname=$(basename $0)

usage() {
    cat <<EOF
Synopsis: 
          $myname - gets pending (hanging) requests

Description:
          This produces the output of the PoolManager's "rc ls" command
EOF
}

if test x"$1" = x-h; then
   usage
   exit 0
fi

if test x"$1" = x-l -o x"$1" = x-a; then
    opt=" $1"
    shift
fi

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

cmdfile=`mktemp /tmp/${USER}-dc_tools.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

cat > $cmdfile <<EOF
cd PoolManager
rc ls
..
logoff
EOF

execute_cmdfile -f $cmdfile retfile
rm -f $cmdfile

if test x"$opt" = x; then
   #sed -i -e '/(.*) admin/d' -e '/^ *$/d' $retfile
   sed -i -e '/(.*) admin/d' -e '/^ *$/d' -e '/Admin/d' -e '/^dmg/d' $retfile
fi

cat $retfile
rm -f $retfile

