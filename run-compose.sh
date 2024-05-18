#!/bin/bash

mkdir -p /data/proxy/{conf.d,letsencrypt,webroot} /data/mysql
touch /data/proxy/conf.d/app.conf 
echo ${DOCKERHUB_PASSWORD} | docker login -u ${DOCKERHUB_USERNAME} --password-stdin
docker compose $@
docker system prune -af