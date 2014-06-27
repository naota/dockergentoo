#!/bin/bash

test -n "${DOCKER_GENTOO_CONFIG}" && \
  test -r "${DOCKER_GENTOO_CONFIG}" && \
  source "${DOCKER_GENTOO_CONFIG}"

NAMESPACE=${NAMESPACE:-$(whoami)}
DIR=${DIR:-$(realpath "$(dirname $0)")}

# Update gentoo and portage container
${DIR}/build.sh gentoo && \
${DIR}/build.sh portage || exit 1
docker rm portage
if [ -z "$(docker ps -a|grep portage)" ]; then
  docker run -v /usr/portage --name portage ${NAMESPACE}/portage true
fi
