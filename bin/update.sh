#!/bin/bash

test -n "${DOCKER_GENTOO_CONFIG}" && \
  test -r "${DOCKER_GENTOO_CONFIG}" && \
  source "${DOCKER_GENTOO_CONFIG}"

NAMESPACE=${NAMESPACE:-$(whoami)}

# Update gentoo and portage container
./build.sh gentoo && \
./build.sh portage && \
docker rm portage
docker run -v /usr/portage --name portage ${NAMESPACE}/portage true
