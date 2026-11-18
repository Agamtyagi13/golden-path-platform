FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=${{ values.port }}
WORKDIR /srv

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Non-root, matches the Kyverno/PSA restricted profile used in the cluster
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin appuser
USER 10001

EXPOSE ${{ values.port }}
CMD ["sh", "-c", "exec gunicorn --worker-tmp-dir /dev/shm -b 0.0.0.0:${PORT} app.main:app"]
