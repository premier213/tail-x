#!/usr/bin/env bash
# ساخت گواهی self-signed برای نود PasarGuard
# خروجی: data/pg-node/certs/ssl_cert.pem و ssl_key.pem

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data/pg-node"
CERTS_DIR="${DATA_DIR}/certs"

mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

# اگر از قبل وجود دارند، نادیده بگیر (یا حذف کن و دوباره اجرا کن)
if [[ -f ssl_cert.pem && -f ssl_key.pem ]]; then
  echo "گواهی از قبل وجود دارد در: $CERTS_DIR"
  echo "برای ساخت دوباره، فایل‌های ssl_cert.pem و ssl_key.pem را حذف کن و اسکریپت را دوباره اجرا کن."
  exit 0
fi

# دامنه یا IP سرور؛ برای self-signed می‌تونی localhost بذاری یا همان IP/دامنه عمومی
CN="${SSL_CN:-localhost}"
DAYS="${SSL_DAYS:-3650}"

openssl req -x509 -nodes -days "$DAYS" -newkey rsa:2048 \
  -keyout ssl_key.pem \
  -out ssl_cert.pem \
  -subj "/CN=${CN}"

chmod 600 ssl_key.pem
chmod 644 ssl_cert.pem

echo "گواهی ساخته شد در: $CERTS_DIR"
echo ""
echo "برای پنل پاسارگارد: محتوای فایل ssl_cert.pem را کپی کن و در فیلد Certificate در صفحه Modify Node قرار بده:"
echo "  cat ${CERTS_DIR}/ssl_cert.pem"
