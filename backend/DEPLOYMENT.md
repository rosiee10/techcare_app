# Production Deployment Guide

## Overview
This guide covers deploying the TechCare Django backend to production with auto-restart capabilities.

## Option 1: Gunicorn + Nginx + Systemd (Recommended for Linux)

### 1. Install Gunicorn
```bash
pip install -r requirements.txt
```

### 2. Create Gunicorn Configuration
Create `gunicorn_config.py` in the backend directory:

```python
import multiprocessing

# Server socket
bind = "0.0.0.0:8000"
backlog = 2048

# Worker processes
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = 'sync'
worker_connections = 1000
timeout = 30
keepalive = 2

# Logging
accesslog = '/var/log/gunicorn/access.log'
errorlog = '/var/log/gunicorn/error.log'
loglevel = 'info'

# Process naming
proc_name = 'techcare_backend'

# Server mechanics
daemon = False
pidfile = '/var/run/gunicorn/techcare.pid'
user = None
group = None
tmp_upload_dir = None

# SSL (if needed)
# keyfile = '/path/to/keyfile'
# certfile = '/path/to/certfile'
```

### 3. Create Systemd Service (Auto-Restart)
Create `/etc/systemd/system/techcare.service`:

```ini
[Unit]
Description=TechCare Django Backend
After=network.target

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/path/to/techcare_app/backend
Environment="PATH=/path/to/venv/bin"
ExecStart=/path/to/venv/bin/gunicorn backend.wsgi:application -c gunicorn_config.py
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true

# Auto-restart settings
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 4. Enable and Start Service
```bash
# Create log directories
sudo mkdir -p /var/log/gunicorn
sudo mkdir -p /var/run/gunicorn
sudo chown www-data:www-data /var/log/gunicorn
sudo chown www-data:www-data /var/run/gunicorn

# Enable service to start on boot
sudo systemctl enable techcare

# Start the service
sudo systemctl start techcare

# Check status
sudo systemctl status techcare

# View logs
sudo journalctl -u techcare -f
```

### 5. Nginx Configuration
Create `/etc/nginx/sites-available/techcare`:

```nginx
upstream techcare_backend {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name your-domain.com;

    client_max_body_size 10M;

    # Static files
    location /static/ {
        alias /path/to/techcare_app/backend/staticfiles/;
    }

    # Media files (profile photos, etc.)
    location /media/ {
        alias /path/to/techcare_app/backend/media/;
    }

    # API requests
    location / {
        proxy_pass http://techcare_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/techcare /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Option 2: Docker + Docker Compose (Cross-Platform)

### 1. Create Dockerfile
Create `Dockerfile` in backend directory:

```dockerfile
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy project
COPY . /app/

# Collect static files
RUN python manage.py collectstatic --noinput

# Create media directory
RUN mkdir -p /app/media/profile_photos

EXPOSE 8000

# Run gunicorn
CMD ["gunicorn", "backend.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

### 2. Create docker-compose.yml
Create in project root:

```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=techcare_db
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=your_password
    restart: always

  backend:
    build: ./backend
    command: gunicorn backend.wsgi:application --bind 0.0.0.0:8000 --workers 4
    volumes:
      - ./backend:/app
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "8000:8000"
    env_file:
      - ./backend/.env
    depends_on:
      - db
    restart: always

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: always

volumes:
  postgres_data:
  static_volume:
  media_volume:
```

### 3. Deploy with Docker
```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f backend

# Restart services
docker-compose restart backend

# Stop services
docker-compose down
```

---

## Option 3: Platform as a Service (PaaS)

### A. Railway.app
1. Connect GitHub repository
2. Add PostgreSQL database
3. Set environment variables
4. Deploy automatically on git push
5. Auto-restart on crashes

### B. Render.com
1. Create Web Service from GitHub
2. Build command: `pip install -r requirements.txt`
3. Start command: `gunicorn backend.wsgi:application`
4. Add PostgreSQL database
5. Auto-deploy on git push

### C. Heroku
Create `Procfile`:
```
web: gunicorn backend.wsgi:application --log-file -
release: python manage.py migrate
```

Deploy:
```bash
heroku create techcare-backend
heroku addons:create heroku-postgresql:hobby-dev
git push heroku main
```

---

## Production Settings Checklist

Update `settings.py` for production:

```python
# Security
DEBUG = False
ALLOWED_HOSTS = ['your-domain.com', 'www.your-domain.com']

# Database - Use environment variables
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }
}

# Static and Media files
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Security settings
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# CORS - Update with your frontend domain
CORS_ALLOWED_ORIGINS = [
    "https://your-frontend-domain.com",
]
```

---

## Auto-Restart Summary

| Method | Auto-Restart | Best For |
|--------|--------------|----------|
| Systemd | ✅ Yes (on crash) | Linux servers |
| Docker | ✅ Yes (restart: always) | Any platform |
| PaaS (Railway/Render) | ✅ Yes (built-in) | Quick deployment |
| Supervisor | ✅ Yes | Alternative to systemd |

---

## Monitoring & Logs

### Systemd
```bash
# View logs
sudo journalctl -u techcare -f

# Restart service
sudo systemctl restart techcare

# Check status
sudo systemctl status techcare
```

### Docker
```bash
# View logs
docker-compose logs -f backend

# Restart
docker-compose restart backend

# Check status
docker-compose ps
```

---

## Maintenance Commands

```bash
# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Check deployment
python manage.py check --deploy
```

---

## Recommended: Use Systemd for Production

For a traditional Linux server deployment, **Systemd is the best choice** because:
- ✅ Auto-restart on crash
- ✅ Start on system boot
- ✅ Easy log management
- ✅ Resource limits
- ✅ Standard on most Linux distributions

The service will automatically restart if it crashes and will start automatically when the server boots.
