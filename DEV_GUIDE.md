# Development Guide - Auto-Restart Server

## Quick Start

### 1. Start Development Server with Auto-Reload
```bash
cd backend
python manage.py runserver
```

That's it! The server will automatically restart when you modify Python files.

---

## What Auto-Restarts Automatically

✅ **Automatically restarts for:**
- Modifying `.py` files (views, models, serializers, etc.)
- Modifying templates
- Modifying URL configurations
- Most code changes

❌ **Requires manual restart (Ctrl+C then restart):**
- Creating new files/directories
- Major `settings.py` changes (like adding MEDIA_ROOT)
- Installing new packages
- Adding new apps to INSTALLED_APPS
- Running migrations

---

## Development Workflow

### Normal Code Changes (Auto-Restart)
1. Edit your Python files
2. Save the file
3. Django automatically detects and restarts
4. Refresh your browser/app

### Major Changes (Manual Restart)
1. Make changes (new settings, new packages, etc.)
2. Press `Ctrl+C` to stop server
3. Run `python manage.py runserver` again
4. Test your changes

---

## Useful Development Commands

### Start Server
```bash
# Default (localhost:8000)
python manage.py runserver

# Custom port
python manage.py runserver 8080

# Accessible from network
python manage.py runserver 0.0.0.0:8000
```

### Database Operations
```bash
# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Open Django shell
python manage.py shell
```

### Static Files
```bash
# Collect static files
python manage.py collectstatic
```

### Check for Issues
```bash
# Check for problems
python manage.py check

# Check deployment readiness
python manage.py check --deploy
```

---

## Troubleshooting Auto-Reload

### Server Not Auto-Restarting?

**Check 1:** Make sure you're not using `--noreload`
```bash
# ❌ Wrong
python manage.py runserver --noreload

# ✅ Correct
python manage.py runserver
```

**Check 2:** Install watchdog for better detection
```bash
pip install watchdog
```

**Check 3:** Some changes require manual restart
- Press `Ctrl+C`
- Run `python manage.py runserver` again

### Server Keeps Crashing?

**Check the error message:**
```bash
# Look for syntax errors, import errors, etc.
# Fix the error in your code
# Server will auto-restart once you save the fix
```

**Common issues:**
- Syntax errors in Python files
- Missing imports
- Database connection issues
- Port already in use

### Port Already in Use?

**Find and kill the process:**
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

**Or use a different port:**
```bash
python manage.py runserver 8080
```

---

## Best Practices

### 1. Keep Server Running While Coding
- Let Django auto-reload handle most changes
- Only restart manually when needed
- Watch the console for errors

### 2. Use Virtual Environment
```bash
# Activate venv before running server
# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 3. Check Console Output
- Django shows when it reloads
- Watch for errors and warnings
- Validation errors appear here

### 4. Test After Changes
- Refresh your frontend app
- Check API endpoints
- Verify database changes

---

## Development vs Production

| Feature | Development | Production |
|---------|-------------|------------|
| Server | `runserver` | Gunicorn/uWSGI |
| Auto-reload | ✅ Yes | ❌ No (use systemd) |
| Debug | `DEBUG=True` | `DEBUG=False` |
| Static files | Served by Django | Nginx/Apache |
| Database | Local PostgreSQL | Production DB |
| Logs | Console | Log files |

---

## Current Setup Status

✅ **Configured:**
- Django auto-reload (built-in)
- Watchdog for better detection
- MEDIA_ROOT for file uploads
- Profile photo upload endpoints

✅ **Ready to use:**
1. Run `python manage.py runserver`
2. Edit your code
3. Django auto-restarts
4. Test your changes

---

## Next Steps

### For Development (Now)
- Use `python manage.py runserver` with auto-reload
- Code normally, server restarts automatically
- Manual restart only when needed

### For Production (Later)
- See `DEPLOYMENT.md` for full guide
- Use Gunicorn + Systemd for auto-restart
- Configure Nginx for static/media files
- Set up proper logging and monitoring

---

## Quick Reference

```bash
# Start development server (auto-reload enabled)
python manage.py runserver

# Stop server
Ctrl+C

# Restart server (if needed)
Ctrl+C
python manage.py runserver

# Install new packages
pip install package_name
# Then restart server manually

# Apply database changes
python manage.py migrate
# Server auto-restarts after this
```

---

**Remember:** For development, just use `python manage.py runserver` and Django handles auto-reload for you! 🚀
