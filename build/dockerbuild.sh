#!/bin/bash

putlog() {
  local x=${RANDOM}
  mkdir /result/${x}
  cd /var/tmp
  tar Jcf /result/${x}/portage.tar.xz portage
  echo The result put into result/${x}
}

flaggie=$1
package=$2

ln -sf /proc/self/fd /dev/fd && \
eselect news read new >/dev/null
export FEATURES=buildpkg
export ACCEPT_KEYWORDS="~amd64 amd64"
if [ -n "$flaggie" ]; then
  emerge -1k flaggie || exit 1
  eval "flaggie $flaggie" || exit 1
fi
CONFIG_PROTECT='-*' emerge -p --autounmask-write $package && \
  (emerge -1k $package || putlog)
