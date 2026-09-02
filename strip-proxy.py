from mitmproxy import http, tls
from dataclasses import dataclass, asdict
import sys
import os
import signal
import re
import json


@dataclass
class TlsSummary:
	sni: str | None = None
	version: str | None = None
	cipher: str | None = None
	alpn: str | None = None


def tls_established_client(data: tls.TlsData) -> None:
	try:
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
	except:
		data.conn.error = True
		raise


def http_connect(flow: http.HTTPFlow) -> None:
	try:
		flow.client_conn._http_connect_seen = True
		flow.client_conn.http_connect_authority = flow.request.authority
		flow.client_conn.http_connect_host_header = flow.request.host_header
	except:
		flow.kill()
		raise


def requestheaders(flow: http.HTTPFlow) -> None:
	try:
		# extract conection data for diagnostics
		http_connect_authority = getattr(flow.client_conn, 'http_connect_authority', None)
		request_target = flow.request.raw_request_line.split()[1]
		request_target_match = re.search('^([^/]+)://([^/]+)', request_target.decode())
		if request_target_match:
			request_target_origin = request_target_match.group(0)
		else:
			request_target_origin = None
		
		# rewrite the request to go to the configured target
		target_host = flow.request.host
		target_scheme = flow.request.scheme
		flow.request.host = os.environ['STRIP_SSL_PROXY_UPSTREAM_HOST']
		flow.request.port = int(os.environ['STRIP_SSL_PROXY_UPSTREAM_PORT'])
		flow.request.scheme = "http"
		flow.request.headers["Host"] = target_host
		
		# set semi-standard reverse-proxy headers
		flow.request.headers["X-Real-IP"] = flow.client_conn.address[0]
		if "X-Forwarded-For" in flow.request.headers:
			xff_prepend = flow.request.headers["X-Forwarded-For"] + ", "
		else:
			xff_prepend = ''
		flow.request.headers["X-Forwarded-For"] = xff_prepend + flow.client_conn.address[0]
		flow.request.headers["X-Forwarded-Scheme"] = target_scheme
		
		# attach diagnostic info
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
	except:
		flow.kill()
		raise
