-- 009_indexes.sql
-- 为常用查询场景创建索引，包括外键关联、状态筛选、JSONB GIN 索引等

-- ============================================================
-- organizations
-- ============================================================
CREATE INDEX idx_organizations_parent ON organizations(parent_id);
CREATE INDEX idx_organizations_status ON organizations(status);

-- ============================================================
-- sites
-- ============================================================
CREATE INDEX idx_sites_org ON sites(org_id);
CREATE INDEX idx_sites_status ON sites(status);

-- ============================================================
-- buildings
-- ============================================================
CREATE INDEX idx_buildings_site ON buildings(site_id);
CREATE INDEX idx_buildings_type ON buildings(building_type);
CREATE INDEX idx_buildings_status ON buildings(status);
CREATE INDEX idx_buildings_profile ON buildings(profile_id);

-- ============================================================
-- floors
-- ============================================================
CREATE INDEX idx_floors_building ON floors(building_id);
CREATE INDEX idx_floors_sort ON floors(building_id, sort_order);

-- ============================================================
-- zones
-- ============================================================
CREATE INDEX idx_zones_floor ON zones(floor_id);
CREATE INDEX idx_zones_building ON zones(building_id);
CREATE INDEX idx_zones_space_type ON zones(space_type);
CREATE INDEX idx_zones_parent ON zones(parent_zone_id);
CREATE INDEX idx_zones_status ON zones(status);

-- ============================================================
-- systems
-- ============================================================
CREATE INDEX idx_systems_building ON systems(building_id);
CREATE INDEX idx_systems_type ON systems(system_type);
CREATE INDEX idx_systems_status ON systems(status);

-- ============================================================
-- equipment
-- ============================================================
CREATE INDEX idx_equipment_system ON equipment(system_id);
CREATE INDEX idx_equipment_zone ON equipment(zone_id);
CREATE INDEX idx_equipment_type ON equipment(equipment_type);
CREATE INDEX idx_equipment_parent ON equipment(parent_equipment_id);
CREATE INDEX idx_equipment_backup ON equipment(backup_equipment_id);
CREATE INDEX idx_equipment_upstream ON equipment(upstream_equipment_id);
CREATE INDEX idx_equipment_redundancy_group ON equipment(redundancy_group_id);
CREATE INDEX idx_equipment_status ON equipment(status);
CREATE INDEX idx_equipment_maintenance ON equipment(maintenance_status);
CREATE INDEX idx_equipment_next_maint ON equipment(next_maintenance_date);

-- ============================================================
-- components
-- ============================================================
CREATE INDEX idx_components_equipment ON components(equipment_id);
CREATE INDEX idx_components_type ON components(component_type);

-- ============================================================
-- points
-- ============================================================
CREATE INDEX idx_points_building ON points(building_id);
CREATE INDEX idx_points_equipment ON points(equipment_id);
CREATE INDEX idx_points_component ON points(component_id);
CREATE INDEX idx_points_zone ON points(zone_id);
CREATE INDEX idx_points_class ON points(point_class);
CREATE INDEX idx_points_data_type ON points(data_type);
CREATE INDEX idx_points_protocol ON points(source_protocol);
CREATE INDEX idx_points_status ON points(status);
CREATE INDEX idx_points_alarm_enabled ON points(building_id) WHERE alarm_enabled = true;
CREATE INDEX idx_points_trend_enabled ON points(building_id) WHERE trend_enabled = true;

-- GIN 索引 for JSONB 字段
CREATE INDEX idx_points_tags_gin ON points USING GIN (tags);
CREATE INDEX idx_points_metadata_gin ON points USING GIN (metadata);
CREATE INDEX idx_points_source_address_gin ON points USING GIN (source_address);

-- ============================================================
-- alarms
-- ============================================================
CREATE INDEX idx_alarms_building ON alarms(building_id);
CREATE INDEX idx_alarms_state ON alarms(state);
CREATE INDEX idx_alarms_severity ON alarms(severity);
CREATE INDEX idx_alarms_category ON alarms(category);
CREATE INDEX idx_alarms_point ON alarms(point_id);
CREATE INDEX idx_alarms_equipment ON alarms(equipment_id);
CREATE INDEX idx_alarms_zone ON alarms(zone_id);
CREATE INDEX idx_alarms_rule ON alarms(alarm_rule_id);
CREATE INDEX idx_alarms_triggered_at ON alarms(triggered_at DESC);
CREATE INDEX idx_alarms_active ON alarms(building_id, state) WHERE state IN ('ACTIVE_UNACKED', 'ACTIVE_ACKED');

-- ============================================================
-- alarm_rules
-- ============================================================
CREATE INDEX idx_alarm_rules_category ON alarm_rules(category);
CREATE INDEX idx_alarm_rules_severity ON alarm_rules(severity);
CREATE INDEX idx_alarm_rules_status ON alarm_rules(status);

-- ============================================================
-- schedules
-- ============================================================
CREATE INDEX idx_schedules_building ON schedules(building_id);
CREATE INDEX idx_schedules_type ON schedules(schedule_type);
CREATE INDEX idx_schedules_status ON schedules(status);

-- ============================================================
-- work_orders
-- ============================================================
CREATE INDEX idx_work_orders_building ON work_orders(building_id);
CREATE INDEX idx_work_orders_state ON work_orders(state);
CREATE INDEX idx_work_orders_priority ON work_orders(priority);
CREATE INDEX idx_work_orders_assigned ON work_orders(assigned_to);
CREATE INDEX idx_work_orders_alarm ON work_orders(alarm_id);
CREATE INDEX idx_work_orders_created ON work_orders(created_at DESC);
CREATE INDEX idx_work_orders_open ON work_orders(building_id, state) WHERE state NOT IN ('CLOSED', 'CANCELLED');

-- ============================================================
-- audit_logs
-- ============================================================
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_building ON audit_logs(building_id);
CREATE INDEX idx_audit_logs_org ON audit_logs(org_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);

-- ============================================================
-- notifications
-- ============================================================
CREATE INDEX idx_notifications_org ON notifications(org_id);
CREATE INDEX idx_notifications_building ON notifications(building_id);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_user_id);
CREATE INDEX idx_notifications_state ON notifications(send_state);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- ============================================================
-- tenants
-- ============================================================
CREATE INDEX idx_tenants_org ON tenants(org_id);
CREATE INDEX idx_tenants_status ON tenants(status);

-- ============================================================
-- leases
-- ============================================================
CREATE INDEX idx_leases_tenant ON leases(tenant_id);
CREATE INDEX idx_leases_building ON leases(building_id);
CREATE INDEX idx_leases_status ON leases(status);
CREATE INDEX idx_leases_dates ON leases(start_date, end_date);

-- ============================================================
-- billing_records
-- ============================================================
CREATE INDEX idx_billing_records_tenant ON billing_records(tenant_id);
CREATE INDEX idx_billing_records_period ON billing_records(period);
CREATE INDEX idx_billing_records_status ON billing_records(status);

-- ============================================================
-- energy_meters
-- ============================================================
CREATE INDEX idx_energy_meters_building ON energy_meters(building_id);
CREATE INDEX idx_energy_meters_parent ON energy_meters(parent_meter_id);
CREATE INDEX idx_energy_meters_type ON energy_meters(meter_type);

-- ============================================================
-- scenarios
-- ============================================================
CREATE INDEX idx_scenarios_building ON scenarios(building_id);
CREATE INDEX idx_scenarios_type ON scenarios(scenario_type);
CREATE INDEX idx_scenarios_state ON scenarios(current_state);

-- ============================================================
-- redundancy_groups
-- ============================================================
CREATE INDEX idx_redundancy_groups_building ON redundancy_groups(building_id);

-- ============================================================
-- cabinet_assets
-- ============================================================
CREATE INDEX idx_cabinet_assets_building ON cabinet_assets(building_id);
CREATE INDEX idx_cabinet_assets_zone ON cabinet_assets(zone_id);

-- ============================================================
-- traffic_sensors
-- ============================================================
CREATE INDEX idx_traffic_sensors_building ON traffic_sensors(building_id);
CREATE INDEX idx_traffic_sensors_zone ON traffic_sensors(zone_id);

-- ============================================================
-- emission_monitorings
-- ============================================================
CREATE INDEX idx_emission_monitorings_building ON emission_monitorings(building_id);
CREATE INDEX idx_emission_monitorings_zone ON emission_monitorings(zone_id);

-- ============================================================
-- GIN 索引 for 其他表的 JSONB 字段
-- ============================================================
CREATE INDEX idx_organizations_metadata_gin ON organizations USING GIN (metadata);
CREATE INDEX idx_buildings_metadata_gin ON buildings USING GIN (metadata);
CREATE INDEX idx_buildings_certifications_gin ON buildings USING GIN (certifications);
CREATE INDEX idx_zones_metadata_gin ON zones USING GIN (metadata);
CREATE INDEX idx_equipment_metadata_gin ON equipment USING GIN (metadata);
CREATE INDEX idx_equipment_rated_capacity_gin ON equipment USING GIN (rated_capacity);
CREATE INDEX idx_systems_metadata_gin ON systems USING GIN (metadata);
CREATE INDEX idx_systems_design_capacity_gin ON systems USING GIN (design_capacity);
CREATE INDEX idx_alarms_metadata_gin ON alarms USING GIN (metadata);
CREATE INDEX idx_work_orders_metadata_gin ON work_orders USING GIN (metadata);
CREATE INDEX idx_audit_logs_before_gin ON audit_logs USING GIN (before_value);
CREATE INDEX idx_audit_logs_after_gin ON audit_logs USING GIN (after_value);
CREATE INDEX idx_schedules_weekly_gin ON schedules USING GIN (weekly_schedule);
CREATE INDEX idx_energy_meters_tariff_gin ON energy_meters USING GIN (tariff_schedule);
CREATE INDEX idx_scenarios_trigger_gin ON scenarios USING GIN (trigger_conditions);
CREATE INDEX idx_scenarios_actions_gin ON scenarios USING GIN (actions);
CREATE INDEX idx_compliance_rules_config_gin ON compliance_rules USING GIN (rule_config);
