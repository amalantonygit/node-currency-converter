
#!/bin/bash

start_deploy () {
    if [[ -z $1 ]]
    then
        echo -e "No Identity File.\nExiting";
        exit 1;
    else 
        echo -e "Path to identity file:\t" $1;
    fi
}


function upload_docker_image {
	if [[ $(ssh -i ubuntu@$REMOTE_SERVER_IP "docker images $IMAGE_REPOSITORY | grep $1 | tr -s ' ' | cut -d ' ' -f 3") != $(docker images $IMAGE_REPOSITORY | grep $1 | tr -s ' ' | cut -d ' ' -f 3) ]]
	then
		echo "$1 image changed, updating..."
		docker save $IMAGE_REPOSITORY:$1 | bzip2 | pv | ssh -i ubuntu@$REMOTE_SERVER_IP 'bunzip2 | docker load'
	else
		echo "$1 image did not change"
	fi
}

remove_previous_files_in_remote () {
    echo -e "Removing previous project files in Server";
    ssh "ubuntu@$REMOTE_SERVER_IP" -o "StrictHostKeyChecking=no" -i $1 -tt 'cd currency-api/; mv build/ build-old/; mv build-new/ build/; rm -rf build-old/;';
}

restart_docker () {
    echo -e "Restarting Docker";
    docker run --name  $IMAGE_REPOSITORY
    echo -e "Deployment Complete";
}


start_deploy $1;
upload_docker_image $1;
restart_docker $1;
remove_previous_files_in_remote $1;
