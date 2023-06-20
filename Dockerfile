FROM ubuntu:18.04 

WORKDIR /work
COPY . ./

RUN apt-get update
RUN apt-get install git -y
RUN apt-get install sudo -y

RUN sh ubuntu.sh

RUN make
RUN ./mininush tools/nuke 
RUN ./mininush tools/nuke install
RUN nuke test
