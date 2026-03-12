-- 004_operational_tables.sql
-- 运营相关表：Schedule（排程）、WorkOrder（工单）、AuditLog（审计日志）、Notification（通知）
-- 包含工单状态机、排程类型、审计操作等枚举定义

-- ============================================================
-- 枚举类型
-- ============================================================

CREATE TYPE schedule_type AS ENUM (
    'WEEKLY', 'CALENDAR', 'ONE_TIME', 'RECURRING'
);

CREATE TYPE calendar_system AS ENUM (
    'GREGORIAN', 'CHINESE_LUNAR', 'ISLAMIC', 'CUSTOM'
);

CREATE TYPE work_order_type AS ENUM (
    'CORRECTIVE', 'PREVENTIVE', 'PREDICTIVE', 'INSPECTION',
    'EMERGENCY', 'PROJECT', 'REQUEST'
);

CREATE TYPE work_order_priority AS ENUM (
    'EMERGENCY', 'HIGH', 'MEDIUM', 'LOW', 'PLANNED'
);

CREATE TYPE work_order_state AS ENUM (
    'OPEN', 'ASSIGNED', 'IN_PROGRESS', 'PENDING_PARTS', 'PENDING_APPROVAL',
    'COMPLETED', 'VERIFIED', 'CLOSED', 'CANCELLED', 'REOPENED'
);

CREATE TYPE work_order_source AS ENUM (
    'ALARM', 'MANUAL', 'SCHEDULE', 'INSPECTION', 'TENANT_REQUEST', 'AI_PREDICTION'
);

CREATE TYPE work_order_change_type AS ENUM (
    'MAINTENANCE', 'EMERGENCY', 'PLANNED_CHANGE', 'STANDARD_CHANGE', 'CAB_REQUIRED'
);

CREATE TYPE risk_level AS ENUM (
    'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
);

CREATE TYPE cab_approval AS ENUM (
    'NOT_REQUIRED', 'PENDING', 'APPROVED', 'REJECTED'
);

CREATE TYPE audit_action AS ENUM (
    'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'LOGIN_FAILED',
    'POINT_WRITE', 'ALARM_ACK', 'ALARM_CLOSE', 'SCENARIO_ACTIVATE',
    'SCENARIO_DEACTIVATE', 'SCHEDULE_OVERRIDE', 'PERMISSION_GRANT',
    'PERMISSION_REVOKE', 'CONFIG_CHANGE', 'DATA_EXPORT'
);

CREATE TYPE audit_result AS ENUM (
    'SUCCESS', 'FAILURE', 'DENIED'
);

CREATE TYPE notification_type AS ENUM (
    'ALARM', 'WORK_ORDER', 'REPORT', 'SYSTEM',
    'MAINTENANCE_REMINDER', 'COMPLIANCE_ALERT', 'ENERGY_ALERT'
);

CREATE TYPE notification_channel AS ENUM (
    'EMAIL', 'SMS', 'PUSH', 'WECHAT', 'DINGTALK',
    'WEBHOOK', 'PA_SYSTEM', 'PA_BROADCAST', 'IN_APP'
);

CREATE TYPE notification_priority AS ENUM (
    'URGENT', 'HIGH', 'NORMAL', 'LOW'
);

CREATE TYPE send_state AS ENUM (
    'PENDING', 'SENDING', 'SENT', 'DELIVERED', 'READ', 'FAILED', 'CANCELLED'
);

-- ============================================================
-- Schedule（排程）
-- ============================================================

CREATE TABLE schedules (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id         UUID NOT NULL REFERENCES buildings(id),
    code                VARCHAR(50) NOT NULL,
    name                VARCHAR(200) NOT NULL,
    schedule_type       schedule_type NOT NULL,
    target_type         VARCHAR(50) NOT NULL,
    target_ids          UUID[] NOT NULL,
    target_point_id     UUID REFERENCES points(id),
    timezone            VARCHAR(40) NOT NULL,
    calendar_system     calendar_system NOT NULL DEFAULT 'GREGORIAN',
    weekly_schedule     JSONB,
    yearly_calendar     JSONB,
    exceptions          JSONB,
    effective_from      DATE,
    effective_to        DATE,
    priority            INT NOT NULL DEFAULT 10,
    metadata            JSONB,
    status              entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (building_id, code)
);

-- ============================================================
-- WorkOrder（工单）
-- ============================================================

CREATE TABLE work_orders (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id             UUID NOT NULL REFERENCES buildings(id),
    code                    VARCHAR(50) NOT NULL UNIQUE,
    title                   VARCHAR(300) NOT NULL,
    description             TEXT,
    wo_type                 work_order_type NOT NULL,
    priority                work_order_priority NOT NULL,
    state                   work_order_state NOT NULL DEFAULT 'OPEN',
    source                  work_order_source NOT NULL,
    alarm_id                UUID REFERENCES alarms(id),
    target_type             VARCHAR(50),
    target_id               UUID,
    zone_id                 UUID REFERENCES zones(id),
    requested_by            UUID NOT NULL,
    assigned_to             UUID,
    assigned_team           VARCHAR(100),
    sla_response_min        INT,
    sla_resolve_min         INT,
    sla_response_deadline   TIMESTAMPTZ,
    sla_resolve_deadline    TIMESTAMPTZ,
    sla_response_met        BOOLEAN,
    sla_resolve_met         BOOLEAN,
    responded_at            TIMESTAMPTZ,
    started_at              TIMESTAMPTZ,
    completed_at            TIMESTAMPTZ,
    verified_at             TIMESTAMPTZ,
    closed_at               TIMESTAMPTZ,
    cancelled_at            TIMESTAMPTZ,
    resolution              TEXT,
    root_cause              TEXT,
    labor_hours             DECIMAL(8,2),
    cost                    DECIMAL(12,2),
    cost_currency           VARCHAR(3),
    consumed_assets         JSONB,
    attachments             JSONB,
    comments                JSONB,
    -- v2 扩展字段
    change_type             work_order_change_type,
    risk_level              risk_level,
    cab_approval            cab_approval,
    reviewer_id             UUID,
    reviewed_at             TIMESTAMPTZ,
    tags                    VARCHAR(50)[],
    metadata                JSONB,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 回填 alarms.work_order_id 外键
ALTER TABLE alarms
    ADD CONSTRAINT fk_alarms_work_order
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id);

-- ============================================================
-- AuditLog（审计日志）
-- ============================================================

CREATE TABLE audit_logs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp           TIMESTAMPTZ NOT NULL DEFAULT now(),
    user_id             UUID,
    user_name           VARCHAR(100),
    client_ip           VARCHAR(45),
    user_agent          VARCHAR(500),
    action              audit_action NOT NULL,
    resource_type       VARCHAR(50) NOT NULL,
    resource_id         UUID NOT NULL,
    resource_name       VARCHAR(200),
    building_id         UUID REFERENCES buildings(id),
    org_id              UUID REFERENCES organizations(id),
    before_value        JSONB,
    after_value         JSONB,
    description         TEXT,
    result              audit_result NOT NULL,
    error_message       TEXT,
    session_id          VARCHAR(100),
    correlation_id      VARCHAR(100),
    reviewer_id         UUID,
    reviewed_at         TIMESTAMPTZ,
    metadata            JSONB,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Notification（通知）
-- ============================================================

CREATE TABLE notifications (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id                  UUID NOT NULL REFERENCES organizations(id),
    building_id             UUID REFERENCES buildings(id),
    notification_type       notification_type NOT NULL,
    channel                 notification_channel NOT NULL,
    priority                notification_priority NOT NULL DEFAULT 'NORMAL',
    source_type             VARCHAR(50) NOT NULL,
    source_id               UUID NOT NULL,
    template_id             UUID,
    recipient_user_id       UUID,
    recipient_role          VARCHAR(50),
    recipient_address       VARCHAR(200) NOT NULL,
    title                   VARCHAR(300) NOT NULL,
    body                    TEXT NOT NULL,
    body_html               TEXT,
    send_state              send_state NOT NULL DEFAULT 'PENDING',
    scheduled_at            TIMESTAMPTZ,
    sent_at                 TIMESTAMPTZ,
    delivered_at            TIMESTAMPTZ,
    read_at                 TIMESTAMPTZ,
    failed_reason           TEXT,
    retry_count             INT NOT NULL DEFAULT 0,
    max_retries             INT NOT NULL DEFAULT 3,
    metadata                JSONB,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);
