FROM python:3.11-slim
WORKDIR /app
RUN mkdir -p /exports /app/data
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
EXPOSE 5000
CMD ["ddtrace-run", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app.main:create_app()"]
