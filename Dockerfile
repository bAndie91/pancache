FROM nginx:stable

COPY apt-proxy.conf /etc/apt/apt.conf.d/

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv pipx \
        perl-modules-5.36 libfile-slurp-perl libhtml-template-perl  \
        cron \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY hband-tools/admin-tools/dmaster* /usr/sbin/
COPY daemontab /etc/

ENV PATH="/root/.local/bin:${PATH}"
RUN pipx install uv

COPY mitmproxy/mitmproxy/ /mitmproxy/mitmproxy/
COPY mitmproxy/uv.locl /mitmproxy/
COPY strip-proxy.py /mitmproxy/

VOLUME ["/pancache"]

COPY nginx/* /etc/nginx/

COPY hband-tools/user-tools/metalink-sync-list /usr/bin/

EXPOSE 5003

CMD ["dmaster"]

# run sync from cron
# take peer list from /pancache/peers
