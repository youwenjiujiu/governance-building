-- 003_alarm_tables.sql
-- 告警相关表：AlarmRule（告警规则模板）、Alarm（告警实例）
-- 包含告警状态机、严重度、类别等枚举定义

-- ============================================================
-- 枚举类型
-- ============================================================

CREATE TYPE alarm_severity AS ENUM (
    'CRITICAL', 'MAJOR', 'MINOR', 'WARNING', 'INFO'
);

CREATE TYPE alarm_category AS ENUM (
    'FIRE', 'SECURITY', 'LIFE_SAFETY', 'PROCESS', 'EQUIPMENT_FAULT',
    'COMMUNICATION', 'ENERGY', 'ENVIRONMENTAL', 'MAINTENANCE', 'SYSTEM',
    'MEDICAL_GAS', 'CLEAN_ROOM', 'COLD_CHAIN', 'RADIATION', 'WATER_QUALITY',
    'KITCHEN_EXHAUST', 'REFRIGERATION', 'CROWD_SAFETY', 'FLOOD',
    'COOLING', 'POWER', 'WATER_LEAK', 'CAPACITY', 'POOL_WATER', 'HOT_WATER'
);

CREATE TYPE alarm_state AS ENUM (
    'ACTIVE_UNACKED', 'ACTIVE_ACKED', 'CLEARED_UNACKED', 'CLEARED_ACKED', 'CLOSED'
);

CREATE TYPE condition_type AS ENUM (
    'HI_HI_LIMIT', 'HI_LIMIT', 'LO_LIMIT', 'LO_LO_LIMIT',
    'DEVIATION', 'RATE_OF_CHANGE', 'STATE_CHANGE',
    'BOOL_TRUE', 'BOOL_FALSE', 'EXPRESSION', 'OFFLINE', 'STALE'
);

CREATE TYPE patient_impact AS ENUM (
    'NONE', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
);

CREATE TYPE affected_scope AS ENUM (
    'EQUIPMENT', 'ZONE', 'FLOOR', 'BUILDING', 'CAMPUS'
);

-- ============================================================
-- AlarmRule（告警规则模板）
-- ============================================================

CREATE TABLE alarm_rules (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                        VARCHAR(50) NOT NULL UNIQUE,
    name                        VARCHAR(200) NOT NULL,
    description                 TEXT,
    severity                    alarm_severity NOT NULL,
    category                    alarm_category NOT NULL,
    target_point_class          VARCHAR(100),
    target_equipment_type       equipment_type,
    condition_type              condition_type NOT NULL,
    condition_expr              TEXT NOT NULL,
    threshold_default           DECIMAL(15,4),
    deadband_default            DECIMAL(10,4),
    delay_s_default             INT,
    escalation_rules            JSONB,
    suppression_rules           JSONB,
    auto_create_work_order      BOOLEAN DEFAULT false,
    notification_template_id    UUID,
    applicable_building_types   building_type[],
    tags                        VARCHAR(50)[],
    metadata                    JSONB,
    status                      entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Alarm（告警实例）
-- ============================================================

CREATE TABLE alarms (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id                 UUID NOT NULL REFERENCES buildings(id),
    alarm_rule_id               UUID REFERENCES alarm_rules(id),
    point_id                    UUID REFERENCES points(id),
    equipment_id                UUID REFERENCES equipment(id),
    zone_id                     UUID REFERENCES zones(id),
    alarm_code                  VARCHAR(50) NOT NULL,
    severity                    alarm_severity NOT NULL,
    category                    alarm_category NOT NULL,
    state                       alarm_state NOT NULL DEFAULT 'ACTIVE_UNACKED',
    title                       VARCHAR(300) NOT NULL,
    description                 TEXT,
    trigger_value               VARCHAR(50),
    threshold_value             VARCHAR(50),
    triggered_at                TIMESTAMPTZ NOT NULL,
    acked_at                    TIMESTAMPTZ,
    acked_by                    UUID,
    ack_note                    TEXT,
    cleared_at                  TIMESTAMPTZ,
    closed_at                   TIMESTAMPTZ,
    closed_by                   UUID,
    close_note                  TEXT,
    duration_s                  INT,
    escalation_level            SMALLINT NOT NULL DEFAULT 0,
    escalation_history          JSONB,
    is_suppressed               BOOLEAN NOT NULL DEFAULT false,
    suppressed_by               VARCHAR(100),
    work_order_id               UUID,  -- FK added in 004_operational_tables.sql
    repeat_count                INT DEFAULT 1,
    -- v2 扩展字段
    patient_impact              patient_impact,
    affected_scope              affected_scope,
    regulatory_report_required  BOOLEAN DEFAULT false,
    tags                        VARCHAR(50)[],
    metadata                    JSONB,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);
