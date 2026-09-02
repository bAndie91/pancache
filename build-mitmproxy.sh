#!/bin/bash

set -e
set -o pipefail
set -u

install_dir=$1

git clone --progress ${GIT_URL_MITMPROXY} "$install_dir"
cd "$install_dir"

git checkout ${GIT_REF_MITMPROXY}
uv sync -v --frozen
