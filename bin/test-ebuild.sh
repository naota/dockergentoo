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
