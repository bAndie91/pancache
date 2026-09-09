#!/bin/bash

set -e
set -o pipefail
set -u

install_dir=$1

apt-get $APT_OPTS install -y --no-install-recommends \
	git gcc libpython3-dev libffi-dev


git clone --progress ${GIT_URL_MITMPROXY} "$install_dir"
cd "$install_dir"

git checkout ${GIT_REF_MITMPROXY}
uv sync -v --frozen


pip cache purge || true
uv cache prune || true
rm -rf /root/.cache/
rm -rf /usr/{local/,}share/{doc,locale}
apt-get $APT_OPTS autoremove --purge -y git gcc libpython3-dev libffi-dev
apt-get clean
rm -rf /var/lib/apt/lists
