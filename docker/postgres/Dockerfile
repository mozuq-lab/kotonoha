# PostgreSQL 15+ Dockerfile for kotonoha project
FROM postgres:15-alpine

# Set environment variables
ENV POSTGRES_DB=kotonoha_db
ENV POSTGRES_USER=kotonoha_user
ENV LANG=ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8

# Copy initialization scripts
COPY init.sql /docker-entrypoint-initdb.d/

# Expose PostgreSQL port
EXPOSE 5432

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} || exit 1
