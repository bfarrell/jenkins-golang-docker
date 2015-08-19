FROM ubuntu:14.04
MAINTAINER Brendan Farrell <brendan_farrell@bmc.com>

# First, let us install Jenkins - as per https://github.com/cloudbees/jenkins-docker
RUN echo "0.13" > .version
RUN apt-get update
RUN echo deb http://pkg.jenkins-ci.org/debian binary/ >> /etc/apt/sources.list
RUN apt-get install -y wget
RUN wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | apt-key add -
RUN apt-get update
RUN apt-get install -y jenkins
RUN apt-get install -y git
RUN apt-get install -y make
RUN apt-get install -y gcc
ENV JENKINS_HOME /var/jenkins_home

# now we install docker in docker - thanks to https://github.com/jpetazzo/dind
RUN echo deb http://archive.ubuntu.com/ubuntu precise universe > /etc/apt/sources.list.d/universe.list
RUN apt-get update -qq
RUN apt-get install -qqy iptables ca-certificates
ADD https://get.docker.io/builds/Linux/x86_64/docker-latest /usr/local/bin/docker
ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/docker /usr/local/bin/wrapdocker
VOLUME /var/lib/docker

# Install go
ADD https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz /tmp/
RUN tar -xvf /tmp/go1.4.2.linux-amd64.tar.gz -C /opt
RUN ln -s /opt/go/bin/go /usr/local/bin/go
RUN mkdir /var/go
ENV GOPATH=/var/go
ENV GOROOT=/opt/go
ENV GOBIN=$GOROOT/bin
ENV PATH=$PATH:$GOBIN
RUN go get github.com/mitchellh/gox
RUN gox -build-toolchain

# Install docker-compose
ADD https://github.com/docker/compose/releases/download/1.3.2/docker-compose-Linux-x86_64 /tmp/
RUN mv /tmp/docker-compose-Linux-x86_64 /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# Make sure we exec to pass on signals correctly
CMD wrapdocker && exec java -jar /usr/share/jenkins/jenkins.war
