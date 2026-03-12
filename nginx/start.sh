#!/bin/sh

perl -ne '/^\s*nameserver\s+(\S+)/ and $n{$1}++; END { print "resolver ".join(" ", keys %n).";\n" }' < /etc/resolv.conf > /etc/nginx/conf.d/resolver.conf

exec nginx "$@"
