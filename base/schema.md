# 公共基础层数据模型 (Base Schema)

> 楼宇远程运营平台底层数据模型，所有行业 Container（酒店/医院/商场/写字楼/工厂等）共享此层。

---

## 目录

1. [设计原则](#设计原则)
2. [实体关系图](#实体关系图)
3. [核心实体 Schema](#核心实体-schema)
4. [枚举值定义](#枚举值定义)

---

## 设计原则

### 为什么这样设计

1. **空间拓扑优先**：采用 Organization → Site → Building → Floor → Zone 的树状空间层级，与物理世界一一映射，便于权限继承、数据聚合和故障定位。
2. **系统-设备-部件-点位四级资产模型**：System → Equipment → Component → Point，将楼宇机电系统拆解到最小可观测/可控单元（Point），实现统一数据采集与控制。
3. **行业无关的基础层 + 行业特定的 Container 层**：本 schema 只定义所有行业共需的实体与字段；行业特有逻辑（如酒店客房状态、医院洁净等级）由上层 Container 扩展，通过 `metadata: JSON` 字段或继承实现。
4. **模板驱动批量部署**：BuildingProfile 作为行业模板，预设子系统、点位、告警规则和排程，新楼宇上线时一键实例化，大幅降低交付成本。
5. **场景模式解耦触发与动作**：Scenario 将触发条件和联动动作分离，支持正常/节假日/应急/VIP 等模式灵活切换。
6. **审计与合规内建**：AuditLog 和 ComplianceRule 作为一等实体，满足各行业/地区的数据保存与合规要求。
7. **多协议适配**：Point 实体包含 `source_protocol` 字段，屏蔽 BACnet/Modbus/OPC-UA/MQTT/KNX 等协议差异。

### 参考行业标准

| 标准 | 采纳内容 |
|------|---------|
| **Project Haystack 4.0** | 标签化语义模型、Point 分类体系（sensor/cmd/sp）、单位标准化 |
| **Brick Schema 1.3** | 空间拓扑关系（isPartOf/isLocationOf/feeds/hasPoint）、设备-点位关联 |
| **IFC 4.3 (buildingSMART)** | 空间层级（IfcSite/IfcBuilding/IfcBuildingStorey/IfcSpace）、设备分类 |
| **ASHRAE 223P** | 系统连接语义、流体/电气拓扑 |
| **ISO 16739 / ISO 52000** | 能效计算、气候区分类 |
| **NIST OSCAL** | 合规规则建模思路 |
| **RFC 5545 (iCalendar)** | 排程/日历/例外模型 |

---

## 实体关系图

```
Organization (组织/集团)
 └──< Site (园区/场地)                         [1:N]
      └──< Building (楼宇)                     [1:N]
           ├──< Floor (楼层)                   [1:N]
           │    └──< Zone (区域/房间)           [1:N]
           │         ├──< Equipment (设备)      [N:M via zone_equipment]
           │         └──< Point (点位)          [通过 Equipment/Component]
           ├──< System (子系统)                 [1:N]
           │    └──< Equipment (设备)           [1:N]
           │         └──< Component (部件)      [1:N]
           │              └──< Point (点位)     [1:N]
           ├──< Alarm (告警实例)                [1:N]
           ├──< Schedule (排程)                 [1:N]
           ├──< EnergyMeter (能源计量)          [1:N]
           ├──< Scenario (场景模式)             [1:N]
           └──  BuildingProfile (楼宇模板)      [N:1 引用]

AlarmRule (告警规则模板)
 └──> Alarm (告警实例)                         [1:N 触发]
 └──> Point (点位)                             [N:M 监控]

WorkOrder (工单)
 ├──> Equipment / Zone / Point                 [关联目标]
 ├──> User (指派人/执行人)                      [N:1]
 └──> Asset (备件消耗)                          [N:M]

Asset (资产/备件)
 └──> Equipment (关联设备)                      [N:M]

Trend (趋势数据)
 └──> Point (点位)                             [N:1]

User ──< Role ──< Permission                   [RBAC]

AuditLog ──> User + 任意实体                    [记录操作]

Notification ──> Alarm / WorkOrder / User       [推送目标]

ComplianceRule ──> Building / Organization      [合规约束]
```

### 关系说明

| 关系类型 | 语义 | 来源 |
|---------|------|------|
| `isPartOf` | 空间/物理从属 | Brick |
| `isLocationOf` | 设备安装位置 | Brick |
| `hasPoint` | 设备/部件拥有点位 | Brick/Haystack |
| `feeds` | 系统/设备送风/供水/供电给区域 | Brick |
| `monitors` | 告警规则监控点位 | 自定义 |
| `triggers` | 场景触发动作 | 自定义 |

---

## 核心实体 Schema

### 1. Organization（组织/集团）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"550e8400-e29b-41d4-a716-446655440000"` |
| `code` | VARCHAR(32) | Y | 组织编码，全局唯一 | `"GRP-WANDA"` |
| `name` | VARCHAR(200) | Y | 组织名称 | `"万达集团"` |
| `name_en` | VARCHAR(200) | N | 英文名称 | `"Wanda Group"` |
| `type` | ENUM(OrgType) | Y | 组织类型 | `"ENTERPRISE"` |
| `parent_id` | UUID | N | 上级组织（支持多级集团） | `null` |
| `legal_entity` | VARCHAR(200) | N | 法人实体名称 | `"万达商业管理集团有限公司"` |
| `tax_id` | VARCHAR(50) | N | 统一社会信用代码/税号 | `"91110000..."` |
| `country` | VARCHAR(3) | Y | ISO 3166-1 alpha-3 | `"CHN"` |
| `timezone` | VARCHAR(40) | Y | IANA 时区 | `"Asia/Shanghai"` |
| `locale` | VARCHAR(10) | Y | 语言区域 | `"zh-CN"` |
| `logo_url` | VARCHAR(500) | N | Logo 地址 | `"https://cdn.example.com/logo.png"` |
| `contact_email` | VARCHAR(200) | N | 联系邮箱 | `"admin@wanda.cn"` |
| `contact_phone` | VARCHAR(30) | N | 联系电话 | `"+86-10-85588888"` |
| `metadata` | JSON | N | 扩展字段 | `{"industry": "commercial_real_estate"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |
| `created_by` | UUID | Y | 创建人 | `"user-uuid-001"` |
| `updated_by` | UUID | Y | 更新人 | `"user-uuid-002"` |

---

### 2. Site（园区/场地）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-site-001"` |
| `org_id` | UUID (FK) | Y | 所属组织 | `"uuid-org-001"` |
| `code` | VARCHAR(32) | Y | 场地编码 | `"SITE-BJ-CBD"` |
| `name` | VARCHAR(200) | Y | 场地名称 | `"北京CBD园区"` |
| `name_en` | VARCHAR(200) | N | 英文名称 | `"Beijing CBD Campus"` |
| `address` | VARCHAR(500) | Y | 详细地址 | `"北京市朝阳区建国路93号"` |
| `city` | VARCHAR(100) | Y | 城市 | `"北京"` |
| `province` | VARCHAR(100) | N | 省/州 | `"北京市"` |
| `country` | VARCHAR(3) | Y | 国家 ISO 3166-1 | `"CHN"` |
| `postal_code` | VARCHAR(20) | N | 邮编 | `"100022"` |
| `latitude` | DECIMAL(10,7) | N | 纬度 | `39.9087257` |
| `longitude` | DECIMAL(10,7) | N | 经度 | `116.4608840` |
| `altitude` | DECIMAL(8,2) | N | 海拔 (m) | `43.50` |
| `timezone` | VARCHAR(40) | Y | IANA 时区 | `"Asia/Shanghai"` |
| `climate_zone` | ENUM(ClimateZone) | N | 气候区 | `"COLD"` |
| `total_area` | DECIMAL(12,2) | N | 总占地面积 (m²) | `120000.00` |
| `metadata` | JSON | N | 扩展字段 | `{"campus_type": "mixed_use"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |
| `created_by` | UUID | Y | 创建人 | `"user-uuid-001"` |
| `updated_by` | UUID | Y | 更新人 | `"user-uuid-002"` |

---

### 3. Building（楼宇）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-bldg-001"` |
| `site_id` | UUID (FK) | Y | 所属园区 | `"uuid-site-001"` |
| `profile_id` | UUID (FK) | N | 引用楼宇模板 | `"uuid-profile-hotel-5star"` |
| `code` | VARCHAR(32) | Y | 楼宇编码 | `"BLDG-A01"` |
| `name` | VARCHAR(200) | Y | 楼宇名称 | `"万达广场A座"` |
| `name_en` | VARCHAR(200) | N | 英文名称 | `"Wanda Plaza Tower A"` |
| `building_type` | ENUM(BuildingType) | Y | 楼宇类型 | `"OFFICE"` |
| `year_built` | SMALLINT | N | 建造年份 | `2018` |
| `year_renovated` | SMALLINT | N | 最近翻修年份 | `2023` |
| `gross_floor_area` | DECIMAL(12,2) | Y | 总建筑面积 (m²) | `85000.00` |
| `usable_area` | DECIMAL(12,2) | N | 可用面积 (m²) | `68000.00` |
| `floors_above` | SMALLINT | Y | 地上层数 | `38` |
| `floors_below` | SMALLINT | N | 地下层数 | `3` |
| `height` | DECIMAL(8,2) | N | 建筑高度 (m) | `168.50` |
| `climate_zone` | ENUM(ClimateZone) | Y | 气候区（ASHRAE/中国标准） | `"COLD"` |
| `regulation_set` | VARCHAR(100)[] | N | 适用法规集 | `["GB50189-2015", "GB55015-2021"]` |
| `certifications` | JSON | N | 绿色认证 | `[{"type":"LEED","level":"Gold","year":2020}]` |
| `design_occupancy` | INT | N | 设计容纳人数 | `5000` |
| `bim_model_url` | VARCHAR(500) | N | BIM 模型链接 | `"https://bim.example.com/model/A01"` |
| `address` | VARCHAR(500) | N | 详细地址（可继承 Site） | `null` |
| `latitude` | DECIMAL(10,7) | N | 纬度 | `39.9087257` |
| `longitude` | DECIMAL(10,7) | N | 经度 | `116.4608840` |
| `metadata` | JSON | N | 扩展字段 | `{"fire_rating": "一级"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |
| `created_by` | UUID | Y | 创建人 | `"user-uuid-001"` |
| `updated_by` | UUID | Y | 更新人 | `"user-uuid-002"` |

---

### 4. Floor（楼层）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-floor-001"` |
| `building_id` | UUID (FK) | Y | 所属楼宇 | `"uuid-bldg-001"` |
| `code` | VARCHAR(32) | Y | 楼层编码 | `"F12"` |
| `name` | VARCHAR(100) | Y | 楼层名称 | `"12层"` |
| `sort_order` | INT | Y | 排序序号（B3=-3, B2=-2, B1=-1, 1=1F...） | `12` |
| `elevation` | DECIMAL(8,2) | N | 标高 (m) | `48.60` |
| `floor_height` | DECIMAL(6,2) | N | 层高 (m) | `3.90` |
| `gross_area` | DECIMAL(10,2) | N | 建筑面积 (m²) | `2200.00` |
| `usable_area` | DECIMAL(10,2) | N | 可用面积 (m²) | `1800.00` |
| `is_underground` | BOOLEAN | Y | 是否地下层 | `false` |
| `floor_type` | ENUM(FloorType) | N | 楼层类型 | `"STANDARD"` |
| `metadata` | JSON | N | 扩展字段 | `{"cad_drawing_url": "..."}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

---

### 5. Zone / Space（区域/房间）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-zone-001"` |
| `floor_id` | UUID (FK) | Y | 所属楼层 | `"uuid-floor-001"` |
| `building_id` | UUID (FK) | Y | 所属楼宇（冗余，便于查询） | `"uuid-bldg-001"` |
| `parent_zone_id` | UUID (FK) | N | 父区域（支持嵌套） | `null` |
| `code` | VARCHAR(32) | Y | 区域编码 | `"Z-12-001"` |
| `name` | VARCHAR(200) | Y | 区域名称 | `"12层会议室A"` |
| `name_en` | VARCHAR(200) | N | 英文名称 | `"12F Meeting Room A"` |
| `space_type` | ENUM(SpaceType) | Y | 空间用途 | `"MEETING_ROOM"` |
| `area` | DECIMAL(10,2) | N | 面积 (m²) | `45.00` |
| `volume` | DECIMAL(10,2) | N | 体积 (m³) | `175.50` |
| `capacity` | INT | N | 设计容纳人数 | `20` |
| `is_public` | BOOLEAN | N | 是否公共区域 | `false` |
| `hvac_zone_id` | VARCHAR(50) | N | HVAC 温控区编号 | `"VAV-12-03"` |
| `lighting_zone_id` | VARCHAR(50) | N | 照明分区编号 | `"LZ-12-A"` |
| `fire_zone_id` | VARCHAR(50) | N | 消防分区编号 | `"FZ-12"` |
| `tags` | VARCHAR(50)[] | N | Haystack 语义标签 | `["conditioned", "occupied"]` |
| `metadata` | JSON | N | 扩展字段 | `{"av_equipped": true}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

---

### 6. System（子系统）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-sys-001"` |
| `building_id` | UUID (FK) | Y | 所属楼宇 | `"uuid-bldg-001"` |
| `code` | VARCHAR(32) | Y | 系统编码 | `"SYS-HVAC-01"` |
| `name` | VARCHAR(200) | Y | 系统名称 | `"中央空调系统-1号冷站"` |
| `system_type` | ENUM(SystemType) | Y | 系统类型 | `"HVAC"` |
| `sub_type` | VARCHAR(50) | N | 子类型 | `"CHILLER_PLANT"` |
| `description` | TEXT | N | 描述 | `"服务A座1-20层的冷站系统"` |
| `serves_zones` | UUID[] | N | 服务区域列表 | `["uuid-zone-001", "uuid-zone-002"]` |
| `serves_floors` | UUID[] | N | 服务楼层列表 | `["uuid-floor-001"]` |
| `design_capacity` | JSON | N | 设计能力 | `{"cooling_kw": 3500, "heating_kw": 2800}` |
| `commissioning_date` | DATE | N | 调试完成日期 | `"2018-06-15"` |
| `tags` | VARCHAR(50)[] | N | Haystack 语义标签 | `["chilled-water", "central-plant"]` |
| `metadata` | JSON | N | 扩展字段 | `{"control_panel": "DDC-01"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

---

### 7. Equipment（设备）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-equip-001"` |
| `system_id` | UUID (FK) | Y | 所属子系统 | `"uuid-sys-001"` |
| `zone_id` | UUID (FK) | N | 安装区域 | `"uuid-zone-001"` |
| `parent_equipment_id` | UUID (FK) | N | 父设备（支持设备组合） | `null` |
| `code` | VARCHAR(50) | Y | 设备编码 | `"CH-01"` |
| `name` | VARCHAR(200) | Y | 设备名称 | `"1号离心冷水机组"` |
| `equipment_type` | ENUM(EquipmentType) | Y | 设备类型 | `"CHILLER"` |
| `sub_type` | VARCHAR(50) | N | 子类型 | `"CENTRIFUGAL"` |
| `manufacturer` | VARCHAR(200) | N | 制造商 | `"开利 Carrier"` |
| `model` | VARCHAR(100) | N | 型号 | `"19XR-600"` |
| `serial_number` | VARCHAR(100) | N | 序列号 | `"SN2018060012345"` |
| `rated_power` | DECIMAL(10,2) | N | 额定功率 (kW) | `350.00` |
| `rated_capacity` | JSON | N | 额定能力 | `{"cooling_kw": 2100, "cop": 6.1}` |
| `install_date` | DATE | N | 安装日期 | `"2018-05-20"` |
| `warranty_expiry` | DATE | N | 质保截止 | `"2023-05-20"` |
| `expected_life_years` | SMALLINT | N | 预期使用年限 | `20` |
| `maintenance_status` | ENUM(MaintenanceStatus) | Y | 维保状态 | `"NORMAL"` |
| `last_maintenance_date` | DATE | N | 上次维保日期 | `"2025-11-10"` |
| `next_maintenance_date` | DATE | N | 下次维保日期 | `"2026-05-10"` |
| `maintenance_cycle_days` | INT | N | 维保周期 (天) | `180` |
| `criticality` | ENUM(Criticality) | N | 关键程度 | `"HIGH"` |
| `barcode` | VARCHAR(100) | N | 条码/资产标签 | `"ASSET-2018-00456"` |
| `qr_code_url` | VARCHAR(500) | N | 二维码链接 | `"https://asset.example.com/qr/00456"` |
| `bim_guid` | VARCHAR(50) | N | BIM 模型中的 GUID | `"3F2504E0-4F89-11D3-9A0C-..."` |
| `tags` | VARCHAR(50)[] | N | Haystack 语义标签 | `["chiller", "centrifugal", "chilled-water"]` |
| `metadata` | JSON | N | 扩展字段 | `{"refrigerant": "R134a"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

---

### 8. Component（部件）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-comp-001"` |
| `equipment_id` | UUID (FK) | Y | 所属设备 | `"uuid-equip-001"` |
| `code` | VARCHAR(50) | Y | 部件编码 | `"CH-01-COMP"` |
| `name` | VARCHAR(200) | Y | 部件名称 | `"1号冷机压缩机"` |
| `component_type` | ENUM(ComponentType) | Y | 部件类型 | `"COMPRESSOR"` |
| `manufacturer` | VARCHAR(200) | N | 制造商 | `"Carrier"` |
| `model` | VARCHAR(100) | N | 型号 | `"06T-2100"` |
| `serial_number` | VARCHAR(100) | N | 序列号 | `"COMP-SN-12345"` |
| `install_date` | DATE | N | 安装日期 | `"2018-05-20"` |
| `replacement_date` | DATE | N | 上次更换日期 | `null` |
| `expected_life_years` | SMALLINT | N | 预期寿命 (年) | `15` |
| `tags` | VARCHAR(50)[] | N | 语义标签 | `["compressor", "centrifugal"]` |
| `metadata` | JSON | N | 扩展字段 | `{"oil_type": "POE"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

---

### 9. Point（点位） — 最核心实体

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-point-001"` |
| `equipment_id` | UUID (FK) | N | 所属设备 | `"uuid-equip-001"` |
| `component_id` | UUID (FK) | N | 所属部件 | `"uuid-comp-001"` |
| `zone_id` | UUID (FK) | N | 所属区域（虚拟点位可直接挂区域） | `"uuid-zone-001"` |
| `building_id` | UUID (FK) | Y | 所属楼宇（冗余，便于查询） | `"uuid-bldg-001"` |
| `code` | VARCHAR(100) | Y | 点位编码，楼宇内唯一 | `"CH-01.ChwST"` |
| `name` | VARCHAR(200) | Y | 点位名称 | `"1号冷机冷冻水供水温度"` |
| `name_en` | VARCHAR(200) | N | 英文名称 | `"Chiller-01 CHW Supply Temp"` |
| `point_class` | ENUM(PointClass) | Y | 点位分类 (Haystack) | `"SENSOR"` |
| `data_type` | ENUM(PointDataType) | Y | 数据类型 | `"FLOAT"` |
| `unit` | VARCHAR(20) | N | 工程单位 (Haystack 标准) | `"°C"` |
| `unit_system` | ENUM(UnitSystem) | N | 单位制 | `"SI"` |
| `precision` | SMALLINT | N | 小数精度 | `1` |
| `access` | ENUM(PointAccess) | Y | 读写权限 | `"READ_ONLY"` |
| `source_protocol` | ENUM(SourceProtocol) | Y | 来源协议 | `"BACNET"` |
| `source_address` | JSON | Y | 协议地址 | `{"device_id": 10001, "object_type": "AI", "instance": 1}` |
| `polling_interval_s` | INT | N | 采集周期 (秒) | `60` |
| `cov_enabled` | BOOLEAN | N | 是否启用 COV (变化上报) | `true` |
| `cov_increment` | DECIMAL(10,4) | N | COV 变化阈值 | `0.5000` |
| `min_value` | DECIMAL(15,4) | N | 工程量程下限 | `0.0000` |
| `max_value` | DECIMAL(15,4) | N | 工程量程上限 | `50.0000` |
| `default_value` | VARCHAR(50) | N | 默认值 | `"7.0"` |
| `alarm_enabled` | BOOLEAN | Y | 是否启用告警 | `true` |
| `alarm_hi_hi` | DECIMAL(15,4) | N | 高高报阈值 | `15.0000` |
| `alarm_hi` | DECIMAL(15,4) | N | 高报阈值 | `12.0000` |
| `alarm_lo` | DECIMAL(15,4) | N | 低报阈值 | `3.0000` |
| `alarm_lo_lo` | DECIMAL(15,4) | N | 低低报阈值 | `1.0000` |
| `alarm_deadband` | DECIMAL(10,4) | N | 告警死区 | `0.5000` |
| `alarm_delay_s` | INT | N | 告警延迟 (秒，防抖) | `60` |
| `trend_enabled` | BOOLEAN | Y | 是否记录趋势 | `true` |
| `trend_interval_s` | INT | N | 趋势记录间隔 (秒) | `300` |
| `trend_method` | ENUM(TrendMethod) | N | 趋势记录方式 | `"COV"` |
| `trend_retention_days` | INT | N | 趋势数据保留天数 | `365` |
| `haystack_tags` | VARCHAR(50)[] | N | Haystack 标签集 | `["sensor", "temp", "chilled", "water", "supply"]` |
| `brick_class` | VARCHAR(100) | N | Brick 类全名 | `"Chilled_Water_Supply_Temperature_Sensor"` |
| `display_group` | VARCHAR(100) | N | 界面显示分组 | `"冷站监控"` |
| `display_order` | INT | N | 显示排序 | `10` |
| `is_virtual` | BOOLEAN | N | 是否虚拟/计算点 | `false` |
| `calc_expression` | TEXT | N | 计算表达式（虚拟点） | `null` |
| `metadata` | JSON | N | 扩展字段 | `{"commissioning_value": 7.0}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `current_value` | VARCHAR(50) | N | 当前值（缓存） | `"7.2"` |
| `current_quality` | ENUM(PointQuality) | N | 当前数据质量 | `"GOOD"` |
| `current_timestamp` | TIMESTAMP | N | 当前值更新时间 | `"2026-03-11T10:30:00Z"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

---

### 10. Alarm（告警实例）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-alarm-001"` |
| `building_id` | UUID (FK) | Y | 所属楼宇 | `"uuid-bldg-001"` |
| `alarm_rule_id` | UUID (FK) | N | 关联告警规则模板 | `"uuid-rule-001"` |
| `point_id` | UUID (FK) | N | 触发点位 | `"uuid-point-001"` |
| `equipment_id` | UUID (FK) | N | 关联设备 | `"uuid-equip-001"` |
| `zone_id` | UUID (FK) | N | 关联区域 | `"uuid-zone-001"` |
| `alarm_code` | VARCHAR(50) | Y | 告警编码 | `"ALM-CH01-HI-TEMP"` |
| `severity` | ENUM(AlarmSeverity) | Y | 严重度 | `"CRITICAL"` |
| `category` | ENUM(AlarmCategory) | Y | 告警类别 | `"PROCESS"` |
| `state` | ENUM(AlarmState) | Y | 告警状态机状态 | `"ACTIVE_UNACKED"` |
| `title` | VARCHAR(300) | Y | 告警标题 | `"1号冷机冷冻水供水温度过高"` |
| `description` | TEXT | N | 告警详情 | `"当前值 14.5°C，超过高报阈值 12.0°C"` |
| `trigger_value` | VARCHAR(50) | N | 触发值 | `"14.5"` |
| `threshold_value` | VARCHAR(50) | N | 阈值 | `"12.0"` |
| `triggered_at` | TIMESTAMP | Y | 触发时间 | `"2026-03-11T10:31:00Z"` |
| `acked_at` | TIMESTAMP | N | 确认时间 | `null` |
| `acked_by` | UUID | N | 确认人 | `null` |
| `ack_note` | TEXT | N | 确认备注 | `null` |
| `cleared_at` | TIMESTAMP | N | 恢复时间 | `null` |
| `closed_at` | TIMESTAMP | N | 关闭时间 | `null` |
| `closed_by` | UUID | N | 关闭人 | `null` |
| `close_note` | TEXT | N | 关闭备注 | `null` |
| `duration_s` | INT | N | 持续时长 (秒，恢复时计算) | `null` |
| `escalation_level` | SMALLINT | Y | 当前升级层级 | `0` |
| `escalation_history` | JSON | N | 升级记录 | `[]` |
| `is_suppressed` | BOOLEAN | Y | 是否被抑制 | `false` |
| `suppressed_by` | VARCHAR(100) | N | 抑制原因/规则 | `null` |
| `work_order_id` | UUID (FK) | N | 关联工单 | `null` |
| `repeat_count` | INT | N | 重复触发次数 | `1` |
| `tags` | VARCHAR(50)[] | N | 标签 | `["chiller", "temperature"]` |
| `metadata` | JSON | N | 扩展字段 | `{"source": "BACnet-event"}` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2026-03-11T10:31:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2026-03-11T10:31:00Z"` |

#### 告警状态机

```
         触发
  NORMAL ────> ACTIVE_UNACKED
                 │         │
           确认 ack    恢复 clear
                 │         │
                 v         v
          ACTIVE_ACKED   CLEARED_UNACKED
                 │         │
           恢复 clear  确认 ack
                 │         │
                 v         v
              CLEARED_ACKED ────> CLOSED (归档)
```

---

### 11. AlarmRule（告警规则模板）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-rule-001"` |
| `code` | VARCHAR(50) | Y | 规则编码 | `"RULE-CHWST-HI"` |
| `name` | VARCHAR(200) | Y | 规则名称 | `"冷冻水供水温度过高"` |
| `description` | TEXT | N | 规则描述 | `"当冷冻水供水温度超过设定阈值时触发"` |
| `severity` | ENUM(AlarmSeverity) | Y | 默认严重度 | `"MAJOR"` |
| `category` | ENUM(AlarmCategory) | Y | 告警类别 | `"PROCESS"` |
| `target_point_class` | VARCHAR(100) | N | 目标点位 Brick 类 | `"Chilled_Water_Supply_Temperature_Sensor"` |
| `target_equipment_type` | ENUM(EquipmentType) | N | 目标设备类型 | `"CHILLER"` |
| `condition_type` | ENUM(ConditionType) | Y | 条件类型 | `"HI_LIMIT"` |
| `condition_expr` | TEXT | Y | 条件表达式 | `"value > threshold"` |
| `threshold_default` | DECIMAL(15,4) | N | 默认阈值 | `12.0000` |
| `deadband_default` | DECIMAL(10,4) | N | 默认死区 | `0.5000` |
| `delay_s_default` | INT | N | 默认延迟 (秒) | `60` |
| `escalation_rules` | JSON | N | 升级规则 | `[{"after_min": 15, "to_role": "CHIEF_ENGINEER"}, {"after_min": 60, "to_role": "FACILITY_MANAGER"}]` |
| `suppression_rules` | JSON | N | 抑制规则 | `[{"when": "equipment.status == 'OFFLINE'", "reason": "设备离线"}]` |
| `auto_create_work_order` | BOOLEAN | N | 是否自动创建工单 | `false` |
| `notification_template_id` | UUID (FK) | N | 通知模板 | `"uuid-notif-tpl-001"` |
| `applicable_building_types` | ENUM(BuildingType)[] | N | 适用楼宇类型 | `["OFFICE", "HOTEL", "HOSPITAL"]` |
| `tags` | VARCHAR(50)[] | N | 标签 | `["chiller", "temperature"]` |
| `metadata` | JSON | N | 扩展字段 | `{}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

---

### 12. Schedule（排程）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-sched-001"` |
| `building_id` | UUID (FK) | Y | 所属楼宇 | `"uuid-bldg-001"` |
| `code` | VARCHAR(50) | Y | 排程编码 | `"SCH-HVAC-WEEKDAY"` |
| `name` | VARCHAR(200) | Y | 排程名称 | `"工作日空调排程"` |
| `schedule_type` | ENUM(ScheduleType) | Y | 排程类型 | `"WEEKLY"` |
| `target_type` | VARCHAR(50) | Y | 目标实体类型 | `"EQUIPMENT"` |
| `target_ids` | UUID[] | Y | 目标实体列表 | `["uuid-equip-001", "uuid-equip-002"]` |
| `target_point_id` | UUID (FK) | N | 控制点位（写入值用） | `"uuid-point-cmd-001"` |
| `timezone` | VARCHAR(40) | Y | 时区 | `"Asia/Shanghai"` |
| `calendar_system` | ENUM(CalendarSystem) | Y | 日历体系 | `"GREGORIAN"` |
| `weekly_schedule` | JSON | N | 周排程 | 见下方示例 |
| `yearly_calendar` | JSON | N | 年度日历/特殊日 | 见下方示例 |
| `exceptions` | JSON | N | 例外排程 | 见下方示例 |
| `effective_from` | DATE | N | 生效起始日 | `"2025-01-01"` |
| `effective_to` | DATE | N | 生效截止日 | `null` |
| `priority` | INT | Y | 优先级（数字越大优先级越高） | `10` |
| `metadata` | JSON | N | 扩展字段 | `{}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

#### weekly_schedule 示例

```json
{
  "monday":    [{"start": "07:00", "end": "18:00", "value": "ON"}, {"start": "18:00", "end": "07:00", "value": "OFF"}],
  "tuesday":   [{"start": "07:00", "end": "18:00", "value": "ON"}],
  "wednesday": [{"start": "07:00", "end": "18:00", "value": "ON"}],
  "thursday":  [{"start": "07:00", "end": "18:00", "value": "ON"}],
  "friday":    [{"start": "07:00", "end": "18:00", "value": "ON"}],
  "saturday":  [{"start": "09:00", "end": "13:00", "value": "ON"}],
  "sunday":    []
}
```

#### yearly_calendar 示例

```json
{
  "holidays": [
    {"date": "2026-01-01", "name": "元旦", "schedule": []},
    {"date_range": ["2026-01-28", "2026-02-04"], "name": "春节", "schedule": []},
    {"date": "2026-04-04", "name": "清明节", "schedule": []}
  ],
  "special_days": [
    {"date": "2026-01-25", "name": "春节调休上班", "type": "WORKDAY", "schedule": [{"start": "07:00", "end": "18:00", "value": "ON"}]}
  ]
}
```

#### exceptions 示例

```json
[
  {
    "name": "VIP接待日",
    "date": "2026-03-15",
    "priority": 100,
    "schedule": [{"start": "06:00", "end": "22:00", "value": "ON"}]
  }
]
```

---

### 13. Trend（趋势数据存储模型）

> 时序数据，通常存储于时序数据库（TimescaleDB / InfluxDB / TDengine），此处定义逻辑模型。

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `point_id` | UUID (FK) | Y | 点位 ID（分区键） | `"uuid-point-001"` |
| `ts` | TIMESTAMP | Y | 时间戳（主键之一） | `"2026-03-11T10:30:00Z"` |
| `value_float` | DOUBLE | N | 浮点值 | `7.2` |
| `value_int` | BIGINT | N | 整数值 | `null` |
| `value_bool` | BOOLEAN | N | 布尔值 | `null` |
| `value_string` | VARCHAR(200) | N | 字符串值 | `null` |
| `value_json` | JSON | N | JSON 值（复合数据） | `null` |
| `quality` | ENUM(PointQuality) | Y | 数据质量标记 | `"GOOD"` |
| `source` | ENUM(TrendSource) | N | 数据来源 | `"FIELD"` |
| `annotation` | VARCHAR(500) | N | 人工标注 | `null` |

#### 存储策略

| 策略 | 说明 |
|------|------|
| **分区键** | `point_id` + 时间分区（按月/按周） |
| **压缩** | 超过 7 天的数据启用列式压缩 |
| **降采样** | 原始 → 5min 平均/最大/最小 → 1h 聚合 → 1d 聚合 |
| **保留策略** | 原始数据 90 天，5min 聚合 1 年，1h 聚合 3 年，1d 聚合 10 年 |
| **索引** | `point_id + ts` 主索引，`building_id + ts` 二级索引 |

#### 聚合表结构

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `point_id` | UUID | 点位 |
| `bucket_start` | TIMESTAMP | 聚合起始时间 |
| `bucket_size` | VARCHAR(10) | 聚合粒度：`"5m"` / `"1h"` / `"1d"` |
| `avg` | DOUBLE | 平均值 |
| `min` | DOUBLE | 最小值 |
| `max` | DOUBLE | 最大值 |
| `sum` | DOUBLE | 累计值 |
| `count` | INT | 样本数 |
| `first_value` | DOUBLE | 首值 |
| `last_value` | DOUBLE | 末值 |
| `quality_good_pct` | DECIMAL(5,2) | 质量合格百分比 |

---

### 14. WorkOrder（工单）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-wo-001"` |
| `building_id` | UUID (FK) | Y | 所属楼宇 | `"uuid-bldg-001"` |
| `code` | VARCHAR(50) | Y | 工单编号 | `"WO-2026-00123"` |
| `title` | VARCHAR(300) | Y | 工单标题 | `"1号冷机冷冻水温度过高 - 检查冷凝器"` |
| `description` | TEXT | N | 工单描述 | `"连续告警2小时，需检查冷凝器清洗状态"` |
| `wo_type` | ENUM(WorkOrderType) | Y | 工单类型 | `"CORRECTIVE"` |
| `priority` | ENUM(WorkOrderPriority) | Y | 优先级 | `"HIGH"` |
| `state` | ENUM(WorkOrderState) | Y | 工单状态 | `"OPEN"` |
| `source` | ENUM(WorkOrderSource) | Y | 来源 | `"ALARM"` |
| `alarm_id` | UUID (FK) | N | 关联告警 | `"uuid-alarm-001"` |
| `target_type` | VARCHAR(50) | N | 目标实体类型 | `"EQUIPMENT"` |
| `target_id` | UUID | N | 目标实体 ID | `"uuid-equip-001"` |
| `zone_id` | UUID (FK) | N | 关联区域 | `"uuid-zone-001"` |
| `requested_by` | UUID (FK) | Y | 报修人/发起人 | `"uuid-user-001"` |
| `assigned_to` | UUID (FK) | N | 当前执行人 | `"uuid-user-002"` |
| `assigned_team` | VARCHAR(100) | N | 指派团队 | `"机电维保组"` |
| `sla_response_min` | INT | N | SLA 响应时限 (分钟) | `30` |
| `sla_resolve_min` | INT | N | SLA 解决时限 (分钟) | `240` |
| `sla_response_deadline` | TIMESTAMP | N | SLA 响应截止时间 | `"2026-03-11T11:01:00Z"` |
| `sla_resolve_deadline` | TIMESTAMP | N | SLA 解决截止时间 | `"2026-03-11T14:31:00Z"` |
| `sla_response_met` | BOOLEAN | N | 是否满足响应SLA | `null` |
| `sla_resolve_met` | BOOLEAN | N | 是否满足解决SLA | `null` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2026-03-11T10:31:00Z"` |
| `responded_at` | TIMESTAMP | N | 响应时间 | `null` |
| `started_at` | TIMESTAMP | N | 开始处理时间 | `null` |
| `completed_at` | TIMESTAMP | N | 完成时间 | `null` |
| `verified_at` | TIMESTAMP | N | 验收时间 | `null` |
| `closed_at` | TIMESTAMP | N | 关闭时间 | `null` |
| `cancelled_at` | TIMESTAMP | N | 取消时间 | `null` |
| `resolution` | TEXT | N | 解决方案描述 | `null` |
| `root_cause` | TEXT | N | 根因分析 | `null` |
| `labor_hours` | DECIMAL(8,2) | N | 工时 (小时) | `null` |
| `cost` | DECIMAL(12,2) | N | 费用 | `null` |
| `cost_currency` | VARCHAR(3) | N | 费用币种 | `"CNY"` |
| `consumed_assets` | JSON | N | 消耗备件列表 | `[]` |
| `attachments` | JSON | N | 附件列表 | `[]` |
| `comments` | JSON | N | 评论/沟通记录 | `[]` |
| `tags` | VARCHAR(50)[] | N | 标签 | `["chiller", "urgent"]` |
| `metadata` | JSON | N | 扩展字段 | `{}` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2026-03-11T10:31:00Z"` |

#### 工单状态机

```
OPEN → ASSIGNED → IN_PROGRESS → PENDING_PARTS → IN_PROGRESS → COMPLETED → VERIFIED → CLOSED
                                                                              ↓
                                                                          REOPENED → IN_PROGRESS
OPEN / ASSIGNED / IN_PROGRESS → CANCELLED
```

---

### 15. Asset（资产/备件）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-asset-001"` |
| `org_id` | UUID (FK) | Y | 所属组织 | `"uuid-org-001"` |
| `code` | VARCHAR(50) | Y | 资产编号 | `"SPR-FILTER-001"` |
| `name` | VARCHAR(200) | Y | 资产名称 | `"初效过滤器 G4-592x592x48"` |
| `asset_type` | ENUM(AssetType) | Y | 资产类型 | `"SPARE_PART"` |
| `category` | VARCHAR(100) | N | 分类 | `"滤网/过滤器"` |
| `manufacturer` | VARCHAR(200) | N | 供应商/制造商 | `"AAF"` |
| `model` | VARCHAR(100) | N | 型号 | `"AmAir-G4-592"` |
| `specification` | TEXT | N | 规格描述 | `"592×592×48mm, G4级, 玻纤"` |
| `unit_of_measure` | VARCHAR(20) | Y | 计量单位 | `"片"` |
| `unit_price` | DECIMAL(12,2) | N | 单价 | `35.00` |
| `currency` | VARCHAR(3) | N | 币种 | `"CNY"` |
| `quantity_on_hand` | INT | N | 库存数量 | `200` |
| `reorder_level` | INT | N | 最低库存 | `50` |
| `reorder_quantity` | INT | N | 补货数量 | `200` |
| `warehouse_location` | VARCHAR(100) | N | 仓库位置 | `"B1仓库-A3-02"` |
| `supplier_id` | UUID (FK) | N | 供应商 | `"uuid-supplier-001"` |
| `supplier_name` | VARCHAR(200) | N | 供应商名称 | `"北京暖通配件有限公司"` |
| `contract_id` | VARCHAR(50) | N | 合同编号 | `"CT-2025-00089"` |
| `purchase_date` | DATE | N | 采购日期 | `"2025-06-01"` |
| `warranty_expiry` | DATE | N | 质保截止 | `"2026-06-01"` |
| `lifecycle_status` | ENUM(AssetLifecycle) | Y | 生命周期状态 | `"IN_SERVICE"` |
| `compatible_equipment_types` | ENUM(EquipmentType)[] | N | 适配设备类型 | `["AHU", "FCU"]` |
| `tags` | VARCHAR(50)[] | N | 标签 | `["filter", "consumable"]` |
| `metadata` | JSON | N | 扩展字段 | `{"grade": "G4"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

---

### 16. User / Role / Permission（用户权限模型）

#### 16.1 User（用户）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-user-001"` |
| `org_id` | UUID (FK) | Y | 所属组织 | `"uuid-org-001"` |
| `username` | VARCHAR(50) | Y | 用户名（唯一） | `"zhangsan"` |
| `display_name` | VARCHAR(100) | Y | 显示名称 | `"张三"` |
| `email` | VARCHAR(200) | Y | 邮箱 | `"zhangsan@example.com"` |
| `phone` | VARCHAR(30) | N | 手机号 | `"+86-13800138000"` |
| `avatar_url` | VARCHAR(500) | N | 头像 | `null` |
| `auth_provider` | ENUM(AuthProvider) | Y | 认证方式 | `"LOCAL"` |
| `external_id` | VARCHAR(200) | N | 外部身份 ID（SSO/LDAP） | `null` |
| `password_hash` | VARCHAR(200) | N | 密码哈希（本地认证） | `"$argon2id$v=19$m=65536..."` |
| `mfa_enabled` | BOOLEAN | Y | 是否启用MFA | `true` |
| `mfa_secret` | VARCHAR(200) | N | MFA 密钥（加密存储） | `null` |
| `last_login_at` | TIMESTAMP | N | 最后登录时间 | `"2026-03-11T08:00:00Z"` |
| `failed_login_count` | INT | Y | 连续失败登录次数 | `0` |
| `locked_until` | TIMESTAMP | N | 锁定截止时间 | `null` |
| `preferred_language` | VARCHAR(10) | N | 偏好语言 | `"zh-CN"` |
| `notification_preferences` | JSON | N | 通知偏好 | `{"email": true, "sms": true, "push": true}` |
| `accessible_building_ids` | UUID[] | N | 可访问楼宇列表（空=按角色继承） | `["uuid-bldg-001"]` |
| `metadata` | JSON | N | 扩展字段 | `{"department": "机电部"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

#### 16.2 Role（角色）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-role-001"` |
| `org_id` | UUID (FK) | Y | 所属组织 | `"uuid-org-001"` |
| `code` | VARCHAR(50) | Y | 角色编码 | `"CHIEF_ENGINEER"` |
| `name` | VARCHAR(100) | Y | 角色名称 | `"总工程师"` |
| `description` | TEXT | N | 角色描述 | `"负责所有楼宇系统的运维管理"` |
| `scope` | ENUM(RoleScope) | Y | 作用范围 | `"BUILDING"` |
| `is_system_role` | BOOLEAN | Y | 是否系统内置角色 | `true` |
| `parent_role_id` | UUID (FK) | N | 继承自 | `null` |
| `permissions` | UUID[] | Y | 权限列表 | `["uuid-perm-001", "uuid-perm-002"]` |
| `metadata` | JSON | N | 扩展字段 | `{}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

#### 16.3 Permission（权限）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-perm-001"` |
| `code` | VARCHAR(100) | Y | 权限编码 | `"point:write"` |
| `name` | VARCHAR(200) | Y | 权限名称 | `"写入点位值"` |
| `resource` | VARCHAR(50) | Y | 资源类型 | `"POINT"` |
| `action` | ENUM(PermAction) | Y | 操作 | `"WRITE"` |
| `description` | TEXT | N | 描述 | `"允许向点位下发控制指令"` |
| `is_system` | BOOLEAN | Y | 是否系统内置 | `true` |

#### 16.4 UserRoleBinding（用户-角色绑定）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-urb-001"` |
| `user_id` | UUID (FK) | Y | 用户 | `"uuid-user-001"` |
| `role_id` | UUID (FK) | Y | 角色 | `"uuid-role-001"` |
| `scope_type` | ENUM(RoleScope) | Y | 绑定范围类型 | `"BUILDING"` |
| `scope_id` | UUID | N | 绑定范围实体 ID | `"uuid-bldg-001"` |
| `granted_by` | UUID (FK) | Y | 授权人 | `"uuid-user-admin"` |
| `expires_at` | TIMESTAMP | N | 过期时间 | `null` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |

---

### 17. AuditLog（操作审计日志）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-audit-001"` |
| `timestamp` | TIMESTAMP | Y | 操作时间 | `"2026-03-11T10:35:00Z"` |
| `user_id` | UUID (FK) | N | 操作人（系统操作可为 null） | `"uuid-user-001"` |
| `user_name` | VARCHAR(100) | N | 操作人名（冗余快查） | `"张三"` |
| `client_ip` | VARCHAR(45) | N | 客户端 IP | `"192.168.1.100"` |
| `user_agent` | VARCHAR(500) | N | 客户端UA | `"Mozilla/5.0..."` |
| `action` | ENUM(AuditAction) | Y | 操作类型 | `"UPDATE"` |
| `resource_type` | VARCHAR(50) | Y | 资源类型 | `"POINT"` |
| `resource_id` | UUID | Y | 资源 ID | `"uuid-point-001"` |
| `resource_name` | VARCHAR(200) | N | 资源名（冗余快查） | `"1号冷机冷冻水供水温度"` |
| `building_id` | UUID (FK) | N | 所属楼宇 | `"uuid-bldg-001"` |
| `org_id` | UUID (FK) | N | 所属组织 | `"uuid-org-001"` |
| `before_value` | JSON | N | 变更前值 | `{"alarm_hi": 12.0}` |
| `after_value` | JSON | N | 变更后值 | `{"alarm_hi": 14.0}` |
| `description` | TEXT | N | 操作描述 | `"修改高报阈值从12.0到14.0"` |
| `result` | ENUM(AuditResult) | Y | 操作结果 | `"SUCCESS"` |
| `error_message` | TEXT | N | 错误信息 | `null` |
| `session_id` | VARCHAR(100) | N | 会话 ID | `"sess-abc-123"` |
| `correlation_id` | VARCHAR(100) | N | 关联追踪 ID | `"trace-xyz-456"` |
| `metadata` | JSON | N | 扩展字段 | `{}` |

> **存储策略**：审计日志为追加写入，不可修改/删除。按 `org_id + timestamp` 分区，保留期限由 ComplianceRule 定义（默认3年）。

---

### 18. BuildingProfile（楼宇模板）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-profile-hotel-5star"` |
| `code` | VARCHAR(50) | Y | 模板编码 | `"TPL-HOTEL-5STAR"` |
| `name` | VARCHAR(200) | Y | 模板名称 | `"五星级酒店标准模板"` |
| `description` | TEXT | N | 模板描述 | `"适用于五星级酒店的标准系统配置模板"` |
| `building_type` | ENUM(BuildingType) | Y | 适用楼宇类型 | `"HOTEL"` |
| `version` | VARCHAR(20) | Y | 版本号 | `"2.1.0"` |
| `is_published` | BOOLEAN | Y | 是否已发布 | `true` |
| `default_systems` | JSON | Y | 默认子系统配置 | 见下方示例 |
| `default_equipment_templates` | JSON | N | 默认设备模板 | `[...]` |
| `default_point_templates` | JSON | N | 默认点位模板 | `[...]` |
| `default_alarm_rules` | UUID[] | N | 默认告警规则 | `["uuid-rule-001", "uuid-rule-002"]` |
| `default_schedules` | JSON | N | 默认排程模板 | `[...]` |
| `default_scenarios` | JSON | N | 默认场景模式 | `[...]` |
| `compliance_rules` | UUID[] | N | 默认合规规则 | `["uuid-comp-001"]` |
| `recommended_energy_meters` | JSON | N | 推荐能源计量配置 | `[...]` |
| `tags` | VARCHAR(50)[] | N | 标签 | `["hotel", "5-star", "luxury"]` |
| `metadata` | JSON | N | 扩展字段 | `{"author": "platform-team"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

#### default_systems 示例

```json
[
  {"system_type": "HVAC", "sub_type": "CHILLER_PLANT", "name_template": "冷站系统"},
  {"system_type": "HVAC", "sub_type": "AHU_SYSTEM", "name_template": "空调箱系统"},
  {"system_type": "HVAC", "sub_type": "FCU_SYSTEM", "name_template": "风机盘管系统"},
  {"system_type": "LIGHTING", "sub_type": "GENERAL", "name_template": "照明系统"},
  {"system_type": "ELECTRICAL", "sub_type": "HV_DISTRIBUTION", "name_template": "高压配电系统"},
  {"system_type": "ELECTRICAL", "sub_type": "LV_DISTRIBUTION", "name_template": "低压配电系统"},
  {"system_type": "ELECTRICAL", "sub_type": "EMERGENCY_POWER", "name_template": "应急电源系统"},
  {"system_type": "FIRE_PROTECTION", "sub_type": "DETECTION", "name_template": "火灾探测系统"},
  {"system_type": "FIRE_PROTECTION", "sub_type": "SUPPRESSION", "name_template": "灭火系统"},
  {"system_type": "SECURITY", "sub_type": "ACCESS_CONTROL", "name_template": "门禁系统"},
  {"system_type": "SECURITY", "sub_type": "CCTV", "name_template": "视频监控系统"},
  {"system_type": "PLUMBING", "sub_type": "DOMESTIC_WATER", "name_template": "生活给水系统"},
  {"system_type": "ELEVATOR", "sub_type": "PASSENGER", "name_template": "客梯系统"}
]
```

---

### 19. Scenario（场景模式）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-scenario-001"` |
| `building_id` | UUID (FK) | Y | 所属楼宇 | `"uuid-bldg-001"` |
| `code` | VARCHAR(50) | Y | 场景编码 | `"SCN-EMERGENCY-FIRE"` |
| `name` | VARCHAR(200) | Y | 场景名称 | `"火灾应急模式"` |
| `description` | TEXT | N | 场景描述 | `"发生火灾时的联动控制方案"` |
| `scenario_type` | ENUM(ScenarioType) | Y | 场景类型 | `"EMERGENCY"` |
| `priority` | INT | Y | 优先级（越高越优先） | `1000` |
| `is_exclusive` | BOOLEAN | Y | 是否排他（激活后其他场景自动退出） | `true` |
| `trigger_conditions` | JSON | Y | 触发条件 | 见下方示例 |
| `actions` | JSON | Y | 联动动作列表 | 见下方示例 |
| `rollback_actions` | JSON | N | 退出场景时的回退动作 | `[...]` |
| `activation_mode` | ENUM(ActivationMode) | Y | 激活方式 | `"AUTO"` |
| `current_state` | ENUM(ScenarioState) | Y | 当前状态 | `"INACTIVE"` |
| `activated_at` | TIMESTAMP | N | 激活时间 | `null` |
| `activated_by` | UUID | N | 激活人（手动时） | `null` |
| `deactivated_at` | TIMESTAMP | N | 退出时间 | `null` |
| `cooldown_s` | INT | N | 退出后冷却期 (秒) | `300` |
| `max_duration_s` | INT | N | 最大持续时长 (秒) | `null` |
| `applicable_schedules` | UUID[] | N | 关联排程（仅在排程时间内可触发） | `null` |
| `tags` | VARCHAR(50)[] | N | 标签 | `["fire", "emergency", "life-safety"]` |
| `metadata` | JSON | N | 扩展字段 | `{}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

#### trigger_conditions 示例

```json
{
  "logic": "OR",
  "conditions": [
    {"type": "ALARM", "alarm_category": "FIRE", "severity_gte": "CRITICAL"},
    {"type": "POINT_VALUE", "point_brick_class": "Fire_Alarm_Sensor", "operator": "==", "value": true},
    {"type": "MANUAL", "authorized_roles": ["FACILITY_MANAGER", "SECURITY_CHIEF"]}
  ]
}
```

#### actions 示例

```json
[
  {"order": 1, "type": "WRITE_POINT", "target": {"brick_class": "Smoke_Control_Damper_Command"}, "value": "OPEN", "delay_s": 0},
  {"order": 2, "type": "WRITE_POINT", "target": {"system_type": "HVAC"}, "value": "OFF", "delay_s": 5},
  {"order": 3, "type": "WRITE_POINT", "target": {"brick_class": "Emergency_Lighting_Command"}, "value": "ON", "delay_s": 0},
  {"order": 4, "type": "WRITE_POINT", "target": {"equipment_type": "ELEVATOR"}, "value": "RECALL_TO_GROUND", "delay_s": 10},
  {"order": 5, "type": "NOTIFICATION", "channels": ["SMS", "PUSH", "PA_SYSTEM"], "template": "FIRE_EVACUATION"},
  {"order": 6, "type": "CREATE_WORK_ORDER", "template": "WO-FIRE-RESPONSE", "priority": "EMERGENCY"}
]
```

---

### 20. ComplianceRule（合规规则）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-comp-001"` |
| `code` | VARCHAR(50) | Y | 规则编码 | `"CR-CN-FIRE-LOG"` |
| `name` | VARCHAR(200) | Y | 规则名称 | `"消防系统日志保留要求"` |
| `description` | TEXT | N | 规则描述 | `"根据GB 25506-2010，消防系统运行记录保留不少于1年"` |
| `regulation_ref` | VARCHAR(200) | N | 法规引用 | `"GB 25506-2010 第5.3条"` |
| `country` | VARCHAR(3) | Y | 适用国家 | `"CHN"` |
| `region` | VARCHAR(50) | N | 适用地区 | `null` |
| `industry` | VARCHAR(50) | N | 适用行业 | `null` |
| `building_types` | ENUM(BuildingType)[] | N | 适用楼宇类型 | `["HOTEL", "OFFICE", "HOSPITAL", "MALL"]` |
| `rule_type` | ENUM(ComplianceRuleType) | Y | 规则类型 | `"DATA_RETENTION"` |
| `rule_config` | JSON | Y | 规则配置 | 见下方示例 |
| `check_interval` | VARCHAR(20) | N | 检查频率 | `"DAILY"` |
| `enforcement_level` | ENUM(EnforcementLevel) | Y | 执行力度 | `"MANDATORY"` |
| `penalty_description` | TEXT | N | 违规后果 | `"可能面临消防部门处罚"` |
| `effective_from` | DATE | N | 生效日期 | `"2011-01-01"` |
| `effective_to` | DATE | N | 失效日期 | `null` |
| `tags` | VARCHAR(50)[] | N | 标签 | `["fire", "data-retention"]` |
| `metadata` | JSON | N | 扩展字段 | `{}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

#### rule_config 示例

```json
{
  "retention": {
    "target_data": ["ALARM", "AUDIT_LOG", "TREND"],
    "target_system_types": ["FIRE_PROTECTION"],
    "min_retention_days": 365,
    "archive_required": true,
    "archive_format": "CSV_ZIP"
  }
}
```

---

### 21. EnergyMeter（能源计量）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-meter-001"` |
| `building_id` | UUID (FK) | Y | 所属楼宇 | `"uuid-bldg-001"` |
| `parent_meter_id` | UUID (FK) | N | 上级表计（支持分项计量树） | `null` |
| `code` | VARCHAR(50) | Y | 表计编码 | `"EM-MAIN-01"` |
| `name` | VARCHAR(200) | Y | 表计名称 | `"总电表-1号进线"` |
| `meter_type` | ENUM(MeterType) | Y | 表计类型 | `"ELECTRICITY"` |
| `sub_type` | ENUM(EnergySubType) | N | 分项类型 | `"TOTAL"` |
| `measurement` | ENUM(EnergyMeasurement) | Y | 计量参数 | `"ACTIVE_ENERGY"` |
| `unit` | VARCHAR(20) | Y | 计量单位 | `"kWh"` |
| `ct_ratio` | DECIMAL(10,2) | N | CT 变比 | `200.00` |
| `pt_ratio` | DECIMAL(10,2) | N | PT 变比 | `1.00` |
| `multiplier` | DECIMAL(10,4) | N | 倍率 | `1.0000` |
| `point_id` | UUID (FK) | N | 关联读数点位 | `"uuid-point-meter-001"` |
| `equipment_id` | UUID (FK) | N | 关联设备 | `"uuid-equip-meter-001"` |
| `serves_systems` | UUID[] | N | 计量的子系统 | `["uuid-sys-001"]` |
| `serves_zones` | UUID[] | N | 计量的区域 | `["uuid-zone-001"]` |
| `tariff_schedule` | JSON | N | 费率方案 | 见下方示例 |
| `billing_cycle` | VARCHAR(20) | N | 计费周期 | `"MONTHLY"` |
| `cost_center` | VARCHAR(50) | N | 成本中心 | `"CC-HVAC-01"` |
| `install_date` | DATE | N | 安装日期 | `"2018-05-20"` |
| `last_calibration_date` | DATE | N | 上次校准日期 | `"2025-06-15"` |
| `next_calibration_date` | DATE | N | 下次校准日期 | `"2026-06-15"` |
| `tags` | VARCHAR(50)[] | N | 标签 | `["main-meter", "electricity"]` |
| `metadata` | JSON | N | 扩展字段 | `{"accuracy_class": "0.5S"}` |
| `status` | ENUM(EntityStatus) | Y | 状态 | `"ACTIVE"` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2025-01-15T08:00:00Z"` |
| `updated_at` | TIMESTAMP | Y | 更新时间 | `"2025-06-01T10:30:00Z"` |

#### tariff_schedule 示例

```json
{
  "tariff_name": "北京市大工业用电-两部制",
  "effective_from": "2025-07-01",
  "demand_charge": {"rate": 38.00, "unit": "CNY/kVA/month"},
  "energy_charges": [
    {"period": "PEAK",   "time_ranges": [["10:00","15:00"], ["18:00","21:00"]], "rate": 1.2647, "unit": "CNY/kWh"},
    {"period": "FLAT",   "time_ranges": [["07:00","10:00"], ["15:00","18:00"], ["21:00","23:00"]], "rate": 0.7875, "unit": "CNY/kWh"},
    {"period": "VALLEY", "time_ranges": [["23:00","07:00"]], "rate": 0.3150, "unit": "CNY/kWh"}
  ],
  "power_factor_adjustment": {"target": 0.90, "penalty_rate": 0.005, "reward_rate": 0.0025}
}
```

---

### 22. Notification（通知模型）

| 字段名 | 类型 | 必填 | 说明 | 示例值 |
|--------|------|------|------|--------|
| `id` | UUID | Y | 主键 | `"uuid-notif-001"` |
| `org_id` | UUID (FK) | Y | 所属组织 | `"uuid-org-001"` |
| `building_id` | UUID (FK) | N | 所属楼宇 | `"uuid-bldg-001"` |
| `notification_type` | ENUM(NotificationType) | Y | 通知类型 | `"ALARM"` |
| `channel` | ENUM(NotificationChannel) | Y | 推送渠道 | `"SMS"` |
| `priority` | ENUM(NotificationPriority) | Y | 通知优先级 | `"HIGH"` |
| `source_type` | VARCHAR(50) | Y | 来源实体类型 | `"ALARM"` |
| `source_id` | UUID | Y | 来源实体 ID | `"uuid-alarm-001"` |
| `template_id` | UUID (FK) | N | 通知模板 ID | `"uuid-tpl-alarm-critical"` |
| `recipient_user_id` | UUID (FK) | N | 接收人 | `"uuid-user-001"` |
| `recipient_role` | VARCHAR(50) | N | 接收角色（群发） | `"CHIEF_ENGINEER"` |
| `recipient_address` | VARCHAR(200) | Y | 接收地址（手机号/邮箱/设备token） | `"+86-13800138000"` |
| `title` | VARCHAR(300) | Y | 通知标题 | `"[紧急] 1号冷机冷冻水温度过高"` |
| `body` | TEXT | Y | 通知正文 | `"北京CBD园区A座1号冷机冷冻水供水温度14.5°C，超过阈值12.0°C"` |
| `body_html` | TEXT | N | HTML 正文（邮件用） | `"<h3>告警通知</h3>..."` |
| `send_state` | ENUM(SendState) | Y | 发送状态 | `"SENT"` |
| `scheduled_at` | TIMESTAMP | N | 计划发送时间 | `null` |
| `sent_at` | TIMESTAMP | N | 实际发送时间 | `"2026-03-11T10:31:05Z"` |
| `delivered_at` | TIMESTAMP | N | 送达时间 | `"2026-03-11T10:31:06Z"` |
| `read_at` | TIMESTAMP | N | 已读时间 | `null` |
| `failed_reason` | TEXT | N | 失败原因 | `null` |
| `retry_count` | INT | Y | 重试次数 | `0` |
| `max_retries` | INT | Y | 最大重试次数 | `3` |
| `metadata` | JSON | N | 扩展字段 | `{"sms_provider": "aliyun", "msg_id": "..."}` |
| `created_at` | TIMESTAMP | Y | 创建时间 | `"2026-03-11T10:31:00Z"` |

---

## 枚举值定义

### EntityStatus（通用实体状态）

| 值 | 说明 |
|----|------|
| `ACTIVE` | 正常使用 |
| `INACTIVE` | 停用 |
| `ARCHIVED` | 已归档 |
| `DELETED` | 已删除（软删除） |
| `PENDING` | 待审批/待激活 |

### OrgType（组织类型）

| 值 | 说明 |
|----|------|
| `ENTERPRISE` | 企业/集团 |
| `SUBSIDIARY` | 子公司 |
| `PROPERTY_MGMT` | 物业管理公司 |
| `SERVICE_PROVIDER` | 服务商 |
| `GOVERNMENT` | 政府/公共机构 |

### BuildingType（楼宇类型）

| 值 | 说明 |
|----|------|
| `OFFICE` | 写字楼 |
| `HOTEL` | 酒店 |
| `HOSPITAL` | 医院 |
| `MALL` | 商场 |
| `FACTORY` | 工厂 |
| `WAREHOUSE` | 仓库 |
| `RESIDENTIAL` | 住宅 |
| `SCHOOL` | 学校 |
| `DATA_CENTER` | 数据中心 |
| `CONVENTION` | 会展中心 |
| `STADIUM` | 体育场馆 |
| `AIRPORT` | 航站楼 |
| `RAIL_STATION` | 轨道交通站点 |
| `MIXED_USE` | 综合体 |
| `OTHER` | 其他 |

### ClimateZone（气候区）

| 值 | 说明 | 参考 |
|----|------|------|
| `SEVERE_COLD` | 严寒地区 | 中国GB 50176 / ASHRAE 7-8 |
| `COLD` | 寒冷地区 | 中国GB 50176 / ASHRAE 5-6 |
| `HOT_SUMMER_COLD_WINTER` | 夏热冬冷 | 中国GB 50176 / ASHRAE 3-4 |
| `HOT_SUMMER_WARM_WINTER` | 夏热冬暖 | 中国GB 50176 / ASHRAE 1-2 |
| `MILD` | 温和地区 | 中国GB 50176 |
| `TROPICAL` | 热带 | ASHRAE 0 |
| `MARINE` | 海洋性 | ASHRAE C |

### FloorType（楼层类型）

| 值 | 说明 |
|----|------|
| `STANDARD` | 标准层 |
| `MECHANICAL` | 设备层 |
| `REFUGE` | 避难层 |
| `LOBBY` | 大堂层 |
| `ROOF` | 屋顶层 |
| `PARKING` | 停车层 |
| `BASEMENT_MECHANICAL` | 地下设备层 |

### SpaceType（空间用途）

| 值 | 说明 |
|----|------|
| `OFFICE` | 办公室 |
| `MEETING_ROOM` | 会议室 |
| `LOBBY` | 大堂 |
| `CORRIDOR` | 走廊 |
| `RESTROOM` | 卫生间 |
| `STAIRWELL` | 楼梯间 |
| `ELEVATOR_HALL` | 电梯厅 |
| `MECHANICAL_ROOM` | 设备机房 |
| `ELECTRICAL_ROOM` | 配电间 |
| `SERVER_ROOM` | 机房 |
| `KITCHEN` | 厨房 |
| `DINING` | 餐厅 |
| `STORAGE` | 储藏室 |
| `PARKING` | 停车场 |
| `GUEST_ROOM` | 客房（酒店） |
| `WARD` | 病房（医院） |
| `OPERATING_ROOM` | 手术室（医院） |
| `RETAIL` | 零售店铺 |
| `PRODUCTION` | 生产车间 |
| `CLEANROOM` | 洁净室 |
| `OUTDOOR` | 室外区域 |
| `OTHER` | 其他 |

### SystemType（子系统类型）

| 值 | 说明 |
|----|------|
| `HVAC` | 暖通空调 |
| `LIGHTING` | 照明 |
| `ELECTRICAL` | 电气 |
| `FIRE_PROTECTION` | 消防 |
| `SECURITY` | 安防 |
| `PLUMBING` | 给排水 |
| `ELEVATOR` | 电梯 |
| `BAS` | 楼宇自控 |
| `ENERGY_MGMT` | 能源管理 |
| `NETWORK` | 网络/通讯 |
| `RENEWABLE` | 可再生能源 |
| `WASTE` | 废弃物处理 |
| `OTHER` | 其他 |

### EquipmentType（设备类型）

| 值 | 说明 |
|----|------|
| `CHILLER` | 冷水机组 |
| `BOILER` | 锅炉 |
| `COOLING_TOWER` | 冷却塔 |
| `AHU` | 空调箱 |
| `FCU` | 风机盘管 |
| `VAV` | 变风量末端 |
| `PUMP` | 水泵 |
| `FAN` | 风机 |
| `HEAT_EXCHANGER` | 换热器 |
| `VRF` | 多联机 |
| `SPLIT_AC` | 分体空调 |
| `TRANSFORMER` | 变压器 |
| `SWITCHGEAR` | 开关柜 |
| `UPS` | 不间断电源 |
| `GENERATOR` | 发电机 |
| `PDU` | 配电单元 |
| `LIGHTING_PANEL` | 照明配电箱 |
| `LUMINAIRE` | 灯具 |
| `FIRE_ALARM_PANEL` | 火灾报警主机 |
| `SMOKE_DETECTOR` | 烟感探测器 |
| `SPRINKLER` | 喷淋 |
| `FIRE_PUMP` | 消防泵 |
| `CCTV_CAMERA` | 摄像头 |
| `ACCESS_CONTROLLER` | 门禁控制器 |
| `ELEVATOR_CAR` | 电梯轿厢 |
| `ESCALATOR` | 扶梯 |
| `WATER_TANK` | 水箱 |
| `METER` | 计量表 |
| `SENSOR` | 传感器 |
| `ACTUATOR` | 执行器 |
| `VALVE` | 阀门 |
| `DAMPER` | 风阀 |
| `SOLAR_PANEL` | 太阳能板 |
| `BATTERY_STORAGE` | 储能电池 |
| `OTHER` | 其他 |

### ComponentType（部件类型）

| 值 | 说明 |
|----|------|
| `COMPRESSOR` | 压缩机 |
| `CONDENSER` | 冷凝器 |
| `EVAPORATOR` | 蒸发器 |
| `EXPANSION_VALVE` | 膨胀阀 |
| `MOTOR` | 电机 |
| `IMPELLER` | 叶轮 |
| `BEARING` | 轴承 |
| `BELT` | 皮带 |
| `FILTER` | 过滤器 |
| `COIL` | 盘管 |
| `BURNER` | 燃烧器 |
| `CONTROL_BOARD` | 控制板 |
| `INVERTER` | 变频器 |
| `CONTACTOR` | 接触器 |
| `RELAY` | 继电器 |
| `OTHER` | 其他 |

### MaintenanceStatus（维保状态）

| 值 | 说明 |
|----|------|
| `NORMAL` | 正常运行 |
| `DUE_SOON` | 即将到期 |
| `OVERDUE` | 已逾期 |
| `IN_MAINTENANCE` | 维保中 |
| `OUT_OF_SERVICE` | 停用/报废 |
| `UNDER_WARRANTY` | 质保期内 |

### Criticality（关键程度）

| 值 | 说明 |
|----|------|
| `CRITICAL` | 关键（故障将导致重大影响） |
| `HIGH` | 高（故障将导致显著影响） |
| `MEDIUM` | 中（故障将导致一定影响） |
| `LOW` | 低（故障影响可接受） |

### PointClass（点位分类，参考 Haystack）

| 值 | 说明 |
|----|------|
| `SENSOR` | 传感器（只读，物理量） |
| `COMMAND` | 控制指令（可写） |
| `SETPOINT` | 设定值（可写） |
| `STATUS` | 状态反馈（只读，枚举/布尔） |
| `ALARM_POINT` | 告警点位（只读，布尔） |
| `CALCULATED` | 计算/虚拟点（只读，由表达式计算） |
| `ACCUMULATOR` | 累积量（如电表读数） |

### PointDataType（点位数据类型）

| 值 | 说明 |
|----|------|
| `FLOAT` | 浮点数 |
| `INT` | 整数 |
| `BOOL` | 布尔 |
| `STRING` | 字符串 |
| `ENUM` | 枚举 |
| `JSON` | 复合JSON |

### PointAccess（读写权限）

| 值 | 说明 |
|----|------|
| `READ_ONLY` | 只读 |
| `READ_WRITE` | 读写 |
| `WRITE_ONLY` | 只写 |

### SourceProtocol（来源协议）

| 值 | 说明 |
|----|------|
| `BACNET` | BACnet IP/MSTP |
| `MODBUS_TCP` | Modbus TCP |
| `MODBUS_RTU` | Modbus RTU |
| `OPC_UA` | OPC Unified Architecture |
| `OPC_DA` | OPC Data Access (经典) |
| `MQTT` | MQTT |
| `KNX` | KNX/EIB |
| `LONWORKS` | LonWorks |
| `DALI` | DALI 照明 |
| `SNMP` | SNMP 网络 |
| `HTTP_API` | HTTP/REST API |
| `VIRTUAL` | 虚拟/计算点 |
| `MANUAL` | 人工录入 |

### PointQuality（数据质量）

| 值 | 说明 |
|----|------|
| `GOOD` | 质量良好 |
| `UNCERTAIN` | 不确定 |
| `BAD` | 质量差/故障 |
| `OFFLINE` | 离线 |
| `NOT_CONFIGURED` | 未配置 |
| `OVERRIDDEN` | 被强制覆盖 |

### UnitSystem（单位制）

| 值 | 说明 |
|----|------|
| `SI` | 国际单位制 |
| `IMPERIAL` | 英制 |

### TrendMethod（趋势记录方式）

| 值 | 说明 |
|----|------|
| `PERIODIC` | 定周期采样 |
| `COV` | 变化触发 |
| `PERIODIC_AND_COV` | 两者兼用 |

### TrendSource（趋势数据来源）

| 值 | 说明 |
|----|------|
| `FIELD` | 现场采集 |
| `CALCULATED` | 计算生成 |
| `MANUAL` | 人工录入 |
| `IMPORTED` | 外部导入 |
| `SIMULATED` | 模拟数据 |

### AlarmSeverity（告警严重度）

| 值 | 数字等级 | 说明 |
|----|---------|------|
| `CRITICAL` | 1 | 紧急（影响安全/核心业务） |
| `MAJOR` | 2 | 重要（影响主要功能） |
| `MINOR` | 3 | 次要（影响辅助功能） |
| `WARNING` | 4 | 警告（趋势预警） |
| `INFO` | 5 | 信息（通知性质） |

### AlarmCategory（告警类别）

| 值 | 说明 |
|----|------|
| `FIRE` | 消防 |
| `SECURITY` | 安防 |
| `LIFE_SAFETY` | 生命安全 |
| `PROCESS` | 工艺/流程 |
| `EQUIPMENT_FAULT` | 设备故障 |
| `COMMUNICATION` | 通讯故障 |
| `ENERGY` | 能源异常 |
| `ENVIRONMENTAL` | 环境异常 |
| `MAINTENANCE` | 维保提醒 |
| `SYSTEM` | 系统/软件告警 |

### AlarmState（告警状态）

| 值 | 说明 |
|----|------|
| `ACTIVE_UNACKED` | 活跃-未确认 |
| `ACTIVE_ACKED` | 活跃-已确认 |
| `CLEARED_UNACKED` | 已恢复-未确认 |
| `CLEARED_ACKED` | 已恢复-已确认 |
| `CLOSED` | 已关闭/归档 |

### ConditionType（告警条件类型）

| 值 | 说明 |
|----|------|
| `HI_HI_LIMIT` | 高高限 |
| `HI_LIMIT` | 高限 |
| `LO_LIMIT` | 低限 |
| `LO_LO_LIMIT` | 低低限 |
| `DEVIATION` | 偏差 |
| `RATE_OF_CHANGE` | 变化率 |
| `STATE_CHANGE` | 状态变化 |
| `BOOL_TRUE` | 布尔为真 |
| `BOOL_FALSE` | 布尔为假 |
| `EXPRESSION` | 自定义表达式 |
| `OFFLINE` | 离线/通讯中断 |
| `STALE` | 数据过期 |

### ScheduleType（排程类型）

| 值 | 说明 |
|----|------|
| `WEEKLY` | 周排程 |
| `CALENDAR` | 日历排程 |
| `ONE_TIME` | 一次性 |
| `RECURRING` | 自定义循环 |

### CalendarSystem（日历体系）

| 值 | 说明 |
|----|------|
| `GREGORIAN` | 公历 |
| `CHINESE_LUNAR` | 中国农历 |
| `ISLAMIC` | 伊斯兰历 |
| `CUSTOM` | 自定义 |

### WorkOrderType（工单类型）

| 值 | 说明 |
|----|------|
| `CORRECTIVE` | 报修/纠正性维护 |
| `PREVENTIVE` | 预防性维护 |
| `PREDICTIVE` | 预测性维护 |
| `INSPECTION` | 巡检 |
| `EMERGENCY` | 应急 |
| `PROJECT` | 工程/改造 |
| `REQUEST` | 服务请求 |

### WorkOrderState（工单状态）

| 值 | 说明 |
|----|------|
| `OPEN` | 新建/待分配 |
| `ASSIGNED` | 已分配 |
| `IN_PROGRESS` | 处理中 |
| `PENDING_PARTS` | 等待备件 |
| `PENDING_APPROVAL` | 等待审批 |
| `COMPLETED` | 已完成 |
| `VERIFIED` | 已验收 |
| `CLOSED` | 已关闭 |
| `CANCELLED` | 已取消 |
| `REOPENED` | 重新打开 |

### WorkOrderPriority（工单优先级）

| 值 | 响应SLA | 解决SLA | 说明 |
|----|---------|---------|------|
| `EMERGENCY` | 15 min | 2 h | 紧急 |
| `HIGH` | 30 min | 4 h | 高 |
| `MEDIUM` | 2 h | 24 h | 中 |
| `LOW` | 8 h | 72 h | 低 |
| `PLANNED` | N/A | 按计划 | 计划性 |

### WorkOrderSource（工单来源）

| 值 | 说明 |
|----|------|
| `ALARM` | 告警自动生成 |
| `MANUAL` | 人工创建 |
| `SCHEDULE` | 排程触发 |
| `INSPECTION` | 巡检发现 |
| `TENANT_REQUEST` | 租户报修 |
| `AI_PREDICTION` | AI 预测 |

### AssetType（资产类型）

| 值 | 说明 |
|----|------|
| `FIXED_ASSET` | 固定资产 |
| `SPARE_PART` | 备件 |
| `CONSUMABLE` | 耗材 |
| `TOOL` | 工具 |

### AssetLifecycle（资产生命周期）

| 值 | 说明 |
|----|------|
| `PROCUREMENT` | 采购中 |
| `IN_STOCK` | 在库 |
| `IN_SERVICE` | 使用中 |
| `IN_REPAIR` | 维修中 |
| `DECOMMISSIONED` | 已退役 |
| `DISPOSED` | 已处置 |

### MeterType（能源表计类型）

| 值 | 说明 |
|----|------|
| `ELECTRICITY` | 电表 |
| `GAS` | 燃气表 |
| `WATER` | 水表 |
| `STEAM` | 蒸汽表 |
| `CHILLED_WATER` | 冷量表 |
| `HOT_WATER` | 热量表 |
| `FUEL` | 燃油表 |
| `RENEWABLE` | 可再生能源 |

### EnergySubType（能源分项类型）

| 值 | 说明 |
|----|------|
| `TOTAL` | 总表 |
| `HVAC` | 暖通空调分项 |
| `LIGHTING` | 照明分项 |
| `POWER_OUTLET` | 插座/动力分项 |
| `ELEVATOR` | 电梯分项 |
| `SPECIAL` | 特殊用电（数据中心/厨房等） |
| `DOMESTIC_HOT_WATER` | 生活热水 |

### EnergyMeasurement（能源计量参数）

| 值 | 说明 |
|----|------|
| `ACTIVE_ENERGY` | 有功电能 (kWh) |
| `REACTIVE_ENERGY` | 无功电能 (kVarh) |
| `ACTIVE_POWER` | 有功功率 (kW) |
| `APPARENT_POWER` | 视在功率 (kVA) |
| `POWER_FACTOR` | 功率因数 |
| `VOLUME` | 体积 (m³) |
| `THERMAL_ENERGY` | 热能 (kWh/GJ) |
| `MASS_FLOW` | 质量流量 (kg) |

### ScenarioType（场景类型）

| 值 | 说明 |
|----|------|
| `NORMAL` | 正常模式 |
| `HOLIDAY` | 节假日模式 |
| `WEEKEND` | 周末模式 |
| `EMERGENCY` | 应急模式 |
| `VIP` | VIP接待模式 |
| `ENERGY_SAVING` | 节能模式 |
| `NIGHT` | 夜间模式 |
| `PEAK_SHAVING` | 削峰模式 |
| `CUSTOM` | 自定义 |

### ScenarioState（场景状态）

| 值 | 说明 |
|----|------|
| `INACTIVE` | 未激活 |
| `ACTIVE` | 已激活 |
| `COOLDOWN` | 冷却中 |

### ActivationMode（激活方式）

| 值 | 说明 |
|----|------|
| `AUTO` | 自动触发 |
| `MANUAL` | 手动触发 |
| `SCHEDULED` | 定时触发 |
| `HYBRID` | 混合（自动+手动确认） |

### AuthProvider（认证方式）

| 值 | 说明 |
|----|------|
| `LOCAL` | 本地账号密码 |
| `LDAP` | LDAP/AD |
| `SAML` | SAML SSO |
| `OIDC` | OpenID Connect |
| `WECHAT` | 企业微信 |
| `DINGTALK` | 钉钉 |

### RoleScope（角色作用范围）

| 值 | 说明 |
|----|------|
| `GLOBAL` | 全局/平台级 |
| `ORGANIZATION` | 组织级 |
| `SITE` | 园区级 |
| `BUILDING` | 楼宇级 |

### PermAction（权限操作）

| 值 | 说明 |
|----|------|
| `READ` | 读取 |
| `WRITE` | 写入/修改 |
| `CREATE` | 创建 |
| `DELETE` | 删除 |
| `EXECUTE` | 执行（控制指令） |
| `APPROVE` | 审批 |
| `EXPORT` | 导出 |
| `ADMIN` | 管理（包含所有操作） |

### AuditAction（审计操作类型）

| 值 | 说明 |
|----|------|
| `CREATE` | 创建 |
| `UPDATE` | 修改 |
| `DELETE` | 删除 |
| `LOGIN` | 登录 |
| `LOGOUT` | 登出 |
| `LOGIN_FAILED` | 登录失败 |
| `POINT_WRITE` | 点位写入/控制 |
| `ALARM_ACK` | 告警确认 |
| `ALARM_CLOSE` | 告警关闭 |
| `SCENARIO_ACTIVATE` | 场景激活 |
| `SCENARIO_DEACTIVATE` | 场景退出 |
| `SCHEDULE_OVERRIDE` | 排程覆盖 |
| `PERMISSION_GRANT` | 权限授予 |
| `PERMISSION_REVOKE` | 权限撤销 |
| `CONFIG_CHANGE` | 配置变更 |
| `DATA_EXPORT` | 数据导出 |

### AuditResult（审计结果）

| 值 | 说明 |
|----|------|
| `SUCCESS` | 成功 |
| `FAILURE` | 失败 |
| `DENIED` | 权限拒绝 |

### ComplianceRuleType（合规规则类型）

| 值 | 说明 |
|----|------|
| `DATA_RETENTION` | 数据保留 |
| `AUDIT_REQUIREMENT` | 审计要求 |
| `INSPECTION_FREQUENCY` | 检查频率 |
| `CERTIFICATION_RENEWAL` | 认证续期 |
| `EMISSION_LIMIT` | 排放限制 |
| `ENERGY_REPORTING` | 能源报告 |
| `SAFETY_STANDARD` | 安全标准 |

### EnforcementLevel（执行力度）

| 值 | 说明 |
|----|------|
| `MANDATORY` | 强制 |
| `RECOMMENDED` | 推荐 |
| `OPTIONAL` | 可选 |

### NotificationType（通知类型）

| 值 | 说明 |
|----|------|
| `ALARM` | 告警通知 |
| `WORK_ORDER` | 工单通知 |
| `REPORT` | 报表推送 |
| `SYSTEM` | 系统通知 |
| `MAINTENANCE_REMINDER` | 维保提醒 |
| `COMPLIANCE_ALERT` | 合规预警 |
| `ENERGY_ALERT` | 能源异常 |

### NotificationChannel（通知渠道）

| 值 | 说明 |
|----|------|
| `EMAIL` | 邮件 |
| `SMS` | 短信 |
| `PUSH` | App 推送 |
| `WECHAT` | 企业微信 |
| `DINGTALK` | 钉钉 |
| `WEBHOOK` | Webhook |
| `PA_SYSTEM` | 广播系统 |
| `IN_APP` | 站内信 |

### NotificationPriority（通知优先级）

| 值 | 说明 |
|----|------|
| `URGENT` | 紧急（立即发送，所有渠道） |
| `HIGH` | 高（立即发送） |
| `NORMAL` | 普通 |
| `LOW` | 低（可合并/延迟） |

### SendState（发送状态）

| 值 | 说明 |
|----|------|
| `PENDING` | 待发送 |
| `SENDING` | 发送中 |
| `SENT` | 已发送 |
| `DELIVERED` | 已送达 |
| `READ` | 已读 |
| `FAILED` | 发送失败 |
| `CANCELLED` | 已取消 |

---

*本文档版本 1.0.0 — 公共基础层数据模型定义，适用于所有行业 Container。*
