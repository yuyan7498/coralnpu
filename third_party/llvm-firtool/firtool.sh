#!/bin/bash

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"
ROOTDIR="${SCRIPT_DIR}/../../"

FIRTOOL_EXE=$(find "${ROOTDIR}" -name 'firtool' -ipath '*linux-x64*' -print -quit)
if [[ -z "${FIRTOOL_EXE}" ]]; then
  echo "firtool not found under ${ROOTDIR}" 1>&2
  exit 1
fi

exec "${FIRTOOL_EXE}" "$@"
