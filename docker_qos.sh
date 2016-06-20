#!/bin/sh

# get the current path
threshold_reached="false"
threshold_value="1900"
container_ids=$(ldocker ps -q)
while true
do
	if [ "$threshold_reached" == "true" ]; then
		sleep 0.5
		echo -e "Threshold status: $threshold_reached"
		echo "MADE PASOK HERE SIYA"
		new_ids=$(ldocker ps -q)
		#grep -Fxv -f <(echo "$container_ids") <(echo "$new_ids")
		echo "Before DIFF"
		create_ids=`diff <(echo "$container_ids") <(echo "$new_ids") | grep '>' | awk '{print $2}'`
		echo "$create_ids"
		echo "AFTER GREP"
		created_ids=`grep -Fxv -f <(echo "$container_ids") <(echo "$new_ids")`
		for ids in $create_ids; do
			echo "Hello $ids"
			swarm-docker rm -f $ids
			swarm-docker run  -v $HOME/Downloads:/home/google-chrome/Downloads:rw -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/snd:/dev/snd -v /dev/shm:/dev/shm -v /home/patricknode02/Desktop/chrome03.log:/home/google-chrome/Desktop/chrome03.log --privileged -e uid=$(id -u) -e gid=$(id -g) -e DISPLAY=unix$DISPLAY -d -e constraint:node==patricknode02-VirtualBox chrisdaish/google-chrome
			#do redirection here
		done
	fi
	inotifywait -e modify -t 5 --timefmt '%d/%m/%y %H:%M:%S' --format '%T %w %f' /tmp/docker_log.txt | while read date time dir file; do
	
	if (( $(sed -n "/${time}/{p; :loop n; p; /</q; b loop}" /tmp/docker_log.txt | grep -q "create") )); then
		if [ "$threshold_reached" == "true" ]; then
			sleep 0.5
			echo -e "Threshold status: $threshold_reached"
			echo "MADE PASOK HERE SIYA"
			new_ids=$(ldocker ps -q)
			#grep -Fxv -f <(echo "$container_ids") <(echo "$new_ids")
			echo "Before DIFF"
			create_ids=`diff <(echo "$container_ids") <(echo "$new_ids") | grep '>' | awk '{print $2}'`
			echo "$create_ids"
			echo "AFTER GREP"
			created_ids=`grep -Fxv -f <(echo "$container_ids") <(echo "$new_ids")`
			for ids in $create_ids; do
				echo "Hello $ids"
				swarm-docker rm -f $ids
				swarm-docker run  -v $HOME/Downloads:/home/google-chrome/Downloads:rw -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/snd:/dev/snd -v /dev/shm:/dev/shm -v /home/patricknode02/Desktop/chrome.log:/home/google-chrome/Desktop/chrome03.log --privileged -e uid=$(id -u) -e gid=$(id -g) -e DISPLAY=unix$DISPLAY -d -e constraint:node==patricknode02-VirtualBox chrisdaish/google-chrome
				#do redirection here
			done
		fi
	elif sed -n "/${time}/{p; :loop n; p; /</q; b loop}" /tmp/docker_log.txt | grep -q "start"; then
		#update container list since we know we just modified logs via starting a container
		echo "WE JUST UPDATED SHIT"
		container_ids=$(ldocker ps -q)
	fi
	break
	done

	echo "Doing monitoring stuff..."
	#should i get the ingoing or outgoing? or weight average of both
	ave_bw=`ifstat -b -i docker0 1 5 |tail -5 | awk '{for(i=1; i<=NF; i++){sum[i]+=$i}} END {for(i=1; i<=NF; i++){printf sum[i]/NR "\t"}}' | awk '{print $2}'` #incase of average of both, add awk for averaging both averages

	if [ "$threshold_reached" == "false" ]; then
		echo -e "Old threshold status: $threshold_reached $ave_bw"
		if (( $(echo "$ave_bw >= $threshold_value" | bc -l)  )); then
			threshold_reached="true"
			echo -e "New threshold status: $threshold_reached $ave_bw"
		else
			echo -e "STILL FALSE!"
			container_ids=$(ldocker ps -q)
		fi
	elif (( $(echo "$ave_bw < $threshold_value" | bc -l)  )); then
		echo -e "Old threshold status: $threshold_reached $ave_bw"
		threshold_reached="false"
		echo -e "New threshold status: $threshold_reached $ave_bw"
		container_ids=$(ldocker ps -q)
	fi
	echo -e "List: \n $container_ids"
done
