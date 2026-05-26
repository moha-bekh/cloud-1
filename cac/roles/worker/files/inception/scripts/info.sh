#!/bin/bash

set -eu

VOL_DIR=$HOME/data

echo -e "\nContainers:"
docker ps -a

echo -e "\nImages:"
docker images

echo -e "\nNetworks:"
docker network ls

echo -e "\nVolumes:"
docker volume ls

if [ -d $VOL_DIR ]; then
	echo -e "\n$VOL_DIR contents:"
	ls -alt $VOL_DIR 2>/dev/null || true
fi