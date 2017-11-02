#!/bin/bash

### Setup Environment ###

COMMAND=$1
SITE=$2
ENTRY=""

source $SITE/servers.cfg

if [ ! -z "$3" ]; then
	ENTRY=$3
fi
### End Setup Environment ###

### Settings ###
# Settings are all contained in '${SITE}/server.cfg',
# which defines the following variables to be used below:
# 
# ${CMD}     The string used for connecting to the servers,
#            via `eval`, as well as searching for the PID
#            via `grep`.
#
# ${SERVERS} An array of strings to be used individually
#            by the ${CMD} variable, via the $server variable
# 
# $server    An entry in the ${SERVERS} array, referenced in
#            the ${CMD} variable.
#
### End Settings ###

GetPid()
{
	ps -ax | grep "$1" | grep -v grep | awk '{ print $1 }'
}

Connect()
{
	server=$1
	eval $CMD
	pid=$(GetPid "$(eval "echo $CMD")") #Lazy evaluation needed since we just defined $server
	echo "pid: $pid"
}

Disconnect()
{
	server=$1
	pid=$(GetPid "$(eval "echo $CMD")")
	kill $pid
}

Status()
{
	server=$1
	ps -ax | grep "$(eval "echo $CMD")" | grep -v grep
}

List()
{
	echo $1
}

Main()
{
	if [ ! -d $SITE ]; then
		echo "Directory $SITE does not exist"
		exit 
	fi

	if [ ! -f $SITE/servers.cfg ]; then
		echo "No config file found in $SITE"
		exit
	fi		

	if [ ! -z "$ENTRY" ]; then
		i=$ENTRY 
		$1 "${SERVERS[$i]}"
	else
		for ((i=0; i < ${#SERVERS[@]}; i++)) #Necessary for array elements with spaces
		do
			$1 "${SERVERS[$i]}"
		done
	fi
}

case $1 in
	start )
		Main Connect
		Main Status
		;;
	stop )
		Main Disconnect
		;;
	status )
		Main Status
		;;
	list )
		Main List
		;;
	* )
		echo "usage: <start|stop|status> <directory> [entry]"
		echo "<directory> is a directory which contains a 'servers.cfg' file"
		echo "[entry] is an index in the SERVERS array defined in servers.cfg"
		echo "[entry] is optional. The script loads all connections by default"
		;;
esac
