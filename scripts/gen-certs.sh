#!/usr/bin/env bash
# SSL certificate generation using acme.sh + Let's Encrypt (from x-ui script approach).
# Usage:
#   Domain: SSL_DOMAIN=example.com ./scripts/gen-certs.sh
#   IP:     SSL_IP=5.196.129.144 ./scripts/gen-certs.sh
# Certificates are written to CERTS_DIR as ssl_cert.pem (fullchain) and ssl_key.pem (privkey).

set -e
CERTS_DIR="${CERTS_DIR:-/var/lib/pg-node/certs}"
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

is_ipv4() {
  [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && return 0 || return 1
}
is_ipv6() {
  [[ "$1" =~ : ]] && return 0 || return 1
}
is_domain() {
  [[ "$1" =~ ^([A-Za-z0-9](-*[A-Za-z0-9])*\.)+(xn--[a-z0-9]{2,}|[A-Za-z]{2,})$ ]] && return 0 || return 1
}

is_port_in_use() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | awk -v p=":${port}$" '$4 ~ p {exit 0} END {exit 1}' && return 0
  fi
  if command -v netstat >/dev/null 2>&1; then
    netstat -lnt 2>/dev/null | awk -v p=":${port} " '$4 ~ p {exit 0} END {exit 1}' && return 0
  fi
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:${port} -sTCP:LISTEN >/dev/null 2>&1 && return 0
  fi
  return 1
}

install_acme() {
  echo -e "${green}Installing acme.sh for SSL certificate management...${plain}"
  cd ~ || return 1
  curl -s https://get.acme.sh | sh >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${red}Failed to install acme.sh${plain}"
    return 1
  fi
  echo -e "${green}acme.sh installed successfully${plain}"
  return 0
}

# Let's Encrypt certificate for a domain (standalone, port 80)
issue_domain_cert() {
  local domain="$1"
  local certPath="$2"
  local webPort="${3:-80}"

  echo -e "${green}Setting up SSL certificate for domain ${domain}...${plain}"
  echo -e "${yellow}Note: Port 80 must be open and accessible from the internet${plain}"

  if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
    install_acme || return 1
  fi

  mkdir -p "$certPath"
  ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt --force >/dev/null 2>&1
  ~/.acme.sh/acme.sh --issue -d "${domain}" --listen-v6 --standalone --httpport "${webPort}" --force

  if [ $? -ne 0 ]; then
    echo -e "${yellow}Failed to issue certificate for ${domain}${plain}"
    rm -rf ~/.acme.sh/"${domain}" 2>/dev/null
    return 1
  fi

  ~/.acme.sh/acme.sh --installcert -d "${domain}" \
    --key-file "${certPath}/ssl_key.pem" \
    --fullchain-file "${certPath}/ssl_cert.pem" \
    --reloadcmd "true" >/dev/null 2>&1

  chmod 600 "${certPath}/ssl_key.pem" 2>/dev/null
  chmod 644 "${certPath}/ssl_cert.pem" 2>/dev/null
  ~/.acme.sh/acme.sh --upgrade --auto-upgrade >/dev/null 2>&1
  echo -e "${green}Domain certificate installed to ${certPath}${plain}"
  return 0
}

# Let's Encrypt IP certificate (shortlived profile, ~6 days)
issue_ip_cert() {
  local ipv4="$1"
  local ipv6="$2"
  local certDir="$3"
  local webPort="${4:-80}"

  echo -e "${green}Setting up Let's Encrypt IP certificate (shortlived profile)...${plain}"
  echo -e "${yellow}Note: IP certificates are valid for ~6 days and will auto-renew. Port ${webPort} must be open.${plain}"

  if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
    install_acme || return 1
  fi

  if [[ -z "$ipv4" ]] || ! is_ipv4 "$ipv4"; then
    echo -e "${red}Invalid or missing IPv4 address${plain}"
    return 1
  fi

  mkdir -p "$certDir"
  local domain_args="-d ${ipv4}"
  if [[ -n "$ipv6" ]] && is_ipv6 "$ipv6"; then
    domain_args="${domain_args} -d ${ipv6}"
  fi

  if is_port_in_use "${webPort}"; then
    echo -e "${red}Port ${webPort} is in use. Stop the service using it or use another port (set SSL_WEB_PORT).${plain}"
    return 1
  fi

  ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt --force >/dev/null 2>&1
  ~/.acme.sh/acme.sh --issue \
    ${domain_args} \
    --standalone \
    --server letsencrypt \
    --certificate-profile shortlived \
    --days 6 \
    --httpport "${webPort}" \
    --force

  if [ $? -ne 0 ]; then
    echo -e "${red}Failed to issue IP certificate${plain}"
    rm -rf ~/.acme.sh/"${ipv4}" 2>/dev/null
    [[ -n "$ipv6" ]] && rm -rf ~/.acme.sh/"${ipv6}" 2>/dev/null
    return 1
  fi

  ~/.acme.sh/acme.sh --installcert -d "${ipv4}" \
    --key-file "${certDir}/ssl_key.pem" \
    --fullchain-file "${certDir}/ssl_cert.pem" \
    --reloadcmd "true" 2>&1 || true

  if [[ ! -f "${certDir}/ssl_cert.pem" || ! -f "${certDir}/ssl_key.pem" ]]; then
    echo -e "${red}Certificate files not found after install${plain}"
    return 1
  fi

  ~/.acme.sh/acme.sh --upgrade --auto-upgrade >/dev/null 2>&1
  chmod 600 "${certDir}/ssl_key.pem" 2>/dev/null
  chmod 644 "${certDir}/ssl_cert.pem" 2>/dev/null
  echo -e "${green}IP certificate installed to ${certDir}${plain}"
  return 0
}

# --- main ---
mkdir -p "$CERTS_DIR"

if [[ -f "${CERTS_DIR}/ssl_cert.pem" && -f "${CERTS_DIR}/ssl_key.pem" ]]; then
  echo -e "${yellow}Certificates already exist in ${CERTS_DIR}${plain}"
  echo "To recreate, remove ssl_cert.pem and ssl_key.pem and run again."
  exit 0
fi

WEB_PORT="${SSL_WEB_PORT:-80}"

if [[ -n "${SSL_DOMAIN}" ]]; then
  if ! is_domain "${SSL_DOMAIN}"; then
    echo -e "${red}Invalid domain: ${SSL_DOMAIN}${plain}"
    exit 1
  fi
  issue_domain_cert "${SSL_DOMAIN}" "${CERTS_DIR}" "${WEB_PORT}" || exit 1
elif [[ -n "${SSL_IP}" ]]; then
  issue_ip_cert "${SSL_IP}" "${SSL_IP6:-}" "${CERTS_DIR}" "${WEB_PORT}" || exit 1
else
  echo -e "${red}Set SSL_DOMAIN or SSL_IP before running this script.${plain}"
  echo "  Domain: SSL_DOMAIN=example.com $0"
  echo "  IP:     SSL_IP=5.196.129.144 $0"
  exit 1
fi

echo "  cat ${CERTS_DIR}/ssl_cert.pem"
