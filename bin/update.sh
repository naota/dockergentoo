#!/bin/bash

test -n "${DOCKER_GENTOO_CONFIG}" && \
  test -r "${DOCKER_GENTOO_CONFIG}" && \
  source "${DOCKER_GENTOO_CONFIG}"

NAMESPACE=${NAMESPACE:-$(whoami)}
DIR=${DIR:-$(realpath "$(dirname $0)")}

# Update gentoo and portage container
${DIR}/build.sh gentoo && \
${DIR}/build.sh portage || exit 1

RUNNING=$(docker ps -a | grep "${NAMESPACE}/portage" | awk '{print $2}')
LATEST_TAG=$(docker images naota/portage | grep -v TAG | grep -v latest | \
  awk '{print $2}'|head -n 1)
LATEST="${NAMESPACE}/portage:${LATEST_TAG}"
if [ -z "${RUNNING}" -o "${RUNNING}" != "${LATEST}" ]; then
  if [ -n "${RUNNING}" ]; then
    docker rm portage || exit 1
  fi
  docker run -v /usr/portage --name portage ${NAMESPACE}/portage true
fi

RUNNING=$(docker ps -a | grep "${NAMESPACE}/distfiles" | awk '{print $2}')
if [ -z "${RUNNING}" ]; then
  ${DIR}/build.sh busybox
  ${DIR}/build.sh distfiles
  docker run -v /usr/portage/distfiles -v /usr/portage/packages --name distfiles ${NAMESPACE}/distfiles true
fi
