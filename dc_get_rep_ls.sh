#!/bin/bash
#################################################################
# get_rep_ls.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2007-08-27
#
# $Id$
#################################################################

myname=$(basename $0)

# DEFAULTS
lopt=""
raw=""
cachedonly=0
use_listfile=0


usage(){
    cat <<EOF
Synopsis:
          $myname [option] poolname [listfile]
Description:
          lists files in a pool.

          -r      : displays raw output
          -i      : only displays files found in the pnfsID list given by listfile
                    or via stdin.
                    if this option is given as -i- then will expect list on stdin
          -l str  : adds a format option -l=str to the admin shell's "rep ls"-command:     
                         s  : sticky files
                         p  : precious files
                         l  : locked files
                         u  : files in use
                         nc : files which are not cached
                         e  : files with error condition

          -c      : lists cached files only (own implementation)

EOF
}

TEMP=`getopt -o chil:r --long help -n "$myname" -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        -c)
            cachedonly=1
            shift
            ;;
        -i)
            use_listfile=1
            shift
            ;;
        -r)
	    raw=1
	    shift
            ;;
        -l)
	    lopt=$2
	    shift 2
            ;;
        --)
            shift;
            break;
            ;;
        *)
            echo "Internal error!"
            usage
            exit 1
            ;;
    esac
done

poolname=$1
listfile=$2

if test x"$lopt" != x -a  $cachedonly -ne 0; then
    usage
    echo "ERROR: Cannot specify both -c and -l options" >&2
    exit 1
fi

if test ! -r $DCACHE_SHELLUTILS/dc_utils_lib.sh; then
    echo "ERROR: Env Var DCACHE_SHELLUTILS must point to directory containing dc_utils_lib.sh" >&2
    exit
fi
source $DCACHE_SHELLUTILS/dc_utils_lib.sh



if test 0"$use_listfile" -ne 0;then
   if test x"$listfile" = x; then
       listfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
       while read line; do
	   echo "$line" >> $listfile
       done
       toremove="$toremove $listfile"

       if test ! -r "$listfile"; then
	   usage
	   echo "Error: Cannot read ID list: $2"
	   exit 1
       fi
       if test x"$lopt" != x; then
	   usage
	   echo "Error: cannot use -l flag together with an ID list file"
	   exit 1
       fi
   fi
fi

if test x"$poolname" = x; then
   usage
   echo "Error: you need to provide a pool name" >&2
   exit 1
fi
check_poolname $poolname
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolname" >&2
    exit 1
fi

toremove=""

cmdfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi
toremove="$toremove $cmdfile"

option=" -l=$lopt"
if test x"$listfile" = x; then
   cat > $cmdfile <<EOF
set timeout 120
cd $poolname
rep ls$option
..
logoff
EOF
else
   echo "cd $poolname" >> $cmdfile
   for n in `cat $listfile`; do
      echo "rep ls $n" >> $cmdfile
   done
   echo ".." >> $cmdfile
   echo "logoff" >> $cmdfile
fi

execute_cmdfile -f $cmdfile resfile
toremove="$toremove $resfile"

# Warning: I conclude that this is the definition of a cached file
#         <C-------X--(0)[0]>
# I have seen <--C-------L(0)[1]> too, but this file had no phys copy at all
if test $cachedonly -ne 0; then
    sed -i -ne '/<C----------.*>/p' $resfile
fi

if test x"$raw" != x1; then
    sed -i -ne 's/^\(0[0-9A-Z]*\).*/\1/p' $resfile
fi

cat $resfile
rm -f $toremove
