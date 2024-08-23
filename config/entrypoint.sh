#!/bin/bash

# Replace 127.0.0.1 with the internal IP and update the port in player.html
sed -i "s|http://127.0.0.1:6878/|http://${INTERNAL_IP}:${HTTP_PORT}/|g" /opt/acestream/data/webui/html/player.html

# Start the Acestream engine with the specified HTTP port
exec /opt/acestream/start-engine --http-port ${HTTP_PORT} --https-port ${HTTPS_PORT} "@/opt/acestream/acestream.conf"
