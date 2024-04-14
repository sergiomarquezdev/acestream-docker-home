#!/bin/bash

# Replace 127.0.0.1 with the internal IP in player.html.
sed -i "s/127.0.0.1/${INTERNAL_IP}/g" /opt/acestream/data/webui/html/player.html

# Start the Acestream engine.
exec /opt/acestream/start-engine "@/opt/acestream/acestream.conf"
