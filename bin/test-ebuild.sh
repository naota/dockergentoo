#!/bin/bash

flags=$1
ebuild=$2

if [ ${ebuild} = ${ebuild%.ebuild} ]; then
  echo "Usage: $0 <flags> <ebuild>"
  exit 1
fi

if [ ! -r ${ebuild} ]; then
    echo "Cannot read ${ebuild}"
    exit 1
fi

ebuilddir=$(realpath $(dirname ${ebuild}))
portageroot=$(realpath ${ebuilddir}/../..)
relativedir=${ebuilddir#${portageroot}/}
tmptree=$(realpath $(dirname $0)/../tmp)/${RANDOM}
bindir=$(realpath $(dirname $0))
category=$(dirname ${relativedir})
target="=${category}/$(basename ${ebuild%.ebuild})::dockergentoo"

function cleanup {
  rm -rf $tmptree
  exit
}

trap cleanup SIGHUP SIGINT SIGTERM
mkdir -p ${tmptree}/profiles ${tmptree}/metadata || exit 1
tar -C ${portageroot} -cf - ${relativedir} | tar -C ${tmptree} -xf -
echo "dockergentoo" > ${tmptree}/profiles/repo_name
echo "masters = gentoo" > ${tmptree}/metadata/layout.conf
${bindir}/build-package.sh "${flags}" "${target}" "${tmptree}"
cleanup
