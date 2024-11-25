# Build base image
FROM python:3.8-slim AS python-base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=1.1.14 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv" \
    PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Build dev image
FROM python-base AS dev-base

# Install dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    libsndfile1 \
    libsndfile1-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python && \
    mv /root/.local/bin/poetry /usr/local/bin/poetry

# Verify Poetry Installation
RUN poetry --version

# Copy project dependency files
COPY poetry.lock pyproject.toml ./

# Install project dependencies with Poetry
RUN poetry install --no-root

# Build production image
FROM python-base AS production

# Copy dependencies and setup files from dev-base
COPY --from=dev-base $PYSETUP_PATH $PYSETUP_PATH

# Copy application code
COPY . /app

# Set the working directory
WORKDIR /app

# Expose the port
EXPOSE ${PORT:-8000}

# Command to run the app using Gunicorn
CMD ["gunicorn", "--workers=4", "--bind", "0.0.0.0:8000", "app:app"]
