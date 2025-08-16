from mitmproxy import http
import os

def request(flow: http.HTTPFlow) -> None:
	target_host = flow.request.host
	flow.request.host = os.environ['STRIP_SSL_PROXY_UPSTREAM_HOST']
	flow.request.port = int(os.environ['STRIP_SSL_PROXY_UPSTREAM_PORT'])
	flow.request.headers["Host"] = target_host
	xff_prepend = flow.request.headers["X-Forwarded-For"] + "," if "X-Forwarded-For" in flow.request.headers else ''
	flow.request.headers["X-Forwarded-For"] = xff_prepend + flow.client_conn.address[0] + ':' + str(flow.client_conn.address[1])
	flow.request.headers["X-Forwarded-Scheme"] = flow.request.scheme
	flow.request.scheme = "http"
