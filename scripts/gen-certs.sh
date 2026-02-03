
set -e
CERTS_DIR="/var/lib/pg-node/certs"

mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

if [[ -f ssl_cert.pem && -f ssl_key.pem ]]; then
  echo "exists in $CERTS_DIR"
  echo "to create again, delete the files ssl_cert.pem and ssl_key.pem and run the script again."
  exit 0
fi

CN="${SSL_CN:-localhost}"
DAYS="${SSL_DAYS:-3650}"

openssl req -x509 -nodes -days "$DAYS" -newkey rsa:2048 \
  -keyout ssl_key.pem \
  -out ssl_cert.pem \
  -subj "/CN=${CN}"

chmod 600 ssl_key.pem
chmod 644 ssl_cert.pem

echo "  cat ${CERTS_DIR}/ssl_cert.pem"
