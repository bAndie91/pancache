from mitmproxy import http, tls
from dataclasses import dataclass, asdict
from typing import Optional
import sys
import os
import re
import json

# {{{
# Monkey-patch mitmproxy to preserve HTTP request line

from mitmproxy.net.http.http1 import read as http1_read

read_request_head_orig = http1_read.read_request_head

def read_request_head_patched(lines):
    req = read_request_head_orig(lines)
    req.raw_request_line = lines[0]   # bytes, verbatim off the wire
    return req

http1_read.read_request_head = read_request_head_patched

# }}}


@dataclass
class TlsSummary:
	sni: str | None = None
	version: str | None = None
	cipher: str | None = None
	alpn: str | None = None


def tls_established_client(data: tls.TlsData) -> None:
	tls_info = TlsSummary(
		sni = data.context.client.sni,
		version = data.context.client.tls_version,
		cipher = data.context.client.cipher,
		alpn = data.context.client.alpn_proto_negotiated,
	)
	if getattr(data.context.client, "_http_connect_seen", False):
		# handshake happened after a CONNECT -> tunnel TLS
		data.context.client.inner_tls = tls_info
	else:
		# handshake happened before any CONNECT, thus TLS session between the client and proxy
		data.context.client.outer_tls = tls_info


def http_connect(flow: http.HTTPFlow) -> None:
	flow.client_conn._http_connect_seen = True
	flow.client_conn.http_connect_authority = flow.request.authority
	flow.client_conn.http_connect_host_header = flow.request.host_header


def requestheaders(flow: http.HTTPFlow) -> None:
	http_connect_authority = getattr(flow.client_conn, 'http_connect_authority', None)
	request_target = flow.request.raw_request_line.split()[1]
	request_target_match = re.search('^([^/]+)://([^/]+)', request_target.decode())
	if request_target_match:
		request_target_origin = request_target_match.group(0)
	else:
		request_target_origin = None
	
	target_host = flow.request.host
	flow.request.host = os.environ['STRIP_SSL_PROXY_UPSTREAM_HOST']
	flow.request.port = int(os.environ['STRIP_SSL_PROXY_UPSTREAM_PORT'])
	
	flow.request.headers["Host"] = target_host
	flow.request.headers["X-Real-IP"] = flow.client_conn.address[0]
	if "X-Forwarded-For" in flow.request.headers:
		xff_prepend = flow.request.headers["X-Forwarded-For"] + ", "
	else:
		xff_prepend = ''
	flow.request.headers["X-Forwarded-For"] = xff_prepend + flow.client_conn.address[0]
	
	flow.request.headers["X-Forwarded-Scheme"] = flow.request.scheme
	flow.request.scheme = "http"
	
	flow.request.headers["X-Proxy-Client-Connection-Details"] = json.dumps({
		"tls": {
			"outer": asdict(getattr(flow.client_conn, "outer_tls", TlsSummary())),
			"inner": asdict(getattr(flow.client_conn, "inner_tls", TlsSummary())),
		},
		"http_connect": {
			"target": http_connect_authority,
			"host_header": getattr(flow.client_conn, 'http_connect_host_header', None),
		},
		"request": {
			"target_origin": request_target_origin,
			"host_header": flow.request.host_header,
		},
	})
