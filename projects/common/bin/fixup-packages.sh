#!/usr/bin/env bash

set -euo pipefail

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "${SELF_DIR}/../dist" >/dev/null

cat >cjs/package.json <<!EOF
{
    "type": "commonjs"
}
!EOF

cat >esm/package.json <<!EOF
{
    "type": "module"
}
!EOF

popd >/dev/null
