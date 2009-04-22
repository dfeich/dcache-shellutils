#!/bin/bash

force=""
yes=""

usage() {
    cat <<EOF
Synopsis:
          rep_rm_list.sh [options] poolname listfile
Options:
          -f           run the command with the force flag, i.e. "rep rm -force"
          -y           (yes) Do not prompt before execution of the generated
                       admin command script

Description:
          The listfile must contain a list of pnfsIDs in the first column. These files
          will be removed from the pool with name "poolname".
EOF
}

##############################################################
TEMP=`getopt -o yf --long help -n 'dc_rep_rm_list.sh' -- "$@"`
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
            force=" -force"
            shift
            ;;
        -y)
            yes="-f"
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
shift

listfile=$1
shift




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

check_poolname $poolname
if test $? -ne 0; then
    usage
    echo "Error: No such pool: $poolname" >&2
    rm -f $toremove
    exit 1
fi

cmdfile=`mktemp /tmp/rep_rm-$USER.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    rm -f $toremove
    exit 1
fi
toremove="$toremove $cmdfile"

echo "cd $poolname" >>$cmdfile
for n in `cat $listfile|awk '{print $1}'`;do
    echo "rep rm $n$force" >>$cmdfile
done
echo ".." >>$cmdfile
echo "logoff" >>$cmdfile

execute_cmdfile $yes $cmdfile retfile
toremove="$toremove $retfile"

cat $retfile
rm -f $toremove
