FROM python:3.11-slim
WORKDIR /app
RUN mkdir -p /exports /app/data
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/

ARG DD_GIT_REPOSITORY_URL
ARG DD_GIT_COMMIT_SHA
ENV DD_GIT_REPOSITORY_URL=${DD_GIT_REPOSITORY_URL}
ENV DD_GIT_COMMIT_SHA=${DD_GIT_COMMIT_SHA}

EXPOSE 5000
CMD ["ddtrace-run", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app.main:create_app()"]
