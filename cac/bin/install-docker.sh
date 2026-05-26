#!/bin/bash

if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh
fi

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER

newgrp docker