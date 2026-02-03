# مرجع متغیرهای محیطی نود PasarGuard

هماهنگ با [پیکربندی رسمی پاسارگارد](https://docs.pasarguard.org/fa/node/configuration/). در این پروژه مقادیر از `.env` و در `docker-compose.yml` به کانتینر پاس داده می‌شوند.

## تنظیمات اصلی

| متغیر       | نوع   | پیش‌فرض | توضیحات |
|-------------|--------|---------|---------|
| `API_KEY`   | string | -       | UUID برای احراز هویت دسترسی به API (ضروری) |
| `NODE_HOST` | string | 127.0.0.1 | آدرس listen نود؛ در داکر `0.0.0.0` تا از بیرون در دسترس باشد |
| `SERVICE_PORT` | int | 62050 | شماره پورت برنامه (همان Node Port در پنل) |
| `SERVICE_PROTOCOL` | string | grpc | پروتکل اتصال: `grpc` (پیشنهادی) یا `rest` |
| `DEBUG`     | bool   | false  | فعال‌سازی لاگ کامل برای رفع مشکل |

## تنظیمات SSL/TLS

| متغیر            | توضیحات |
|------------------|---------|
| `SSL_CERT_FILE`  | مسیر فایل گواهینامه SSL (مثلاً `/var/lib/pg-node/certs/ssl_cert.pem`) |
| `SSL_KEY_FILE`   | مسیر فایل کلید خصوصی SSL |

## تنظیمات Xray (اختیاری)

| متغیر                   | پیش‌فرض              | توضیحات |
|-------------------------|----------------------|---------|
| `XRAY_EXECUTABLE_PATH`  | /usr/local/bin/xray  | مسیر باینری Xray |
| `XRAY_ASSETS_PATH`      | /usr/local/share/xray| مسیر داده‌های Xray |

## پروژه tail-x

- **API_PORT**: پورت جدا برای آپدیت Xray از پنل (مثلاً 62051)؛ در پنل در Advanced Settings → API Port همان مقدار را وارد کن.
- **PANEL_HOST**: آدرس پنل؛ در صورت نیاز نود از آن برای اتصال به پنل استفاده می‌کند (متغیر `HOST` داخل کانتینر).

ساخت گواهی SSL با اسکریپت: `./scripts/gen-certs.sh`
