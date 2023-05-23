#!/usr/bin/env bash

set -uo pipefail;

function pckenv-exec() {
  for _arg in ${@:1}; do
    if [[ "${_arg}" == -chdir=* ]]; then
      log 'debug' "Found -chdir arg. Setting PCKENV_DIR to: ${_arg#-chdir=}";
      export PCKENV_DIR="${PWD}/${_arg#-chdir=}";
    fi;
  done;

  log 'debug' 'Getting version from pckenv-version-name';
  PCKENV_VERSION="$(pckenv-version-name)" \
    && log 'debug' "PCKENV_VERSION is ${PCKENV_VERSION}" \
    || {
      # Errors will be logged from pckenv-version name,
      # we don't need to trouble STDERR with repeat information here
      log 'debug' 'Failed to get version from pckenv-version-name';
      return 1;
    };
  export PCKENV_VERSION;

  if [ ! -d "${pckenv_CONFIG_DIR}/versions/${PCKENV_VERSION}" ]; then
  if [ "${PCKENV_AUTO_INSTALL:-true}" == "true" ]; then
    if [ -z "${PCKENV_PACKER_VERSION:-""}" ]; then
      PCKENV_VERSION_SOURCE="$(pckenv-version-file)";
    else
      PCKENV_VERSION_SOURCE='PCKENV_PACKER_VERSION';
    fi;
      log 'info' "version '${PCKENV_VERSION}' is not installed (set by ${PCKENV_VERSION_SOURCE}). Installing now as PCKENV_AUTO_INSTALL==true";
      pckenv-install;
    else
      log 'error' "version '${PCKENV_VERSION}' was requested, but not installed and PCKENV_AUTO_INSTALL is not 'true'";
    fi;
  fi;

  PCK_BIN_PATH="${pckenv_CONFIG_DIR}/versions/${PCKENV_VERSION}/packer";
  export PATH="${PCK_BIN_PATH}:${PATH}";
  log 'debug' "PCK_BIN_PATH added to PATH: ${PCK_BIN_PATH}";
  log 'debug' "Executing: ${PCK_BIN_PATH} $@";

  exec "${PCK_BIN_PATH}" "$@" \
  || log 'error' "Failed to execute: ${PCK_BIN_PATH} $*";

  return 0;
};
export -f pckenv-exec;
