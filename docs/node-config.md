# پیکربندی نود – تنظیم کانفیگ‌های PasarGuard Node و متغیرهای محیطی

یک نگاه کلی به کانفیگ: می‌توانی PasarGuard Node را با **متغیرهای محیطی** (environment variables) تنظیم کنی. همهٔ تنظیمات را می‌شود در فایل `.env` یا مستقیم به‌عنوان متغیر محیطی ست کرد.

> **توجه:** PasarGuard Node در مرحلهٔ تست و توسعه است. استفاده به مسئولیت خودتان است.

---

## متغیرهای محیطی

### تنظیمات اصلی

| متغیر | نوع | پیش‌فرض | توضیحات |
|--------|------|---------|----------|
| `API_KEY` | string | - | UUID برای احراز هویت دسترسی به API (**ضروری**) |
| `NODE_HOST` | string | 127.0.0.1 | آدرس هاست برای اتصال برنامه |
| `SERVICE_PORT` | int | 62050 | شماره پورت برنامه |
| `SERVICE_PROTOCOL` | string | grpc | پروتکل اتصال (`grpc` یا `rest`؛ پیشنهادی: grpc) |
| `DEBUG` | bool | false | فعال‌سازی حالت دیباگ برای لاگ‌های کامل |

### تنظیمات SSL/TLS

| متغیر | نوع | پیش‌فرض | توضیحات |
|--------|------|---------|----------|
| `SSL_CERT_FILE` | string | - | مسیر فایل گواهینامه SSL |
| `SSL_KEY_FILE` | string | - | مسیر فایل کلید خصوصی SSL |

### تنظیمات Xray

| متغیر | نوع | پیش‌فرض | توضیحات |
|--------|------|---------|----------|
| `XRAY_EXECUTABLE_PATH` | string | /usr/local/bin/xray | مسیر فایل اجرایی Xray |
| `XRAY_ASSETS_PATH` | string | /usr/local/share/xray | مسیر پوشهٔ داده‌های Xray |

**هسته‌های پشتیبانی‌شده:**

- ✅ **xray-core**
- ❌ sing-box (پشتیبانی نمی‌شود)
- ❌ v2ray-core (پشتیبانی نمی‌شود)

---

## مثال‌های کانفیگ

### تنظیمات پایه

```env
# Core Settings
API_KEY=your-uuid-here
NODE_HOST=127.0.0.1
SERVICE_PORT=62050
SERVICE_PROTOCOL=grpc
DEBUG=false

# SSL Configuration
SSL_CERT_FILE=/path/to/ssl_cert.pem
SSL_KEY_FILE=/path/to/ssl_key.pem

# Xray Paths (defaults usually work)
XRAY_EXECUTABLE_PATH=/usr/local/bin/xray
XRAY_ASSETS_PATH=/usr/local/share/xray
```

### تنظیمات برای سرور واقعی

```env
# Core Settings
API_KEY=change-this-to-a-secure-uuid
NODE_HOST=0.0.0.0
SERVICE_PORT=62050
SERVICE_PROTOCOL=grpc
DEBUG=false

# SSL - Use valid certificates
SSL_CERT_FILE=/etc/ssl/certs/your-domain.pem
SSL_KEY_FILE=/etc/ssl/private/your-domain-key.pem

# Xray Configuration
XRAY_EXECUTABLE_PATH=/usr/local/bin/xray
XRAY_ASSETS_PATH=/usr/local/share/xray
```

### تنظیمات Docker Compose (پروژه tail-x)

وقتی از Docker استفاده می‌کنی، متغیرها را در `.env` یا `docker-compose.yml` تنظیم کن. در این پروژه مسیر SSL داخل کانتینر ثابت است (`/var/lib/pg-node/certs/`). نمونهٔ `.env`:

```env
API_KEY=your-uuid-here
NODE_HOST=0.0.0.0
SERVICE_PORT=62050
API_PORT=62051
SERVICE_PROTOCOL=grpc
DEBUG=false
SSL_CERT_FILE=/app/certs/ssl_cert.pem
SSL_KEY_FILE=/app/certs/ssl_key.pem
```

گواهی‌ها با `./scripts/gen-certs.sh` در `data/pg-node/certs/` ساخته می‌شوند و به همان مسیر داخل کانتینر مپ می‌شوند.

---

## راه‌اندازی گواهی SSL

### ساخت گواهی Self-Signed

برای تست یا استفادهٔ داخلی:

```bash
openssl req -x509 -newkey rsa:4096 -keyout ssl_key.pem \
  -out ssl_cert.pem -days 36500 -nodes \
  -subj "/CN=your-server-ip-or-domain" \
  -addext "subjectAltName = DNS:your-domain.com,IP:your.server.ip"
```

در این پروژه می‌توانی از اسکریپت آماده استفاده کنی:

```bash
# پیش‌فرض (CN=localhost)
./scripts/gen-certs.sh

# با دامنه یا IP مشخص
SSL_CN=5.196.129.144 ./scripts/gen-certs.sh
```

سپس مسیرها را تنظیم کن:

```env
SSL_CERT_FILE=/path/to/ssl_cert.pem
SSL_KEY_FILE=/path/to/ssl_key.pem
```

### استفاده از گواهی Let's Encrypt

برای سرور واقعی با دامنه:

1. نصب Certbot: `sudo apt-get install certbot`
2. دریافت گواهی: `sudo certbot certonly --standalone -d your-domain.com`
3. تنظیم متغیرها:

```env
SSL_CERT_FILE=/etc/letsencrypt/live/your-domain.com/fullchain.pem
SSL_KEY_FILE=/etc/letsencrypt/live/your-domain.com/privkey.pem
```

### استفاده از گواهی شخصی

```env
SSL_CERT_FILE=/path/to/your/certificate.pem
SSL_KEY_FILE=/path/to/your/private-key.pem
```

---

## نکات امنیتی مهم

### ساخت API Key امن

```bash
# uuidgen (Linux/macOS)
uuidgen

# Python
python3 -c "import uuid; print(uuid.uuid4())"

# OpenSSL
openssl rand -hex 16 | awk '{print substr($1,1,8)"-"substr($1,9,4)"-"substr($1,13,4)"-"substr($1,17,4)"-"substr($1,21,12)}'
```

### دسترسی فایل‌ها

```bash
chmod 600 /path/to/ssl_key.pem
chmod 644 /path/to/ssl_cert.pem
chmod 600 .env
```

### فایروال

فقط پورت‌های لازم را باز کن:

```bash
sudo ufw allow 62050/tcp
sudo ufw enable
```

---

## تنظیمات پروتکل

- **gRPC (پیشنهادی):** `SERVICE_PROTOCOL=grpc` — سریع‌تر و تاخیر کمتر.
- **REST API:** `SERVICE_PROTOCOL=rest` — پشتیبانی می‌شود؛ ممکن است کندتر باشد.

---

## رفع مشکلات

### پورت از قبل استفاده شده

در `.env` پورت را عوض کن، مثلاً:

```env
SERVICE_PORT=62051
```

### حالت دیباگ

برای لاگ کامل:

```env
DEBUG=true
```

---

برای ارتباط نود با پنل و فیلدهای **Modify Node** به [panel-node-connection.md](./panel-node-connection.md) مراجعه کن.
