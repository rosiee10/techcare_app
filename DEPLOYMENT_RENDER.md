# TechCare Backend Deployment Guide - Render

This guide explains how to deploy your Django backend to Render for free.

## Why Render?

- **Free tier:** 750 hours/month (enough for continuous operation)
- **PostgreSQL included:** Free database with 256MB storage
- **GitHub integration:** Auto-deploy on push
- **SSL/HTTPS:** Automatic and free
- **Easy scaling:** Upgrade anytime as your app grows

## Prerequisites

1. GitHub account (already have it ✓)
2. Render account (free at https://render.com)
3. Backend pushed to GitHub (already done ✓)

## Step-by-Step Deployment

### Step 1: Create Render Account

1. Go to https://render.com
2. Sign up with GitHub (recommended)
3. Authorize Render to access your GitHub repositories

### Step 2: Create a New Web Service

1. Click "New +" → "Web Service"
2. Select your `backend` repository
3. Configure the service:
   - **Name:** `techcare-backend` (or your choice)
   - **Environment:** `Python 3`
   - **Region:** `Oregon` (or closest to you)
   - **Branch:** `main`
   - **Build Command:** 
     ```
     pip install -r requirements.txt && python manage.py collectstatic --noinput && python manage.py migrate
     ```
   - **Start Command:** 
     ```
     gunicorn backend.wsgi:application
     ```

### Step 3: Add Environment Variables

In Render dashboard, go to your service → Environment:

Add these variables:

```
DEBUG=False
SECRET_KEY=<generate-a-new-secret-key>
ALLOWED_HOSTS=techcare-backend.onrender.com,yourdomain.com
DATABASE_URL=<will-be-auto-set-by-postgres>
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=techcarepch@gmail.com
EMAIL_HOST_PASSWORD=uyjvnpezvgrvsovr
DEFAULT_FROM_EMAIL=TECHCARE - Plaridel Community Hospital <noreply@plaridel-hospital.com>
POLYGON_RPC_URL=https://polygon-rpc.com
POLYGON_CHAIN_ID=137
```

### Step 4: Create PostgreSQL Database

1. Click "New +" → "PostgreSQL"
2. Configure:
   - **Name:** `techcare-db`
   - **Region:** Same as web service
   - **PostgreSQL Version:** 15
3. Create the database
4. Copy the `Internal Database URL` and add it as `DATABASE_URL` in your web service

### Step 5: Deploy

1. Click "Deploy"
2. Wait for build to complete (5-10 minutes)
3. Check logs for any errors
4. Your backend URL will be: `https://techcare-backend.onrender.com`

## Step 6: Update Flutter Mobile App

Update your `api_config.dart` to use the Render URL:

```dart
AppEnvironment.production: {
  'web': 'https://techcare-backend.onrender.com',
  'android': 'https://techcare-backend.onrender.com',
  'ios': 'https://techcare-backend.onrender.com',
},
```

## Troubleshooting

### Build Fails

Check the build logs in Render dashboard. Common issues:
- Missing dependencies in `requirements.txt`
- Database migration errors
- Missing environment variables

### Database Connection Error

- Verify `DATABASE_URL` is set correctly
- Check PostgreSQL is created in same region
- Run migrations: Check logs for migration status

### CORS Errors

Add your mobile app domain to `ALLOWED_HOSTS` in environment variables.

### Static Files Not Loading

WhiteNoise middleware is configured to serve static files automatically.

## Monitoring

- **Logs:** View in Render dashboard
- **Metrics:** CPU, memory, disk usage visible in dashboard
- **Alerts:** Set up email notifications for errors

## Upgrading from Free Tier

When you need more resources:
- Upgrade to paid plan ($7+/month)
- Increase database storage
- Enable auto-scaling

## Cost Estimate

- **Web Service:** Free tier (750 hrs/month)
- **PostgreSQL:** Free tier (256MB)
- **Total:** **$0/month** (until you scale)

## Security Checklist

- ✅ `.env` file is in `.gitignore` (not pushed to GitHub)
- ✅ `DEBUG=False` in production
- ✅ Secret key from environment variable
- ✅ HTTPS/SSL enabled automatically
- ✅ Database password protected

## Next Steps

1. Create Render account
2. Deploy backend
3. Test API endpoints
4. Update Flutter app with production URL
5. Test mobile app connection

## Support

- Render Docs: https://render.com/docs
- Django Deployment: https://docs.djangoproject.com/en/6.0/howto/deployment/
- Issues? Check Render logs first!
