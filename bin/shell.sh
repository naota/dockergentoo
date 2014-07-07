#!/bin/bash

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
