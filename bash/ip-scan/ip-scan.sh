#!/bin/bash

SUB=$1
BEG=$2
END=$3

for ip in $(seq $BEG $END)
do
	(
		if $(ping -c 1 ${SUB}.$ip > /dev/null); then
			echo ${SUB}.$ip
		fi
	) &
done | sort
