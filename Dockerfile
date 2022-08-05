# syntax=docker/dockerfile:1
 #FROM node:12-alpine
 FROM ubuntu:xenial
 #RUN apk add --no-cache python3 g++ make dpkg
 RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
 RUN apt install dpkg
 #RUN npm install --global yarn
 WORKDIR /app
 COPY . .
 COPY packages /packages
 RUN dpkg -i /packages/* && \
    mkdir /var/run/sshd
 #RUN yarn install --production
 CMD ["node", "src/index.js"]
