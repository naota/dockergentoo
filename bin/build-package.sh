#!/bin/bash

test -n "${DOCKER_GENTOO_CONFIG}" && \
  test -r "${DOCKER_GENTOO_CONFIG}" && \
  source "${DOCKER_GENTOO_CONFIG}"

NAMESPACE=${NAMESPACE:-$(whoami)}
DIR=${DIR:-$(realpath "$(dirname $0)/..")}
flag=$1
package=$2
overlay=$3

if [ -z "${package}" ]; then
  echo "Usage: $0 <flags> <package> [<overlay>]"
  exit 1
fi

volumes="-v ${DIR}/build:/build -v ${DIR}/result:/result "
test -n "${overlay}" && volumes="${volumes} -v ${overlay}:/overlay "
mkdir -p ${DIR}/build ${DIR}/result
docker run -i -t --rm \
  --volumes-from portage --volumes-from distfiles \
  ${volumes} \
  ${NAMESPACE}/gentoo bash /build/dockerbuild.sh "${flag}" "${package}"
