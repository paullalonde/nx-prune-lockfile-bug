#!/bin/bash

set -euo pipefail

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="${SELF_DIR}/.."

pushd "${BASE_DIR}" >/dev/null

rm -rf \
  .artifacts \
  .nyc_output \
  coverage \
  dist \
  dist-spec \
  node_modules \
  package-deps.json

popd >/dev/null
