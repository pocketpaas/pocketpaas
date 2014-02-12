FROM       ubuntu:12.04
MAINTAINER Nate Jones <nate@endot.org>

RUN apt-get update
RUN apt-get install git curl build-essential -y
RUN curl -L http://cpanmin.us | perl - App::cpanminus

WORKDIR /pps
ADD     . /pps
RUN     cpanm --installdeps . --force

RUN     git clone https://github.com/pocketpaas/servicepack.git /svp
ENV     PATH $PATH:/svp:/pps

# from http://docs.docker.io/en/latest/installation/ubuntulinux/
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
RUN echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
RUN apt-get update
RUN apt-get install lxc-docker -y

#ONBUILD ADD . /app
#ONBUILD WORKDIR /app

ENTRYPOINT ["pps"]
