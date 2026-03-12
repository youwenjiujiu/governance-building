-- ============================================================================
-- 011_office_hvac_seed.sql
-- Office-HVAC Container: Realistic seed data for BLD-SH-001 (上海浦东国际金融中心)
-- 10 equipment types, ~120 standard points, alarm thresholds, schedules
-- ============================================================================

-- Use the existing building
-- BLD-SH-001 = 5da6918d-0f36-41b0-878e-5dd39bd20eaf

-- ─── Fixed UUIDs for referential integrity ──────────────────────────────────
-- Building
\set bld   '''5da6918d-0f36-41b0-878e-5dd39bd20eaf'''

-- Floors
\set fl_b1  '''00000001-0001-4000-8000-000000000001'''
\set fl_1f  '''00000001-0001-4000-8000-000000000002'''
\set fl_2f  '''00000001-0001-4000-8000-000000000003'''
\set fl_3f  '''00000001-0001-4000-8000-000000000004'''
\set fl_5f  '''00000001-0001-4000-8000-000000000005'''
\set fl_rf  '''00000001-0001-4000-8000-000000000006'''

-- Zones
\set z_mech    '''00000002-0001-4000-8000-000000000001'''
\set z_lobby   '''00000002-0001-4000-8000-000000000002'''
\set z_office2 '''00000002-0001-4000-8000-000000000003'''
\set z_office3 '''00000002-0001-4000-8000-000000000004'''
\set z_office5 '''00000002-0001-4000-8000-000000000005'''
\set z_roof    '''00000002-0001-4000-8000-000000000006'''
\set z_meet2   '''00000002-0001-4000-8000-000000000007'''

-- Systems
\set sys_hvac '''00000003-0001-4000-8000-000000000001'''
\set sys_vent '''00000003-0001-4000-8000-000000000002'''

-- Equipment (fixed IDs for point FK references)
\set eq_ch1   '''00000010-0001-4000-8000-000000000001'''
\set eq_ch2   '''00000010-0001-4000-8000-000000000002'''
\set eq_ct1   '''00000010-0001-4000-8000-000000000003'''
\set eq_chwp1 '''00000010-0001-4000-8000-000000000004'''
\set eq_chwp2 '''00000010-0001-4000-8000-000000000005'''
\set eq_cwp1  '''00000010-0001-4000-8000-000000000006'''
\set eq_ahu1  '''00000010-0001-4000-8000-000000000007'''
\set eq_ahu2  '''00000010-0001-4000-8000-000000000008'''
\set eq_mau1  '''00000010-0001-4000-8000-000000000009'''
\set eq_fcu01 '''00000010-0001-4000-8000-000000000010'''
\set eq_fcu02 '''00000010-0001-4000-8000-000000000011'''
\set eq_fcu03 '''00000010-0001-4000-8000-000000000012'''
\set eq_fcu04 '''00000010-0001-4000-8000-000000000013'''
\set eq_vav01 '''00000010-0001-4000-8000-000000000014'''
\set eq_vav02 '''00000010-0001-4000-8000-000000000015'''
\set eq_vfd_chwp1 '''00000010-0001-4000-8000-000000000016'''
\set eq_vfd_sf1   '''00000010-0001-4000-8000-000000000017'''

-- ============================================================================
-- 1. FLOORS
-- ============================================================================

INSERT INTO floors (id, building_id, code, name, sort_order, elevation, floor_height, gross_area, usable_area, is_underground, floor_type) VALUES
  (:fl_b1, :bld, 'B1',  '地下一层-冷站', -1, -4.5, 4.5, 3000, 2500, true,  'BASEMENT_MECHANICAL'),
  (:fl_1f, :bld, '1F',  '一层-大堂',      1,  0.0, 5.0, 2000, 1800, false, 'LOBBY'),
  (:fl_2f, :bld, '2F',  '二层-办公A',     2,  5.0, 3.8, 2000, 1700, false, 'STANDARD'),
  (:fl_3f, :bld, '3F',  '三层-办公B',     3,  8.8, 3.8, 2000, 1700, false, 'STANDARD'),
  (:fl_5f, :bld, '5F',  '五层-办公C',     5, 16.4, 3.8, 2000, 1700, false, 'STANDARD'),
  (:fl_rf, :bld, 'RF',  '屋顶-设备层',   99, 50.0, 3.0, 1000,  800, false, 'MECHANICAL')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 2. ZONES
-- ============================================================================

INSERT INTO zones (id, floor_id, building_id, code, name, space_type, area, capacity, is_public, hvac_zone_id) VALUES
  (:z_mech,    :fl_b1, :bld, 'Z-MECH',     '冷站机房',      'MECHANICAL_ROOM', 500, NULL,  false, 'HVAC-B1-MECH'),
  (:z_lobby,   :fl_1f, :bld, 'Z-LOBBY',    '大堂',           'LOBBY',          600,  200,  true,  'HVAC-1F-LOBBY'),
  (:z_office2, :fl_2f, :bld, 'Z-OFFICE-2', '2F 办公区',      'OFFICE',        1500,  120,  false, 'HVAC-2F-OFFICE'),
  (:z_office3, :fl_3f, :bld, 'Z-OFFICE-3', '3F 办公区',      'OFFICE',        1500,  120,  false, 'HVAC-3F-OFFICE'),
  (:z_office5, :fl_5f, :bld, 'Z-OFFICE-5', '5F 办公区',      'OFFICE',        1500,  120,  false, 'HVAC-5F-OFFICE'),
  (:z_roof,    :fl_rf, :bld, 'Z-ROOF',     '屋顶设备区',    'MECHANICAL_ROOM',  800, NULL,  false, 'HVAC-RF-EQUIP'),
  (:z_meet2,   :fl_2f, :bld, 'Z-MEET-2',   '2F 会议室',     'MEETING_ROOM',     80,   20,  false, 'HVAC-2F-MEET')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. SYSTEMS
-- ============================================================================

INSERT INTO systems (id, building_id, code, name, system_type, description, design_capacity) VALUES
  (:sys_hvac, :bld, 'SYS-HVAC', 'HVAC 暖通系统', 'HVAC',
   '冷站 + AHU + FCU + VAV 全链路暖通空调系统',
   '{"cooling_capacity_kw": 2800, "cooling_capacity_rt": 796, "design_cop": 5.5}'::jsonb),
  (:sys_vent, :bld, 'SYS-VENT', '新风系统', 'HVAC',
   '新风处理 + 热回收',
   '{"fresh_air_volume_m3h": 50000}'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. EQUIPMENT
-- ============================================================================

INSERT INTO equipment (id, system_id, zone_id, code, name, equipment_type, sub_type, manufacturer, model, rated_power, rated_capacity, install_date, criticality, tags, metadata) VALUES
  -- ── Chiller Plant ──
  (:eq_ch1, :sys_hvac, :z_mech, 'CH-01', '1号冷水机组', 'CHILLER', 'centrifugal',
   'York', 'YKFC-350', 280, '{"cooling_kw": 1400, "cooling_rt": 398, "rated_cop": 6.1, "refrigerant": "R134a"}'::jsonb,
   '2022-06-15', 'CRITICAL', ARRAY['chiller','chiller-plant'], '{"design_chws_temp": 7.0, "design_chwr_temp": 12.0}'::jsonb),

  (:eq_ch2, :sys_hvac, :z_mech, 'CH-02', '2号冷水机组', 'CHILLER', 'centrifugal',
   'York', 'YKFC-350', 280, '{"cooling_kw": 1400, "cooling_rt": 398, "rated_cop": 6.1, "refrigerant": "R134a"}'::jsonb,
   '2022-06-15', 'CRITICAL', ARRAY['chiller','chiller-plant'], '{"design_chws_temp": 7.0, "design_chwr_temp": 12.0}'::jsonb),

  (:eq_ct1, :sys_hvac, :z_roof, 'CT-01', '1号冷却塔', 'COOLING_TOWER', 'cross-flow',
   'BAC', 'VXC-300', 45, '{"cooling_capacity_kw": 1800}'::jsonb,
   '2022-06-15', 'HIGH', ARRAY['cooling-tower','chiller-plant'], NULL),

  (:eq_chwp1, :sys_hvac, :z_mech, 'CHWP-01', '1号冷冻水泵', 'PUMP', 'chilled-water',
   'Grundfos', 'NB 80-200', 37, '{"flow_m3h": 240, "head_kpa": 350}'::jsonb,
   '2022-06-15', 'HIGH', ARRAY['pump','chw','chiller-plant'], NULL),

  (:eq_chwp2, :sys_hvac, :z_mech, 'CHWP-02', '2号冷冻水泵', 'PUMP', 'chilled-water',
   'Grundfos', 'NB 80-200', 37, '{"flow_m3h": 240, "head_kpa": 350}'::jsonb,
   '2022-06-15', 'HIGH', ARRAY['pump','chw','chiller-plant'], NULL),

  (:eq_cwp1, :sys_hvac, :z_mech, 'CWP-01', '1号冷却水泵', 'PUMP', 'condenser-water',
   'Grundfos', 'NB 100-250', 45, '{"flow_m3h": 300, "head_kpa": 250}'::jsonb,
   '2022-06-15', 'HIGH', ARRAY['pump','cw','chiller-plant'], NULL),

  -- ── AHU ──
  (:eq_ahu1, :sys_hvac, :z_mech, 'AHU-01', '1号空调机组-大堂', 'AHU', 'combined',
   'Carrier', 'AHU-39CQ-25', 22, '{"air_volume_m3h": 25000, "cooling_kw": 180}'::jsonb,
   '2022-06-15', 'HIGH', ARRAY['ahu','air-side'], NULL),

  (:eq_ahu2, :sys_hvac, :z_mech, 'AHU-02', '2号空调机组-2~3F办公', 'AHU', 'combined',
   'Carrier', 'AHU-39CQ-30', 30, '{"air_volume_m3h": 30000, "cooling_kw": 220}'::jsonb,
   '2022-06-15', 'HIGH', ARRAY['ahu','air-side'], NULL),

  -- ── MAU ──
  (:eq_mau1, :sys_vent, :z_roof, 'MAU-01', '1号新风机组', 'AHU', 'mau',
   'Daikin', 'HRV-150', 15, '{"air_volume_m3h": 15000, "heat_recovery_eff": 0.75}'::jsonb,
   '2022-06-15', 'HIGH', ARRAY['mau','fresh-air'], NULL),

  -- ── FCU (4 units, representing 4 zones) ──
  (:eq_fcu01, :sys_hvac, :z_lobby, 'FCU-01-01', '大堂风机盘管-1', 'FCU', 'ceiling-concealed',
   'Trane', 'FCC-800', 0.2, '{"cooling_kw": 8.0}'::jsonb,
   '2022-06-15', 'MEDIUM', ARRAY['fcu','air-side'], NULL),

  (:eq_fcu02, :sys_hvac, :z_office2, 'FCU-02-01', '2F办公区风机盘管-1', 'FCU', 'ceiling-concealed',
   'Trane', 'FCC-600', 0.15, '{"cooling_kw": 6.0}'::jsonb,
   '2022-06-15', 'MEDIUM', ARRAY['fcu','air-side'], NULL),

  (:eq_fcu03, :sys_hvac, :z_office3, 'FCU-03-01', '3F办公区风机盘管-1', 'FCU', 'ceiling-concealed',
   'Trane', 'FCC-600', 0.15, '{"cooling_kw": 6.0}'::jsonb,
   '2022-06-15', 'MEDIUM', ARRAY['fcu','air-side'], NULL),

  (:eq_fcu04, :sys_hvac, :z_meet2, 'FCU-02-MR', '2F会议室风机盘管', 'FCU', 'ceiling-concealed',
   'Trane', 'FCC-400', 0.1, '{"cooling_kw": 4.0}'::jsonb,
   '2022-06-15', 'MEDIUM', ARRAY['fcu','air-side'], NULL),

  -- ── VAV (2 units) ──
  (:eq_vav01, :sys_hvac, :z_office5, 'VAV-05-01', '5F变风量末端-东', 'VAV', 'pressure-independent',
   'Belimo', 'VAV-PI-300', 0.05, '{"max_air_m3h": 1200, "min_air_m3h": 300}'::jsonb,
   '2022-06-15', 'MEDIUM', ARRAY['vav','air-side'], NULL),

  (:eq_vav02, :sys_hvac, :z_office5, 'VAV-05-02', '5F变风量末端-西', 'VAV', 'pressure-independent',
   'Belimo', 'VAV-PI-300', 0.05, '{"max_air_m3h": 1200, "min_air_m3h": 300}'::jsonb,
   '2022-06-15', 'MEDIUM', ARRAY['vav','air-side'], NULL),

  -- ── VFD ──
  (:eq_vfd_chwp1, :sys_hvac, :z_mech, 'VFD-CHWP01', 'CHWP-01变频器', 'ACTUATOR', 'vfd',
   'ABB', 'ACS580-37', 37, NULL,
   '2022-06-15', 'HIGH', ARRAY['vfd','chiller-plant'], NULL),

  (:eq_vfd_sf1, :sys_hvac, :z_mech, 'VFD-AHU01-SF', 'AHU-01送风机变频器', 'ACTUATOR', 'vfd',
   'ABB', 'ACS580-22', 22, NULL,
   '2022-06-15', 'HIGH', ARRAY['vfd','air-side'], NULL)

ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. POINTS — Standard point list from scenario.md
-- ============================================================================
-- Convention: point code = {equipment_code}_{point_tag}
-- All protocol = BACNET, polling = 15s (sensors), 60s (status/accum)

-- ── 5.1 Chiller CH-01 (19 points) ──────────────────────────────────────────

INSERT INTO points (equipment_id, building_id, code, name, name_en, point_class, data_type, unit, access, source_protocol, source_address, polling_interval_s, min_value, max_value, alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband, alarm_delay_s, trend_enabled, trend_interval_s, haystack_tags, display_group, display_order) VALUES
  -- Status & Control
  (:eq_ch1, :bld, 'CH01_Status',     '运行状态',       'CH_Status',     'STATUS',  'ENUM', NULL,  'READ_ONLY',  'BACNET', '{"device":1001,"object":"BI:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['chiller','status'], '冷水机组 CH-01', 1),
  (:eq_ch1, :bld, 'CH01_CMD',        '启停命令',       'CH_CMD',        'COMMAND', 'ENUM', NULL,  'READ_WRITE', 'BACNET', '{"device":1001,"object":"BO:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, ARRAY['chiller','cmd'], '冷水机组 CH-01', 2),

  -- Temperatures
  (:eq_ch1, :bld, 'CH01_CHWS_Temp',  '冷冻水供水温度', 'CHWS_Temp',     'SENSOR',  'FLOAT', '°C',  'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:1"}'::jsonb, 15, 2.0, 15.0, true, 12.0, 9.0, 4.0, 3.0, 0.5, 300, true, 15, ARRAY['chiller','chws','temp'], '冷水机组 CH-01', 3),
  (:eq_ch1, :bld, 'CH01_CHWR_Temp',  '冷冻水回水温度', 'CHWR_Temp',     'SENSOR',  'FLOAT', '°C',  'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:2"}'::jsonb, 15, 5.0, 20.0, true, 16.0, 14.0, NULL, NULL, 0.5, 300, true, 15, ARRAY['chiller','chwr','temp'], '冷水机组 CH-01', 4),
  (:eq_ch1, :bld, 'CH01_CHWS_SP',    '冷冻水供水温度设定', 'CHWS_SP',   'SETPOINT','FLOAT', '°C',  'READ_WRITE', 'BACNET', '{"device":1001,"object":"AO:1"}'::jsonb, 60, 5.0, 10.0, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['chiller','chws','sp'], '冷水机组 CH-01', 5),
  (:eq_ch1, :bld, 'CH01_CWS_Temp',   '冷却水供水温度', 'CWS_Temp',      'SENSOR',  'FLOAT', '°C',  'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:3"}'::jsonb, 15, 20.0, 42.0, true, NULL, 37.0, NULL, NULL, 1.0, 600, true, 15, ARRAY['chiller','cws','temp'], '冷水机组 CH-01', 6),
  (:eq_ch1, :bld, 'CH01_CWR_Temp',   '冷却水回水温度', 'CWR_Temp',      'SENSOR',  'FLOAT', '°C',  'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:4"}'::jsonb, 15, 25.0, 45.0, true, NULL, 37.0, NULL, NULL, 1.0, 600, true, 15, ARRAY['chiller','cwr','temp'], '冷水机组 CH-01', 7),

  -- Pressures
  (:eq_ch1, :bld, 'CH01_Evap_Press', '蒸发器压力',     'Evap_Press',    'SENSOR',  'FLOAT', 'kPa', 'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:5"}'::jsonb, 15, 200, 700, true, NULL, NULL, 280, 250, 10, 300, true, 15, ARRAY['chiller','pressure'], '冷水机组 CH-01', 8),
  (:eq_ch1, :bld, 'CH01_Cond_Press', '冷凝器压力',     'Cond_Press',    'SENSOR',  'FLOAT', 'kPa', 'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:6"}'::jsonb, 15, 600, 1800, true, 1600, 1500, NULL, NULL, 20, 300, true, 15, ARRAY['chiller','pressure'], '冷水机组 CH-01', 9),

  -- Electrical
  (:eq_ch1, :bld, 'CH01_Comp_Amps',  '压缩机电流',     'Comp_Amps',     'SENSOR',  'FLOAT', 'A',   'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:7"}'::jsonb, 15, 0, 500, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['chiller','electrical'], '冷水机组 CH-01', 10),
  (:eq_ch1, :bld, 'CH01_Comp_Load',  '压缩机负载率',   'Comp_Load',     'SENSOR',  'FLOAT', '%',   'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:8"}'::jsonb, 15, 0, 100, true, NULL, 95.0, NULL, NULL, 2.0, 900, true, 15, ARRAY['chiller','load'], '冷水机组 CH-01', 11),
  (:eq_ch1, :bld, 'CH01_kW',         '输入功率',       'CH_kW',         'SENSOR',  'FLOAT', 'kW',  'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:9"}'::jsonb, 15, 0, 350, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['chiller','power'], '冷水机组 CH-01', 12),
  (:eq_ch1, :bld, 'CH01_COP',        'COP 实时',       'CH_COP',        'CALCULATED','FLOAT', NULL, 'READ_ONLY',  'VIRTUAL', '{"formula":"cooling_kw/input_kw"}'::jsonb, 60, 0, 10, true, NULL, NULL, 3.5, 3.0, 0.2, 1800, true, 60, ARRAY['chiller','efficiency'], '冷水机组 CH-01', 13),
  (:eq_ch1, :bld, 'CH01_CHW_Flow',   '冷冻水流量',     'CHW_Flow',      'SENSOR',  'FLOAT', 'm³/h','READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:10"}'::jsonb, 15, 0, 300, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['chiller','flow'], '冷水机组 CH-01', 14),
  (:eq_ch1, :bld, 'CH01_RunHrs',     '运行时间累计',   'CH_RunHrs',     'ACCUMULATOR','FLOAT','h', 'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:11"}'::jsonb, 300, 0, 99999, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 3600, ARRAY['chiller','runtime'], '冷水机组 CH-01', 15),
  (:eq_ch1, :bld, 'CH01_FaultCode',  '故障代码',       'CH_FaultCode',  'STATUS',  'INT',   NULL,  'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:12"}'::jsonb, 60, 0, 999, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['chiller','fault'], '冷水机组 CH-01', 16),
  (:eq_ch1, :bld, 'CH01_Freeze',     '防冻保护',       'CH_Freeze',     'ALARM_POINT','BOOL', NULL,'READ_ONLY',  'BACNET', '{"device":1001,"object":"BI:2"}'::jsonb, 15, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['chiller','safety'], '冷水机组 CH-01', 17),
  (:eq_ch1, :bld, 'CH01_Oil_Temp',   '油温',           'Oil_Temp',      'SENSOR',  'FLOAT', '°C',  'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:13"}'::jsonb, 60, 20, 80, true, NULL, 65.0, 25.0, NULL, 2.0, 300, true, 60, ARRAY['chiller','oil','temp'], '冷水机组 CH-01', 18),
  (:eq_ch1, :bld, 'CH01_Oil_DiffP',  '油压差',         'Oil_DiffPress', 'SENSOR',  'FLOAT', 'kPa', 'READ_ONLY',  'BACNET', '{"device":1001,"object":"AI:14"}'::jsonb, 60, 50, 400, true, NULL, NULL, 100, 80, 10, 300, true, 60, ARRAY['chiller','oil','pressure'], '冷水机组 CH-01', 19)
ON CONFLICT (building_id, code) DO NOTHING;

-- ── 5.2 Cooling Tower CT-01 (11 points) ────────────────────────────────────

INSERT INTO points (equipment_id, building_id, code, name, name_en, point_class, data_type, unit, access, source_protocol, source_address, polling_interval_s, min_value, max_value, alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband, alarm_delay_s, trend_enabled, trend_interval_s, haystack_tags, display_group, display_order) VALUES
  (:eq_ct1, :bld, 'CT01_Status',     '运行状态',       'CT_Status',     'STATUS',  'ENUM', NULL,  'READ_ONLY',  'BACNET', '{"device":2001,"object":"BI:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['cooling-tower','status'], '冷却塔 CT-01', 1),
  (:eq_ct1, :bld, 'CT01_CMD',        '启停命令',       'CT_CMD',        'COMMAND', 'ENUM', NULL,  'READ_WRITE', 'BACNET', '{"device":2001,"object":"BO:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, ARRAY['cooling-tower','cmd'], '冷却塔 CT-01', 2),
  (:eq_ct1, :bld, 'CT01_Fan_Hz',     '风机频率',       'CT_Fan_Hz',     'SETPOINT','FLOAT', 'Hz', 'READ_WRITE', 'BACNET', '{"device":2001,"object":"AO:1"}'::jsonb, 15, 0, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['cooling-tower','vfd','freq'], '冷却塔 CT-01', 3),
  (:eq_ct1, :bld, 'CT01_In_Temp',    '进水温度',       'CT_In_Temp',    'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":2001,"object":"AI:1"}'::jsonb, 15, 25, 45, true, NULL, 42.0, NULL, NULL, 1.0, 600, true, 15, ARRAY['cooling-tower','temp'], '冷却塔 CT-01', 4),
  (:eq_ct1, :bld, 'CT01_Out_Temp',   '出水温度',       'CT_Out_Temp',   'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":2001,"object":"AI:2"}'::jsonb, 15, 20, 40, true, NULL, 33.0, NULL, NULL, 1.0, 900, true, 15, ARRAY['cooling-tower','temp'], '冷却塔 CT-01', 5),
  (:eq_ct1, :bld, 'CT01_Fan_Amps',   '风机电流',       'CT_Fan_Amps',   'SENSOR',  'FLOAT', 'A',  'READ_ONLY',  'BACNET', '{"device":2001,"object":"AI:3"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['cooling-tower','electrical'], '冷却塔 CT-01', 6),
  (:eq_ct1, :bld, 'CT01_Fan_kW',     '风机功率',       'CT_Fan_kW',     'SENSOR',  'FLOAT', 'kW', 'READ_ONLY',  'BACNET', '{"device":2001,"object":"AI:4"}'::jsonb, 15, 0, 55, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['cooling-tower','power'], '冷却塔 CT-01', 7),
  (:eq_ct1, :bld, 'CT01_Makeup',     '补水阀状态',     'CT_Makeup',     'STATUS',  'BOOL', NULL,  'READ_ONLY',  'BACNET', '{"device":2001,"object":"BI:2"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['cooling-tower','valve'], '冷却塔 CT-01', 8),
  (:eq_ct1, :bld, 'CT01_Level',      '集水盘液位',     'CT_Level',      'SENSOR',  'FLOAT', '%',  'READ_ONLY',  'BACNET', '{"device":2001,"object":"AI:5"}'::jsonb, 60, 0, 100, true, 90, NULL, 20, NULL, 3.0, 300, true, 60, ARRAY['cooling-tower','level'], '冷却塔 CT-01', 9),
  (:eq_ct1, :bld, 'CT01_Vibration',  '振动',           'CT_Vibration',  'SENSOR',  'FLOAT', 'mm/s','READ_ONLY', 'BACNET', '{"device":2001,"object":"AI:6"}'::jsonb, 60, 0, 15, true, NULL, 6.0, NULL, NULL, 0.5, 300, true, 60, ARRAY['cooling-tower','vibration'], '冷却塔 CT-01', 10),
  (:eq_ct1, :bld, 'CT01_Blowdown',   '排污阀状态',     'CT_Blowdown',   'STATUS',  'BOOL', NULL,  'READ_ONLY',  'BACNET', '{"device":2001,"object":"BI:3"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['cooling-tower','valve'], '冷却塔 CT-01', 11)
ON CONFLICT (building_id, code) DO NOTHING;

-- ── 5.3 CHWP-01 (13 points) ────────────────────────────────────────────────

INSERT INTO points (equipment_id, building_id, code, name, name_en, point_class, data_type, unit, access, source_protocol, source_address, polling_interval_s, min_value, max_value, alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband, alarm_delay_s, trend_enabled, trend_interval_s, haystack_tags, display_group, display_order) VALUES
  (:eq_chwp1, :bld, 'CHWP01_Status',    '运行状态',       'Pump_Status',   'STATUS',  'ENUM', NULL,  'READ_ONLY',  'BACNET', '{"device":3001,"object":"BI:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['pump','chw','status'], '冷冻水泵 CHWP-01', 1),
  (:eq_chwp1, :bld, 'CHWP01_CMD',       '启停命令',       'Pump_CMD',      'COMMAND', 'ENUM', NULL,  'READ_WRITE', 'BACNET', '{"device":3001,"object":"BO:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, ARRAY['pump','chw','cmd'], '冷冻水泵 CHWP-01', 2),
  (:eq_chwp1, :bld, 'CHWP01_Hz_SP',     '频率设定',       'Pump_Hz_SP',    'SETPOINT','FLOAT', 'Hz', 'READ_WRITE', 'BACNET', '{"device":3001,"object":"AO:1"}'::jsonb, 15, 15, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['pump','chw','vfd','freq'], '冷冻水泵 CHWP-01', 3),
  (:eq_chwp1, :bld, 'CHWP01_Hz_FB',     '实际频率',       'Pump_Hz_FB',    'SENSOR',  'FLOAT', 'Hz', 'READ_ONLY',  'BACNET', '{"device":3001,"object":"AI:1"}'::jsonb, 15, 0, 50, true, NULL, 48.0, NULL, NULL, 1.0, 7200, true, 15, ARRAY['pump','chw','vfd','freq'], '冷冻水泵 CHWP-01', 4),
  (:eq_chwp1, :bld, 'CHWP01_Amps',      '电流',           'Pump_Amps',     'SENSOR',  'FLOAT', 'A',  'READ_ONLY',  'BACNET', '{"device":3001,"object":"AI:2"}'::jsonb, 15, 0, 80, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['pump','chw','electrical'], '冷冻水泵 CHWP-01', 5),
  (:eq_chwp1, :bld, 'CHWP01_kW',        '功率',           'Pump_kW',       'SENSOR',  'FLOAT', 'kW', 'READ_ONLY',  'BACNET', '{"device":3001,"object":"AI:3"}'::jsonb, 15, 0, 45, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['pump','chw','power'], '冷冻水泵 CHWP-01', 6),
  (:eq_chwp1, :bld, 'CHWP01_DiffP',     '进出口压差',     'Pump_DiffP',    'SENSOR',  'FLOAT', 'kPa','READ_ONLY',  'BACNET', '{"device":3001,"object":"AI:4"}'::jsonb, 15, 0, 500, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['pump','chw','pressure'], '冷冻水泵 CHWP-01', 7),
  (:eq_chwp1, :bld, 'CHWP01_Sys_DiffP', '管网压差',       'Sys_DiffP',     'SENSOR',  'FLOAT', 'kPa','READ_ONLY',  'BACNET', '{"device":3001,"object":"AI:5"}'::jsonb, 15, 0, 250, true, NULL, 200.0, 30.0, NULL, 5.0, 300, true, 15, ARRAY['pump','chw','pressure','system'], '冷冻水泵 CHWP-01', 8),
  (:eq_chwp1, :bld, 'CHWP01_Flow',      '流量',           'Pump_Flow',     'SENSOR',  'FLOAT', 'm³/h','READ_ONLY', 'BACNET', '{"device":3001,"object":"AI:6"}'::jsonb, 15, 0, 300, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['pump','chw','flow'], '冷冻水泵 CHWP-01', 9),
  (:eq_chwp1, :bld, 'CHWP01_Vib',       '泵体振动',       'Pump_Vib',      'SENSOR',  'FLOAT', 'mm/s','READ_ONLY', 'BACNET', '{"device":3001,"object":"AI:7"}'::jsonb, 60, 0, 15, true, NULL, 6.0, NULL, NULL, 0.5, 300, true, 60, ARRAY['pump','chw','vibration'], '冷冻水泵 CHWP-01', 10),
  (:eq_chwp1, :bld, 'CHWP01_BearTemp',  '轴承温度',       'Pump_BearTemp', 'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":3001,"object":"AI:8"}'::jsonb, 60, 15, 90, true, NULL, 70.0, NULL, NULL, 2.0, 300, true, 60, ARRAY['pump','chw','temp'], '冷冻水泵 CHWP-01', 11),
  (:eq_chwp1, :bld, 'CHWP01_VFD_Fault', 'VFD 故障',       'VFD_Fault',     'ALARM_POINT','BOOL', NULL,'READ_ONLY', 'BACNET', '{"device":3001,"object":"BI:2"}'::jsonb, 15, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['pump','chw','vfd','fault'], '冷冻水泵 CHWP-01', 12),
  (:eq_chwp1, :bld, 'CHWP01_RunHrs',    '运行时间累计',   'Pump_RunHrs',   'ACCUMULATOR','FLOAT','h','READ_ONLY', 'BACNET', '{"device":3001,"object":"AI:9"}'::jsonb, 300, 0, 99999, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 3600, ARRAY['pump','chw','runtime'], '冷冻水泵 CHWP-01', 13)
ON CONFLICT (building_id, code) DO NOTHING;

-- ── 5.4 AHU-01 (24 points) ─────────────────────────────────────────────────

INSERT INTO points (equipment_id, building_id, code, name, name_en, point_class, data_type, unit, access, source_protocol, source_address, polling_interval_s, min_value, max_value, alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband, alarm_delay_s, trend_enabled, trend_interval_s, haystack_tags, display_group, display_order) VALUES
  (:eq_ahu1, :bld, 'AHU01_Status',      '运行状态',       'AHU_Status',    'STATUS',  'ENUM', NULL,  'READ_ONLY',  'BACNET', '{"device":4001,"object":"BI:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['ahu','status'], 'AHU-01 大堂机组', 1),
  (:eq_ahu1, :bld, 'AHU01_CMD',         '启停命令',       'AHU_CMD',       'COMMAND', 'ENUM', NULL,  'READ_WRITE', 'BACNET', '{"device":4001,"object":"BO:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, ARRAY['ahu','cmd'], 'AHU-01 大堂机组', 2),
  (:eq_ahu1, :bld, 'AHU01_SA_Temp',     '送风温度',       'SA_Temp',       'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:1"}'::jsonb, 15, 8, 30, true, NULL, 20.0, 10.0, NULL, 1.0, 600, true, 15, ARRAY['ahu','supply','temp'], 'AHU-01 大堂机组', 3),
  (:eq_ahu1, :bld, 'AHU01_SA_Temp_SP',  '送风温度设定',   'SA_Temp_SP',    'SETPOINT','FLOAT', '°C', 'READ_WRITE', 'BACNET', '{"device":4001,"object":"AO:1"}'::jsonb, 60, 12, 20, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['ahu','supply','temp','sp'], 'AHU-01 大堂机组', 4),
  (:eq_ahu1, :bld, 'AHU01_RA_Temp',     '回风温度',       'RA_Temp',       'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:2"}'::jsonb, 15, 15, 35, true, NULL, 28.0, NULL, NULL, 1.0, 600, true, 15, ARRAY['ahu','return','temp'], 'AHU-01 大堂机组', 5),
  (:eq_ahu1, :bld, 'AHU01_RA_RH',       '回风湿度',       'RA_RH',         'SENSOR',  'FLOAT', '%RH','READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:3"}'::jsonb, 15, 10, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['ahu','return','humidity'], 'AHU-01 大堂机组', 6),
  (:eq_ahu1, :bld, 'AHU01_SA_RH',       '送风湿度',       'SA_RH',         'SENSOR',  'FLOAT', '%RH','READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:4"}'::jsonb, 15, 50, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['ahu','supply','humidity'], 'AHU-01 大堂机组', 7),
  (:eq_ahu1, :bld, 'AHU01_OA_Temp',     '新风温度',       'OA_Temp',       'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:5"}'::jsonb, 60, -10, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['ahu','outdoor','temp'], 'AHU-01 大堂机组', 8),
  (:eq_ahu1, :bld, 'AHU01_OA_RH',       '新风湿度',       'OA_RH',         'SENSOR',  'FLOAT', '%RH','READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:6"}'::jsonb, 60, 5, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['ahu','outdoor','humidity'], 'AHU-01 大堂机组', 9),
  (:eq_ahu1, :bld, 'AHU01_SF_Hz',       '送风机频率',     'SF_Hz',         'SETPOINT','FLOAT', 'Hz', 'READ_WRITE', 'BACNET', '{"device":4001,"object":"AO:2"}'::jsonb, 15, 0, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','fan','supply','freq'], 'AHU-01 大堂机组', 10),
  (:eq_ahu1, :bld, 'AHU01_SF_Amps',     '送风机电流',     'SF_Amps',       'SENSOR',  'FLOAT', 'A',  'READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:7"}'::jsonb, 15, 0, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','fan','supply','electrical'], 'AHU-01 大堂机组', 11),
  (:eq_ahu1, :bld, 'AHU01_RF_Hz',       '回风机频率',     'RF_Hz',         'SETPOINT','FLOAT', 'Hz', 'READ_WRITE', 'BACNET', '{"device":4001,"object":"AO:3"}'::jsonb, 15, 0, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','fan','return','freq'], 'AHU-01 大堂机组', 12),
  (:eq_ahu1, :bld, 'AHU01_CHW_Valve',   '冷水阀开度',     'CHW_Valve',     'SETPOINT','FLOAT', '%',  'READ_WRITE', 'BACNET', '{"device":4001,"object":"AO:4"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','valve','chw'], 'AHU-01 大堂机组', 13),
  (:eq_ahu1, :bld, 'AHU01_HW_Valve',    '热水阀开度',     'HW_Valve',      'SETPOINT','FLOAT', '%',  'READ_WRITE', 'BACNET', '{"device":4001,"object":"AO:5"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','valve','hw'], 'AHU-01 大堂机组', 14),
  (:eq_ahu1, :bld, 'AHU01_OA_Damper',   '新风阀开度',     'OA_Damper',     'SETPOINT','FLOAT', '%',  'READ_WRITE', 'BACNET', '{"device":4001,"object":"AO:6"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','damper','outdoor'], 'AHU-01 大堂机组', 15),
  (:eq_ahu1, :bld, 'AHU01_RA_Damper',   '回风阀开度',     'RA_Damper',     'SETPOINT','FLOAT', '%',  'READ_WRITE', 'BACNET', '{"device":4001,"object":"AO:7"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','damper','return'], 'AHU-01 大堂机组', 16),
  (:eq_ahu1, :bld, 'AHU01_EA_Damper',   '排风阀开度',     'EA_Damper',     'SETPOINT','FLOAT', '%',  'READ_WRITE', 'BACNET', '{"device":4001,"object":"AO:8"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','damper','exhaust'], 'AHU-01 大堂机组', 17),
  (:eq_ahu1, :bld, 'AHU01_SA_Press',    '送风静压',       'SA_Press',      'SENSOR',  'FLOAT', 'Pa', 'READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:8"}'::jsonb, 15, 0, 1000, true, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','supply','pressure'], 'AHU-01 大堂机组', 18),
  (:eq_ahu1, :bld, 'AHU01_SA_Press_SP', '送风静压设定',   'SA_Press_SP',   'SETPOINT','FLOAT', 'Pa', 'READ_WRITE', 'BACNET', '{"device":4001,"object":"AO:9"}'::jsonb, 60, 100, 500, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['ahu','supply','pressure','sp'], 'AHU-01 大堂机组', 19),
  (:eq_ahu1, :bld, 'AHU01_Filter_DiffP','过滤器压差',     'Filter_DiffP',  'SENSOR',  'FLOAT', 'Pa', 'READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:9"}'::jsonb, 60, 0, 600, true, 350.0, 250.0, NULL, NULL, 10.0, 300, true, 60, ARRAY['ahu','filter','pressure'], 'AHU-01 大堂机组', 20),
  (:eq_ahu1, :bld, 'AHU01_CO2',         'CO2 浓度',       'CO2',           'SENSOR',  'FLOAT', 'ppm','READ_ONLY',  'BACNET', '{"device":4001,"object":"AI:10"}'::jsonb, 30, 300, 5000, true, 1500, 1000, NULL, NULL, 50, 900, true, 30, ARRAY['ahu','air-quality','co2'], 'AHU-01 大堂机组', 21),
  (:eq_ahu1, :bld, 'AHU01_SA_CFM',      '送风风量',       'SA_CFM',        'SENSOR',  'FLOAT', 'm³/h','READ_ONLY', 'BACNET', '{"device":4001,"object":"AI:11"}'::jsonb, 15, 0, 30000, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['ahu','supply','flow'], 'AHU-01 大堂机组', 22),
  (:eq_ahu1, :bld, 'AHU01_Freeze_Stat', '防冻开关',       'Freeze_Stat',   'ALARM_POINT','BOOL', NULL,'READ_ONLY', 'BACNET', '{"device":4001,"object":"BI:2"}'::jsonb, 15, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['ahu','safety','freeze'], 'AHU-01 大堂机组', 23)
ON CONFLICT (building_id, code) DO NOTHING;

-- ── 5.5 MAU-01 (11 points) ─────────────────────────────────────────────────

INSERT INTO points (equipment_id, building_id, code, name, name_en, point_class, data_type, unit, access, source_protocol, source_address, polling_interval_s, min_value, max_value, alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband, alarm_delay_s, trend_enabled, trend_interval_s, haystack_tags, display_group, display_order) VALUES
  (:eq_mau1, :bld, 'MAU01_Status',      '运行状态',       'MAU_Status',    'STATUS',  'ENUM', NULL,  'READ_ONLY',  'BACNET', '{"device":5001,"object":"BI:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['mau','status'], 'MAU-01 新风机组', 1),
  (:eq_mau1, :bld, 'MAU01_CMD',         '启停命令',       'MAU_CMD',       'COMMAND', 'ENUM', NULL,  'READ_WRITE', 'BACNET', '{"device":5001,"object":"BO:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, ARRAY['mau','cmd'], 'MAU-01 新风机组', 2),
  (:eq_mau1, :bld, 'MAU01_SA_Temp',     '送风温度',       'MAU_SA_Temp',   'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":5001,"object":"AI:1"}'::jsonb, 15, 10, 30, true, NULL, 25.0, 15.0, NULL, 1.0, 600, true, 15, ARRAY['mau','supply','temp'], 'MAU-01 新风机组', 3),
  (:eq_mau1, :bld, 'MAU01_SA_SP',       '送风温度设定',   'MAU_SA_SP',     'SETPOINT','FLOAT', '°C', 'READ_WRITE', 'BACNET', '{"device":5001,"object":"AO:1"}'::jsonb, 60, 16, 22, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['mau','supply','temp','sp'], 'MAU-01 新风机组', 4),
  (:eq_mau1, :bld, 'MAU01_SA_RH',       '送风湿度',       'MAU_SA_RH',     'SENSOR',  'FLOAT', '%RH','READ_ONLY',  'BACNET', '{"device":5001,"object":"AI:2"}'::jsonb, 30, 30, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['mau','supply','humidity'], 'MAU-01 新风机组', 5),
  (:eq_mau1, :bld, 'MAU01_OA_Temp',     '新风温度',       'MAU_OA_Temp',   'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":5001,"object":"AI:3"}'::jsonb, 60, -10, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['mau','outdoor','temp'], 'MAU-01 新风机组', 6),
  (:eq_mau1, :bld, 'MAU01_SF_Hz',       '送风机频率',     'MAU_SF_Hz',     'SETPOINT','FLOAT', 'Hz', 'READ_WRITE', 'BACNET', '{"device":5001,"object":"AO:2"}'::jsonb, 15, 0, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['mau','fan','freq'], 'MAU-01 新风机组', 7),
  (:eq_mau1, :bld, 'MAU01_CHW_Valve',   '冷水阀开度',     'MAU_CHW_Valve', 'SETPOINT','FLOAT', '%',  'READ_WRITE', 'BACNET', '{"device":5001,"object":"AO:3"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['mau','valve','chw'], 'MAU-01 新风机组', 8),
  (:eq_mau1, :bld, 'MAU01_HRE_Eff',     '热回收效率',     'HRE_Eff',       'CALCULATED','FLOAT','%','READ_ONLY',  'VIRTUAL', '{"formula":"(sa_temp-oa_temp)/(ra_temp-oa_temp)"}'::jsonb, 60, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['mau','heat-recovery'], 'MAU-01 新风机组', 9),
  (:eq_mau1, :bld, 'MAU01_Filter_DP',   '过滤器压差',     'MAU_Filter_DP', 'SENSOR',  'FLOAT', 'Pa', 'READ_ONLY',  'BACNET', '{"device":5001,"object":"AI:4"}'::jsonb, 60, 0, 600, true, 350.0, 250.0, NULL, NULL, 10.0, 300, true, 60, ARRAY['mau','filter','pressure'], 'MAU-01 新风机组', 10),
  (:eq_mau1, :bld, 'MAU01_SA_Press',    '送风静压',       'MAU_SA_Press',  'SENSOR',  'FLOAT', 'Pa', 'READ_ONLY',  'BACNET', '{"device":5001,"object":"AI:5"}'::jsonb, 15, 0, 600, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['mau','supply','pressure'], 'MAU-01 新风机组', 11)
ON CONFLICT (building_id, code) DO NOTHING;

-- ── 5.6 FCU-02-01 (7 points, representative) ───────────────────────────────

INSERT INTO points (equipment_id, building_id, code, name, name_en, point_class, data_type, unit, access, source_protocol, source_address, polling_interval_s, min_value, max_value, alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband, alarm_delay_s, trend_enabled, trend_interval_s, haystack_tags, display_group, display_order) VALUES
  (:eq_fcu02, :bld, 'FCU0201_Status',    '运行状态',       'FCU_Status',    'STATUS',  'ENUM', NULL,  'READ_ONLY',  'BACNET', '{"device":6001,"object":"BI:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['fcu','status'], 'FCU-02-01 2F办公', 1),
  (:eq_fcu02, :bld, 'FCU0201_CMD',       '启停/模式',      'FCU_CMD',       'COMMAND', 'ENUM', NULL,  'READ_WRITE', 'BACNET', '{"device":6001,"object":"MO:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, ARRAY['fcu','cmd'], 'FCU-02-01 2F办公', 2),
  (:eq_fcu02, :bld, 'FCU0201_FanSpd',    '风速',           'FCU_FanSpd',    'SETPOINT','ENUM', NULL,  'READ_WRITE', 'BACNET', '{"device":6001,"object":"MO:2"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['fcu','fan','speed'], 'FCU-02-01 2F办公', 3),
  (:eq_fcu02, :bld, 'FCU0201_Room_Temp', '房间温度',       'Room_Temp',     'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":6001,"object":"AI:1"}'::jsonb, 30, 15, 35, true, NULL, 28.0, 18.0, NULL, 1.0, 1200, true, 30, ARRAY['fcu','zone','temp'], 'FCU-02-01 2F办公', 4),
  (:eq_fcu02, :bld, 'FCU0201_Room_SP',   '温度设定值',     'Room_Temp_SP',  'SETPOINT','FLOAT', '°C', 'READ_WRITE', 'BACNET', '{"device":6001,"object":"AO:1"}'::jsonb, 60, 20, 28, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['fcu','zone','temp','sp'], 'FCU-02-01 2F办公', 5),
  (:eq_fcu02, :bld, 'FCU0201_Valve',     '水阀状态',       'FCU_Valve',     'SETPOINT','FLOAT', '%',  'READ_WRITE', 'BACNET', '{"device":6001,"object":"AO:2"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['fcu','valve'], 'FCU-02-01 2F办公', 6),
  (:eq_fcu02, :bld, 'FCU0201_Occupancy', '占用状态',       'Occupancy',     'STATUS',  'BOOL', NULL,  'READ_ONLY',  'BACNET', '{"device":6001,"object":"BI:2"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['fcu','occupancy'], 'FCU-02-01 2F办公', 7)
ON CONFLICT (building_id, code) DO NOTHING;

-- ── 5.7 VAV-05-01 (8 points) ───────────────────────────────────────────────

INSERT INTO points (equipment_id, building_id, code, name, name_en, point_class, data_type, unit, access, source_protocol, source_address, polling_interval_s, min_value, max_value, alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband, alarm_delay_s, trend_enabled, trend_interval_s, haystack_tags, display_group, display_order) VALUES
  (:eq_vav01, :bld, 'VAV0501_Zone_Temp', '区域温度',       'Zone_Temp',     'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":7001,"object":"AI:1"}'::jsonb, 30, 15, 35, true, NULL, 28.0, 18.0, NULL, 1.0, 900, true, 30, ARRAY['vav','zone','temp'], 'VAV-05-01 5F东区', 1),
  (:eq_vav01, :bld, 'VAV0501_Zone_SP',   '温度设定值',     'Zone_Temp_SP',  'SETPOINT','FLOAT', '°C', 'READ_WRITE', 'BACNET', '{"device":7001,"object":"AO:1"}'::jsonb, 60, 20, 28, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['vav','zone','temp','sp'], 'VAV-05-01 5F东区', 2),
  (:eq_vav01, :bld, 'VAV0501_CFM',       '风量',           'VAV_CFM',       'SENSOR',  'FLOAT', 'm³/h','READ_ONLY', 'BACNET', '{"device":7001,"object":"AI:2"}'::jsonb, 15, 0, 1500, true, NULL, NULL, 240, NULL, 20, 600, true, 15, ARRAY['vav','flow'], 'VAV-05-01 5F东区', 3),
  (:eq_vav01, :bld, 'VAV0501_Damper',    '风阀开度',       'VAV_Damper',    'SETPOINT','FLOAT', '%',  'READ_WRITE', 'BACNET', '{"device":7001,"object":"AO:2"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['vav','damper'], 'VAV-05-01 5F东区', 4),
  (:eq_vav01, :bld, 'VAV0501_Min_SP',    '最小风量设定',   'VAV_Min_SP',    'SETPOINT','FLOAT', 'm³/h','READ_WRITE','BACNET', '{"device":7001,"object":"AO:3"}'::jsonb, 300, 0, 600, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 3600, ARRAY['vav','min','sp'], 'VAV-05-01 5F东区', 5),
  (:eq_vav01, :bld, 'VAV0501_Max_SP',    '最大风量设定',   'VAV_Max_SP',    'SETPOINT','FLOAT', 'm³/h','READ_WRITE','BACNET', '{"device":7001,"object":"AO:4"}'::jsonb, 300, 0, 1500, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 3600, ARRAY['vav','max','sp'], 'VAV-05-01 5F东区', 6),
  (:eq_vav01, :bld, 'VAV0501_Reheat',    '再热阀开度',     'Reheat_Valve',  'SETPOINT','FLOAT', '%',  'READ_WRITE', 'BACNET', '{"device":7001,"object":"AO:5"}'::jsonb, 15, 0, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['vav','reheat','valve'], 'VAV-05-01 5F东区', 7),
  (:eq_vav01, :bld, 'VAV0501_Occ',       '占用状态',       'VAV_Occ',       'STATUS',  'BOOL', NULL,  'READ_ONLY',  'BACNET', '{"device":7001,"object":"BI:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['vav','occupancy'], 'VAV-05-01 5F东区', 8)
ON CONFLICT (building_id, code) DO NOTHING;

-- ── 5.8 VFD-CHWP01 (10 points) ─────────────────────────────────────────────

INSERT INTO points (equipment_id, building_id, code, name, name_en, point_class, data_type, unit, access, source_protocol, source_address, polling_interval_s, min_value, max_value, alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband, alarm_delay_s, trend_enabled, trend_interval_s, haystack_tags, display_group, display_order) VALUES
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_Status',    '运行状态',     'VFD_Status',    'STATUS',  'ENUM', NULL,  'READ_ONLY',  'BACNET', '{"device":8001,"object":"BI:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['vfd','status'], 'VFD CHWP-01', 1),
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_CMD',       '启停命令',     'VFD_CMD',       'COMMAND', 'ENUM', NULL,  'READ_WRITE', 'BACNET', '{"device":8001,"object":"BO:1"}'::jsonb, 60, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, NULL, ARRAY['vfd','cmd'], 'VFD CHWP-01', 2),
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_Hz_SP',     '频率设定',     'VFD_Hz_SP',     'SETPOINT','FLOAT', 'Hz', 'READ_WRITE', 'BACNET', '{"device":8001,"object":"AO:1"}'::jsonb, 15, 0, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['vfd','freq','sp'], 'VFD CHWP-01', 3),
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_Hz_FB',     '实际频率',     'VFD_Hz_FB',     'SENSOR',  'FLOAT', 'Hz', 'READ_ONLY',  'BACNET', '{"device":8001,"object":"AI:1"}'::jsonb, 15, 0, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['vfd','freq','fb'], 'VFD CHWP-01', 4),
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_Amps',      '输出电流',     'VFD_Amps',      'SENSOR',  'FLOAT', 'A',  'READ_ONLY',  'BACNET', '{"device":8001,"object":"AI:2"}'::jsonb, 15, 0, 80, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['vfd','electrical'], 'VFD CHWP-01', 5),
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_kW',        '输出功率',     'VFD_kW',        'SENSOR',  'FLOAT', 'kW', 'READ_ONLY',  'BACNET', '{"device":8001,"object":"AI:3"}'::jsonb, 15, 0, 45, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['vfd','power'], 'VFD CHWP-01', 6),
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_Volts',     '输出电压',     'VFD_Volts',     'SENSOR',  'FLOAT', 'V',  'READ_ONLY',  'BACNET', '{"device":8001,"object":"AI:4"}'::jsonb, 60, 0, 420, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['vfd','electrical'], 'VFD CHWP-01', 7),
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_Temp',      '散热器温度',   'VFD_Temp',      'SENSOR',  'FLOAT', '°C', 'READ_ONLY',  'BACNET', '{"device":8001,"object":"AI:5"}'::jsonb, 60, 15, 90, true, NULL, 75.0, NULL, NULL, 3.0, 300, true, 60, ARRAY['vfd','temp'], 'VFD CHWP-01', 8),
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_FaultCode', '故障代码',     'VFD_FaultCode', 'STATUS',  'INT',   NULL,  'READ_ONLY',  'BACNET', '{"device":8001,"object":"AI:6"}'::jsonb, 60, 0, 999, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['vfd','fault'], 'VFD CHWP-01', 9),
  (:eq_vfd_chwp1, :bld, 'VFD_CHWP01_RunHrs',    '运行时间',     'VFD_RunHrs',    'ACCUMULATOR','FLOAT','h','READ_ONLY', 'BACNET', '{"device":8001,"object":"AI:7"}'::jsonb, 300, 0, 99999, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 3600, ARRAY['vfd','runtime'], 'VFD CHWP-01', 10)
ON CONFLICT (building_id, code) DO NOTHING;

-- ── 5.9 Environment Sensors (building-level, 10 points) ────────────────────

INSERT INTO points (equipment_id, building_id, code, name, name_en, point_class, data_type, unit, access, source_protocol, source_address, polling_interval_s, min_value, max_value, alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband, alarm_delay_s, trend_enabled, trend_interval_s, haystack_tags, display_group, display_order) VALUES
  (NULL, :bld, 'ENV_OAT',        '室外温度',       'OAT',           'SENSOR',  'FLOAT', '°C',    'READ_ONLY', 'BACNET', '{"device":9001,"object":"AI:1"}'::jsonb, 60, -20, 50, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['weather','outdoor','temp'], '环境传感器', 1),
  (NULL, :bld, 'ENV_OAH',        '室外湿度',       'OAH',           'SENSOR',  'FLOAT', '%RH',   'READ_ONLY', 'BACNET', '{"device":9001,"object":"AI:2"}'::jsonb, 60, 5, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['weather','outdoor','humidity'], '环境传感器', 2),
  (NULL, :bld, 'ENV_OA_Enthalpy','室外焓值',       'OA_Enthalpy',   'CALCULATED','FLOAT','kJ/kg','READ_ONLY', 'VIRTUAL', '{"formula":"1.006*t+h*(2501+1.86*t)/1000"}'::jsonb, 60, 0, 120, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 300, ARRAY['weather','outdoor','enthalpy'], '环境传感器', 3),
  (NULL, :bld, 'ENV_2F_Temp',    '2F 区域温度',    'Zone_Temp_2F',  'SENSOR',  'FLOAT', '°C',    'READ_ONLY', 'BACNET', '{"device":9001,"object":"AI:3"}'::jsonb, 60, 15, 35, true, 30.0, 28.0, 18.0, 16.0, 1.0, 600, true, 60, ARRAY['zone','indoor','temp'], '环境传感器', 4),
  (NULL, :bld, 'ENV_2F_RH',      '2F 区域湿度',    'Zone_RH_2F',    'SENSOR',  'FLOAT', '%RH',   'READ_ONLY', 'BACNET', '{"device":9001,"object":"AI:4"}'::jsonb, 60, 10, 100, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 60, ARRAY['zone','indoor','humidity'], '环境传感器', 5),
  (NULL, :bld, 'ENV_2F_CO2',     '2F CO2 浓度',    'Zone_CO2_2F',   'SENSOR',  'FLOAT', 'ppm',   'READ_ONLY', 'BACNET', '{"device":9001,"object":"AI:5"}'::jsonb, 60, 300, 5000, true, 1500, 1000, NULL, NULL, 50, 900, true, 60, ARRAY['zone','indoor','co2'], '环境传感器', 6),
  (NULL, :bld, 'ENV_2F_PM25',    '2F PM2.5',       'Zone_PM25_2F',  'SENSOR',  'FLOAT', 'μg/m³', 'READ_ONLY', 'BACNET', '{"device":9001,"object":"AI:6"}'::jsonb, 60, 0, 500, true, NULL, 75.0, NULL, NULL, 5.0, 600, true, 60, ARRAY['zone','indoor','pm25'], '环境传感器', 7),
  (NULL, :bld, 'ENV_CHW_Supply_Temp','冷冻水总管供水温度','Pipe_Temp_CHWS','SENSOR','FLOAT','°C','READ_ONLY','BACNET','{"device":9001,"object":"AI:7"}'::jsonb, 15, 2, 15, true, 12.0, 9.0, 4.0, 3.0, 0.5, 300, true, 15, ARRAY['pipe','chw','supply','temp'], '环境传感器', 8),
  (NULL, :bld, 'ENV_CHW_Return_Temp','冷冻水总管回水温度','Pipe_Temp_CHWR','SENSOR','FLOAT','°C','READ_ONLY','BACNET','{"device":9001,"object":"AI:8"}'::jsonb, 15, 5, 20, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['pipe','chw','return','temp'], '环境传感器', 9),
  (NULL, :bld, 'ENV_CHW_Flow',       '冷冻水总管流量',   'Pipe_Flow_CHW', 'SENSOR','FLOAT','m³/h','READ_ONLY','BACNET','{"device":9001,"object":"AI:9"}'::jsonb, 15, 0, 600, false, NULL, NULL, NULL, NULL, NULL, NULL, true, 15, ARRAY['pipe','chw','flow'], '环境传感器', 10)
ON CONFLICT (building_id, code) DO NOTHING;

-- ============================================================================
-- 6. ALARM RULES (template-based, for display / reference)
-- ============================================================================

INSERT INTO alarm_rules (code, name, description, severity, category, condition_type, condition_expr, threshold_default, deadband_default, delay_s_default) VALUES
  ('ALR-CHWS-HI',     '冷冻水供水温度偏高',  'CHWS_Temp > SP + 2°C 持续 10min',  'MAJOR',    'PROCESS',        'EXPRESSION', 'CHWS_Temp > CHWS_SP + 2', 9.0, 0.5, 600),
  ('ALR-CHWS-HIHI',   '冷冻水供水温度过高',  'CHWS_Temp > SP + 5°C 持续 5min',   'CRITICAL', 'PROCESS',        'EXPRESSION', 'CHWS_Temp > CHWS_SP + 5', 12.0, 0.5, 300),
  ('ALR-COP-LO',      '冷机 COP 过低',       'COP < 3.5 持续 30min',             'MAJOR',    'PROCESS',        'LO_LIMIT',   'CH_COP < 3.5', 3.5, 0.2, 1800),
  ('ALR-CH-FAULT',    '冷机故障',             'CH_Status = FAULT',                'CRITICAL', 'EQUIPMENT_FAULT','STATE_CHANGE','CH_Status == FAULT', NULL, NULL, 0),
  ('ALR-CH-FREEZE',   '防冻保护触发',         'CH_Freeze = ALARM',                'CRITICAL', 'LIFE_SAFETY',    'BOOL_TRUE',  'CH_Freeze == true', NULL, NULL, 0),
  ('ALR-CW-HI',       '冷却水出水温度偏高',  'CT_Out_Temp > 33°C 持续 15min',    'MAJOR',    'PROCESS',        'HI_LIMIT',   'CT_Out_Temp > 33', 33.0, 1.0, 900),
  ('ALR-CT-VIB',      '冷却塔振动过大',       'CT_Vibration > 6 mm/s',            'MAJOR',    'EQUIPMENT_FAULT','HI_LIMIT',   'CT_Vibration > 6', 6.0, 0.5, 300),
  ('ALR-DIFFP-LO',    '管网压差过低',         'Sys_DiffP < 30kPa',                'CRITICAL', 'PROCESS',        'LO_LIMIT',   'Sys_DiffP < 30', 30.0, 5.0, 300),
  ('ALR-BEAR-HI',     '泵轴承温度过高',       'Pump_BearTemp > 70°C',             'MAJOR',    'EQUIPMENT_FAULT','HI_LIMIT',   'Pump_BearTemp > 70', 70.0, 2.0, 300),
  ('ALR-SA-HI',       'AHU 送风温度偏高',     'SA_Temp > SP + 3°C 持续 10min',    'MAJOR',    'PROCESS',        'EXPRESSION', 'SA_Temp > SA_Temp_SP + 3', NULL, 1.0, 600),
  ('ALR-FILTER-HI',   '过滤器压差过大',       'Filter_DiffP > 250Pa',             'MAJOR',    'EQUIPMENT_FAULT','HI_LIMIT',   'Filter_DiffP > 250', 250.0, 10.0, 300),
  ('ALR-FILTER-HIHI', '过滤器压差临界',       'Filter_DiffP > 350Pa',             'CRITICAL', 'EQUIPMENT_FAULT','HI_LIMIT',   'Filter_DiffP > 350', 350.0, 10.0, 0),
  ('ALR-CO2-HI',      'CO2 浓度偏高',         'CO2 > 1000ppm 持续 15min',         'MAJOR',    'ENVIRONMENTAL',  'HI_LIMIT',   'CO2 > 1000', 1000.0, 50.0, 900),
  ('ALR-CO2-HIHI',    'CO2 浓度过高',         'CO2 > 1500ppm',                    'CRITICAL', 'ENVIRONMENTAL',  'HI_LIMIT',   'CO2 > 1500', 1500.0, 50.0, 0),
  ('ALR-FCU-TEMP-HI', 'FCU 房间温度偏高',     'Room_Temp > SP + 3°C 持续 20min',  'MAJOR',    'PROCESS',        'EXPRESSION', 'Room_Temp > Room_Temp_SP + 3', NULL, 1.0, 1200),
  ('ALR-VFD-TEMP-HI', 'VFD 散热器温度过高',   'VFD_Temp > 75°C',                  'MAJOR',    'EQUIPMENT_FAULT','HI_LIMIT',   'VFD_Temp > 75', 75.0, 3.0, 300)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. SCHEDULES (cooling season weekday template)
-- ============================================================================

INSERT INTO schedules (building_id, code, name, schedule_type, target_type, target_ids, timezone, effective_from, priority, weekly_schedule, metadata) VALUES
  (:bld, 'SCH-HVAC-WEEKDAY', '工作日制冷排程', 'WEEKLY', 'system', ARRAY[:sys_hvac]::uuid[], 'Asia/Shanghai', '2026-03-01', 10,
   '{
     "mon": [
       {"start":"06:30","end":"08:00","action":"pre_cool","params":{"chiller_count":1,"chwp_hz":25,"ahu_hz":30}},
       {"start":"08:00","end":"12:00","action":"full_operation","params":{"chiller_count":"auto","ahu_hz":50}},
       {"start":"12:00","end":"13:00","action":"lunch_saving","params":{"reduce_chiller":true,"ahu_hz":35}},
       {"start":"13:00","end":"17:30","action":"full_operation","params":{"chiller_count":"auto","ahu_hz":50}},
       {"start":"17:30","end":"19:00","action":"transition","params":{"reduce_chiller":true}},
       {"start":"19:00","end":"22:00","action":"overtime_only","params":{"on_demand":true}},
       {"start":"22:00","end":"06:30","action":"shutdown","params":{}}
     ],
     "tue": "same_as_mon", "wed": "same_as_mon", "thu": "same_as_mon", "fri": "same_as_mon",
     "sat": [{"start":"00:00","end":"24:00","action":"weekend_shutdown","params":{"anti_freeze":true}}],
     "sun": "same_as_sat"
   }'::jsonb,
   '{"season":"cooling","description":"夏季制冷工作日排程，含预冷、全运行、午休节能、过渡、加班、停机 6 个时段"}'::jsonb),

  (:bld, 'SCH-HVAC-WINTER', '工作日制热排程', 'WEEKLY', 'system', ARRAY[:sys_hvac]::uuid[], 'Asia/Shanghai', '2026-11-01', 10,
   '{
     "mon": [
       {"start":"06:00","end":"08:00","action":"pre_heat","params":{"boiler":"on","ahu_low_speed":true}},
       {"start":"08:00","end":"12:00","action":"normal_heating","params":{"target_temp":23}},
       {"start":"12:00","end":"13:00","action":"maintain","params":{}},
       {"start":"13:00","end":"17:30","action":"normal_heating","params":{"target_temp":23}},
       {"start":"17:30","end":"22:00","action":"transition_overtime","params":{}},
       {"start":"22:00","end":"06:00","action":"anti_freeze","params":{"min_pipe_temp":5}}
     ],
     "tue": "same_as_mon", "wed": "same_as_mon", "thu": "same_as_mon", "fri": "same_as_mon",
     "sat": [{"start":"00:00","end":"24:00","action":"anti_freeze","params":{"min_pipe_temp":5}}],
     "sun": "same_as_sat"
   }'::jsonb,
   '{"season":"heating","description":"冬季制热排程，含预热、正常供暖、过渡、夜间防冻"}'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Done! Summary will be printed below.
-- ============================================================================

-- Verify counts
DO $$
DECLARE
  v_floors INT; v_zones INT; v_equip INT; v_points INT; v_rules INT; v_sched INT;
BEGIN
  SELECT count(*) INTO v_floors FROM floors WHERE building_id = '5da6918d-0f36-41b0-878e-5dd39bd20eaf';
  SELECT count(*) INTO v_zones  FROM zones  WHERE building_id = '5da6918d-0f36-41b0-878e-5dd39bd20eaf';
  SELECT count(*) INTO v_equip  FROM equipment e JOIN systems s ON e.system_id = s.id WHERE s.building_id = '5da6918d-0f36-41b0-878e-5dd39bd20eaf';
  SELECT count(*) INTO v_points FROM points WHERE building_id = '5da6918d-0f36-41b0-878e-5dd39bd20eaf';
  SELECT count(*) INTO v_rules  FROM alarm_rules WHERE code LIKE 'ALR-%';
  SELECT count(*) INTO v_sched  FROM schedules WHERE building_id = '5da6918d-0f36-41b0-878e-5dd39bd20eaf';

  RAISE NOTICE '=== Office-HVAC Seed Complete for BLD-SH-001 ===';
  RAISE NOTICE 'Floors:      %', v_floors;
  RAISE NOTICE 'Zones:       %', v_zones;
  RAISE NOTICE 'Equipment:   %', v_equip;
  RAISE NOTICE 'Points:      %', v_points;
  RAISE NOTICE 'Alarm Rules: %', v_rules;
  RAISE NOTICE 'Schedules:   %', v_sched;
END $$;
