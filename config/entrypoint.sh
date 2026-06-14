#!/bin/bash

# ================================================
# ACESTREAM DOCKER ENTRYPOINT
# Enhanced with logging, format validation and error handling
# ================================================

set -e  # Exit on any error

# === VALIDATION HELPERS ===
validate_ip() {
    local ip="$1"
    if [[ -z "$ip" ]]; then
        echo "ERROR: INTERNAL_IP is empty"
        return 1
    fi
    if ! [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "ERROR: INTERNAL_IP '$ip' is not a valid IPv4 address"
        return 1
    fi
    local IFS='.'
    read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ 10#$octet -lt 0 || 10#$octet -gt 255 ]]; then
            echo "ERROR: INTERNAL_IP '$ip' contains an invalid octet ($octet)"
            return 1
        fi
    done
    return 0
}

validate_port() {
    local port="$1"
    local name="$2"
    if [[ -z "$port" ]]; then
        echo "ERROR: $name is empty"
        return 1
    fi
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "ERROR: $name '$port' is not a number"
        return 1
    fi
    if [[ 10#$port -lt 1024 || 10#$port -gt 65535 ]]; then
        echo "ERROR: $name '$port' must be between 1024 and 65535"
        return 1
    fi
    return 0
}

validate_https_port() {
    local http="$1"
    local https="$2"
    local expected=$((10#$http + 1))
    if [[ 10#$https -ne $expected ]]; then
        echo "ERROR: HTTPS_PORT ($https) must be HTTP_PORT ($http) + 1 (expected $expected)"
        return 1
    fi
    return 0
}

# === LOGGING SETUP ===
echo "=== ACESTREAM DOCKER STARTUP ==="
echo "Timestamp: $(date)"
echo "Internal IP: ${INTERNAL_IP}"
echo "HTTP Port: ${HTTP_PORT}"
echo "HTTPS Port: ${HTTPS_PORT}"
echo "Extra Flags: ${ACESTREAM_EXTRA_FLAGS:-none}"

# === CONFIGURATION VALIDATION ===
echo "=== VALIDATING CONFIGURATION ==="

validate_ip "${INTERNAL_IP}" || exit 1
validate_port "${HTTP_PORT}" "HTTP_PORT" || exit 1
validate_port "${HTTPS_PORT}" "HTTPS_PORT" || exit 1
validate_https_port "${HTTP_PORT}" "${HTTPS_PORT}" || exit 1

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

# === VERIFY ENGINE BINDS TO INTERNAL_IP ===
echo "=== VERIFYING NETWORK BIND ==="
python3 -c "
import socket, sys
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    s.bind(('${INTERNAL_IP}', ${HTTP_PORT}))
    s.close()
    print('Network bind test: OK')
except Exception as e:
    print(f'WARNING: Cannot bind to ${INTERNAL_IP}:${HTTP_PORT}: {e}')
    print('This may be expected if INTERNAL_IP is not local to the container.')
" || true

# === ACESTREAM ENGINE STARTUP ===
echo "=== STARTING ACESTREAM ENGINE ==="
echo "Command: exec /opt/acestream/start-engine --http-port ${HTTP_PORT} --https-port ${HTTPS_PORT} ${ACESTREAM_EXTRA_FLAGS} \"@/opt/acestream/acestream.conf\""

# Pre-flight check so a missing binary yields a useful message (exec replaces this shell).
if [ ! -x "/opt/acestream/start-engine" ]; then
    echo "ERROR: /opt/acestream/start-engine is missing or not executable"
    echo "Configuration file contents:"
    cat /opt/acestream/acestream.conf
    exit 1
fi

# exec so the engine becomes PID 1: Docker's SIGTERM reaches it directly,
# allowing a graceful shutdown instead of a SIGKILL after the stop timeout.
exec /opt/acestream/start-engine --http-port ${HTTP_PORT} --https-port ${HTTPS_PORT} ${ACESTREAM_EXTRA_FLAGS} "@/opt/acestream/acestream.conf"
