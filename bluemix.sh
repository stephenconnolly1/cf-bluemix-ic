#!/usr/bin/env bash

declare -a VARS=($CF_USER $CF_PASS $CF_ORG $CF_SPACE $CF_API $CF_CONTAINER $CF_PORTS $LAUNCH_CMD)

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

function cfinit {
  cf login -u $CF_USER -p $CF_PASS -o $CF_ORG -s $CF_SPACE -a $CF_API
  cf ic init
}

function running {
  echo RUNNING - $1
  if [[ -z $1 ]];
    then
      return 1
    else
      echo "Container ID=$2"
      return 0
  fi
}

function setip {
  IP_ADDRESS=$(cf ic ip request -q)
}

function buildports {
  IFS=',' read -ra PORTS <<< "$CF_PORTS"
  for element in "${PORTS[@]}"; do
    printf " -p $element "
  done
}


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
  CONTAINERID=$(cf ic run $(buildports) registry.eu-gb.bluemix.net/aie_london/$CF_CONTAINER $LAUNCH_CMD)
  cf ic ip bind $IP_ADDRESS $CONTAINERID
  return 0
}

checkvar
cfinit

IMAGE_NAME=${CF_CONTAINER}
CF_OUTPUT=$(cf ic ps --format 'table {{.ID}}|{{.Image}}|{{.Ports}}' |grep ${IMAGE_NAME})
RUNNING_CONTAINER=$(echo "$CF_OUTPUT" | grep $IMAGE_NAME | cut -d '|' -f 1)

running ${CF_OUTPUT} ${RUNNING_CONTAINER}

if [[ "$?" != "0" ]];
  then
    # check if port exposed, if so request an ip, else return 0.
    if [[ -z "${CF_PORTS}" ]]; then
      echo "Set a port to obtain an ip, otherwise we assume none is required."
      return 0;
    else
      setip ${RUNNING_CONTAINER}
      reprovision ${CF_OUTPUT} ${RUNNING_CONTAINER} ${IP_ADDRESS}
      echo "Serving on: ${IP_ADDRESS}:${CF_PORTS}"
      curl -X POST -H 'Content-type: application/json' --data '{"text":"The wercker build of ${WERCKER_GIT_REPOSITORY} branch ${WERCKER_GIT_BRANCH} triggered by commit ${WERCKER_GIT_COMMIT} has been completed.\n You can view the build at ${WERCKER_RUN_URL}.\n This should now be listening on ${IP_ADDRESS} and the following ports.\n ${CF_PORTS}", "channel":"#${NOTIFY}"}' ${NOTIFY_URL}
    fi
  else
    reprovision ${CF_OUTPUT} ${RUNNING_CONTAINER} ${IP_ADDRESS}
    echo "Serving on:  ${IP_ADDRESS}:${CF_PORTS}"
    curl -X POST -H 'Content-type: application/json' --data '{"text":"The wercker build of ${WERCKER_GIT_REPOSITORY} branch ${WERCKER_GIT_BRANCH} triggered by commit ${WERCKER_GIT_COMMIT} has been completed.\n You can view the build at ${WERCKER_RUN_URL}.\n This should now be listening on ${IP_ADDRESS} and the following ports.\n ${CF_PORTS}", "channel":"#${NOTIFY}"}' ${NOTIFY_URL}
fi
