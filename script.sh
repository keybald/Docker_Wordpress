#!/bin/bash

ETC_HOSTS=/etc/hosts
HOSTNAME="wp.local"

# This function takes care of removing wp.local line from the /etc/hosts file
# This is necessary, because the network settings change every time the ./script.sh down command is being used

function remove() {
    HOSTS_LINE="$HOSTNAME"
    if [ -n "$(grep -P $HOSTS_LINE $ETC_HOSTS)" ]
    then
        echo "$HOSTS_LINE Found in your $ETC_HOSTS, Removing now...";
        sudo sed -i".bak" "/$HOSTS_LINE/d" $ETC_HOSTS
    else
        echo "$HOSTS_LINE was not found in your $ETC_HOSTS";
    fi
}

case "$1" in

up)
        if [ -f /var/run/docker_script.pid ]; then
		echo "It's not possible to bring the Docker system to the UP stage as it seems to be already running"
	else
		run_me='docker-compose up -d'
		eval $run_me
		echo $!>/var/run/docker_script.pid

		sleep 120

		cmd=`docker volume inspect project_wp_dir | grep 'Mountpoint' | awk '{print $2}' | tr -d '\",'`

		check_if_exists=`grep -o $cmd'/wp-content/themes/twentytwentytwo/templates/home.html' -e 'existence_marker'`
		ip_address=`docker container inspect wp | grep "IPAddress" | head -n3 | tail -n1 | awk -F ":" '/1/ {print $2 }' | tr -d ",\" "`
		verify_hosts_file=`cat /etc/hosts | grep -o "wp.local" | tail -n1`

		if [[ $check_if_exists != 'existence_marker' ]]
		then
			sed -i '/post-excerpt/a <iframe class="existence_marker" width="1113" height="626" src="https://www.youtube.com/embed/qQzdAsjWGPg" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>' $cmd/wp-content/themes/twentytwentytwo/templates/home.html
		fi

		if [[ $verify_hosts_file != $HOSTNAME ]]
		then
			echo $ip_address $HOSTNAME >> $ETC_HOSTS
		elif [[ $verify_hosts_file = $HOSTNAME ]]
		then
			while [ $verify_hosts_file = $HOSTNAME ]; do
				remove $ip_address $HOSTNAME
				if [ $verify_hosts_file != $HOSTNAME ]
				then
					break;
				fi
			done
			add $ip_address $HOSTNAME 
		fi

		verify_if_wordpress_URL_correct=`grep -o $cmd'/wp-config.php' -e $HOSTNAME`

		if [[ $verify_if_wordpress_URL_correct != $HOSTNAME ]]
		then
			echo "define( 'WP_HOME', 'http://wp.local' );" >> $cmd'/wp-config.php'
			echo "define( 'WP_SITEURL', 'http://wp.local' );" >> $cmd'/wp-config.php'
		fi
        fi
	;;
start)
        if [ -f /var/run/docker_script.pid ]; then
		echo "It's not possible to start the Docker system as it seems to be already running"
	else
		run_me='docker-compose start'
        	eval $run_me
                echo $!>/var/run/docker_script.pid
	fi
        ;;
stop)
        if [ -f /var/run/docker_script.pid ]; then
		run_me='docker-compose stop'
        	eval $run_me
                rm /var/run/docker_script.pid
	else
		echo "The Docker system can't be stopped as it doesnt appear to be running"
        fi
	;;
down)
        if [ -f /var/run/docker_script.pid ]; then
                run_me='docker-compose down'
                eval $run_me
		rm /var/run/docker_script.pid
                while [ $verify_hosts_file == $HOSTNAME ]; do
	                remove $ip_address $HOSTNAME
                done
        elif [ `docker container ps | wc -l` != "1"  ]; then
		run_me='docker-compose down'
                eval $run_me 
                while [ $verify_hosts_file == $HOSTNAME ]; do
	                remove $ip_address $HOSTNAME
                done
	else
                echo "The Docker system can't go down as it doesnt appear to be running"
        fi
        ;;
status)
	if [ -f /var/run/docker_script.pid ]; then
		echo "The Docker system appears to be running"
		echo $cmd
	else
		echo "The Docker system doesnt appear to be running"
	fi
	;;
mount)
	if [ -d "Wordpress_Mount" ]; then
		echo "The Wordpress folder appears to be mounted"
	else
		cmd=`docker volume inspect project_wp_dir | grep 'Mountpoint' | awk '{print $2}' | tr -d '\",'`
		ln -s $cmd "Wordpress_Mount"
	fi
	;;
unmount)
	if [ -d "Wordpress_Mount" ]; then
		rm Wordpress_Mount
	else
		echo "The Wordpress folder appears to be already unmounted."
	fi
	;;
*)
	echo ""
	echo "Usage: $0 {up|down|start|stop|status|mount|unmount}"
	echo ""
	echo "The script is used to manage the Docker containers used by Wordpress and the remaining servers such as MySQL and Apache."
	echo ""
	echo "The UP command should be used instead of start to bring the Docker system online for the first time. After that you can use START and STOP arguments."
	echo ""
	echo "The START command should only be used if the Docker system was stopped before by using the command STOP."
	echo ""
	echo "Using the STOP command does what is says on tin. It will stop the container and they can be restarted by using the START argument."
	echo ""
	echo "If you use the DOWN command, the Docker network for the relevant containers will be affected. The command also deletes the containers from the memory and you then need to use UP to bring the system back online."
	echo ""
	echo "Use MOUNT and UNMOUNT commands to mount/unmount Wordpress folder located inside the WP Docker container. The mounted folder will be located in the same folder as the ./script.sh file."
esac

exit 0
