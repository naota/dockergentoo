#!/bin/bash

test -n "${DOCKER_GENTOO_CONFIG}" && \
  test -r "${DOCKER_GENTOO_CONFIG}" && \
  source "${DOCKER_GENTOO_CONFIG}"

NAMESPACE=${NAMESPACE:-$(whoami)}
SERVER=${SERVER:-http://distfiles.gentoo.org}
DIR=${DIR:-$(dirname $0)/..}

FILES=${FILES:-files}
STAGE3_PREFIX=/releases/amd64/autobuilds/
STAGE3_TEXT=latest-stage3-amd64.txt
STAGE3_TEXT_URL=${SERVER}${STAGE3_PREFIX}${STAGE3_TEXT}
PORTAGE_PREFIX=/snapshots/
PORTAGE_TEXT_URL=${SERVER}${PORTAGE_PREFIX}
GPG_KEYSERVER=${GPG_KEYSERVER:-pgp.mit.edu}
GPG_KEYID_STAGE3=${GPG_KEYID_STAGE3:-0x2D182910}
GPG_KEYID_PORTAGE=${GPG_KEYID_PORTAGE:-0x96D8BF6D}

AWK=${AWK:-$(command -v awk)}
CURL=${CURL:-$(command -v curl)}
DOCKER=${DOCKER:-$(command -v docker)}
GPG=${GPG:-$(command -v gpg)}
GREP=${GREP:-$(command -v grep)}
REALPATH=${REALPATH:-$(command -v realpath)}
SHA512SUM=${SHA512SUM:-$(command -v sha512sum)}
TAIL=${TAIL:-$(command -v tail)}
TAR=${TAR:-$(command -v tar)}
WGET=${WGET:-$(command -v wget)}
SED=${SED:-$(command -v sed)}

repo_exists()
{
    local REPO=$1
    local TAG=$2
    ${DOCKER} images ${REPO} | ${AWK} '{print $2}' | ${TAIL} -n +2 | ${GREP} -q "${TAG}"
}

die() {
    echo "$1"
    exit 1
}

fetchkey() {
    key=$1
    ${GPG} -k ${key} >/dev/null || \
	${GPG} --keyserver ${GPG_KEYSERVER} --recv-key ${key} || die "Failed to fetch key"
}

test -n "${NAMESPACE}" || die "Please set NAMESPACE"
test -n "${MAINTAINER}"  || die "Please set MAINTAINER"

build_gentoo() {
    local STAGE3=$(${CURL} ${STAGE3_TEXT_URL} | ${GREP} -v '#')
    local STAGE3_URL=${SERVER}${STAGE3_PREFIX}${STAGE3}
    local STAGE3_DIGESTS_URL=${SERVER}${STAGE3_PREFIX}${STAGE3}.DIGESTS.asc
    local STAGE3_FILENAME=$(basename ${STAGE3})
    local STAGE3_DIGESTS_FILENAME=${STAGE3_FILENAME}.DIGESTS.asc

    local x=${STAGE3_FILENAME%.tar.bz2}
    local DATE=${x#stage3-amd64-}

    if ! repo_exists "${NAMESPACE}/gentoo" "${DATE}"; then
      mkdir -p "${FILES}"
      ${WGET} -c ${STAGE3_URL} -P "${FILES}" || die "Failed to download stage3 file"
      ${WGET} -c ${STAGE3_DIGESTS_URL} -P "${FILES}" || die "Failed to download stage3 digest file"
      fetchkey ${GPG_KEYID_STAGE3}
      ${GPG} --verify "${FILES}/${STAGE3_DIGESTS_FILENAME}" || die "Insecure digests"

      local SHA512_HASHES=$(${GREP} -A 1 "# SHA512 HASH" "${FILES}/${STAGE3_DIGESTS_FILENAME}" | head -n 2)
      local SHA512_CHECK=$(cd "${FILES}" && (echo "${SHA512_HASHES}" | ${SHA512SUM} -c))
      local SHA512_FAILED=$(echo "${SHA512_CHECK}" | grep FAILED)
      test -n "${SHA512_FAILED}" && die "${SHA512_FAILED}"

      bzcat "${FILES}"/${STAGE3_FILENAME} | \
      ${DOCKER} import - "${NAMESPACE}/gentoo:${DATE}" || die "failed to import"
    fi
    ${DOCKER} tag -f "${NAMESPACE}/gentoo:${DATE}" "${NAMESPACE}/gentoo:latest" || die "failed to tag"
}

build_portage() {
    local PORTAGE=$(${CURL} ${PORTAGE_TEXT_URL} | \
      ${AWK} 'match($0, /href="portage-[0-9]+.tar.xz"/){print substr($0,RSTART+6,RLENGTH-7)}' | \
      tail -n 1)
    local PORTAGE_URL=${SERVER}${PORTAGE_PREFIX}${PORTAGE}
    local PORTAGE_GPGSIG_URL=${SERVER}${PORTAGE_PREFIX}${PORTAGE}.gpgsig
    local PORTAGE_FILENAME=$(basename ${PORTAGE})
    local PORTAGE_GPGSIG_FILENAME=${PORTAGE_FILENAME}.gpgsig

    local x=${PORTAGE_FILENAME%.tar.xz}
    local DATE=${x#portage-}

    if ! repo_exists "${NAMESPACE}/portage-import" "${DATE}"; then
      ${WGET} -c ${PORTAGE_URL} -P "${FILES}" || die "Failed to download portage file"
      ${WGET} -c ${PORTAGE_GPGSIG_URL} -P "${FILES}" || die "Failed to download portage signature file"
      fetchkey ${GPG_KEYID_PORTAGE}
      ${GPG} --verify "${FILES}/${PORTAGE_GPGSIG_FILENAME}" "${FILES}/${PORTAGE_FILENAME}" || die "Insecure digests"
      ${DOCKER} import - "${NAMESPACE}/portage-import:${DATE}" \
        < "${FILES}/${PORTAGE_FILENAME}" || die "failed to import"
    fi
    ${DOCKER} tag -f "${NAMESPACE}/portage-import:${DATE}" "${NAMESPACE}/portage-import:latest" \
      || die "failed to tag"
}

extract_busybox()
{
  SUBDIR=$1
  THIS_DIR=$(${REALPATH} .)
  CONTAINER="${NAMESPACE}-gentoo-latest-extract-busybox"
  mkdir -p "${THIS_DIR}/${SUBDIR}"
  "${DOCKER}" run --name "${CONTAINER}" -v "${THIS_DIR}/${SUBDIR}/":/tmp \
    "${NAMESPACE}/gentoo:latest" cp /bin/busybox /tmp/ || die "Failed to copy busybox"
  "${DOCKER}" rm "${CONTAINER}" || die "Failed to remove ${CONTAINER}"
}

build_repo()
{
	local REPO=$1
	local TAG=$2
	test -n "${REPO}" || die "Invalid REPO"
	test -n "${TAG}" || die "Invalid TAG"

	if ! repo_exists "${NAMESPACE}/${REPO}" "${TAG}"; then
		${SED} -e "s/\${NAMESPACE}/${NAMESPACE}/" -e "s/\${TAG}/${TAG}/" -e "s/\${MAINTAINER}/${MAINTAINER}/" "${REPO}/Dockerfile.template" > "${REPO}/Dockerfile"

		"${DOCKER}" build -t "${NAMESPACE}/${REPO}:${TAG}" "${REPO}" || die "failed to build"
	fi
	"${DOCKER}" tag -f "${NAMESPACE}/${REPO}:${TAG}" "${NAMESPACE}/${REPO}:latest" || die "failed to tag"
}

cd ${DIR}
ACTION="${1:-all}"
case "${ACTION}" in
gentoo) build_gentoo ;;
portage)
	build_portage
	PORTAGE_DATE=$(${DOCKER} images "${NAMESPACE}/portage-import" |
	    ${AWK} '$2 != "latest" && $2 != "TAG"{print $2;exit}')
	if ! repo_exists "${NAMESPACE}/portage" "${PORTAGE_DATE}"; then
	  extract_busybox portage
	  build_repo portage ${PORTAGE_DATE}
  fi
	;;
busybox)
	extract_busybox tmp
  cd tmp; mkdir -p bin; mv -f busybox bin/sh
	STAGE3_DATE=$(${DOCKER} images "${NAMESPACE}/gentoo" |
	    ${AWK} '$2 != "latest" && $2 != "TAG"{print $2;exit}')
  test -z "${STAGE3_DATE}" && die "No stage3 date"
  ${TAR} cf - bin | ${DOCKER} import - "${NAMESPACE}/busybox:${STAGE3_DATE}" || die "failed to import"
  ${DOCKER} tag -f ${NAMESPACE}/busybox:${STAGE3_DATE} ${NAMESPACE}/busybox:latest || die "failed to tag"
	;;
*)
	STAGE3_DATE=$(${DOCKER} images "${NAMESPACE}/gentoo" |
	    ${AWK} '$2 != "latest" && $2 != "TAG"{print $2;exit}')
	PORTAGE_DATE=$(${DOCKER} images "${NAMESPACE}/portage-import" |
	    ${AWK} '$2 != "latest" && $2 != "TAG"{print $2;exit}')
	if [ -d "${ACTION}" ]; then
	    build_repo "${ACTION}" "${STAGE3_DATE}"
	else
	    die "invalid action ${ACTION}"
	fi
	;;
esac
