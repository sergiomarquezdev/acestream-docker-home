#!/bin/bash

# ================================================
# ACESTREAM DOCKER ENTRYPOINT
# Enhanced with logging, format validation and error handling
# ================================================

set -e  # Exit on any error

# === VALIDATION HELPERS ===
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
echo "HTTP Port: ${HTTP_PORT}"
echo "HTTPS Port: ${HTTPS_PORT}"
echo "Extra Flags: ${ACESTREAM_EXTRA_FLAGS:-none}"

# === CONFIGURATION VALIDATION ===
echo "=== VALIDATING CONFIGURATION ==="

validate_port "${HTTP_PORT}" "HTTP_PORT" || exit 1
validate_port "${HTTPS_PORT}" "HTTPS_PORT" || exit 1
validate_https_port "${HTTP_PORT}" "${HTTPS_PORT}" || exit 1

# Validate acestream.conf exists
if [ ! -f "/opt/acestream/acestream.conf" ]; then
    echo "ERROR: acestream.conf not found"
    exit 1
fi

echo "Configuration validation: OK"

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

# exec so no extra shell sits between tini (PID 1) and the engine; tini -g
# delivers docker stop's SIGTERM to the whole process group.
exec /opt/acestream/start-engine --http-port ${HTTP_PORT} --https-port ${HTTPS_PORT} ${ACESTREAM_EXTRA_FLAGS} "@/opt/acestream/acestream.conf"
