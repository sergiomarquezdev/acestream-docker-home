#!/bin/bash

# ================================================
# ACESTREAM DOCKER ENTRYPOINT
# Enhanced with logging and error handling
# ================================================

set -e  # Exit on any error

# === LOGGING SETUP ===
echo "=== ACESTREAM DOCKER STARTUP ==="
echo "Timestamp: $(date)"
echo "Internal IP: ${INTERNAL_IP}"
echo "HTTP Port: ${HTTP_PORT}"
echo "HTTPS Port: ${HTTPS_PORT}"
echo "Extra Flags: ${ACESTREAM_EXTRA_FLAGS:-none}"

# === CONFIGURATION VALIDATION ===
echo "=== VALIDATING CONFIGURATION ==="

# Validate required environment variables
if [ -z "${INTERNAL_IP}" ]; then
    echo "ERROR: INTERNAL_IP environment variable not set"
    exit 1
fi

if [ -z "${HTTP_PORT}" ]; then
    echo "ERROR: HTTP_PORT environment variable not set"
    exit 1
fi

if [ -z "${HTTPS_PORT}" ]; then
    echo "ERROR: HTTPS_PORT environment variable not set"
    exit 1
fi

# Validate acestream.conf exists
if [ ! -f "/opt/acestream/acestream.conf" ]; then
    echo "ERROR: acestream.conf not found"
    exit 1
fi

echo "Configuration validation: OK"

# === PLAYER HTML CONFIGURATION ===
echo "=== CONFIGURING PLAYER HTML ==="
if [ -f "/opt/acestream/data/webui/html/player.html" ]; then
    sed -i "s|http://127.0.0.1:6878/|http://${INTERNAL_IP}:${HTTP_PORT}/|g" /opt/acestream/data/webui/html/player.html
    echo "Player HTML configured successfully"
else
    echo "WARNING: player.html not found, skipping configuration"
fi

# === ACESTREAM ENGINE STARTUP ===
echo "=== STARTING ACESTREAM ENGINE ==="
echo "Command: /opt/acestream/start-engine --http-port ${HTTP_PORT} --https-port ${HTTPS_PORT} ${ACESTREAM_EXTRA_FLAGS} \"@/opt/acestream/acestream.conf\""

# Add error handling for engine startup
if ! /opt/acestream/start-engine --http-port ${HTTP_PORT} --https-port ${HTTPS_PORT} ${ACESTREAM_EXTRA_FLAGS} "@/opt/acestream/acestream.conf"; then
    echo "ERROR: Failed to start Acestream engine"
    echo "Configuration file contents:"
    cat /opt/acestream/acestream.conf
    exit 1
fi
