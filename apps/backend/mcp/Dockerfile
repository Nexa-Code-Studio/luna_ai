FROM python:3.11-slim

WORKDIR /workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY packages/shared packages/shared
COPY packages/ai packages/ai
COPY apps/backend/mcp apps/backend/mcp

RUN pip install --no-cache-dir -e ./packages/shared
RUN pip install --no-cache-dir -e ./packages/ai
RUN pip install --no-cache-dir -e ./apps/backend/mcp

WORKDIR /workspace/apps/backend/mcp

EXPOSE 8001

CMD ["python", "-m", "app.main"]
