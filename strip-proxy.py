from mitmproxy import http
import os

def request(flow: http.HTTPFlow) -> None:
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
