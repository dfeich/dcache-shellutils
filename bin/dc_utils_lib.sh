#!/bin/bash
#################################################################
# dc_utils_lib.sh
# bash utility library for dcache
#
# Author: Derek Feichtinger <derek.feichtinger@psi.ch> 2007-08-27
#
# $Id: dc_utils_lib.sh 2925 2010-09-01 12:40:32Z dfeich $
#################################################################
# 2007-08-25 Derek Feichtinger <derek.feichtinger@psi.ch>

# all routines assume that the admin door's contact information is found in
# these variables
# DCACHEADMINHOST : hostname of admin interface
# DCACHEADMINPORT : port name of admin interface

if test x"$DCACHEADMINHOST" = x; then
    echo "Error: Environment variable DCACHEADMINHOST not defined" >&2
    exit 1
fi
if test x"$DCACHEADMINPORT" = x; then
    echo "Error: variable DCACHEADMINPORT not defined" >&2
    exit 1
fi

keyfileopt=""
if test x"$DCACHEADMIN_KEY" != x; then
    if test ! -r "$DCACHEADMIN_KEY"; then
        echo "Error:Cannot read keyfile (DCACHEADMIN_KEY=$DCACHEADMIN_KEY)" >&2
        exit 1
    fi
    keyfileopt="-i $DCACHEADMIN_KEY"
fi

# returns 0 for OK, i.e. the poolname exists, otherwise 1
check_poolname() {
    poolname=$1
    if test x"$poolname" = x; then
	echo "check_poolname: Error: no poolname given" >&2
	exit 1
    fi
    tmpfile=`mktemp /tmp/rep_rm-$USER.XXXXXXXX`
    if test $? -ne 0; then
	echo "Error: Could not create a tmpfile" >&2
	exit 1
    fi
    # note: need to use -l which produces longer output, because dcache breaks off the connection uncleanly
    # and short outputs are sometimes lost
    ssh $keyfileopt -T -l admin -p $DCACHEADMINPORT $DCACHEADMINHOST 2>${tmpfile}.err > $tmpfile <<EOF        
cd PoolManager
psu ls pool -l
..
logoff
EOF
    #if test $? != 0; then
    #   echo "Error: check_poolname() error in ssh connection" >&2
    #   cat ${tmpfile}.err >&2
    #   rm -f ${tmpfile}.err # $tmpfile
       #exit 1
    #fi
    #sed -i -ne 's/\cM\(se.*\).*/\1/p' $tmpfile
    sed -nie 's/^\([^ ]*\).*enabled.*/\1/p'  $tmpfile
    grep $poolname $tmpfile &>/dev/null;
    status=$?
    rm -f ${tmpfile}.err $tmpfile
    if test $status -ne 0; then
	#echo "Error: No such pool: $poolname" >&2
	return 1
    fi
    return 0
}

# executes a file with dcache admin commands
# if first arg is -f, then user will not be interactively prompted
# first arg: name of command file
# second arg: variable name into which name of result file will be passed
execute_cmdfile() {
    if test x"$1" = x-f; then
	local force=1
	shift
    fi
    local cmdfile=$1
    fileref=$2

    if test x"$cmdfile" = x -o ! -r $cmdfile; then
	echo "execute_cmdfile: Error: Cannot read command file ($cmdfile)" >&2
	exit 1
    fi


    if test x"$force" != x1; then
	cat $cmdfile >&2
	echo "ARE YOU SURE YOU WANT TO EXECUTE this file?" >&2
	read a
	if test x"$a" != xy; then
	    echo "Cancelling..."
	    rm -f $cmdfile
	    exit 0
	fi
    fi

    local tmpfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
    if test $? -ne 0; then
	echo "execute_cmdfile: Error: Could not create a cmdfile" >&2
	exit 1
    fi
    local errfile=`mktemp /tmp/get_pnfsname-$USER.XXXXXXXX`
    if test $? -ne 0; then
	echo "execute_cmdfile: Error: Could not create a tmpfile for stderr" >&2
	exit 1
    fi

    ssh $keyfileopt -T -l admin -p $DCACHEADMINPORT $DCACHEADMINHOST 2>$errfile > $tmpfile <$cmdfile

    rm -f $errfile

    #clean out the leading ^M
    sed -i -e 's/\cM\(.*\)/\1/' $tmpfile

    # remove colours
    sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" -i $tmpfile

    eval $fileref=$tmpfile

    return 0
}


# two functions to start a timer and to get the number of passed seconds
starttimer() {
  timerstart=`date +%s`
}
gettimer() {
  if test x"$timerstart" = x; then
     echo "Error: gettimer called without previous starttimer" >&2
     echo 0
     return 1
  fi
  local t2=`date +%s`
  echo $((t2-timerstart))
  return 0
}
