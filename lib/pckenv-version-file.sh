#!/usr/bin/env bash

set -uo pipefail;

function find_local_version_file() {
  log 'debug' "Looking for a version file in ${1}";

  local root="${1}";

  while ! [[ "${root}" =~ ^//[^/]*$ ]]; do

    if [ -e "${root}/.terraform-version" ]; then
      log 'debug' "Found at ${root}/.terraform-version";
      echo "${root}/.terraform-version";
      return 0;
    else
      log 'debug' "Not found at ${root}/.terraform-version";
    fi;

    [ -n "${root}" ] || break;
    root="${root%/*}";

  done;

  log 'debug' "No version file found in ${1}";
  return 1;
};
export -f find_local_version_file;

function pckenv-version-file() {
  if ! find_local_version_file "${pckenv_DIR:-${PWD}}"; then
    if ! find_local_version_file "${HOME:-/}"; then
      log 'debug' "No version file found in search paths. Defaulting to PCKENV_CONFIG_DIR: ${PCKENV_CONFIG_DIR}/version";
      echo "${PCKENV_CONFIG_DIR}/version";
    fi;
  fi;
};
export -f pckenv-version-file;
