FROM debian:bookworm-slim

ARG APT_OPTS=""
RUN apt-get ${APT_OPTS} update && \
	apt-get ${APT_OPTS} install -y --no-install-recommends \
		procps iputils-ping netcat-openbsd curl \
		libnginx-mod-http-perl \
		python3 python3-pip python3-venv pipx \
		perl-modules-5.36 libfile-slurp-perl libhtml-template-perl  \
		cron \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/bin
COPY hband-tools/admin-tools/dmaster hband-tools/user-tools/metalink-sync-list hband-tools/user-tools/cdexec ./
COPY daemontab /etc/

ENV PATH="/root/.local/bin:${PATH}"
RUN pipx install uv

WORKDIR /mitmproxy
COPY mitmproxy/mitmproxy mitmproxy/pyproject.toml mitmproxy/uv.lock strip-proxy.py ./
ARG UV_DEFAULT_INDEX=""
RUN uv sync --frozen

WORKDIR /etc/nginx
COPY nginx/proxy nginx/sites-enabled ./


VOLUME ["/pancache"]
EXPOSE 5003

WORKDIR /
CMD ["dmaster"]

# run sync from cron
# take peer list from /pancache/peers
