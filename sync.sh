#! /bin/bash
user="bcat"
pass="wonder"
host="ip.address.of.switch"
port="6000"
date=$(date -u "+%Y.%m.%d-%H%M")
basedir="/path/to/archive/directory"
discord="/path/to/discord.sh --text"

quantity="9"
dirs=("lgp" "lge" "sw" "sh" "bd" "sp" "la" "s" "v")
names=("Let^s%Go,%Pikachu!" "Let^s%Go,%Eevee!" "Sword" "Shield" "Brilliant%Diamond" "Shining%Pearl" "Legends:%Arceus" "Scarlet" "Violet")
# Use '%' to designate spaces and '^' to designate apostrophes in names

for (( n=0; n<$quantity; n++ ))
do
	dir=$basedir"/"${dirs[$n]}
	mkdir -p $dir/latest
	mkdir -p $dir/new
	mkdir -p $dir/cumulative
	wget -T 10 -t 3 -m -c -nH --cut-dirs=2 --server-response ftp://$user:$pass@$host:$port/bfs$((n + 1)):/directories/ -P $dir/.fresh1
	if [ $? -eq 0 ]
	then
		touch $dir/last_synced
		echo $(date "+%Y.%m.%d/%H:%M") > $dir/.last_synced
		find $dir/.fresh1 -type f -name ".listing" -delete
		diff -qr $dir/.fresh1 $dir/latest
		if [ $? -eq 1 ]
		then
			sleep 60
			wget -T 10 -t 3 -m -c -nH --cut-dirs=2 ftp://$user:$pass@$host:$port/bfs$((n + 1)):/directories/ -P $dir/.fresh2
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
						sed -i "s@: @/@g" $dir/discord_report
						sed -i 's@Only in '"$dir"'/.fresh1/@['"${names[$n]}"'] Added: '"$dir"'/.fresh1/@g' $dir/discord_report
						sed -i 's@Only in '"$dir"'/latest/@['"${names[$n]}"'] Removed: @g' $dir/discord_report
						sed -i 's@Files @'"[${names[$n]}"'] Modified: @g' $dir/discord_report
						cat $dir/discord_report | awk '{print $1 " " $2 " " $3}' > $dir/report
						cp $dir/report $dir/discord_report
						sed -i 's@'"$dir"'/.fresh1/@@g' $dir/discord_report
						cat $dir/discord_report | awk -v dir="$dir" '{if (index($3, "/") == 0) print "echo " $1 " " $2 " " $3 "/$(ls " dir "/.fresh1/" $3 "/files)"; else print "echo " $1 " " $2 " " $3}' | sh > $dir/discord_report2
						pr -t -d $dir/discord_report2 > $dir/discord_report
						sed -i "s@%@ @g" $dir/discord_report
						sed -i "s@\^@'@g" $dir/discord_report
						# printf "\nhttps://citrusbolt.net/bcat/${dirs[$n]}/$date/" >> $dir/discord_report
						$discord "$(jq -Rs . <$dir/discord_report | cut -c 2- | rev | cut -c 2- | rev)"
						printf "\n($date)\n" >> $dir/history
						cat $dir/discord_report2 >> $dir/history
						rm $dir/discord_report
						rm -r $dir/new/*
						cat $dir/report | awk -v dir="$dir" '{gsub(dir"/.fresh1/",""); print "mkdir -p " dir "/new/$(dirname " $3 ")"}' | sh
						cat $dir/report | awk '{copy=$3; gsub(".fresh1","new"); print "cp -r " copy  " " $3}' | sh
						mv $dir/discord_report2 $dir/report
						sed -i "s@%@ @g" $dir/report
						sed -i "s@\^@'@g" $dir/report
						rm -r $dir/latest/*
						cp -r $dir/.fresh1/* $dir/latest/
						cp -r $dir/latest/* $dir/cumulative/
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
	sleep 60
done
