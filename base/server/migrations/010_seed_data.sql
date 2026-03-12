-- 010_seed_data.sql
-- 基础种子数据：默认楼宇模板、常用告警规则、默认排程模板

-- ============================================================
-- 1. 默认 BuildingProfile：写字楼标准模板
-- ============================================================

INSERT INTO building_profiles (
    id, code, name, description, building_type, version, is_published,
    default_systems, default_equipment_templates, default_point_templates,
    default_schedules, tags, status
) VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'TPL-OFFICE-STD',
    '标准写字楼模板',
    '适用于标准写字楼的系统配置模板，包含暖通、电气、消防、安防、电梯、照明、给排水等基本子系统',
    'OFFICE',
    '1.0.0',
    true,
    '[
        {"system_type": "HVAC", "sub_type": "CHILLER_PLANT", "name_template": "冷站系统"},
        {"system_type": "HVAC", "sub_type": "AHU_SYSTEM", "name_template": "空调箱系统"},
        {"system_type": "LIGHTING", "sub_type": "GENERAL", "name_template": "照明系统"},
        {"system_type": "ELECTRICAL", "sub_type": "HV_DISTRIBUTION", "name_template": "高压配电系统"},
        {"system_type": "ELECTRICAL", "sub_type": "LV_DISTRIBUTION", "name_template": "低压配电系统"},
        {"system_type": "FIRE_PROTECTION", "sub_type": "DETECTION", "name_template": "火灾探测系统"},
        {"system_type": "FIRE_PROTECTION", "sub_type": "SUPPRESSION", "name_template": "灭火系统"},
        {"system_type": "SECURITY", "sub_type": "ACCESS_CONTROL", "name_template": "门禁系统"},
        {"system_type": "SECURITY", "sub_type": "CCTV", "name_template": "视频监控系统"},
        {"system_type": "ELEVATOR", "sub_type": "PASSENGER", "name_template": "客梯系统"},
        {"system_type": "PLUMBING", "sub_type": "DOMESTIC_WATER", "name_template": "生活给水系统"},
        {"system_type": "ENERGY_MGMT", "sub_type": "METERING", "name_template": "能源计量系统"},
        {"system_type": "BAS", "sub_type": "DDC", "name_template": "楼宇自控系统"}
    ]'::jsonb,
    '[
        {"equipment_type": "CHILLER", "name_template": "冷水机组-{n}", "typical_count": 2},
        {"equipment_type": "COOLING_TOWER", "name_template": "冷却塔-{n}", "typical_count": 2},
        {"equipment_type": "PUMP", "sub_type": "CHW", "name_template": "冷冻水泵-{n}", "typical_count": 3},
        {"equipment_type": "PUMP", "sub_type": "CW", "name_template": "冷却水泵-{n}", "typical_count": 3},
        {"equipment_type": "AHU", "name_template": "空调箱-{n}", "typical_count": 4},
        {"equipment_type": "TRANSFORMER", "name_template": "变压器-{n}", "typical_count": 2},
        {"equipment_type": "FIRE_ALARM_PANEL", "name_template": "火灾报警主机", "typical_count": 1},
        {"equipment_type": "ELEVATOR_CAR", "name_template": "客梯-{n}", "typical_count": 6}
    ]'::jsonb,
    '[
        {"point_class": "SENSOR", "brick_class": "Chilled_Water_Supply_Temperature_Sensor", "data_type": "FLOAT", "unit": "°C", "alarm_enabled": true},
        {"point_class": "SENSOR", "brick_class": "Chilled_Water_Return_Temperature_Sensor", "data_type": "FLOAT", "unit": "°C", "alarm_enabled": true},
        {"point_class": "SENSOR", "brick_class": "Supply_Air_Temperature_Sensor", "data_type": "FLOAT", "unit": "°C"},
        {"point_class": "SENSOR", "brick_class": "Zone_Air_Temperature_Sensor", "data_type": "FLOAT", "unit": "°C"},
        {"point_class": "SENSOR", "brick_class": "Power_Sensor", "data_type": "FLOAT", "unit": "kW"},
        {"point_class": "STATUS", "brick_class": "Run_Status", "data_type": "BOOL"},
        {"point_class": "COMMAND", "brick_class": "Run_Command", "data_type": "BOOL", "access": "READ_WRITE"},
        {"point_class": "SETPOINT", "brick_class": "Chilled_Water_Supply_Temperature_Setpoint", "data_type": "FLOAT", "unit": "°C", "access": "READ_WRITE"}
    ]'::jsonb,
    '[
        {"schedule_type": "WEEKLY", "name_template": "工作日空调排程", "code_template": "SCH-HVAC-WEEKDAY",
         "weekly_schedule": {
            "monday":    [{"start": "07:00", "end": "19:00", "value": "ON"}],
            "tuesday":   [{"start": "07:00", "end": "19:00", "value": "ON"}],
            "wednesday": [{"start": "07:00", "end": "19:00", "value": "ON"}],
            "thursday":  [{"start": "07:00", "end": "19:00", "value": "ON"}],
            "friday":    [{"start": "07:00", "end": "19:00", "value": "ON"}],
            "saturday":  [],
            "sunday":    []
         }
        },
        {"schedule_type": "WEEKLY", "name_template": "照明排程", "code_template": "SCH-LIGHT-WEEKDAY",
         "weekly_schedule": {
            "monday":    [{"start": "06:30", "end": "20:00", "value": "ON"}],
            "tuesday":   [{"start": "06:30", "end": "20:00", "value": "ON"}],
            "wednesday": [{"start": "06:30", "end": "20:00", "value": "ON"}],
            "thursday":  [{"start": "06:30", "end": "20:00", "value": "ON"}],
            "friday":    [{"start": "06:30", "end": "20:00", "value": "ON"}],
            "saturday":  [{"start": "08:00", "end": "14:00", "value": "ON"}],
            "sunday":    []
         }
        }
    ]'::jsonb,
    ARRAY['office', 'standard', 'template'],
    'ACTIVE'
);

-- ============================================================
-- 2. 常用告警规则模板
-- ============================================================

-- 冷冻水供水温度过高
INSERT INTO alarm_rules (
    id, code, name, description, severity, category,
    target_point_class, target_equipment_type,
    condition_type, condition_expr,
    threshold_default, deadband_default, delay_s_default,
    escalation_rules, auto_create_work_order,
    applicable_building_types, tags, status
) VALUES (
    'b0000000-0000-0000-0000-000000000001',
    'RULE-CHWST-HI',
    '冷冻水供水温度过高',
    '当冷冻水供水温度超过设定阈值时触发，可能导致空调效果不佳',
    'MAJOR',
    'PROCESS',
    'Chilled_Water_Supply_Temperature_Sensor',
    'CHILLER',
    'HI_LIMIT',
    'value > threshold',
    12.0000,
    0.5000,
    60,
    '[{"after_min": 15, "to_role": "CHIEF_ENGINEER"}, {"after_min": 60, "to_role": "FACILITY_MANAGER"}]'::jsonb,
    false,
    ARRAY['OFFICE', 'HOTEL', 'HOSPITAL', 'MALL', 'DATA_CENTER']::building_type[],
    ARRAY['chiller', 'temperature', 'cooling'],
    'ACTIVE'
);

-- 冷冻水供水温度过低
INSERT INTO alarm_rules (
    id, code, name, description, severity, category,
    target_point_class, target_equipment_type,
    condition_type, condition_expr,
    threshold_default, deadband_default, delay_s_default,
    applicable_building_types, tags, status
) VALUES (
    'b0000000-0000-0000-0000-000000000002',
    'RULE-CHWST-LO',
    '冷冻水供水温度过低',
    '当冷冻水供水温度低于设定阈值时触发，可能导致冻结风险',
    'MAJOR',
    'PROCESS',
    'Chilled_Water_Supply_Temperature_Sensor',
    'CHILLER',
    'LO_LIMIT',
    'value < threshold',
    3.0000,
    0.5000,
    60,
    ARRAY['OFFICE', 'HOTEL', 'HOSPITAL', 'MALL', 'DATA_CENTER']::building_type[],
    ARRAY['chiller', 'temperature', 'cooling'],
    'ACTIVE'
);

-- 设备通讯中断
INSERT INTO alarm_rules (
    id, code, name, description, severity, category,
    condition_type, condition_expr,
    delay_s_default,
    escalation_rules,
    applicable_building_types, tags, status
) VALUES (
    'b0000000-0000-0000-0000-000000000003',
    'RULE-COMM-OFFLINE',
    '设备通讯中断',
    '设备或点位通讯中断，无法获取实时数据',
    'MINOR',
    'COMMUNICATION',
    'OFFLINE',
    'point.quality == OFFLINE',
    120,
    '[{"after_min": 30, "to_role": "BAS_ENGINEER"}]'::jsonb,
    ARRAY['OFFICE', 'HOTEL', 'HOSPITAL', 'MALL', 'FACTORY', 'DATA_CENTER']::building_type[],
    ARRAY['communication', 'offline'],
    'ACTIVE'
);

-- 火灾报警
INSERT INTO alarm_rules (
    id, code, name, description, severity, category,
    target_point_class, target_equipment_type,
    condition_type, condition_expr,
    delay_s_default, auto_create_work_order,
    escalation_rules,
    applicable_building_types, tags, status
) VALUES (
    'b0000000-0000-0000-0000-000000000004',
    'RULE-FIRE-ALARM',
    '火灾报警',
    '烟感或火灾报警系统触发告警',
    'CRITICAL',
    'FIRE',
    'Fire_Alarm_Sensor',
    'SMOKE_DETECTOR',
    'BOOL_TRUE',
    'value == true',
    0,
    true,
    '[{"after_min": 0, "to_role": "FACILITY_MANAGER"}, {"after_min": 5, "to_role": "SECURITY_MANAGER"}]'::jsonb,
    ARRAY['OFFICE', 'HOTEL', 'HOSPITAL', 'MALL', 'FACTORY', 'DATA_CENTER', 'SCHOOL', 'WAREHOUSE']::building_type[],
    ARRAY['fire', 'life-safety'],
    'ACTIVE'
);

-- 室内温度异常
INSERT INTO alarm_rules (
    id, code, name, description, severity, category,
    target_point_class,
    condition_type, condition_expr,
    threshold_default, deadband_default, delay_s_default,
    applicable_building_types, tags, status
) VALUES (
    'b0000000-0000-0000-0000-000000000005',
    'RULE-ZONE-TEMP-HI',
    '室内温度过高',
    '区域温度超过舒适范围上限',
    'WARNING',
    'ENVIRONMENTAL',
    'Zone_Air_Temperature_Sensor',
    'HI_LIMIT',
    'value > threshold',
    28.0000,
    1.0000,
    300,
    ARRAY['OFFICE', 'HOTEL', 'HOSPITAL', 'MALL']::building_type[],
    ARRAY['zone', 'temperature', 'comfort'],
    'ACTIVE'
);

-- 电力过载
INSERT INTO alarm_rules (
    id, code, name, description, severity, category,
    target_equipment_type,
    condition_type, condition_expr,
    delay_s_default, auto_create_work_order,
    escalation_rules,
    applicable_building_types, tags, status
) VALUES (
    'b0000000-0000-0000-0000-000000000006',
    'RULE-POWER-OVERLOAD',
    '电力过载告警',
    '变压器或配电柜负载率超过安全阈值',
    'CRITICAL',
    'POWER',
    'TRANSFORMER',
    'HI_HI_LIMIT',
    'value > threshold',
    30,
    true,
    '[{"after_min": 5, "to_role": "CHIEF_ENGINEER"}, {"after_min": 15, "to_role": "FACILITY_MANAGER"}]'::jsonb,
    ARRAY['OFFICE', 'HOTEL', 'HOSPITAL', 'MALL', 'FACTORY', 'DATA_CENTER']::building_type[],
    ARRAY['power', 'electrical', 'overload'],
    'ACTIVE'
);
