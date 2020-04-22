#!/bin/bash

sleep 30

snap install docker
systemctl enable snap.docker.dockerd
systemctl start snap.docker.dockerd

sleep 30

eval ${DOCKER_COMMAND}

