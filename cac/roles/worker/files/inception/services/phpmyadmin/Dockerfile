FROM debian:bookworm-slim

COPY scripts/ /docker-entrypoint-initdb.d/

ARG PKGS=

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y $PKGS \
	&& rm -rf /var/lib/apt/lists/*
