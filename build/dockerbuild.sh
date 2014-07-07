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

test -n "${package}" || exit 1

test -e /dev/fd || ln -sf /proc/self/fd /dev/fd
eselect news read new >/dev/null
export FEATURES="buildpkg parallel-install"
export ACCEPT_KEYWORDS="~amd64 amd64"
if [ -n "$flaggie" ]; then
  emerge -1k -j2 flaggie || exit 1
  eval "flaggie $flaggie" || exit 1
fi
test -d /overlay && export PORTDIR_OVERLAY="/overlay"
export CONFIG_PROTECT='-/etc'
before_emerge=$(find /etc/portage -ls | sha1sum)
exclude=$(qatom ${package} | awk '{if($1 == "(null)"){print $2}else{printf("%s/%s\n",$1,$2)}}')
common_args="-1k -j2 --usepkg-exclude ${exclude} "
emerge ${common_args} --autounmask-write $package
result=$?
after_emerge=$(find /etc/portage -ls | sha1sum)
if [ "${before_emerge}" = "${after_emerge}" ]; then
  test "${result}" = "0" || putlog
else
  emerge ${common_args} ${package} || putlog
fi
