# syntax=docker/dockerfile:1
 FROM node:12-alpine
 RUN apk add --no-cache python3 g++ make
 WORKDIR /app
 COPY . .
 COPY packages /packages
RUN dpkg -i /packages/* && \
    mkdir /var/run/sshd
 RUN yarn install --production
 CMD ["node", "src/index.js"]
