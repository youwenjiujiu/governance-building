-- 002_core_entities.sql
-- 核心实体表：Organization, Site, Building, Floor, Zone, System, Equipment, Component, Point
-- 以及所有相关的枚举类型定义

-- ============================================================
-- 枚举类型
-- ============================================================

CREATE TYPE entity_status AS ENUM (
    'ACTIVE', 'INACTIVE', 'ARCHIVED', 'DELETED', 'PENDING'
);

CREATE TYPE org_type AS ENUM (
    'ENTERPRISE', 'SUBSIDIARY', 'PROPERTY_MGMT', 'SERVICE_PROVIDER', 'GOVERNMENT'
);

CREATE TYPE building_type AS ENUM (
    'OFFICE', 'HOTEL', 'HOSPITAL', 'MALL', 'FACTORY', 'WAREHOUSE',
    'RESIDENTIAL', 'SCHOOL', 'DATA_CENTER', 'CONVENTION', 'STADIUM',
    'AIRPORT', 'RAIL_STATION', 'MIXED_USE', 'OTHER'
);

CREATE TYPE climate_zone AS ENUM (
    'SEVERE_COLD', 'COLD', 'HOT_SUMMER_COLD_WINTER',
    'HOT_SUMMER_WARM_WINTER', 'MILD', 'TROPICAL', 'MARINE'
);

CREATE TYPE floor_type AS ENUM (
    'STANDARD', 'MECHANICAL', 'REFUGE', 'LOBBY', 'ROOF', 'PARKING', 'BASEMENT_MECHANICAL'
);

CREATE TYPE space_type AS ENUM (
    'OFFICE', 'MEETING_ROOM', 'LOBBY', 'CORRIDOR', 'RESTROOM',
    'STAIRWELL', 'ELEVATOR_HALL', 'MECHANICAL_ROOM', 'ELECTRICAL_ROOM',
    'SERVER_ROOM', 'KITCHEN', 'DINING', 'STORAGE', 'PARKING',
    'GUEST_ROOM', 'WARD', 'OPERATING_ROOM', 'RETAIL', 'PRODUCTION',
    'CLEANROOM', 'OUTDOOR', 'ICU', 'ISOLATION_ROOM', 'PHARMACY',
    'BLOOD_BANK', 'RADIOLOGY', 'RETAIL_UNIT', 'FOOD_COURT', 'ATRIUM',
    'LOADING_DOCK', 'COLD_STORAGE', 'WHITE_SPACE', 'GRAY_SPACE',
    'BATTERY_ROOM', 'GENERATOR_YARD', 'NOC', 'BANQUET_HALL', 'SPA',
    'SWIMMING_POOL', 'LAUNDRY', 'OTHER'
);

CREATE TYPE system_type AS ENUM (
    'HVAC', 'LIGHTING', 'ELECTRICAL', 'FIRE_PROTECTION', 'SECURITY',
    'PLUMBING', 'ELEVATOR', 'BAS', 'ENERGY_MGMT', 'NETWORK',
    'RENEWABLE', 'WASTE', 'MEDICAL_GAS', 'CLEAN_ROOM', 'COLD_CHAIN',
    'RADIATION_PROTECTION', 'PURIFIED_WATER', 'KITCHEN_EXHAUST',
    'REFRIGERATION', 'ESCALATOR_ELEVATOR', 'DRAINAGE', 'LIQUID_COOLING',
    'PRECISION_COOLING', 'POWER_DISTRIBUTION', 'UPS_GENERATOR', 'OTHER'
);

CREATE TYPE equipment_type AS ENUM (
    'CHILLER', 'BOILER', 'COOLING_TOWER', 'AHU', 'FCU', 'VAV',
    'PUMP', 'FAN', 'HEAT_EXCHANGER', 'VRF', 'SPLIT_AC',
    'TRANSFORMER', 'SWITCHGEAR', 'UPS', 'GENERATOR', 'PDU',
    'LIGHTING_PANEL', 'LUMINAIRE', 'FIRE_ALARM_PANEL', 'SMOKE_DETECTOR',
    'SPRINKLER', 'FIRE_PUMP', 'CCTV_CAMERA', 'ACCESS_CONTROLLER',
    'ELEVATOR_CAR', 'ESCALATOR', 'WATER_TANK', 'METER', 'SENSOR',
    'ACTUATOR', 'VALVE', 'DAMPER', 'SOLAR_PANEL', 'BATTERY_STORAGE',
    'O2_MANIFOLD', 'VACUUM_PUMP', 'MEDICAL_AIR_COMPRESSOR', 'HEPA_UNIT',
    'PARTICLE_COUNTER', 'BLOOD_FRIDGE', 'PHARMACY_FRIDGE',
    'ULTRA_LOW_FREEZER', 'RADIATION_MONITOR', 'RO_UNIT', 'EXHAUST_FAN',
    'ESP_UNIT', 'WALK_IN_COOLER', 'DISPLAY_CABINET', 'SUMP_PUMP',
    'CRAC', 'CRAH', 'CDU', 'ATS', 'STS', 'UPS_UNIT',
    'DIESEL_GENERATOR', 'VESDA_DETECTOR', 'LEAK_DETECTION_CABLE',
    'HOT_WATER_BOILER', 'HEAT_PUMP_DHW', 'POOL_FILTER_PUMP',
    'POOL_HEATER', 'CHEMICAL_DOSING', 'OTHER'
);

CREATE TYPE component_type AS ENUM (
    'COMPRESSOR', 'CONDENSER', 'EVAPORATOR', 'EXPANSION_VALVE',
    'MOTOR', 'IMPELLER', 'BEARING', 'BELT', 'FILTER', 'COIL',
    'BURNER', 'CONTROL_BOARD', 'INVERTER', 'CONTACTOR', 'RELAY', 'OTHER'
);

CREATE TYPE maintenance_status AS ENUM (
    'NORMAL', 'DUE_SOON', 'OVERDUE', 'IN_MAINTENANCE', 'OUT_OF_SERVICE', 'UNDER_WARRANTY'
);

CREATE TYPE criticality AS ENUM (
    'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'
);

CREATE TYPE medical_device_class AS ENUM ('I', 'II', 'III');

CREATE TYPE point_class AS ENUM (
    'SENSOR', 'COMMAND', 'SETPOINT', 'STATUS', 'ALARM_POINT', 'CALCULATED', 'ACCUMULATOR'
);

CREATE TYPE point_data_type AS ENUM (
    'FLOAT', 'INT', 'BOOL', 'STRING', 'ENUM', 'JSON'
);

CREATE TYPE point_access AS ENUM (
    'READ_ONLY', 'READ_WRITE', 'WRITE_ONLY'
);

CREATE TYPE source_protocol AS ENUM (
    'BACNET', 'MODBUS_TCP', 'MODBUS_RTU', 'OPC_UA', 'OPC_DA',
    'MQTT', 'KNX', 'LONWORKS', 'DALI', 'SNMP', 'HTTP_API',
    'VIRTUAL', 'MANUAL'
);

CREATE TYPE point_quality AS ENUM (
    'GOOD', 'UNCERTAIN', 'BAD', 'OFFLINE', 'NOT_CONFIGURED', 'OVERRIDDEN'
);

CREATE TYPE unit_system AS ENUM ('SI', 'IMPERIAL');

CREATE TYPE trend_method AS ENUM ('PERIODIC', 'COV', 'PERIODIC_AND_COV');

-- ============================================================
-- 核心表
-- ============================================================

-- 1. Organization（组织/集团）
CREATE TABLE organizations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(32) NOT NULL UNIQUE,
    name            VARCHAR(200) NOT NULL,
    name_en         VARCHAR(200),
    type            org_type NOT NULL,
    parent_id       UUID REFERENCES organizations(id),
    legal_entity    VARCHAR(200),
    tax_id          VARCHAR(50),
    country         VARCHAR(3) NOT NULL,
    timezone        VARCHAR(40) NOT NULL,
    locale          VARCHAR(10) NOT NULL,
    logo_url        VARCHAR(500),
    contact_email   VARCHAR(200),
    contact_phone   VARCHAR(30),
    metadata        JSONB,
    status          entity_status NOT NULL DEFAULT 'ACTIVE',
    created_by      UUID,
    updated_by      UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Site（园区/场地）
CREATE TABLE sites (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL REFERENCES organizations(id),
    code            VARCHAR(32) NOT NULL,
    name            VARCHAR(200) NOT NULL,
    name_en         VARCHAR(200),
    address         VARCHAR(500) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    province        VARCHAR(100),
    country         VARCHAR(3) NOT NULL,
    postal_code     VARCHAR(20),
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    altitude        DECIMAL(8,2),
    timezone        VARCHAR(40) NOT NULL,
    climate_zone    climate_zone,
    total_area      DECIMAL(12,2),
    metadata        JSONB,
    status          entity_status NOT NULL DEFAULT 'ACTIVE',
    created_by      UUID,
    updated_by      UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (org_id, code)
);

-- 3. Building（楼宇）
CREATE TABLE buildings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id             UUID NOT NULL REFERENCES sites(id),
    profile_id          UUID,  -- FK added later in 008_building_profiles.sql
    code                VARCHAR(32) NOT NULL,
    name                VARCHAR(200) NOT NULL,
    name_en             VARCHAR(200),
    building_type       building_type NOT NULL,
    year_built          SMALLINT,
    year_renovated      SMALLINT,
    gross_floor_area    DECIMAL(12,2) NOT NULL,
    usable_area         DECIMAL(12,2),
    floors_above        SMALLINT NOT NULL,
    floors_below        SMALLINT,
    height              DECIMAL(8,2),
    climate_zone        climate_zone NOT NULL,
    regulation_set      VARCHAR(100)[],
    certifications      JSONB,
    design_occupancy    INT,
    bim_model_url       VARCHAR(500),
    address             VARCHAR(500),
    latitude            DECIMAL(10,7),
    longitude           DECIMAL(10,7),
    metadata            JSONB,
    status              entity_status NOT NULL DEFAULT 'ACTIVE',
    created_by          UUID,
    updated_by          UUID,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (site_id, code)
);

-- 4. Floor（楼层）
CREATE TABLE floors (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id     UUID NOT NULL REFERENCES buildings(id),
    code            VARCHAR(32) NOT NULL,
    name            VARCHAR(100) NOT NULL,
    sort_order      INT NOT NULL,
    elevation       DECIMAL(8,2),
    floor_height    DECIMAL(6,2),
    gross_area      DECIMAL(10,2),
    usable_area     DECIMAL(10,2),
    is_underground  BOOLEAN NOT NULL DEFAULT false,
    floor_type      floor_type,
    metadata        JSONB,
    status          entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (building_id, code)
);

-- 5. Zone（区域/房间）
CREATE TABLE zones (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    floor_id            UUID NOT NULL REFERENCES floors(id),
    building_id         UUID NOT NULL REFERENCES buildings(id),
    parent_zone_id      UUID REFERENCES zones(id),
    code                VARCHAR(32) NOT NULL,
    name                VARCHAR(200) NOT NULL,
    name_en             VARCHAR(200),
    space_type          space_type NOT NULL,
    area                DECIMAL(10,2),
    volume              DECIMAL(10,2),
    capacity            INT,
    is_public           BOOLEAN,
    hvac_zone_id        VARCHAR(50),
    lighting_zone_id    VARCHAR(50),
    fire_zone_id        VARCHAR(50),
    tags                VARCHAR(50)[],
    metadata            JSONB,
    status              entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (building_id, code)
);

-- 6. System（子系统）
CREATE TABLE systems (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id         UUID NOT NULL REFERENCES buildings(id),
    code                VARCHAR(32) NOT NULL,
    name                VARCHAR(200) NOT NULL,
    system_type         system_type NOT NULL,
    sub_type            VARCHAR(50),
    description         TEXT,
    serves_zones        UUID[],
    serves_floors       UUID[],
    design_capacity     JSONB,
    commissioning_date  DATE,
    tags                VARCHAR(50)[],
    metadata            JSONB,
    status              entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (building_id, code)
);

-- 7. Equipment（设备）
CREATE TABLE equipment (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id               UUID NOT NULL REFERENCES systems(id),
    zone_id                 UUID REFERENCES zones(id),
    parent_equipment_id     UUID REFERENCES equipment(id),
    code                    VARCHAR(50) NOT NULL,
    name                    VARCHAR(200) NOT NULL,
    equipment_type          equipment_type NOT NULL,
    sub_type                VARCHAR(50),
    manufacturer            VARCHAR(200),
    model                   VARCHAR(100),
    serial_number           VARCHAR(100),
    rated_power             DECIMAL(10,2),
    rated_capacity          JSONB,
    install_date            DATE,
    warranty_expiry         DATE,
    expected_life_years     SMALLINT,
    maintenance_status      maintenance_status NOT NULL DEFAULT 'NORMAL',
    last_maintenance_date   DATE,
    next_maintenance_date   DATE,
    maintenance_cycle_days  INT,
    criticality             criticality,
    barcode                 VARCHAR(100),
    qr_code_url             VARCHAR(500),
    bim_guid                VARCHAR(50),
    -- v2 扩展字段
    backup_equipment_id     UUID REFERENCES equipment(id),
    redundancy_group_id     UUID,  -- FK added later in 006_industry_extras.sql
    power_chain_order       INT,
    upstream_equipment_id   UUID REFERENCES equipment(id),
    medical_device_class    medical_device_class,
    cold_chain_category     VARCHAR(50),
    registration_number     VARCHAR(100),
    tags                    VARCHAR(50)[],
    metadata                JSONB,
    status                  entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. Component（部件）
CREATE TABLE components (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    equipment_id        UUID NOT NULL REFERENCES equipment(id),
    code                VARCHAR(50) NOT NULL,
    name                VARCHAR(200) NOT NULL,
    component_type      component_type NOT NULL,
    manufacturer        VARCHAR(200),
    model               VARCHAR(100),
    serial_number       VARCHAR(100),
    install_date        DATE,
    replacement_date    DATE,
    expected_life_years SMALLINT,
    tags                VARCHAR(50)[],
    metadata            JSONB,
    status              entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9. Point（点位）— 最核心实体
CREATE TABLE points (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    equipment_id            UUID REFERENCES equipment(id),
    component_id            UUID REFERENCES components(id),
    zone_id                 UUID REFERENCES zones(id),
    building_id             UUID NOT NULL REFERENCES buildings(id),
    code                    VARCHAR(100) NOT NULL,
    name                    VARCHAR(200) NOT NULL,
    name_en                 VARCHAR(200),
    point_class             point_class NOT NULL,
    data_type               point_data_type NOT NULL,
    unit                    VARCHAR(20),
    unit_system             unit_system,
    precision               SMALLINT,
    access                  point_access NOT NULL,
    source_protocol         source_protocol NOT NULL,
    source_address          JSONB NOT NULL,
    polling_interval_s      INT,
    cov_enabled             BOOLEAN,
    cov_increment           DECIMAL(10,4),
    min_value               DECIMAL(15,4),
    max_value               DECIMAL(15,4),
    default_value           VARCHAR(50),
    -- 告警相关
    alarm_enabled           BOOLEAN NOT NULL DEFAULT false,
    alarm_hi_hi             DECIMAL(15,4),
    alarm_hi                DECIMAL(15,4),
    alarm_lo                DECIMAL(15,4),
    alarm_lo_lo             DECIMAL(15,4),
    alarm_deadband          DECIMAL(10,4),
    alarm_delay_s           INT,
    -- 趋势记录相关
    trend_enabled           BOOLEAN NOT NULL DEFAULT true,
    trend_interval_s        INT,
    trend_method            trend_method,
    trend_retention_days    INT,
    -- 语义标签
    haystack_tags           VARCHAR(50)[],
    brick_class             VARCHAR(100),
    -- 显示相关
    display_group           VARCHAR(100),
    display_order           INT,
    -- 虚拟/计算点
    is_virtual              BOOLEAN DEFAULT false,
    calc_expression         TEXT,
    -- 实时缓存
    current_value           VARCHAR(50),
    current_quality         point_quality,
    current_timestamp       TIMESTAMPTZ,
    -- 扩展
    tags                    JSONB,
    metadata                JSONB,
    status                  entity_status NOT NULL DEFAULT 'ACTIVE',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (building_id, code)
);
