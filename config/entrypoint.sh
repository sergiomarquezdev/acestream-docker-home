#!/bin/bash

# ================================================
# ACESTREAM DOCKER ENTRYPOINT
# Enhanced with logging and error handling
# ================================================

set -e  # Exit on any error

# === VALIDATION HELPERS ===
validate_ip() {
    local ip="$1"
    if [ -z "$ip" ]; then
        echo "ERROR: INTERNAL_IP environment variable not set"
        return 1
    fi
    local IFS='.'
    local -a octets
    read -ra octets <<< "$ip"
    if [ "${#octets[@]}" -ne 4 ]; then
        echo "ERROR: INTERNAL_IP does not match IPv4 format X.X.X.X"
        return 1
    fi
    for octet in "${octets[@]}"; do
        case "$octet" in
            ''|*[!0-9]*)
                echo "ERROR: INTERNAL_IP does not match IPv4 format X.X.X.X"
                return 1
                ;;
        esac
        if [ "$octet" -gt 255 ]; then
            echo "ERROR: INTERNAL_IP octet $octet is out of range 0-255"
            return 1
        fi
    done
    return 0
}

validate_port() {
    local port="$1"
    local name="$2"
    if [ -z "$port" ]; then
        echo "ERROR: $name environment variable not set"
        return 1
    fi
    case "$port" in
        ''|*[!0-9]*)
            echo "ERROR: $name is not numeric"
            return 1
            ;;
    esac
    if [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then
        echo "ERROR: $name must be between 1024 and 65535"
        return 1
    fi
    return 0
}

validate_https_port() {
    local http="$1"
    local https="$2"
    if [ "$https" -ne $((http + 1)) ]; then
        echo "ERROR: HTTPS_PORT ($https) must be HTTP_PORT ($http) + 1"
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

# === NETWORK BIND VERIFICATION ===
echo "=== VERIFYING NETWORK BIND ==="
python3 -c "
import socket, sys
ip = '${INTERNAL_IP}'
port = ${HTTP_PORT}
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind((ip, port))
    s.close()
    print('Network bind verification: OK')
except Exception as e:
    print('WARNING: Cannot bind to ' + ip + ':' + str(port) + ' - ' + str(e))
    sys.exit(0)
" || true

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
