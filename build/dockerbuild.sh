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

putlog() {
  local x=${RANDOM}
  if [ -d /var/tmp/portage ]; then
      mkdir /result/${x}
      cd /var/tmp
      tar Jcf /result/${x}/portage.tar.xz portage
      echo The result put into result/${x}
  fi
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
export PORTAGE_ELOG_CLASSES="*"
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
