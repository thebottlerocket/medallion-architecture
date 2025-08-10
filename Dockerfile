FROM python:3.11-slim

# Prevent interactive tzdata prompts etc.
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DBT_PROFILES_DIR=/app/profiles \
    DBT_LOG_LEVEL=info

WORKDIR /app

# Minimal system deps; keep image slim.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
 && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt /app/requirements.txt

# Install Python deps with specific versions for reproducibility
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app

# Make sure target dir exists for DuckDB file
RUN mkdir -p /app/target && chmod -R 777 /app/target

# Entrypoint runs dbt seed/run/test and shows a preview of gold view
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
