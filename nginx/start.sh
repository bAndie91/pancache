#!/bin/sh

perl -ne '/^\s*nameserver\s+(\S+)/ and print "resolver $1;\n"' < /etc/resolv.conf > /etc/nginx/conf.d/resolver.conf

exec nginx "$@"
