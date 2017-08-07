#!/bin/sh

# Check for VIRTUAL_HOST variable and exit if not provided
if [ -z "${VIRTUAL_HOST}" ]; then
  echo "Error: VIRTUAL_HOST environment variable is not set." 1>&2
  exit 1
fi

# Apply default environment variables if not provided
export CONSUL_HOST="${CONSUL_HOST:-consul}"
export CONSUL_PORT="${CONSUL_PORT:-8500}"
export SERVICE_TAG="${SERVICE_TAG:-openlmis-service}"
export RESOURCES_PATH="${RESOURCES_PATH:-resources}"
export NGINX_LOG_DIR="${NGINX_LOG_DIR:-/var/log/nginx}"
export CONSUL_TEMPLATE_LOG_DIR="${CONSUL_TEMPLATE_LOG_DIR:-/var/log/consul-template}"
export CLIENT_MAX_BODY_SIZE="${CLIENT_MAX_BODY_SIZE:-1m}"
export PROXY_CONNECT_TIMEOUT="${PROXY_CONNECT_TIMEOUT:-${NGINX_TIMEOUT:-60s}}"
export PROXY_SEND_TIMEOUT="${PROXY_SEND_TIMEOUT:-${NGINX_TIMEOUT:-60s}}"
export PROXY_READ_TIMEOUT="${PROXY_READ_TIMEOUT:-${NGINX_TIMEOUT:-60s}}"
export SEND_TIMEOUT="${SEND_TIMEOUT:-${NGINX_TIMEOUT:-60s}}"

# Run consul-template in background
CONSUL_PATH="${CONSUL_HOST}:${CONSUL_PORT}"
INPUT_FILE="/etc/consul-template/openlmis.conf"
OUTPUT_FILE="/etc/nginx/conf.d/default.conf"
CALLBACK="nginx -s reload"

consul-template \
  -consul "$CONSUL_PATH" \
  -template "$INPUT_FILE:$OUTPUT_FILE:$CALLBACK" >> "${CONSUL_TEMPLATE_LOG_DIR}/ctmpl.log" 2>&1 &

# Run nginx
nginx -g 'daemon off;'
