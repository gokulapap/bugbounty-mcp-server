# syntax=docker/dockerfile:1
FROM python:3.14-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DATA_DIR=/app/data \
    OUTPUT_DIR=/app/output

RUN groupadd --gid 10001 bugbounty \
    && useradd --uid 10001 --gid 10001 --create-home --home-dir /home/bugbounty bugbounty

WORKDIR /app

COPY pyproject.toml README.md LICENSE ./
COPY bugbounty_mcp_server ./bugbounty_mcp_server
RUN python -m pip install --no-cache-dir .

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod 0755 /usr/local/bin/docker-entrypoint \
    && mkdir -p /app/data /app/output \
    && chown -R bugbounty:bugbounty /app/data /app/output

USER 10001:10001

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD bugbounty-mcp validate-config --json >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["serve"]

LABEL org.opencontainers.image.title="BugBounty MCP Server" \
      org.opencontainers.image.description="Scope-safe MCP server for authorized bug bounty work" \
      org.opencontainers.image.version="2.1.0" \
      org.opencontainers.image.source="https://github.com/gokulapap/bugbounty-mcp-server" \
      org.opencontainers.image.licenses="MIT"
