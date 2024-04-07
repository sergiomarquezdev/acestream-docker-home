#!/bin/bash

# Sustituye 127.0.0.1 con la IP interna en player.html.
sed -i "s/127.0.0.1/${INTERNAL_IP}/g" /opt/acestream/data/webui/html/player.html

# Inicia el motor Acestream.
exec /opt/acestream/start-engine "@/opt/acestream/acestream.conf"
