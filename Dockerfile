# syntax=docker/dockerfile:1
 #FROM node:12-alpine
 FROM ubuntu:xenial
 #RUN apk add --no-cache python3 g++ make dpkg
 RUN apt install dpkg
 WORKDIR /app
 COPY . .
 COPY packages /packages
 RUN dpkg -i /packages/* && \
    mkdir /var/run/sshd
 RUN yarn install --production
 CMD ["node", "src/index.js"]
