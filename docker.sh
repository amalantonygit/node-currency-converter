
#!/bin/bash
set -e

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
	if [[ $(ssh -i $1 ubuntu@$REMOTE_SERVER_IP "docker images $IMAGE_REPOSITORY | tr -s ' ' | cut -d ' ' -f 3") != $(docker images $IMAGE_REPOSITORY | tr -s ' ' | cut -d ' ' -f 3) ]]
	then
		echo "Docker image changed, updating..."
		docker save $IMAGE_REPOSITORY | bzip2 | pv | ssh -i $1 ubuntu@$REMOTE_SERVER_IP "bunzip2 | docker load"
	else
		echo "Docker image did not change"
	fi
}

cleanup_docker () {
    echo -e "Removing unused Docker objects in server";
    ssh "ubuntu@$REMOTE_SERVER_IP" -o "StrictHostKeyChecking=no" -i $1 -tt "docker system prune -a -f";
}

restart_docker () {
    echo -e "Restarting Docker";
    ssh "ubuntu@$REMOTE_SERVER_IP" -o "StrictHostKeyChecking=no" -i $1 -tt "docker rm -f currency-api || :";
    ssh "ubuntu@$REMOTE_SERVER_IP" -o "StrictHostKeyChecking=no" -i $1 -tt "docker run -d --name currency-api -p 80:9393 $IMAGE_REPOSITORY";
    echo -e "Deployment Complete";
}

start_deploy $1;
upload_docker_image $1;
restart_docker $1;
cleanup_docker $1;
