FROM ubuntu:14.04 
MAINTAINER casey-capgem 

RUN apt-get update 
RUN apt-get install -y apt-transport-https ca-certificates curl wget
RUN apt-key adv --keyserver hkp://eu.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
RUN echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list
RUN apt-get update
RUN apt-get install -y docker-engine

RUN wget -q -O - 'https://cli.run.pivotal.io/stable?release=linux64-binary' | tar -xzf - -C /usr/local/bin 
RUN cf install-plugin -f https://static-ice.ng.bluemix.net/ibm-containers-linux_x64

