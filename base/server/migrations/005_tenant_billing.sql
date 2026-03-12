-- 005_tenant_billing.sql
-- 租户与计费相关表：Tenant（租户）、Lease（租约）、BillingRule（计费规则）、BillingRecord（计费记录）

-- ============================================================
-- 枚举类型
-- ============================================================

CREATE TYPE tenant_type AS ENUM (
    'ENTERPRISE', 'INDIVIDUAL', 'GOVERNMENT'
);

CREATE TYPE tenant_status AS ENUM (
    'ACTIVE', 'EXPIRED', 'PENDING'
);

CREATE TYPE lease_status AS ENUM (
    'ACTIVE', 'EXPIRED', 'PENDING', 'TERMINATED'
);

CREATE TYPE billing_type AS ENUM (
    'BY_AREA', 'BY_COOLING', 'BY_TIME', 'BY_USAGE', 'MIXED'
);

CREATE TYPE billing_status AS ENUM (
    'DRAFT', 'CONFIRMED', 'PAID'
);

-- ============================================================
-- Tenant（租户）
-- ============================================================

CREATE TABLE tenants (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(id),
    name                VARCHAR(200) NOT NULL,
    type                tenant_type NOT NULL,
    contact_name        VARCHAR(100),
    contact_phone       VARCHAR(30),
    contact_email       VARCHAR(200),
    lease_start         DATE,
    lease_end           DATE,
    space_ids           UUID[],
    energy_meter_ids    UUID[],
    metadata            JSONB,
    status              tenant_status NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- Lease（租约）
-- ============================================================

CREATE TABLE leases (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    building_id         UUID NOT NULL REFERENCES buildings(id),
    spaces              UUID[] NOT NULL,
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    billing_model       VARCHAR(50),
    power_limit_kw      DOUBLE PRECISION,
    metadata            JSONB,
    status              lease_status NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- BillingRule（计费规则）
-- ============================================================

CREATE TABLE billing_rules (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                    VARCHAR(200) NOT NULL,
    type                    billing_type NOT NULL,
    rate_table              JSONB NOT NULL,
    shared_cost_algorithm   VARCHAR(50),
    overtime_rate           DOUBLE PRECISION,
    tenant_ids              UUID[],
    energy_meter_ids        UUID[],
    metadata                JSONB,
    status                  entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- BillingRecord（计费记录）
-- ============================================================

CREATE TABLE billing_records (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID NOT NULL REFERENCES tenants(id),
    billing_rule_id     UUID REFERENCES billing_rules(id),
    period              VARCHAR(20) NOT NULL,
    meter_readings      JSONB NOT NULL,
    amount              DOUBLE PRECISION NOT NULL,
    shared_cost         DOUBLE PRECISION,
    total               DOUBLE PRECISION NOT NULL,
    currency            VARCHAR(3) NOT NULL DEFAULT 'CNY',
    metadata            JSONB,
    status              billing_status NOT NULL DEFAULT 'DRAFT',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
