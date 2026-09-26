ARG PYTHON_IMAGE=python:3.13-slim
ARG UV_IMAGE=ghcr.io/astral-sh/uv:latest

FROM ${UV_IMAGE} AS uv
FROM ${PYTHON_IMAGE}

WORKDIR /app

COPY --from=uv /uv /uvx /bin/
COPY pyproject.toml uv.lock ./

RUN uv sync --frozen --no-dev

COPY alembic.ini ./alembic.ini
COPY migrations ./migrations
COPY app ./app

EXPOSE 8000
CMD ["sh", "-c", "uv run alembic upgrade head && uv run uvicorn app.main:app --host 0.0.0.0 --port 8000"]
