#!/bin/bash

force=""

usage() {
    cat <<EOF
Synopsis:
          set_sticky.sh [option] poolname IDlistfile
Description:
          The files in the IDlist will be set to system sticky in the given pool
          system sticky file won't be automatically deleted if the pool free space gets few

Options:
         -f        :   force - do not show what will be done and query for approval

EOF
}

TEMP=`getopt -o hf --long help -n 'dc_set_sticky.sh' -- "$@"`
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
echo "\c $poolname" >>$cmdfile
for n in `cat $listfile`;do
    echo "rep set sticky -o=system $n" >>$cmdfile
done
echo "\q" >>$cmdfile

execute_cmdfile $force $cmdfile resfile
toremove="$toremove $resfile"

rm -f $toremove


#  
#  
#  NAME
#         rep set sticky -- change sticky flags
#  
#  SYNOPSIS
#         rep set sticky [-al=online|nearline] [-all] [-cache=<class>]
#         [-rp=custodial|replica|output] [-storage=<class>] [-l=<millis>]
#         [-o=<name>] [<pnfsid>] on|off 
#  
#  DESCRIPTION
#         Changes the sticky flags on one or more replicas. Sticky flags prevent
#         sweeper from garbage collecting files. A sticky flag has an owner (a
#         name) and an expiration date. The expiration date may be infinite, in
#         which case the sticky flag never expires. Each replica can have zero or
#         more sticky flags.
#         
#         The command may set or clear a sticky flag of a specific replica or for
#         a set of replicas matches the given filter cafeterias.
#  
#  ARGUMENTS
#         <pnfsid>
#                Only change the replica with the given ID. 
#         on|off
#                Whether to set or clear the sticky flag.
#  
#  OPTIONS
#         Filter options:
#           -al=online|nearline
#                Only change replicas with the given access latency. 
#           -all
#                Allow using the command without any filter options and without a
#                PNFS ID. This is a safe guard against accidentally changing all
#                replicas. 
#           -cache=<class>
#                Only change replicas with the given cache class. If set to the
#                empty string, the condition will match any replica that does not
#                have a cache class. 
#           -rp=custodial|replica|output
#                Only change replicas with the given retention policy. 
#           -storage=<class>
#                Only change replicas with the given storage class. 
#         Sticky properties:
#           -l=<millis>
#                The lifetime in milliseconds from now. Once the lifetime expires,
#                the sticky flag is removed. If no other sticky flags are left and
#                the replica is marked as a cache, sweeper may garbage collect it.
#                A sticky flag with a lifetime of -1 never expires. 
#           -o=<name>
#                The owner is a name for the flag. A replica can only have one
#                sticky flag per owner. Defaults to system.
#  
