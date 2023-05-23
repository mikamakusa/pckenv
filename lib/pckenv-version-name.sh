#!/usr/bin/env bash

set -uo pipefail;

function pckenv-version-name() {
  if [[ -z "${PCKENV_PACKER_VERSION:-""}" ]]; then
    log 'debug' 'We are not hardcoded by a PCKENV_PACKER_VERSION environment variable';

    PCKENV_VERSION_FILE="$(pckenv-version-file)" \
      && log 'debug' "PCKENV_VERSION_FILE retrieved from pckenv-version-file: ${PCKENV_VERSION_FILE}" \
      || log 'error' 'Failed to retrieve PCKENV_VERSION_FILE from pckenv-version-file';

    PCKENV_VERSION="$(cat "${PCKENV_VERSION_FILE}" || true)" \
      && log 'debug' "PCKENV_VERSION specified in PCKENV_VERSION_FILE: ${PCKENV_VERSION}";

    PCKENV_VERSION_SOURCE="${PCKENV_VERSION_FILE}";

  else
    PCKENV_VERSION="${PCKENV_PACKER_VERSION}" \
      && log 'debug' "PCKENV_VERSION specified in PCKENV_PACKER_VERSION environment variable: ${PCKENV_VERSION}";

    PCKENV_VERSION_SOURCE='PCKENV_PACKER_VERSION';
  fi;

  local auto_install="${PCKENV_AUTO_INSTALL:-true}";

  if [[ "${PCKENV_VERSION}" == "min-required" ]]; then
    log 'debug' 'PCKENV_VERSION uses min-required keyword, looking for a required_version in the code';

    local potential_min_required="$(pckenv-min-required)";
    if [[ -n "${potential_min_required}" ]]; then
      log 'debug' "'min-required' converted to '${potential_min_required}'";
      PCKENV_VERSION="${potential_min_required}" \
      PCKENV_VERSION_SOURCE='packer{required_version}';
    else
      log 'error' 'Specifically asked for min-required via packer{required_version}, but none found';
    fi;
  fi;

  if [[ "${PCKENV_VERSION}" =~ ^latest.*$ ]]; then
    log 'debug' "PCKENV_VERSION uses 'latest' keyword: ${PCKENV_VERSION}";

    if [[ "${PCKENV_VERSION}" == latest-allowed ]]; then
        PCKENV_VERSION="$(pckenv-resolve-version)";
        log 'debug' "Resolved latest-allowed to: ${PCKENV_VERSION}";
    fi;

    if [[ "${PCKENV_VERSION}" =~ ^latest\:.*$ ]]; then
      regex="${PCKENV_VERSION##*\:}";
      log 'debug' "'latest' keyword uses regex: ${regex}";
    else
      regex="^[0-9]\+\.[0-9]\+\.[0-9]\+$";
      log 'debug' "Version uses latest keyword alone. Forcing regex to match stable versions only: ${regex}";
    fi;

    declare local_version='';
    if [[ -d "${PCKENV_CONFIG_DIR}/versions" ]]; then
      local_version="$(\find "${PCKENV_CONFIG_DIR}/versions/" -type d -exec basename {} \; \
        | tail -n +2 \
        | sort -t'.' -k 1nr,1 -k 2nr,2 -k 3nr,3 \
        | grep -e "${regex}" \
        | head -n 1)";

      log 'debug' "Resolved ${PCKENV_VERSION} to locally installed version: ${local_version}";
    elif [[ "${auto_install}" != "true" ]]; then
      log 'error' 'No versions of packer installed and PCKENV_AUTO_INSTALL is not true. Please install a version of packer before it can be selected as latest';
    fi;

    if [[ "${auto_install}" == "true" ]]; then
      log 'debug' "Using latest keyword and auto_install means the current version is whatever is latest in the remote. Trying to find the remote version using the regex: ${regex}";
      remote_version="$(pckenv-list-remote | grep -e "${regex}" | head -n 1)";
      if [[ -n "${remote_version}" ]]; then
          if [[ "${local_version}" != "${remote_version}" ]]; then
            log 'debug' "The installed version '${local_version}' does not much the remote version '${remote_version}'";
            PCKENV_VERSION="${remote_version}";
          else
            PCKENV_VERSION="${local_version}";
          fi;
      else
        log 'error' "No versions matching '${requested}' found in remote";
      fi;
    else
      if [[ -n "${local_version}" ]]; then
        PCKENV_VERSION="${local_version}";
      else
        log 'error' "No installed versions of packer matched '${PCKENV_VERSION}'";
      fi;
    fi;
  else
    log 'debug' 'PCKENV_VERSION does not use "latest" keyword';

    # Accept a v-prefixed version, but strip the v.
    if [[ "${PCKENV_VERSION}" =~ ^v.*$ ]]; then
      log 'debug' "Version Requested is prefixed with a v. Stripping the v.";
      PCKENV_VERSION="${PCKENV_VERSION#v*}";
    fi;
  fi;

  if [[ -z "${PCKENV_VERSION}" ]]; then
    log 'error' "Version could not be resolved (set by ${PCKENV_VERSION_SOURCE} or pckenv use <version>)";
  fi;

  if [[ "${PCKENV_VERSION}" == min-required ]]; then
    PCKENV_VERSION="$(pckenv-min-required)";
  fi;

  if [[ ! -d "${PCKENV_CONFIG_DIR}/versions/${PCKENV_VERSION}" ]]; then
    log 'debug' "version '${PCKENV_VERSION}' is not installed (set by ${PCKENV_VERSION_SOURCE})";
  fi;

  echo "${PCKENV_VERSION}";
};
export -f pckenv-version-name;

