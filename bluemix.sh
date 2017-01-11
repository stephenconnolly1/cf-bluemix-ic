#!/bin/bash
	
function connect {
	cf login -u $CF_USER -p $CF_PASS -o $CF_ORG -s $CF_SPACE -a $CF_API
	cf ic init
}

connect

IMAGE_NAME=${CF_CONTAINER}
CF_OUTPUT=$(cf ic ps --format 'table {{.ID}}|{{.Image}}|{{.Ports}}' |grep ${IMAGE_NAME})
RUNNING_CONTAINER=$(echo "$CF_OUTPUT" | grep $IMAGE_NAME | cut -d '|' -f 1)

function running {
	echo RUNNING - $1
	if [[ -z $1 ]]; then
		return 1
	else
		echo "Container ID=$2"
		return 0
	fi
}

function setip {
	IP_ADDRESS=$(cf ic ip request -q)
        cf ic ip bind $IP_ADDRESS $1
}

function reprovision {
	if [ -z "$3" ]; then
		IP_ADDRESS=$(echo $1 | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])')
	else
		IP_ADDRESS=$3	
	fi
	cf ic rm $2 --force
	CONTAINERID=$(cf ic run -p $CF_PORT:$CF_PORT registry.eu-gb.bluemix.net/aie_london/$CONTAINER_NAME)
	cf ic ip bind $IP_ADDRESS $CONTAINERID
	return 0
}

running ${CF_OUTPUT} ${RUNNING_CONTAINER}

if [[ "$?" != "0" ]]; then
	# check if port exposed, if so request an ip, else return 0.
        if [[ -z "${CF_PORT}" ]]; then
	  setip ${RUNNING_CONTAINER}
          echo "Serving on: $(IP_ADDRESS):$(CF_PORT)"
        fi

else
	reprovision ${CF_OUTPUT} ${RUNNING_CONTAINER} ${IP_ADDRESS}
        echo "Serving on:  $(IP_ADDRESS):$(CF_PORT)"
fi
