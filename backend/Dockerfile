FROM python:3.11-slim

WORKDIR /app

# Install system dependencies including PostgreSQL client for RDS connectivity
RUN apt-get update && apt-get install -y \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VERSION=1.6.1 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=false \
    POETRY_NO_INTERACTION=1 \
    POSTGRES_SERVER=db \
    PROJECT_NAME="Full Stack FastAPI Project" \
    STACK_NAME=full-stack-fastapi-project \
    USERS_OPEN_REGISTRATION=True

# Install poetry
RUN pip install "poetry==$POETRY_VERSION"

# Copy poetry configuration files
COPY pyproject.toml poetry.lock ./

# Install dependencies
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root --without dev

# Copy application code
COPY . .

# Make prestart.sh executable
RUN chmod +x /app/prestart.sh

# Expose port
EXPOSE 8000

# Set up container healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run prestart script and start the application
CMD ["sh", "-c", "./prestart.sh && uvicorn app.main:app --host 0.0.0.0 --port 8000"]