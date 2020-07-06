#!/bin/sh

# We launch nginx with a location.conf which specifies whether autoindex should
# be enabled or not.

rm -rf /etc/nginx/locations-enabled/*

TARGET_LOCATION="/etc/nginx/locations-enabled/location.conf"

if [ -n "$NOAUTOINDEX" ]; then
	ln -s /nginx/location_no_autoindex.conf $TARGET_LOCATION
	echo "Launching nginx without autoindex"
else
	ln -s /nginx/location_autoindex.conf $TARGET_LOCATION
	echo "Launching nginx with autoindex"
fi

nginx -g "daemon off;"
