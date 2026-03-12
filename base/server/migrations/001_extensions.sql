-- 001_extensions.sql
-- 启用必要的 PostgreSQL 扩展：uuid-ossp 用于 UUID 生成，TimescaleDB 用于时序数据处理

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS timescaledb;
