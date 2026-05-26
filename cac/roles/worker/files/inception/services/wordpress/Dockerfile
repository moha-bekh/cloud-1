FROM debian:bookworm-slim

COPY scripts/ /docker-entrypoint-initdb.d/

ARG PKGS=

RUN apt-get update \
	&& apt-get install -y $PKGS \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html