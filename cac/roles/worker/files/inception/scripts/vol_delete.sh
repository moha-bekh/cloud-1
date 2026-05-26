#!/bin/bash

VOL_DIR=$HOME/data

for vol in $@; do
	if docker volume inspect "$vol" &>/dev/null; then
		docker volume rm "$vol"
	fi
done
