#!/bin/bash

force=""
debug=0

usage(){
    cat <<EOF
Synopsis: 
      dc_generic_cellcommand.sh [options] -c 'command' cellname [listfile]
Options:
         -c                    :  command. use \$n as a placeholder for substitutions
                                  by the list contents
         -f                    :  force. Do not prompt for execution
         -d                    :  debug only. Do not execute

Description:
      For every line in the list file, the specified command will be executed in the target
      cell, where the \$n placeholder will be replaced by a line in the list file.
      Will accept lines on stdin Instead of a list file.

Example:
      dc_generic_cellcommand.sh -d -c 'rep ls \$n' somePool myPoolIDs.lst

EOF
}

##############################################################
TEMP=`getopt -o c:df --long help -n 'dc_replicate_IDlist.sh' -- "$@"`
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
            command=$2
            shift 2
            ;;
        -d)
            debug=1
            shift
            ;;
        -f)
            force="-f"
            shift
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

cell=$1
shift

listfile=$1
shift


if test x"$cell" = x ; then
    echo "Error: Need a Cell name" >&2
    exit 1
fi

toremove=""
if test x"$listfile" = x; then
   listfile=`mktemp /tmp/dc_generic-$USER.XXXXXXXX`
   while read line; do
      echo "$line" >> $listfile
   done
   toremove="$toremove $listfile"
fi
if test ! -r $listfile; then
    echo "Error: Cannot read ID list file: $listfile" >&2
    exit 1
fi

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

cmdfile=`mktemp /tmp/dc_generic-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

echo "cd $cell" > $cmdfile
for n in `cat $listfile`; do
    tmp=`eval echo $command`
    echo $tmp >> $cmdfile
done

cat >> $cmdfile <<EOF
..
logoff
EOF
toremove="$toremove $cmdfile"

if test $debug -ne 0; then
   cat $cmdfile
   rm -f $toremove
   exit 0
fi

execute_cmdfile $force $cmdfile resfile
toremove="$toremove $resfile"


#if test x"$opt" = x; then
#   sed -i -e '/(.*)/d' -e '/^ *$/d' $retfile
#fi

cat $retfile
rm -f $retfile

rm -f $toremove
