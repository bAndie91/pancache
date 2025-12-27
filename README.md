# Pancache

Pancache is an opaque http/https forward proxy aiming to work offline,
ie. continue to serve any web resource to clients which were previously accessed when it was online.
This is done by storing all http responses (successful and errors too) in cache and serve them even when they become stale.

## Features

- based on nginx
- set response headers for debugging
  - `X-Cache-Status`: MISS, HIT, STALE, ...
  - `X-Cache-File`: filename under the cache storage directory
  - `Age`: seconds since the resource acquired
  - `Via`: `1.0`, hostname, and nginx version
- preserve the upstream's `Server` and `Date` headers among others
- HTTPS proxy by **mitmproxy**
  - mitmproxy sets these helper headers:
    - `X-Forwarded-For`
    - `X-Forwarded-Scheme`
- works in 3 access modes:
  - absolute-form / opaque / explicite proxy mode
    - the user sets up the proxy service address for his user-agent
  - application-level / "web-proxy" mode
    - accessing pancache as an orinary http service, no as a proxy
    - URLs look like `http://pancache.local:5003/https://example.net/example-page.html`, where
      - `pancache.local:5003` is your local pancache instance
      - works in http and https transport layers too
      - `https://example.net/example-page.html` verbatim in the place of the URL path is the internet resource's URL you want to access (and put in cache)
      - the internet resource's URL can be either http or https too
    - does NOT transform on-page URLs (anchor href, image sources, script sources, links, other references, etc)
      so absolute links will be BROKEN on sites visited this way.
      More useful for programmatic access rather than browser-interactive usage.
  - mirror mode
    - the user addresses pancache in explicite proxy mode, by the dedicated `pancache-mirror.local` domain name or by a private IP as http domain name, i.e.
      - `http://pancache-mirror.local:5003`
      - `http://127.0.0.1:5003` (any from the loopback range)
      - `http://192.168.x.y:5003` (any of RFC 1918 ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
    - the cache store can be downloaded, sync'ed to an other pancache instance (or anywhere for that matter)
    - see `http://pancache-mirror.local:5003/index.meta4` for Metalink4-compatible file list
- automatically sync to other preset pancache instances
  - put `hostname:port` addresses line-by-line in `pancache/peers.txt` file (in the docker volume)
  - it periodically downloads newer cache items from these peers
  - so you can organize a pancache cluster for yourself

## Build

- `make image`
  - to build the container image using the default build backend, which is `buildah`.
  - `make docker-image` to make the image using Docker
- upload to container registries
  - `make push OCI_REGISTRY_REPO=gitlab.com/hband-default`
  - `make push OCI_REGISTRY_REPO=registry-1.docker.io/hband`
- `make` variables:
  - `TAG` – override container image tag. Default is the current git commit (short) hash. You can change tags on the image after the build.
  - `DOCKER_PULL_http_proxy` and `DOCKER_PULL_https_proxy` – proxy addresses to pull base images (both for Docker and Buildah)
  - variables affecting the **build** process:
    - `DOCKER_BUILD_http_proxy`, and `DOCKER_BUILD_https_proxy` - general proxy address during the build sequence, usually empty
    - `APT_OPTS` – custom options for `apt-get` (eg. `-oAcquire::http::Proxy=http://acng.local:9999/`)
    - `PIP_INDEX_URL` and `PIP_TRUSTED_HOST` – custom index url for `pip` during the build, useful to fetch packages from your local PYPI cache
    - `UV_DEFAULT_INDEX` and `UV_INSECURE_HOST` – custom index url for `uv` during the build, useful to fetch packages from your local cache

## Download

- source
  - http://git.uucp.hu/sysop/pancache
  - https://codeberg.org/hband/pancache.git
- available on some Container Registries:
  - Docker Hub
    - https://hub.docker.com/r/hband/pancache
    - `docker pull hband/pancache`
  - GitLab
    - https://gitlab.com/hband-default/pancache/container_registry
    - `docker pull registry.gitlab.com/hband-default/pancache`
  - `docker pull cr.bitinfo.hu/hband/pancache`

## Install

- run as a docker container
  - `docker run -d --name pancache -p 5003:5003 -v /mnt/drive/pancahce:/pancache hband/pancache`
- install on a host system
  - TBD

## Usage

- install the mitmproxy CA cert:
  1. `curl -f -x http://localhost:5003 http://mitm.it/cert/pem > /etc/ssl/certs/pancache-mitmproxy.pem`
  1. `update-ca-certificates`
  1. `c_rehash`
- setup proxy:
  - `http_proxy=http://localhost:5003`
  - `https_proxy=http://localhost:5003`

## TODO

- space manager
  - delete old cache items to keep user-defined limit (`pancache/size-limit`)
- auto discover other pancache instances on LAN
  - multicast with docker networking
- distributed mode
  - don't neccessary sync other instance's cache store
  - but fetch those from there for the user in real time

## Issues, bugs, feature requests, ideas

1. clone the repo
2. use [git-bug](https://github.com/git-bug/git-bug) to open a new ticket within this repo
3. find one or more person in the commit history to make contact with, then either

   a. send the URL of your git clone to the other contributor(s), via E-mail or other channel, 
   requesting them to pull (`git-bug` issues and/or branches as well) from you.
   This is the preferred way, since it's easier to update your ticket, amend changes, and/or contibute later on.
   
   b. or, if you don't provide your repo's location, send your newly created `git-bug` ticket (or patch if you already propose a code change) via E-mail.
