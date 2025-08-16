FROM debian:bookworm-slim

COPY apt-proxy.conf /etc/apt/apt.conf.d/
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		procps \
		libnginx-mod-http-perl \
		python3 python3-pip python3-venv pipx \
		perl-modules-5.36 libfile-slurp-perl libhtml-template-perl  \
		cron \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/bin
COPY hband-tools/admin-tools/dmaster* hband-tools/user-tools/metalink-sync-list hband-tools/user-tools/cdexec ./
COPY daemontab /etc/

ENV PATH="/root/.local/bin:${PATH}"
RUN pipx install uv

WORKDIR /mitmproxy
COPY mitmproxy/mitmproxy mitmproxy/pyproject.toml mitmproxy/uv.lock strip-proxy.py ./
ARG UV_DEFAULT_INDEX=""
RUN uv venv

WORKDIR /etc/nginx
COPY nginx/* ./


VOLUME ["/pancache"]
EXPOSE 5003

WORKDIR /
CMD ["dmaster"]

# run sync from cron
# take peer list from /pancache/peers
