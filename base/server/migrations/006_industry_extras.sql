-- 006_industry_extras.sql
-- 行业扩展表：RedundancyGroup（冗余组）、CabinetAsset（机柜资产）、TrafficSensor（客流传感器）、EmissionMonitoring（排放监测）

-- ============================================================
-- 枚举类型
-- ============================================================

CREATE TYPE redundancy_type AS ENUM (
    'N_PLUS_1', 'TWO_N', 'TWO_N_PLUS_1'
);

CREATE TYPE traffic_sensor_type AS ENUM (
    'INFRARED', 'VIDEO', 'WIFI', 'BLUETOOTH'
);

CREATE TYPE traffic_direction AS ENUM (
    'IN', 'OUT', 'BIDIRECTIONAL'
);

CREATE TYPE emission_type AS ENUM (
    'FUME', 'EXHAUST_GAS', 'WASTEWATER', 'NOISE'
);

-- ============================================================
-- RedundancyGroup（冗余组）
-- ============================================================

CREATE TABLE redundancy_groups (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                    VARCHAR(200) NOT NULL,
    building_id             UUID NOT NULL REFERENCES buildings(id),
    type                    redundancy_type NOT NULL,
    primary_equipment_ids   UUID[] NOT NULL,
    standby_equipment_ids   UUID[] NOT NULL,
    auto_failover           BOOLEAN NOT NULL DEFAULT true,
    metadata                JSONB,
    status                  entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 添加 equipment.redundancy_group_id 外键约束
ALTER TABLE equipment
    ADD CONSTRAINT fk_equipment_redundancy_group
    FOREIGN KEY (redundancy_group_id) REFERENCES redundancy_groups(id);

-- ============================================================
-- CabinetAsset（机柜资产）— 数据中心专用
-- ============================================================

CREATE TABLE cabinet_assets (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(200) NOT NULL,
    zone_id             UUID NOT NULL REFERENCES zones(id),
    building_id         UUID NOT NULL REFERENCES buildings(id),
    total_u             SMALLINT NOT NULL,
    used_u              SMALLINT,
    power_capacity_kw   DECIMAL(8,2),
    actual_power_kw     DECIMAL(8,2),
    cooling_capacity_kw DECIMAL(8,2),
    network_ports       INT,
    weight_limit_kg     DECIMAL(8,2),
    metadata            JSONB,
    status              entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- TrafficSensor（客流传感器）
-- ============================================================

CREATE TABLE traffic_sensors (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200) NOT NULL,
    zone_id         UUID NOT NULL REFERENCES zones(id),
    building_id     UUID NOT NULL REFERENCES buildings(id),
    sensor_type     traffic_sensor_type NOT NULL,
    direction       traffic_direction NOT NULL,
    metadata        JSONB,
    status          entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- EmissionMonitoring（排放监测）
-- ============================================================

CREATE TABLE emission_monitorings (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                    VARCHAR(200) NOT NULL,
    building_id             UUID NOT NULL REFERENCES buildings(id),
    zone_id                 UUID REFERENCES zones(id),
    type                    emission_type NOT NULL,
    regulation_standard     VARCHAR(200),
    limit_value             DECIMAL(12,4),
    unit                    VARCHAR(20),
    point_id                UUID REFERENCES points(id),
    metadata                JSONB,
    status                  entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);
