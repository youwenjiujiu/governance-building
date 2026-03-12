use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

use super::enums::*;

// ─── Organization ───────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Organization {
    pub id: Uuid,
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    #[sqlx(rename = "type")]
    #[serde(rename = "type")]
    pub org_type: OrgType,
    pub parent_id: Option<Uuid>,
    pub legal_entity: Option<String>,
    pub tax_id: Option<String>,
    pub country: String,
    pub timezone: String,
    pub locale: String,
    pub logo_url: Option<String>,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
    pub updated_by: Uuid,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateOrganization {
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    #[serde(rename = "type")]
    pub org_type: OrgType,
    pub parent_id: Option<Uuid>,
    pub legal_entity: Option<String>,
    pub tax_id: Option<String>,
    pub country: String,
    pub timezone: String,
    pub locale: String,
    pub logo_url: Option<String>,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub metadata: Option<serde_json::Value>,
}

// ─── Site ────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Site {
    pub id: Uuid,
    pub org_id: Uuid,
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    pub address: String,
    pub city: String,
    pub province: Option<String>,
    pub country: String,
    pub postal_code: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub altitude: Option<f64>,
    pub timezone: String,
    pub climate_zone: Option<ClimateZone>,
    pub total_area: Option<f64>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
    pub updated_by: Uuid,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateSite {
    pub org_id: Uuid,
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    pub address: String,
    pub city: String,
    pub province: Option<String>,
    pub country: String,
    pub postal_code: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub timezone: String,
    pub climate_zone: Option<ClimateZone>,
    pub total_area: Option<f64>,
    pub metadata: Option<serde_json::Value>,
}

// ─── Building ────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Building {
    pub id: Uuid,
    pub site_id: Uuid,
    pub profile_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    pub building_type: BuildingType,
    pub year_built: Option<i16>,
    pub year_renovated: Option<i16>,
    pub gross_floor_area: f64,
    pub usable_area: Option<f64>,
    pub floors_above: i16,
    pub floors_below: Option<i16>,
    pub height: Option<f64>,
    pub climate_zone: ClimateZone,
    pub design_occupancy: Option<i32>,
    pub bim_model_url: Option<String>,
    pub address: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
    pub updated_by: Uuid,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateBuilding {
    pub site_id: Uuid,
    pub profile_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    pub building_type: BuildingType,
    pub year_built: Option<i16>,
    pub gross_floor_area: f64,
    pub usable_area: Option<f64>,
    pub floors_above: i16,
    pub floors_below: Option<i16>,
    pub height: Option<f64>,
    pub climate_zone: ClimateZone,
    pub design_occupancy: Option<i32>,
    pub address: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub metadata: Option<serde_json::Value>,
}

// ─── Floor ───────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Floor {
    pub id: Uuid,
    pub building_id: Uuid,
    pub code: String,
    pub name: String,
    pub sort_order: i32,
    pub elevation: Option<f64>,
    pub floor_height: Option<f64>,
    pub gross_area: Option<f64>,
    pub usable_area: Option<f64>,
    pub is_underground: bool,
    pub floor_type: Option<FloorType>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateFloor {
    pub building_id: Uuid,
    pub code: String,
    pub name: String,
    pub sort_order: i32,
    pub elevation: Option<f64>,
    pub floor_height: Option<f64>,
    pub gross_area: Option<f64>,
    pub usable_area: Option<f64>,
    pub is_underground: bool,
    pub metadata: Option<serde_json::Value>,
}

// ─── Zone ────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Zone {
    pub id: Uuid,
    pub floor_id: Uuid,
    pub building_id: Uuid,
    pub parent_zone_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    pub space_type: SpaceType,
    pub area: Option<f64>,
    pub volume: Option<f64>,
    pub capacity: Option<i32>,
    pub is_public: Option<bool>,
    pub hvac_zone_id: Option<String>,
    pub lighting_zone_id: Option<String>,
    pub fire_zone_id: Option<String>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateZone {
    pub floor_id: Uuid,
    pub building_id: Uuid,
    pub parent_zone_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    pub space_type: SpaceType,
    pub area: Option<f64>,
    pub volume: Option<f64>,
    pub capacity: Option<i32>,
    pub is_public: Option<bool>,
    pub metadata: Option<serde_json::Value>,
}

// ─── System ──────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct System {
    pub id: Uuid,
    pub building_id: Uuid,
    pub code: String,
    pub name: String,
    pub system_type: SystemType,
    pub sub_type: Option<String>,
    pub description: Option<String>,
    pub design_capacity: Option<serde_json::Value>,
    pub commissioning_date: Option<NaiveDate>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateSystem {
    pub building_id: Uuid,
    pub code: String,
    pub name: String,
    pub system_type: SystemType,
    pub sub_type: Option<String>,
    pub description: Option<String>,
    pub design_capacity: Option<serde_json::Value>,
    pub commissioning_date: Option<NaiveDate>,
    pub metadata: Option<serde_json::Value>,
}

// ─── Equipment ───────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Equipment {
    pub id: Uuid,
    pub system_id: Uuid,
    pub zone_id: Option<Uuid>,
    pub parent_equipment_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub equipment_type: EquipmentType,
    pub sub_type: Option<String>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub serial_number: Option<String>,
    pub rated_power: Option<f64>,
    pub rated_capacity: Option<serde_json::Value>,
    pub install_date: Option<NaiveDate>,
    pub warranty_expiry: Option<NaiveDate>,
    pub expected_life_years: Option<i16>,
    pub last_maintenance_date: Option<NaiveDate>,
    pub next_maintenance_date: Option<NaiveDate>,
    pub maintenance_cycle_days: Option<i32>,
    pub barcode: Option<String>,
    pub qr_code_url: Option<String>,
    pub bim_guid: Option<String>,
    pub backup_equipment_id: Option<Uuid>,
    pub redundancy_group_id: Option<Uuid>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateEquipment {
    pub system_id: Uuid,
    pub zone_id: Option<Uuid>,
    pub parent_equipment_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub equipment_type: EquipmentType,
    pub sub_type: Option<String>,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub serial_number: Option<String>,
    pub rated_power: Option<f64>,
    pub rated_capacity: Option<serde_json::Value>,
    pub install_date: Option<NaiveDate>,
    pub metadata: Option<serde_json::Value>,
}

// ─── Component ───────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Component {
    pub id: Uuid,
    pub equipment_id: Uuid,
    pub code: String,
    pub name: String,
    pub component_type: String,
    pub manufacturer: Option<String>,
    pub model: Option<String>,
    pub serial_number: Option<String>,
    pub install_date: Option<NaiveDate>,
    pub replacement_date: Option<NaiveDate>,
    pub expected_life_years: Option<i16>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── Point ───────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Point {
    pub id: Uuid,
    pub equipment_id: Option<Uuid>,
    pub component_id: Option<Uuid>,
    pub zone_id: Option<Uuid>,
    pub building_id: Uuid,
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    pub point_class: PointClass,
    pub data_type: PointDataType,
    pub unit: Option<String>,
    pub access: PointAccess,
    pub source_protocol: SourceProtocol,
    pub source_address: serde_json::Value,
    pub polling_interval_s: Option<i32>,
    pub cov_enabled: Option<bool>,
    pub cov_increment: Option<f64>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
    pub default_value: Option<String>,
    pub alarm_enabled: bool,
    pub alarm_hi_hi: Option<f64>,
    pub alarm_hi: Option<f64>,
    pub alarm_lo: Option<f64>,
    pub alarm_lo_lo: Option<f64>,
    pub alarm_deadband: Option<f64>,
    pub alarm_delay_s: Option<i32>,
    pub trend_enabled: bool,
    pub trend_interval_s: Option<i32>,
    pub trend_retention_days: Option<i32>,
    pub display_group: Option<String>,
    pub display_order: Option<i32>,
    pub is_virtual: Option<bool>,
    pub calc_expression: Option<String>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub current_value: Option<String>,
    pub current_quality: Option<PointQuality>,
    pub value_timestamp: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePoint {
    pub equipment_id: Option<Uuid>,
    pub component_id: Option<Uuid>,
    pub zone_id: Option<Uuid>,
    pub building_id: Uuid,
    pub code: String,
    pub name: String,
    pub name_en: Option<String>,
    pub point_class: PointClass,
    pub data_type: PointDataType,
    pub unit: Option<String>,
    pub access: PointAccess,
    pub source_protocol: SourceProtocol,
    pub source_address: serde_json::Value,
    pub polling_interval_s: Option<i32>,
    pub alarm_enabled: bool,
    pub alarm_hi: Option<f64>,
    pub alarm_lo: Option<f64>,
    pub trend_enabled: bool,
    pub metadata: Option<serde_json::Value>,
}

// ─── AlarmRule ────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AlarmRule {
    pub id: Uuid,
    pub code: String,
    pub name: String,
    pub description: Option<String>,
    pub severity: AlarmSeverity,
    pub category: AlarmCategory,
    pub target_point_class: Option<String>,
    pub target_equipment_type: Option<EquipmentType>,
    pub condition_type: ConditionType,
    pub condition_expr: String,
    pub threshold_default: Option<f64>,
    pub deadband_default: Option<f64>,
    pub delay_s_default: Option<i32>,
    pub escalation_rules: Option<serde_json::Value>,
    pub suppression_rules: Option<serde_json::Value>,
    pub auto_create_work_order: Option<bool>,
    pub notification_template_id: Option<Uuid>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── Alarm ───────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Alarm {
    pub id: Uuid,
    pub building_id: Uuid,
    pub alarm_rule_id: Option<Uuid>,
    pub point_id: Option<Uuid>,
    pub equipment_id: Option<Uuid>,
    pub zone_id: Option<Uuid>,
    pub alarm_code: String,
    pub severity: AlarmSeverity,
    pub category: AlarmCategory,
    pub state: AlarmState,
    pub title: String,
    pub description: Option<String>,
    pub trigger_value: Option<String>,
    pub threshold_value: Option<String>,
    pub triggered_at: DateTime<Utc>,
    pub acked_at: Option<DateTime<Utc>>,
    pub acked_by: Option<Uuid>,
    pub ack_note: Option<String>,
    pub cleared_at: Option<DateTime<Utc>>,
    pub closed_at: Option<DateTime<Utc>>,
    pub closed_by: Option<Uuid>,
    pub close_note: Option<String>,
    pub duration_s: Option<i32>,
    pub escalation_level: i16,
    pub is_suppressed: bool,
    pub suppressed_by: Option<String>,
    pub work_order_id: Option<Uuid>,
    pub repeat_count: Option<i32>,
    pub patient_impact: Option<PatientImpact>,
    pub affected_scope: Option<AffectedScope>,
    pub metadata: Option<serde_json::Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateAlarm {
    pub building_id: Uuid,
    pub alarm_rule_id: Option<Uuid>,
    pub point_id: Option<Uuid>,
    pub equipment_id: Option<Uuid>,
    pub zone_id: Option<Uuid>,
    pub alarm_code: String,
    pub severity: AlarmSeverity,
    pub category: AlarmCategory,
    pub title: String,
    pub description: Option<String>,
    pub trigger_value: Option<String>,
    pub threshold_value: Option<String>,
}

// ─── Schedule ────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Schedule {
    pub id: Uuid,
    pub building_id: Uuid,
    pub code: String,
    pub name: String,
    pub schedule_type: ScheduleType,
    pub target_type: String,
    pub target_ids: Vec<Uuid>,
    pub target_point_id: Option<Uuid>,
    pub timezone: String,
    pub weekly_schedule: Option<serde_json::Value>,
    pub yearly_calendar: Option<serde_json::Value>,
    pub exceptions: Option<serde_json::Value>,
    pub effective_from: Option<NaiveDate>,
    pub effective_to: Option<NaiveDate>,
    pub priority: i32,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateSchedule {
    pub building_id: Uuid,
    pub code: String,
    pub name: String,
    pub schedule_type: ScheduleType,
    pub target_type: String,
    pub target_ids: Vec<Uuid>,
    pub target_point_id: Option<Uuid>,
    pub timezone: String,
    pub weekly_schedule: Option<serde_json::Value>,
    pub yearly_calendar: Option<serde_json::Value>,
    pub exceptions: Option<serde_json::Value>,
    pub effective_from: Option<NaiveDate>,
    pub effective_to: Option<NaiveDate>,
    pub priority: i32,
    pub metadata: Option<serde_json::Value>,
}

// ─── WorkOrder ───────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct WorkOrder {
    pub id: Uuid,
    pub building_id: Uuid,
    pub code: String,
    pub title: String,
    pub description: Option<String>,
    pub wo_type: WorkOrderType,
    pub priority: WorkOrderPriority,
    pub state: WorkOrderStatus,
    pub source: WorkOrderSource,
    pub alarm_id: Option<Uuid>,
    pub target_type: Option<String>,
    pub target_id: Option<Uuid>,
    pub zone_id: Option<Uuid>,
    pub requested_by: Uuid,
    pub assigned_to: Option<Uuid>,
    pub assigned_team: Option<String>,
    pub sla_response_min: Option<i32>,
    pub sla_resolve_min: Option<i32>,
    pub sla_response_deadline: Option<DateTime<Utc>>,
    pub sla_resolve_deadline: Option<DateTime<Utc>>,
    pub sla_response_met: Option<bool>,
    pub sla_resolve_met: Option<bool>,
    pub responded_at: Option<DateTime<Utc>>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub verified_at: Option<DateTime<Utc>>,
    pub closed_at: Option<DateTime<Utc>>,
    pub cancelled_at: Option<DateTime<Utc>>,
    pub resolution: Option<String>,
    pub root_cause: Option<String>,
    pub labor_hours: Option<f64>,
    pub cost: Option<f64>,
    pub cost_currency: Option<String>,
    pub consumed_assets: Option<serde_json::Value>,
    pub attachments: Option<serde_json::Value>,
    pub comments: Option<serde_json::Value>,
    pub change_type: Option<WorkOrderChangeType>,
    pub risk_level: Option<RiskLevel>,
    pub cab_approval: Option<CabApproval>,
    pub reviewer_id: Option<Uuid>,
    pub reviewed_at: Option<DateTime<Utc>>,
    pub metadata: Option<serde_json::Value>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateWorkOrder {
    pub building_id: Uuid,
    pub code: String,
    pub title: String,
    pub description: Option<String>,
    pub wo_type: WorkOrderType,
    pub priority: WorkOrderPriority,
    pub source: WorkOrderSource,
    pub alarm_id: Option<Uuid>,
    pub target_type: Option<String>,
    pub target_id: Option<Uuid>,
    pub zone_id: Option<Uuid>,
    pub requested_by: Uuid,
    pub assigned_to: Option<Uuid>,
    pub assigned_team: Option<String>,
    pub metadata: Option<serde_json::Value>,
}

// ─── AuditLog ────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AuditLog {
    pub id: Uuid,
    pub timestamp: DateTime<Utc>,
    pub user_id: Option<Uuid>,
    pub user_name: Option<String>,
    pub client_ip: Option<String>,
    pub user_agent: Option<String>,
    pub action: AuditAction,
    pub resource_type: String,
    pub resource_id: Uuid,
    pub resource_name: Option<String>,
    pub building_id: Option<Uuid>,
    pub org_id: Option<Uuid>,
    pub before_value: Option<serde_json::Value>,
    pub after_value: Option<serde_json::Value>,
    pub description: Option<String>,
    pub result: AuditResult,
    pub error_message: Option<String>,
    pub session_id: Option<String>,
    pub correlation_id: Option<String>,
    pub metadata: Option<serde_json::Value>,
}

// ─── Notification ────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Notification {
    pub id: Uuid,
    pub org_id: Uuid,
    pub building_id: Option<Uuid>,
    pub notification_type: NotificationType,
    pub channel: NotificationChannel,
    pub priority: NotificationPriority,
    pub source_type: String,
    pub source_id: Uuid,
    pub template_id: Option<Uuid>,
    pub recipient_user_id: Option<Uuid>,
    pub recipient_role: Option<String>,
    pub recipient_address: String,
    pub title: String,
    pub body: String,
    pub body_html: Option<String>,
    pub send_state: SendState,
    pub scheduled_at: Option<DateTime<Utc>>,
    pub sent_at: Option<DateTime<Utc>>,
    pub delivered_at: Option<DateTime<Utc>>,
    pub read_at: Option<DateTime<Utc>>,
    pub failed_reason: Option<String>,
    pub retry_count: i32,
    pub max_retries: i32,
    pub metadata: Option<serde_json::Value>,
    pub created_at: DateTime<Utc>,
}

// ─── Tenant ──────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Tenant {
    pub id: Uuid,
    pub org_id: Uuid,
    pub name: String,
    pub tenant_type: TenantType,
    pub contact_name: Option<String>,
    pub contact_phone: Option<String>,
    pub contact_email: Option<String>,
    pub lease_start: Option<NaiveDate>,
    pub lease_end: Option<NaiveDate>,
    pub metadata: Option<serde_json::Value>,
    pub status: TenantStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTenant {
    pub org_id: Uuid,
    pub name: String,
    pub tenant_type: TenantType,
    pub contact_name: Option<String>,
    pub contact_phone: Option<String>,
    pub contact_email: Option<String>,
    pub metadata: Option<serde_json::Value>,
}

// ─── Lease ───────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Lease {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub building_id: Uuid,
    pub spaces: Vec<Uuid>,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub billing_model: Option<String>,
    pub power_limit_kw: Option<f64>,
    pub metadata: Option<serde_json::Value>,
    pub status: LeaseStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── BillingRule ─────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BillingRule {
    pub id: Uuid,
    pub name: String,
    pub billing_type: BillingType,
    pub rate_table: serde_json::Value,
    pub shared_cost_algorithm: Option<String>,
    pub overtime_rate: Option<f64>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── BillingRecord ───────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BillingRecord {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub billing_rule_id: Option<Uuid>,
    pub period: String,
    pub meter_readings: serde_json::Value,
    pub amount: f64,
    pub shared_cost: Option<f64>,
    pub total: f64,
    pub currency: String,
    pub metadata: Option<serde_json::Value>,
    pub status: BillingStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── RedundancyGroup ─────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct RedundancyGroup {
    pub id: Uuid,
    pub name: String,
    pub building_id: Uuid,
    pub redundancy_type: RedundancyType,
    pub primary_equipment_ids: Vec<Uuid>,
    pub standby_equipment_ids: Vec<Uuid>,
    pub auto_failover: bool,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── CabinetAsset ────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CabinetAsset {
    pub id: Uuid,
    pub name: String,
    pub zone_id: Uuid,
    pub building_id: Uuid,
    pub total_u: i16,
    pub used_u: Option<i16>,
    pub power_capacity_kw: Option<f64>,
    pub actual_power_kw: Option<f64>,
    pub cooling_capacity_kw: Option<f64>,
    pub network_ports: Option<i32>,
    pub weight_limit_kg: Option<f64>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── TrafficSensor ───────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct TrafficSensor {
    pub id: Uuid,
    pub name: String,
    pub zone_id: Uuid,
    pub building_id: Uuid,
    pub sensor_type: TrafficSensorType,
    pub direction: TrafficDirection,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── EmissionMonitoring ──────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct EmissionMonitoring {
    pub id: Uuid,
    pub name: String,
    pub building_id: Uuid,
    pub zone_id: Option<Uuid>,
    pub emission_type: EmissionType,
    pub regulation_standard: Option<String>,
    pub limit_value: Option<f64>,
    pub unit: Option<String>,
    pub point_id: Option<Uuid>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── BuildingProfile ─────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BuildingProfile {
    pub id: Uuid,
    pub code: String,
    pub name: String,
    pub description: Option<String>,
    pub building_type: BuildingType,
    pub version: String,
    pub is_published: bool,
    pub default_systems: serde_json::Value,
    pub default_equipment_templates: Option<serde_json::Value>,
    pub default_point_templates: Option<serde_json::Value>,
    pub default_schedules: Option<serde_json::Value>,
    pub default_scenarios: Option<serde_json::Value>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── Scenario ────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Scenario {
    pub id: Uuid,
    pub building_id: Uuid,
    pub code: String,
    pub name: String,
    pub description: Option<String>,
    pub scenario_type: String,
    pub priority: i32,
    pub is_exclusive: bool,
    pub trigger_conditions: serde_json::Value,
    pub actions: serde_json::Value,
    pub rollback_actions: Option<serde_json::Value>,
    pub activation_mode: String,
    pub current_state: String,
    pub activated_at: Option<DateTime<Utc>>,
    pub activated_by: Option<Uuid>,
    pub deactivated_at: Option<DateTime<Utc>>,
    pub cooldown_s: Option<i32>,
    pub max_duration_s: Option<i32>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── ComplianceRule ──────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ComplianceRule {
    pub id: Uuid,
    pub code: String,
    pub name: String,
    pub description: Option<String>,
    pub regulation_ref: Option<String>,
    pub country: String,
    pub region: Option<String>,
    pub industry: Option<String>,
    pub rule_type: String,
    pub rule_config: serde_json::Value,
    pub check_interval: Option<String>,
    pub enforcement_level: String,
    pub effective_from: Option<NaiveDate>,
    pub effective_to: Option<NaiveDate>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── EnergyMeter ─────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct EnergyMeter {
    pub id: Uuid,
    pub building_id: Uuid,
    pub parent_meter_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub meter_type: String,
    pub sub_type: Option<String>,
    pub measurement: String,
    pub unit: String,
    pub ct_ratio: Option<f64>,
    pub pt_ratio: Option<f64>,
    pub multiplier: Option<f64>,
    pub point_id: Option<Uuid>,
    pub equipment_id: Option<Uuid>,
    pub tariff_schedule: Option<serde_json::Value>,
    pub billing_cycle: Option<String>,
    pub cost_center: Option<String>,
    pub install_date: Option<NaiveDate>,
    pub last_calibration_date: Option<NaiveDate>,
    pub next_calibration_date: Option<NaiveDate>,
    pub metadata: Option<serde_json::Value>,
    pub status: EntityStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ─── PointValue (Time series) ────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PointValue {
    pub point_id: Uuid,
    pub ts: DateTime<Utc>,
    pub value_numeric: Option<f64>,
    pub value_text: Option<String>,
    pub value_bool: Option<bool>,
    pub value_json: Option<serde_json::Value>,
    pub quality: PointQuality,
}
