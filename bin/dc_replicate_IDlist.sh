#!/bin/bash

#################################################################
# dc_replicate_IDlist.sh
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2007-08-27
#
# $Id$
#################################################################

myname=$(basename $0)

# DEFAULTS
dbg=0
eligible_pools="se01_cms se02_cms se03_cms se04_cms se05_cms se06_cms se07_cms"
maxrepls=2
force=""

usage(){
    cat <<EOF
Synopsis:
          $myname -p "pool1 pool2 ..."  id-pool-list

Options:
         -p "pool1 pool2 ..."  :  specify list of eligible target pools ($eligible_pools)
         -f                    :  force. Do not prompt for execution
         -r number             :  define max number of replicas a file may have on the system
                                  (so, no copy will be initiated, if there there are already _number_
                                  of copies existing)   
         -d                    :  debug output

Description:
          Expects a file with lines in the format of
              pnfsID  pool1 [pool2 pool3 ...]

          This is the same format as produced by the dc_get_cacheinfo_from_IDlist.sh
          script.
          The script will replicate the given files to one of the pools
          specified by the list following the -p argument

EOF
}




get_tgt_pool() {
   local avoid_pools=$1
   local prev_given=$2

   local i=1
   for n in $eligible_pools; do
      pool[$i]=$n
      i=$((i+1))
   done

   num_pools=`echo $eligible_pools|wc -w`

   local counter=1
   if test x"$prev_given" != x; then
      counter=`echo $eligible_pools|sed -e 's/  */\n/g'| grep -n "$prev_given"|cut -f1 -d:`
      if test x"$counter" = x; then
         echo "Error in get_tgt_pool: prev_given not in eligible pools" >&2
         return 1
      fi
      counter=$((counter+1))
   fi

   local miss=0
   while test 1; do
      if test $counter -gt $num_pools; then
         counter=1
      fi

      local res=`echo $avoid_pools|grep "${pool[$counter]}"`
      if test x"$res" = x; then
         echo ${pool[$counter]}
         return 0
      fi

      miss=$((miss+1))
      if test $miss -ge $num_pools; then
         echo "Error in get_tgt_pool: Cannot find placement (avoid=$avoi_pools)" >&2
         return 1
      fi

      counter=$((counter+1))
   done

}

##############################################################
TEMP=`getopt -o dfhp:r: --long help -n "$myname" -- "$@"`
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
            dbg=1
            shift
            ;;
        -f)
            force="-f"
            shift
            ;;
        -p)
            eligible_pools=$2
            shift 2
            ;;
        -r)
            maxrepl=$2
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

listfile=$1


if test ! -r $DCACHE_SHELLUTILS/dc_utils_lib.sh; then
    echo "ERROR: Env Var DCACHE_SHELLUTILS must point to directory containing dc_utils_lib.sh" >&2
    exit
fi
source $DCACHE_SHELLUTILS/dc_utils_lib.sh

toremove=""
if test x"$listfile" = x; then
   listfile=`mktemp /tmp/dc_tools-$USER.XXXXXXXX`
   while read line; do
      echo "$line" >> $listfile
   done
   toremove="$toremove $listfile"
fi
if test ! -r $listfile; then
    echo "Error: Cannot read ID list file: $listfile" >&2
    exit 1
fi


tmpfile=`mktemp /tmp/dc_tools-${USER}.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a tmpfile" >&2
    exit 1
fi
toremove="$toremove $tmpfile"

cmdfile=`mktemp /tmp/dc_tools-${USER}.XXXXXXXX`
if test $? -ne 0; then
    echo "Error: Could not create a cmdfile" >&2
    exit 1
fi
toremove="$toremove $cmdfile"

prev=""
while read id cachelocs; do
   numrepl=`echo $cachelocs | tr "," " "|wc -w`
   if test 0"$maxrepl" -gt 0; then
      if test $numrepl -ge $maxrepl; then
	  if test $dbg -ne 0; then echo "id=$id cache: $cachelocs   ignore, already has $numrepl replicas"; fi
	  continue
      fi
   fi
   newtgt=`get_tgt_pool "$cachelocs" $prev`
   status=$?
   if test $status -ne 0; then
      rm -f $toremove
      exit $status
   fi
   if test $dbg -ne 0; then echo id=$id  cache: $cachelocs   newtgt: $newtgt; fi

   srcpool=`echo "$cachelocs"|cut -f1 -d' '`   
   echo "$newtgt $srcpool $id" >> $cmdfile

   prev=$newtgt
done < $listfile

# now sort the list
sort -r $cmdfile > $tmpfile 

# build the commandfile
echo "" > $cmdfile
prevdstpool=""
while read dstpool srcpool id; do
   if test x"$dstpool" != x"$prevdstpool"; then
      echo -e "..\n\c $dstpool"    >> $cmdfile
   fi
   srcpool=`echo $srcpool|cut -f 1 -d","`
   echo "pp get file $id $srcpool" >> $cmdfile
   prevdstpool=$dstpool
done < $tmpfile

cat >> $cmdfile <<EOF
\q
EOF

execute_cmdfile $force $cmdfile resfile
toremove="$toremove $resfile"

cat $resfile

rm -f $toremove

exit 0
