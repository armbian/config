#!/bin/bash

REMOTE=

function sync_backup ()
{
	echo -e "[\e[0;32m o.k. \x1B[0m] \e[1;32m$1\x1B[0mSync over trusted ssh net"

	filename=filelist.txt
	IFS=$'\n'
	for next in `cat $filename`
	do
		if [[ $next != \#* ]]; then
			echo $next
			rsync --dry-run -az --progress $REMOTE:$next ${next%*/*}
			[[ ! $? -eq 0 ]] && read
		fi
	done
}


sync_backup
