#!/bin/bash

VOL_DIR=$HOME/data

set -eu

for vol in $@; do
	if [ ! -d "$VOL_DIR/$vol" ]; then
		mkdir -p "$VOL_DIR/$vol"
		docker volume create \
			--driver local \
			--opt type=none \
			--opt device="$VOL_DIR/$vol" \
			--opt o=bind $vol
	fi
done