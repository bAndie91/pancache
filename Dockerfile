FROM devuan/devuan:ceres-2025-08-16

ARG APT_OPTS=""
RUN apt-get ${APT_OPTS} update && \
	apt-get ${APT_OPTS} install -y --no-install-recommends \
		procps iputils-ping netcat-openbsd curl \
		libnginx-mod-http-perl \
		python3 python3-pip python3-venv pipx \
		perl libfile-slurp-perl libhtml-template-perl libtimedate-perl libipc-run-perl libxml-simple-perl \
		cron \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /usr/bin
COPY hband-tools/admin-tools/dmaster hband-tools/user-tools/metalink-sync-list hband-tools/user-tools/cdexec ./
COPY daemontab /etc/

ENV PATH="/root/.local/bin:${PATH}"
RUN pipx install uv

WORKDIR /mitmproxy
COPY mitmproxy/mitmproxy ./mitmproxy
COPY mitmproxy/pyproject.toml mitmproxy/uv.lock strip-proxy.py ./
ARG UV_DEFAULT_INDEX=""
ARG UV_INSECURE_HOST=""
RUN uv sync -v --frozen

WORKDIR /etc/nginx
COPY nginx/proxy ./proxy
COPY nginx/sites-enabled ./sites-enabled


VOLUME ["/pancache"]
EXPOSE 5003

WORKDIR /
CMD ["dmaster"]

# run sync from cron
# take peer list from /pancache/peers
