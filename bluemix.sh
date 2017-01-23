#!/usr/bin/env bash

################################################################
#			Bluemix.sh			       #
#	This script was created to interface wercker           #
#	and IBM's Bluemix using a the clounfoundry tools.      #
#	     Created by caseyr232 and davecapgemini            #
################################################################
# The following arguments are expected for the script to run.  #
# These should be passed as environment variables in wercker.  #
#							       #
# CF_USER  - The bluemix user you wish to authenticate as.     #
# CF_PASS  - The above users password.                         #
# CF_ORG   - The bluemix organisation to target.               #
# CF_SPACE - The bluemix space to target.                      #
# CF_API   - The regional approriate API endpoint for bluemix. #
# CF_CONTAINER - The desired name of your docker image.        #
# CF_PORTS - The ports you would like the container to listen  #
#          - on, can be specified as either a single "<PORT>"  #
#          - or by using "<EXTERNALPORT>:<INTERNALPORT>"       #
#          - should be "," delimited for multiples.            #
# LAUNCH_CMD - The entrypoint command for your container.      #
################################################################

declare -a VARS=($CF_USER $CF_PASS $CF_ORG $CF_SPACE $CF_API $CF_CONTAINER $CF_PORTS $LAUNCH_CMD)

# Checks that we have the correct number of variables we are expecting to run set. 
function checkvar {
  NumberOfVars=8
  if [ ${#VARS[@]} -le $NumberOfVars ];
    then
      for x in $(seq 1 $NumberOfVars); do
        if [ ${#VARS[$x]} -eq 0 ]; then
          echo "Only ${#VARS[@]} variables set, expecting $NumberOfVars"
          echo "I see: ${VARS[@]}"
        fi
      done
    else
      return 0;
  fi
}

#Authenticates us to Bluemix using the cloudfoundry tools and sets up our environment and keys.
function cfinit {
  cf login -u $CF_USER -p $CF_PASS -o $CF_ORG -s $CF_SPACE -a $CF_API
  cf ic init
}

#Check to see if a container is already running using the image we are trying to deploy.
function running {
  echo RUNNING - $1
  if [[ -z $1 ]];
    then
      echo "No existing containers running"
      return 1
    else
      echo "I see container with Container ID=$2"
      return 0
  fi
}

#Request an IP address from Bluemix.
function setip {
  IP_ADDRESS=$(cf ic ip request -q)
}

#Create our ports argument for the cf ic / docker run.
function buildports {
  IFS=',' read -ra PORTS <<< "$CF_PORTS"
  for element in "${PORTS[@]}"; do
    printf " -p $element "
  done
}

# Remove our old container and deploy with the same IP or deploy a new container with new IP if no previous container exists. 
function reprovision {
  if [ -z "$3" ];
    then
      IP_ADDRESS=$(echo $1 | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])')
    else
      IP_ADDRESS=$3
  fi
  if [[ -z "${2}" ]];
    then
      echo "No Previous container, we have nothing to remove".
    else
      cf ic rm $2 --force
  fi
  CONTAINERID=$(cf ic run $(buildports) $(if [ ! -z ${WORKDIR} ]; then echo -w=${WORKDIR}; fi) registry.eu-gb.bluemix.net/aie_london/$CF_CONTAINER $LAUNCH_CMD)
  cf ic ip bind $IP_ADDRESS $CONTAINERID
  return 0
}

checkvar
cfinit

IMAGE_NAME=${CF_CONTAINER}
CF_OUTPUT=$(cf ic ps -a --format 'table {{.ID}}|{{.Image}}|{{.Ports}}' |grep ${IMAGE_NAME})
RUNNING_CONTAINER=$(echo "$CF_OUTPUT" | grep $IMAGE_NAME | cut -d '|' -f 1)

if [ -z "${CF_DEBUG}"  ]; 
	then 
		echo "Debug not set" 
	else 
	 	set -x
		cf ic ps
		cf ic ip list
                cf ic info
		cf ic images
		printenv
		pwd
		ls
                cf ic inspect ${RUNNING_CONTAINER}
fi

running ${CF_OUTPUT} ${RUNNING_CONTAINER}

if [[ "$?" != "0" ]];
  then
    # Check if port exposed, if so request an ip, else return 0.
    if [[ -z "${CF_PORTS}" ]]; then
      echo "Set a port to obtain an ip, otherwise we assume none is required."
      return 0;
    else
      setip ${RUNNING_CONTAINER}
      reprovision ${CF_OUTPUT} ${RUNNING_CONTAINER} ${IP_ADDRESS}
      echo "Serving on: ${IP_ADDRESS}:${CF_PORTS}"
      # Post the status of our build to a webhook, in this case slack.
      curl -X POST -H 'Content-type: application/json' --data '{"text":"The wercker build of '"${WERCKER_GIT_REPOSITORY}"' branch '"${WERCKER_GIT_BRANCH}"' triggered by commit '"${WERCKER_GIT_COMMIT}"' has been completed.\n You can view the build at '"${WERCKER_RUN_URL}"'.\n This should now be listening on '"${IP_ADDRESS}"' and the following ports.\n '"${CF_PORTS}"'", "channel":"'"${NOTIFY}"'"}' ${NOTIFY_URL}
    fi
  else
    reprovision ${CF_OUTPUT} ${RUNNING_CONTAINER} ${IP_ADDRESS}
    echo "Serving on:  ${IP_ADDRESS}:${CF_PORTS}"
    # Post the status of our build to a webhook, in this case slack.
    curl -X POST -H 'Content-type: application/json' --data '{"text":"The wercker build of '"${WERCKER_GIT_REPOSITORY}"' branch '"${WERCKER_GIT_BRANCH}"' triggered by commit '"${WERCKER_GIT_COMMIT}"' has been completed.\n You can view the build at '"${WERCKER_RUN_URL}"'.\n This should now be listening on '"${IP_ADDRESS}"' and the following ports.\n '"${CF_PORTS}"'", "channel":"'"${NOTIFY}"'"}' ${NOTIFY_URL}
fi
