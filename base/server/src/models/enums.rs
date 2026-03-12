use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "building_type", rename_all = "snake_case")]
pub enum BuildingType {
    Office,
    Hotel,
    Hospital,
    Mall,
    Factory,
    Warehouse,
    Residential,
    School,
    DataCenter,
    Convention,
    Stadium,
    Airport,
    RailStation,
    MixedUse,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "climate_zone", rename_all = "snake_case")]
pub enum ClimateZone {
    SevereCold,
    Cold,
    HotSummerColdWinter,
    HotSummerWarmWinter,
    Mild,
    Tropical,
    Marine,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "system_type", rename_all = "snake_case")]
pub enum SystemType {
    Hvac,
    Lighting,
    Electrical,
    FireProtection,
    Security,
    Plumbing,
    Elevator,
    Bas,
    EnergyMgmt,
    Network,
    Renewable,
    Waste,
    MedicalGas,
    CleanRoom,
    ColdChain,
    RadiationProtection,
    PurifiedWater,
    KitchenExhaust,
    Refrigeration,
    EscalatorElevator,
    Drainage,
    LiquidCooling,
    PrecisionCooling,
    PowerDistribution,
    UpsGenerator,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "equipment_type", rename_all = "snake_case")]
pub enum EquipmentType {
    Chiller,
    Boiler,
    CoolingTower,
    Ahu,
    Fcu,
    Vav,
    Pump,
    Fan,
    HeatExchanger,
    Vrf,
    SplitAc,
    Transformer,
    Switchgear,
    Ups,
    Generator,
    Pdu,
    LightingPanel,
    Luminaire,
    FireAlarmPanel,
    SmokeDetector,
    Sprinkler,
    FirePump,
    CctvCamera,
    AccessController,
    ElevatorCar,
    Escalator,
    WaterTank,
    Meter,
    Sensor,
    Actuator,
    Valve,
    Damper,
    SolarPanel,
    BatteryStorage,
    O2Manifold,
    VacuumPump,
    MedicalAirCompressor,
    HepaUnit,
    ParticleCounter,
    BloodFridge,
    PharmacyFridge,
    UltraLowFreezer,
    RadiationMonitor,
    RoUnit,
    ExhaustFan,
    EspUnit,
    WalkInCooler,
    DisplayCabinet,
    SumpPump,
    Crac,
    Crah,
    Cdu,
    Ats,
    Sts,
    UpsUnit,
    DieselGenerator,
    VesdaDetector,
    LeakDetectionCable,
    HotWaterBoiler,
    HeatPumpDhw,
    PoolFilterPump,
    PoolHeater,
    ChemicalDosing,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "space_type", rename_all = "snake_case")]
pub enum SpaceType {
    Office,
    MeetingRoom,
    Lobby,
    Corridor,
    Restroom,
    Stairwell,
    ElevatorHall,
    MechanicalRoom,
    ElectricalRoom,
    ServerRoom,
    Kitchen,
    Dining,
    Storage,
    Parking,
    GuestRoom,
    Ward,
    OperatingRoom,
    Retail,
    Production,
    Cleanroom,
    Outdoor,
    Icu,
    IsolationRoom,
    Pharmacy,
    BloodBank,
    Radiology,
    RetailUnit,
    FoodCourt,
    Atrium,
    LoadingDock,
    ColdStorage,
    WhiteSpace,
    GraySpace,
    BatteryRoom,
    GeneratorYard,
    Noc,
    BanquetHall,
    Spa,
    SwimmingPool,
    Laundry,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "point_data_type", rename_all = "snake_case")]
pub enum PointDataType {
    Float,
    Int,
    Bool,
    String,
    Enum,
    Json,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "point_access", rename_all = "snake_case")]
pub enum PointAccess {
    ReadOnly,
    ReadWrite,
    WriteOnly,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "source_protocol", rename_all = "snake_case")]
pub enum SourceProtocol {
    Bacnet,
    ModbusTcp,
    ModbusRtu,
    OpcUa,
    OpcDa,
    Mqtt,
    Knx,
    Lonworks,
    Dali,
    Snmp,
    HttpApi,
    Virtual,
    Manual,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "alarm_severity", rename_all = "snake_case")]
pub enum AlarmSeverity {
    Critical,
    Major,
    Minor,
    Warning,
    Info,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "alarm_category", rename_all = "snake_case")]
pub enum AlarmCategory {
    Fire,
    Security,
    LifeSafety,
    Process,
    EquipmentFault,
    Communication,
    Energy,
    Environmental,
    Maintenance,
    System,
    MedicalGas,
    CleanRoom,
    ColdChain,
    Radiation,
    WaterQuality,
    KitchenExhaust,
    Refrigeration,
    CrowdSafety,
    Flood,
    Cooling,
    Power,
    WaterLeak,
    Capacity,
    PoolWater,
    HotWater,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "alarm_state", rename_all = "snake_case")]
pub enum AlarmState {
    ActiveUnacked,
    ActiveAcked,
    ClearedUnacked,
    ClearedAcked,
    Closed,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "work_order_status", rename_all = "snake_case")]
pub enum WorkOrderStatus {
    Open,
    Assigned,
    InProgress,
    PendingParts,
    PendingApproval,
    Completed,
    Verified,
    Closed,
    Cancelled,
    Reopened,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "work_order_type", rename_all = "snake_case")]
pub enum WorkOrderType {
    Corrective,
    Preventive,
    Predictive,
    Inspection,
    Emergency,
    Project,
    Request,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "work_order_change_type", rename_all = "snake_case")]
pub enum WorkOrderChangeType {
    Maintenance,
    Emergency,
    PlannedChange,
    StandardChange,
    CabRequired,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "risk_level", rename_all = "snake_case")]
pub enum RiskLevel {
    Low,
    Medium,
    High,
    Critical,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "cab_approval", rename_all = "snake_case")]
pub enum CabApproval {
    NotRequired,
    Pending,
    Approved,
    Rejected,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "schedule_type", rename_all = "snake_case")]
pub enum ScheduleType {
    Weekly,
    Calendar,
    OneTime,
    Recurring,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "notification_channel", rename_all = "snake_case")]
pub enum NotificationChannel {
    Email,
    Sms,
    Push,
    Wechat,
    Dingtalk,
    Webhook,
    PaSystem,
    PaBroadcast,
    InApp,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "tenant_type", rename_all = "snake_case")]
pub enum TenantType {
    Enterprise,
    Individual,
    Government,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "tenant_status", rename_all = "snake_case")]
pub enum TenantStatus {
    Active,
    Expired,
    Pending,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "lease_status", rename_all = "snake_case")]
pub enum LeaseStatus {
    Active,
    Expired,
    Pending,
    Terminated,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "billing_type", rename_all = "snake_case")]
pub enum BillingType {
    ByArea,
    ByCooling,
    ByTime,
    ByUsage,
    Mixed,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "billing_status", rename_all = "snake_case")]
pub enum BillingStatus {
    Draft,
    Confirmed,
    Paid,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "patient_impact", rename_all = "snake_case")]
pub enum PatientImpact {
    None,
    Low,
    Medium,
    High,
    Critical,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "affected_scope", rename_all = "snake_case")]
pub enum AffectedScope {
    Equipment,
    Zone,
    Floor,
    Building,
    Campus,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "redundancy_type", rename_all = "snake_case")]
pub enum RedundancyType {
    NPlus1,
    TwoN,
    TwoNPlus1,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "emission_type", rename_all = "snake_case")]
pub enum EmissionType {
    Fume,
    ExhaustGas,
    Wastewater,
    Noise,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "traffic_sensor_type", rename_all = "snake_case")]
pub enum TrafficSensorType {
    Infrared,
    Video,
    Wifi,
    Bluetooth,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "traffic_direction", rename_all = "snake_case")]
pub enum TrafficDirection {
    In,
    Out,
    Bidirectional,
}

// Additional enums used by entities

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "entity_status", rename_all = "snake_case")]
pub enum EntityStatus {
    Active,
    Inactive,
    Archived,
    Deleted,
    Pending,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "point_class", rename_all = "snake_case")]
pub enum PointClass {
    Sensor,
    Command,
    Setpoint,
    Status,
    AlarmPoint,
    Calculated,
    Accumulator,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "point_quality", rename_all = "snake_case")]
pub enum PointQuality {
    Good,
    Uncertain,
    Bad,
    Offline,
    NotConfigured,
    Overridden,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "condition_type", rename_all = "snake_case")]
pub enum ConditionType {
    HiHiLimit,
    HiLimit,
    LoLimit,
    LoLoLimit,
    Deviation,
    RateOfChange,
    StateChange,
    BoolTrue,
    BoolFalse,
    Expression,
    Offline,
    Stale,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "work_order_priority", rename_all = "snake_case")]
pub enum WorkOrderPriority {
    Emergency,
    High,
    Medium,
    Low,
    Planned,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "work_order_source", rename_all = "snake_case")]
pub enum WorkOrderSource {
    Alarm,
    Manual,
    Schedule,
    Inspection,
    TenantRequest,
    AiPrediction,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "audit_action", rename_all = "snake_case")]
pub enum AuditAction {
    Create,
    Update,
    Delete,
    Login,
    Logout,
    LoginFailed,
    PointWrite,
    AlarmAck,
    AlarmClose,
    ScenarioActivate,
    ScenarioDeactivate,
    ScheduleOverride,
    PermissionGrant,
    PermissionRevoke,
    ConfigChange,
    DataExport,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "audit_result", rename_all = "snake_case")]
pub enum AuditResult {
    Success,
    Failure,
    Denied,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "notification_type", rename_all = "snake_case")]
pub enum NotificationType {
    Alarm,
    WorkOrder,
    Report,
    System,
    MaintenanceReminder,
    ComplianceAlert,
    EnergyAlert,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "notification_priority", rename_all = "snake_case")]
pub enum NotificationPriority {
    Urgent,
    High,
    Normal,
    Low,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "send_state", rename_all = "snake_case")]
pub enum SendState {
    Pending,
    Sending,
    Sent,
    Delivered,
    Read,
    Failed,
    Cancelled,
}
