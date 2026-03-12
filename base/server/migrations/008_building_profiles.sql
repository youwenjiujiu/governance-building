-- 008_building_profiles.sql
-- BuildingProfile（楼宇模板）、Scenario（场景模式）、ComplianceRule（合规规则）、EnergyMeter（能源计量）

-- ============================================================
-- 枚举类型
-- ============================================================

CREATE TYPE scenario_type AS ENUM (
    'NORMAL', 'HOLIDAY', 'WEEKEND', 'EMERGENCY', 'VIP',
    'ENERGY_SAVING', 'NIGHT', 'PEAK_SHAVING', 'CUSTOM'
);

CREATE TYPE scenario_state AS ENUM (
    'INACTIVE', 'ACTIVE', 'COOLDOWN'
);

CREATE TYPE activation_mode AS ENUM (
    'AUTO', 'MANUAL', 'SCHEDULED', 'HYBRID'
);

CREATE TYPE compliance_rule_type AS ENUM (
    'DATA_RETENTION', 'AUDIT_REQUIREMENT', 'INSPECTION_FREQUENCY',
    'CERTIFICATION_RENEWAL', 'EMISSION_LIMIT', 'ENERGY_REPORTING', 'SAFETY_STANDARD'
);

CREATE TYPE enforcement_level AS ENUM (
    'MANDATORY', 'RECOMMENDED', 'OPTIONAL'
);

CREATE TYPE meter_type AS ENUM (
    'ELECTRICITY', 'GAS', 'WATER', 'STEAM',
    'CHILLED_WATER', 'HOT_WATER', 'FUEL', 'RENEWABLE'
);

CREATE TYPE energy_sub_type AS ENUM (
    'TOTAL', 'HVAC', 'LIGHTING', 'POWER_OUTLET',
    'ELEVATOR', 'SPECIAL', 'DOMESTIC_HOT_WATER'
);

CREATE TYPE energy_measurement AS ENUM (
    'ACTIVE_ENERGY', 'REACTIVE_ENERGY', 'ACTIVE_POWER',
    'APPARENT_POWER', 'POWER_FACTOR', 'VOLUME',
    'THERMAL_ENERGY', 'MASS_FLOW'
);

-- ============================================================
-- BuildingProfile（楼宇模板）
-- ============================================================

CREATE TABLE building_profiles (
    id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                            VARCHAR(50) NOT NULL UNIQUE,
    name                            VARCHAR(200) NOT NULL,
    description                     TEXT,
    building_type                   building_type NOT NULL,
    version                         VARCHAR(20) NOT NULL,
    is_published                    BOOLEAN NOT NULL DEFAULT false,
    default_systems                 JSONB NOT NULL,
    default_equipment_templates     JSONB,
    default_point_templates         JSONB,
    default_alarm_rules             UUID[],
    default_schedules               JSONB,
    default_scenarios               JSONB,
    compliance_rules                UUID[],
    recommended_energy_meters       JSONB,
    tags                            VARCHAR(50)[],
    metadata                        JSONB,
    status                          entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 回填 buildings.profile_id 外键
ALTER TABLE buildings
    ADD CONSTRAINT fk_buildings_profile
    FOREIGN KEY (profile_id) REFERENCES building_profiles(id);

-- ============================================================
-- Scenario（场景模式）
-- ============================================================

CREATE TABLE scenarios (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id             UUID NOT NULL REFERENCES buildings(id),
    code                    VARCHAR(50) NOT NULL,
    name                    VARCHAR(200) NOT NULL,
    description             TEXT,
    scenario_type           scenario_type NOT NULL,
    priority                INT NOT NULL DEFAULT 0,
    is_exclusive            BOOLEAN NOT NULL DEFAULT false,
    trigger_conditions      JSONB NOT NULL,
    actions                 JSONB NOT NULL,
    rollback_actions        JSONB,
    activation_mode         activation_mode NOT NULL DEFAULT 'AUTO',
    current_state           scenario_state NOT NULL DEFAULT 'INACTIVE',
    activated_at            TIMESTAMPTZ,
    activated_by            UUID,
    deactivated_at          TIMESTAMPTZ,
    cooldown_s              INT,
    max_duration_s          INT,
    applicable_schedules    UUID[],
    tags                    VARCHAR(50)[],
    metadata                JSONB,
    status                  entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (building_id, code)
);

-- ============================================================
-- ComplianceRule（合规规则）
-- ============================================================

CREATE TABLE compliance_rules (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                    VARCHAR(50) NOT NULL UNIQUE,
    name                    VARCHAR(200) NOT NULL,
    description             TEXT,
    regulation_ref          VARCHAR(200),
    regulation_version      VARCHAR(50),
    effective_date          DATE,
    expiry_date             DATE,
    -- v2 扩展字段
    food_safety_category    VARCHAR(50),
    sla_target              VARCHAR(100),
    measurement_method      VARCHAR(200),
    country                 VARCHAR(3) NOT NULL,
    region                  VARCHAR(50),
    industry                VARCHAR(50),
    building_types          building_type[],
    rule_type               compliance_rule_type NOT NULL,
    rule_config             JSONB NOT NULL,
    check_interval          VARCHAR(20),
    enforcement_level       enforcement_level NOT NULL,
    penalty_description     TEXT,
    effective_from          DATE,
    effective_to            DATE,
    tags                    VARCHAR(50)[],
    metadata                JSONB,
    status                  entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- EnergyMeter（能源计量）
-- ============================================================

CREATE TABLE energy_meters (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id             UUID NOT NULL REFERENCES buildings(id),
    parent_meter_id         UUID REFERENCES energy_meters(id),
    code                    VARCHAR(50) NOT NULL,
    name                    VARCHAR(200) NOT NULL,
    meter_type              meter_type NOT NULL,
    sub_type                energy_sub_type,
    measurement             energy_measurement NOT NULL,
    unit                    VARCHAR(20) NOT NULL,
    ct_ratio                DOUBLE PRECISION,
    pt_ratio                DOUBLE PRECISION,
    multiplier              DOUBLE PRECISION,
    point_id                UUID REFERENCES points(id),
    equipment_id            UUID REFERENCES equipment(id),
    serves_systems          UUID[],
    serves_zones            UUID[],
    tariff_schedule         JSONB,
    billing_cycle           VARCHAR(20),
    cost_center             VARCHAR(50),
    install_date            DATE,
    last_calibration_date   DATE,
    next_calibration_date   DATE,
    tags                    VARCHAR(50)[],
    metadata                JSONB,
    status                  entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (building_id, code)
);
