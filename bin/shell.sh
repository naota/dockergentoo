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

ebuild=$1

NAMESPACE=${NAMESPACE:-$(whoami)}
DIR=${DIR:-$(realpath "$(dirname $0)/..")}

function cleanup {
  rm -rf $tmptree
  exit
}

volumes="-v ${DIR}/build:/build -v ${DIR}/result:/result "
if [ -n "${ebuild}" ]; then
    ebuilddir=$(realpath $(dirname ${ebuild}))
    portageroot=$(realpath ${ebuilddir}/../..)
    relativedir=${ebuilddir#${portageroot}/}
    tmptree=$(realpath $(dirname $0)/../tmp)/${RANDOM}
    trap cleanup SIGHUP SIGINT SIGTERM
    mkdir -p ${tmptree}/profiles ${tmptree}/metadata || exit 1
    tar -C ${portageroot} -cf - ${relativedir} | tar -C ${tmptree} -xf -
    echo "dockergentoo" > ${tmptree}/profiles/repo_name
    echo "masters = gentoo" > ${tmptree}/metadata/layout.conf
    volumes="${volumes} -v ${tmptree}:/overlay "
fi
mkdir -p ${DIR}/build ${DIR}/result
docker run -i -t --rm \
  --volumes-from portage --volumes-from distfiles \
  ${volumes} \
  ${NAMESPACE}/gentoo bash
cleanup
