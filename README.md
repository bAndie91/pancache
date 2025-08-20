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
  - mirror mode
    - the user addresses `http://pancache-mirror.local` via explicite proxy mode
    - the cache store can be downloaded, sync'ed to an other pancache instance (or anywhere for that matter)
    - see `http://pancache-mirror.local/index.meta4` for Metalink4-compatible file list
- automatically sync to other preset pancache instances
  - put `hostname:port` addresses line-by-line in `pancache/peers.txt` file (in the docker volume)
  - it periodically downloads newer cache items from these peers
  - so you can organize a pancache cluster for yourself

## Download

- source
  - http://git.uucp.hu/sysop/pancache
  - https://codeberg.org/hband/pancache.git
- available on Docker Hub (`docker pull hband/pancache`)
  - https://hub.docker.com/r/hband/pancache
  - https://cr.bitinfo.hu/pancache (TBD)

## Install

- run as a docker container
  - `docker run -d --name pancache -p 5003:5003 -v /mnt/drive/pancahce:/pancache hband/pancache`
- install on a host system
  - TBD

## Usage

- install the mitmproxy CA cert:
  - `curl -f -x http://localhost:5003 http://mitm.it/cert/pem > /etc/ssl/certs/pancache-mitmproxy.pem`
  - `update-ca-certificates`
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
