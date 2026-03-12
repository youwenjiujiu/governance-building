-- 007_timescale.sql
-- 时序数据表：point_values（基于 TimescaleDB hypertable）
-- 包含连续聚合视图（5分钟/1小时/1天）和数据保留策略

-- ============================================================
-- 趋势来源枚举
-- ============================================================

CREATE TYPE trend_source AS ENUM (
    'FIELD', 'CALCULATED', 'MANUAL', 'IMPORTED', 'SIMULATED'
);

-- ============================================================
-- point_values 时序主表
-- ============================================================

CREATE TABLE point_values (
    point_id        UUID NOT NULL,
    ts              TIMESTAMPTZ NOT NULL,
    value_numeric   DOUBLE PRECISION,
    value_text      VARCHAR(200),
    value_bool      BOOLEAN,
    value_json      JSONB,
    quality         point_quality NOT NULL DEFAULT 'GOOD',
    source          trend_source,
    annotation      VARCHAR(500)
);

-- 转为 TimescaleDB hypertable，按 ts 分区，chunk 间隔 7 天
SELECT create_hypertable('point_values', 'ts', chunk_time_interval => INTERVAL '7 days');

-- 主索引：point_id + ts（hypertable 自动包含 ts 索引，这里补 point_id 联合索引）
CREATE INDEX idx_point_values_point_ts ON point_values (point_id, ts DESC);

-- ============================================================
-- 启用压缩策略：超过 7 天的 chunk 自动压缩
-- ============================================================

ALTER TABLE point_values SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'point_id',
    timescaledb.compress_orderby = 'ts DESC'
);

SELECT add_compression_policy('point_values', INTERVAL '7 days');

-- ============================================================
-- 数据保留策略：原始数据保留 90 天
-- ============================================================

SELECT add_retention_policy('point_values', INTERVAL '90 days');

-- ============================================================
-- 连续聚合视图：5 分钟聚合
-- ============================================================

CREATE MATERIALIZED VIEW point_values_5min
WITH (timescaledb.continuous) AS
SELECT
    point_id,
    time_bucket('5 minutes', ts) AS bucket,
    avg(value_numeric)          AS avg_value,
    min(value_numeric)          AS min_value,
    max(value_numeric)          AS max_value,
    sum(value_numeric)          AS sum_value,
    count(*)                    AS sample_count,
    first(value_numeric, ts)    AS first_value,
    last(value_numeric, ts)     AS last_value,
    count(*) FILTER (WHERE quality = 'GOOD') * 100.0 / NULLIF(count(*), 0)
                                AS quality_good_pct
FROM point_values
GROUP BY point_id, time_bucket('5 minutes', ts)
WITH NO DATA;

-- 刷新策略：持续刷新，滞后 10 分钟
SELECT add_continuous_aggregate_policy('point_values_5min',
    start_offset    => INTERVAL '2 hours',
    end_offset      => INTERVAL '10 minutes',
    schedule_interval => INTERVAL '5 minutes'
);

-- 5 分钟聚合保留 1 年
SELECT add_retention_policy('point_values_5min', INTERVAL '1 year');

-- ============================================================
-- 连续聚合视图：1 小时聚合
-- ============================================================

CREATE MATERIALIZED VIEW point_values_1hour
WITH (timescaledb.continuous) AS
SELECT
    point_id,
    time_bucket('1 hour', ts) AS bucket,
    avg(value_numeric)          AS avg_value,
    min(value_numeric)          AS min_value,
    max(value_numeric)          AS max_value,
    sum(value_numeric)          AS sum_value,
    count(*)                    AS sample_count,
    first(value_numeric, ts)    AS first_value,
    last(value_numeric, ts)     AS last_value,
    count(*) FILTER (WHERE quality = 'GOOD') * 100.0 / NULLIF(count(*), 0)
                                AS quality_good_pct
FROM point_values
GROUP BY point_id, time_bucket('1 hour', ts)
WITH NO DATA;

SELECT add_continuous_aggregate_policy('point_values_1hour',
    start_offset    => INTERVAL '12 hours',
    end_offset      => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);

-- 1 小时聚合保留 3 年
SELECT add_retention_policy('point_values_1hour', INTERVAL '3 years');

-- ============================================================
-- 连续聚合视图：1 天聚合
-- ============================================================

CREATE MATERIALIZED VIEW point_values_1day
WITH (timescaledb.continuous) AS
SELECT
    point_id,
    time_bucket('1 day', ts) AS bucket,
    avg(value_numeric)          AS avg_value,
    min(value_numeric)          AS min_value,
    max(value_numeric)          AS max_value,
    sum(value_numeric)          AS sum_value,
    count(*)                    AS sample_count,
    first(value_numeric, ts)    AS first_value,
    last(value_numeric, ts)     AS last_value,
    count(*) FILTER (WHERE quality = 'GOOD') * 100.0 / NULLIF(count(*), 0)
                                AS quality_good_pct
FROM point_values
GROUP BY point_id, time_bucket('1 day', ts)
WITH NO DATA;

SELECT add_continuous_aggregate_policy('point_values_1day',
    start_offset    => INTERVAL '3 days',
    end_offset      => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day'
);

-- 1 天聚合保留 10 年
SELECT add_retention_policy('point_values_1day', INTERVAL '10 years');
