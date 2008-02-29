#!/bin/bash

force=""

usage() {
    cat <<EOF
Synopsis:
          set_precious.sh [option] poolname IDlistfile
Description:
          The files in the IDlist will be set to precious in the given pool

Options:
         -f        :   force - do not show what will be done and query for approval

EOF
}

TEMP=`getopt -o hf --long help -n 'dc_set_precious.sh' -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        -f)
	    force="-f "
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

poolname=$1
listfile=$2


source $DCACHE_SHELLUTILS/dc_utils_lib.sh

if test x"$poolname" = x; then
    usage
    echo "Error: no poolname given" >&2
    exit 1
fi
check_poolname $poolname
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolname" >&2
    exit 1
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

cmdfile=`mktemp /tmp/set_precious-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi

toremove="$toremove $cmdfile"
echo "cd $poolname" >>$cmdfile
for n in `cat $listfile`;do
    echo "rep set precious $n -force" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

execute_cmdfile $force $cmdfile resfile
toremove="$toremove $resfile"

rm -f $toremove
