## The purpose behind the scripts:

To automate installation of Wordpress. In addition, after the scripts have finished installing the software, it should be possible to see a videoclip of Frank Sinatra when opening the main Wordpress page. Also, developers should have access to a persistent volume where they should be able to make modifications to various configuration files that are located within the Wordpress Docker image.

## Pre-requisites: 

1. You need to make sure that the Docker and the docker-compose tool are installed on the machine which will have the containers installed in place. 

## Installation instructions:

1. Navigate to the Docker/project folder and execute the following command as the root user: 

`./script.sh up`

This command will cause for the docker containers to be created, one called WP and another DB, and populated with services such as MySQL, Apache or Wordpress. It may take about 2 minutes for the script to complete running, so please don't interrupt it. 

On my test system I ran the script from this location: /root/Docker/project/script.sh. I don't anticipate any problems from running the script in another location, but please preserve the folder sctructure to be as follows: 

```
Docker
     |_docker
     |_project
```
If you are running the script for the first time, you should run it with the `up` option to make everything work correctly, as it will execute `docker-compose up` command, among other things. Then you can use `stop` and `start` to control the lifecycle of the Docker containers. If you are a developer and need to have access to WordPress files located on one of the Docker containers, please run `./script.sh mount`. The folder containing Wordpress related files should appear in the same folder as the script itself. Once you finish working with the folder you can unmount it by issuing `./script.sh unmount` command. You can use `status` command to see whether the Docker container system is running or not. 

The script itself is also responsible for adding a wp.local entry to /etc/hosts on the Host machine. You then need to open your web browser and type in wp.local into the address field. Hopefully, the Wordpress configuration website will open. If you run `./script.sh down` command, the network settings will be affected as the system will delete the network settings of the Docker containers. Fortunately the script will take care of assigning a new IP address in the hosts file next time you start the script with `./script.sh up` command. The script will modify the wp-config.php file to set the URL of the website to http://wp.local. You will notice that you can't change this setting from within the UI, you need to modify the PHP file itself (wp-config.php). 

The ./script.sh is also responsible for embedding a Youtube videoclip (in this case Frank Sinatra's song) on the home page, so hopefully, once you finish running `./script.sh up` command, you will notice the videoclip when landing on the home page of Wordpress. Of course, you will need to go through some basic configuration steps, including entering your email address and login details as the wordpress user, but only if you are going through the installation process for the first time. 

I wouldn't recommend changing the theme from the default one as it will cause for the embedded Youtube clip to disappear. 

I'm not happy that there is no backup system to preserve the MySQL and Wordpress containers. If someone deletes a file on those volumes, by accident, it's gone for good. I would be happy to implement a backup system of some sort, but I don't have much time for that. I could also experiment with Git, but perhaps I will do that in a near future. 

Oh, and I know that editing Wordpress files by the script is not the ideal way of doing things, but again, I haven't had enough time to research injecting commands into the database itself. 

Once the script has finished running, proceed to the next step.

2. Check with `docker volume list` to see if both the *wp_dir and *database_dir volumes are listed. Those are volumes that will be used for data persistence for both the WP and DB data. It means that the volumes and data stored on them will be preserved, even if the WP and DB containers are deleted.

======Potentially remove this section======
3. Run the following command: 

`docker image list` 

You may notice images with empty tags or repository name. In this case run the next command to get rid of those images: 

`docker rmi $(docker images -f "dangling=true" -q)`

I will try to automate it in the future, but for now, I haven't had enough time for that. 

===========================================

3. Since the data is persisting, you should be able to locate the Wordpress folders outside of the Docker images, on a local disk. The path is usually as follows: 

`/var/lib/docker/volumes/[volume_name]`

In our case, we have two volumes: one storing MySQL database and the second one the Wordpress folders. Use mount and unmount command to gain access to the Wordpress files from the same folder where the `script.sh` is located. 

## XDebug notes: 

1. After running `script.sh up` from the previous steps, the script will also take care of configuring php.ini and installing xdebug on the WP server. 

2. After launching Visual Studio Code, install the PHP Debug extension. 

3. Click 'Run and Debug' option in VSC. On the top of the window you will have 'Listen for Xdebug' option. Click on the small cog icon and paste the following into the launch.json tab: 
```
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003
        },
        {
            "name": "Launch currently open script",
            "type": "php",
            "request": "launch",
            "program": "${file}",
            "cwd": "${fileDirname}",
            "port": 0,
            "runtimeArgs": [
                "-dxdebug.start_with_request=yes"
            ],
            "env": {
                "XDEBUG_MODE": "debug,develop",
                "XDEBUG_CONFIG": "client_port=${port}"
            }
        },
    ]
}
```
4. To check if the debug works properly, run the following command:

a) `docker container ps`
b) Take note of the CONTAINER ID of the wordpress target and run the following command: 

`docker exec -it "PUT_CONTAINER_ID_HERE" /bin/bash`

c) The above command should allow you to connect to the Wordpress container.
d) You can now go to `/var/www/html` and create a file, let's call it `myscript.php`.
e) Paste the following into the PHP file: 
```
<?php 

xdebug_break();
$a=1;

?>
```
f) Make sure that the debugger is listening in Visual Studio Code. Then run the following command: 

`php myscript.php`

The result should be establishing a connection between XDebug and Visual Studio Code, which means that all works as expected. 

Please note that I have tested this script on two Ubuntu VMs and all was working OK, apart from the inability to open debugged PHP files in the VSC. I haven't had time to see what's causing this problem. 
