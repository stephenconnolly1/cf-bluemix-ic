#!/usr/bin/env bash

VARS="CF_USER CF_PASS CF_ORG CF_SPACE CF_API CF_CONTAINER CF_PORTS LAUNCH_CMD"

function checkvar {
	if [ -z ${1} ];
		then
			echo "Variable ${1} is not set, please check your wercker environment variables."
			exit 1;
		else
			return 0;
	fi
}

function cfinit {
	cf login -u $CF_USER -p $CF_PASS -o $CF_ORG -s $CF_SPACE -a $CF_API
	cf ic init
}

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

function buildports {
	IFS=',' read -ra PORTS <<< "$CF_PORTS"
	for element in "${PORTS[@]}"; do
        printf " -p $element "
	done
}


function reprovision {
	if [ -z "$3" ]; then
		IP_ADDRESS=$(echo $1 | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])')
	else
		IP_ADDRESS=$3	
	fi
	cf ic rm $2 --force
	CONTAINERID=$(cf ic run $(buildports) registry.eu-gb.bluemix.net/aie_london/$CF_CONTAINER $LAUNCH_CMD)
	cf ic ip bind $IP_ADDRESS $CONTAINERID
	return 0
}

# for i in $VARS; do checkvar $i; done

cfinit

IMAGE_NAME=${CF_CONTAINER}
CF_OUTPUT=$(cf ic ps --format 'table {{.ID}}|{{.Image}}|{{.Ports}}' |grep ${IMAGE_NAME})
RUNNING_CONTAINER=$(echo "$CF_OUTPUT" | grep $IMAGE_NAME | cut -d '|' -f 1)


running ${CF_OUTPUT} ${RUNNING_CONTAINER}

if [[ "$?" != "0" ]]; then
	echo "Check if port exposed, if so request an ip, else return 0."
        if [[ -z "${CF_PORT}" ]]; then
	  setip ${RUNNING_CONTAINER}
          echo "Serving on: $(IP_ADDRESS):$(CF_PORT)"
        fi

else
	echo "Reprov"
	reprovision ${CF_OUTPUT} ${RUNNING_CONTAINER} ${IP_ADDRESS}
        echo "Serving on:  $(IP_ADDRESS):$(CF_PORT)"
fi
