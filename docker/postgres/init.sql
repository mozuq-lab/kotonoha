-- PostgreSQL Initialization Script for kotonoha project
-- This script is executed when the PostgreSQL container is first created

-- Create test database for pytest
CREATE DATABASE kotonoha_test;

-- Create database (if not exists)
-- Note: The database is already created via POSTGRES_DB environment variable
-- This is a placeholder for future initialization needs

-- Set timezone
SET timezone = 'Asia/Tokyo';

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text search optimization

-- Create schema version table for tracking migrations
-- Note: Alembic will manage migrations, but this provides a basic schema info table
CREATE TABLE IF NOT EXISTS schema_info (
    version VARCHAR(50) PRIMARY KEY,
    description TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial schema version
INSERT INTO schema_info (version, description)
VALUES ('0.0.0', 'Initial database setup')
ON CONFLICT (version) DO NOTHING;

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'kotonoha database initialization completed successfully';
END $$;
