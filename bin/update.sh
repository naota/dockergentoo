#!/bin/bash
#
# Copyright (C) 2014 Naohiro Aota <naota@gentoo.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

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
