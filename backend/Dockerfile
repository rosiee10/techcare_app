FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

COPY . .

CMD ["command: gunicorn techcare_app.wsgi:application --bind 0.0.0.0:8000"]