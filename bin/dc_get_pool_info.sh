#!/bin/bash
#################################################################
# dc_get_pool_info.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch>
#
# 2022-06-27
#################################################################

myname=$(basename $0)

# DEFAULTS
condition=""
raw=0
############

usage(){
    cat <<EOF
Synopsis:
          $myname poolfile

Description:
          list tabular info about the pools listed in poolfile. Each line in poolfile must
          contain one poolname

          -d           : debug
EOF
}

##############################################################
TEMP=`getopt -o dh: --long help -n "$myname" -- "$@"`
if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi
#echo "TEMP: $TEMP"
eval set -- "$TEMP"

while true; do
    case "$1" in
        --help|-h)
            usage
            exit
            ;;
        -d)
            debug=1
            shift
            ;;
        # -r)
        #     raw=1
        #     shift
        #     ;;
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

listfile=$1
shift

source $DCACHE_SHELLUTILS/dc_utils_lib.sh

toremove=""

metrics="Total Used Free Gap"
for pool in `cat $listfile`; do
    cmdfile=`mktemp /tmp/${USER}-${myname}.XXXXXXXX`
    tmpres=`mktemp /tmp/dc_utils-$USER.XXXXXXXX`
    
    if test $? -ne 0; then
        echo "Error: Could not create a cmdfile" >&2
        exit 1
    fi
    cat > $cmdfile <<EOF
\s $pool info
\q
EOF
    if test x"$debug" = x1; then
        cat $cmdfile >&2
    fi
    execute_cmdfile -f $cmdfile resfile
    if test x"$debug" = x1; then
        cat $resfile
    fi
    for metr in $metrics; do eval ${metr}="NA"; done
    sed -e '0,/^ *Total *:/{s/^ *Total *: *\([0-9]*[T]\?\)/Total="\1"/p}' \
        -e '0,/^ *Used *:/{s/^ *Used *: *\([0-9]*\).*/Used="\1"/p}' \
        -e '0,/^ *Free *:/{s/^ *Free *: *\([0-9]*\).*Gap *: *\([0-9]*\).*/Free="\1"\nGap="\2"/p}' \
        -e 's#Mover Queue (\([^)]*\)) \([0-9]*\)(\([0-9]*\)).*#mover_\1="\2_of_\3"#p' \
        -n $resfile > $tmpres
    if test x"$debug" = x1; then
        cat $tmpres
    fi

    source $tmpres
    printf "%20s %20s %20s %20s %20s\n" $pool $Total $Used $Free $Gap
    
    rm -f $cmdfile $resfile    
done

# 335544320 t3fs01_cms_01
