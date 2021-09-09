#! /bin/bash
user="bcat"
pass="wonder"
host="ip.address.of.switch"
port="6000"
date=$(date -u "+%Y.%m.%d-%H%M")
dir="/path/to/archive/directory"
discord="/path/to/discord.sh --text"

mkdir -p $dir/latest
mkdir -p $dir/new
wget -T 10 -t 3 -m -c -nH --cut-dirs=1 ftp://$user:$pass@$host:$port/directories/ -P $dir/.fresh1
if [ $? -eq 0 ]
then
	touch $dir/last_synced
	echo $(date "+%Y.%m.%d/%H:%M") > $dir/.last_synced
	find $dir/.fresh1 -type f -name ".listing" -delete
	diff -qr $dir/.fresh1 $dir/latest
	if [ $? -eq 1 ]
	then
		sleep 60
		wget -T 10 -t 3 -m -c -nH --cut-dirs=1 ftp://$user:$pass@$host:$port/directories/ -P $dir/.fresh2
		if [ $? -eq 0 ]
		then
			find $dir/.fresh2 -type f -name ".listing" -delete
			diff -qr $dir/.fresh1 $dir/.fresh2
			if [ $? -eq 0 ]
			then
				diff -qr $dir/.fresh1 $dir/latest
				if [ $? -eq 1 ]
				then
					diff -qr $dir/.fresh1 $dir/latest > $dir/report
					cp $dir/report $dir/discord_report
					sed -i "s/: /\//g" $dir/discord_report
					sed -i 's,Only in '"$dir"'/.fresh1/,Added: '"$dir"'/.fresh1/,g' $dir/discord_report
					sed -i 's,Only in '"$dir"'/latest/,Removed: ,g' $dir/discord_report
					sed -i 's/Files /Modified: /g' $dir/discord_report
					cat $dir/discord_report | awk '{print $1 " " $2}' > $dir/report
					cp $dir/report $dir/discord_report
					sed -i 's,'"$dir"'/.fresh1/,,g' $dir/discord_report
					cat $dir/discord_report | awk -v dir="$dir" '{if (index($2, "/") == 0) print "echo " $1 " " $2 "/$(ls " dir "/.fresh1/" $2 "/files)"; else print "echo " $1 " " $2}' | sh > $dir/discord_report2
					pr -t -d $dir/discord_report2 > $dir/discord_report
					$discord "$(jq -Rs . <$dir/discord_report | cut -c 2- | rev | cut -c 2- | rev)"
					rm $dir/discord_report
					rm -r $dir/new/*
					cat $dir/report | awk -v dir="$dir" '{gsub(dir"/.fresh1/",""); print "mkdir -p " dir "/new/$(dirname " $2 ")"}' | sh
					cat $dir/report | awk '{copy=$2; gsub(".fresh1","new"); print "cp -r " copy  " " $2}' | sh
					mv $dir/discord_report2 $dir/report
					rm -r $dir/latest/*
					cp -r $dir/.fresh1/* $dir/latest/
					mv $dir/.fresh1 $dir/$date
					rm -r $dir/.fresh2
				else
					rm -r $dir/.fresh1
					rm -r $dir/.fresh2
				fi
			else
				rm -r $dir/.fresh1
				rm -r $dir/.fresh2
			fi
		else
			rm -r $dir/.fresh1
			rm -r $dir/.fresh2
		fi
	else
		rm -r $dir/.fresh1
		rm -r $dir/.fresh2
	fi
else
	rm -r $dir/.fresh1
	rm -r $dir/.fresh2
fi
