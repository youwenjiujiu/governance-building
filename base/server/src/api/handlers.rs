use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{Path, Query, State};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::Json;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::api::state::AppState;
use crate::models::entities::*;
use crate::models::enums::*;

// ─── Common types ────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct PaginationParams {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
}

impl PaginationParams {
    pub fn offset(&self) -> i64 {
        let page = self.page.unwrap_or(1).max(1);
        let per_page = self.per_page.unwrap_or(20).min(100);
        (page - 1) * per_page
    }
    pub fn limit(&self) -> i64 {
        self.per_page.unwrap_or(20).min(100)
    }
}

#[derive(Debug, Serialize)]
pub struct ListResponse<T: Serialize> {
    pub data: Vec<T>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
}

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub error: String,
}

fn internal_error(e: impl std::fmt::Display) -> (StatusCode, Json<ErrorResponse>) {
    tracing::error!("Internal error: {e}");
    (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ErrorResponse {
            error: e.to_string(),
        }),
    )
}

// ─── Organizations ───────────────────────────────────────────────────────────

pub async fn list_organizations(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<PaginationParams>,
) -> Result<Json<ListResponse<Organization>>, (StatusCode, Json<ErrorResponse>)> {
    let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM organizations")
        .fetch_one(&pool)
        .await
        .map_err(internal_error)?;

    let rows: Vec<Organization> = sqlx::query_as(
        "SELECT * FROM organizations ORDER BY created_at DESC LIMIT $1 OFFSET $2",
    )
    .bind(params.limit())
    .bind(params.offset())
    .fetch_all(&pool)
    .await
    .map_err(internal_error)?;

    Ok(Json(ListResponse {
        data: rows,
        total: total.0,
        page: params.page.unwrap_or(1),
        per_page: params.limit(),
    }))
}

pub async fn create_organization(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateOrganization>,
) -> Result<(StatusCode, Json<Organization>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();
    let creator = Uuid::nil(); // placeholder, would come from auth

    let org: Organization = sqlx::query_as(
        r#"INSERT INTO organizations (id, code, name, name_en, type, parent_id, legal_entity, tax_id,
            country, timezone, locale, logo_url, contact_email, contact_phone, metadata,
            status, created_at, updated_at, created_by, updated_by)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)
        RETURNING *"#,
    )
    .bind(id)
    .bind(&body.code)
    .bind(&body.name)
    .bind(&body.name_en)
    .bind(&body.org_type)
    .bind(body.parent_id)
    .bind(&body.legal_entity)
    .bind(&body.tax_id)
    .bind(&body.country)
    .bind(&body.timezone)
    .bind(&body.locale)
    .bind(&body.logo_url)
    .bind(&body.contact_email)
    .bind(&body.contact_phone)
    .bind(&body.metadata)
    .bind(EntityStatus::Active)
    .bind(now)
    .bind(now)
    .bind(creator)
    .bind(creator)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(org)))
}

// ─── Buildings ───────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct BuildingFilter {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub site_id: Option<Uuid>,
    pub building_type: Option<String>,
}

pub async fn list_buildings(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<BuildingFilter>,
) -> Result<Json<ListResponse<Building>>, (StatusCode, Json<ErrorResponse>)> {
    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let (count_sql, query_sql) = if let Some(site_id) = params.site_id {
        let _ = site_id; // used in bind below
        (
            "SELECT COUNT(*) FROM buildings WHERE site_id = $1".to_string(),
            "SELECT * FROM buildings WHERE site_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3"
                .to_string(),
        )
    } else {
        (
            "SELECT COUNT(*) FROM buildings".to_string(),
            "SELECT * FROM buildings ORDER BY created_at DESC LIMIT $1 OFFSET $2".to_string(),
        )
    };

    let (total, rows): (i64, Vec<Building>) = if let Some(site_id) = params.site_id {
        let t: (i64,) = sqlx::query_as(&count_sql)
            .bind(site_id)
            .fetch_one(&pool)
            .await
            .map_err(internal_error)?;
        let r: Vec<Building> = sqlx::query_as(&query_sql)
            .bind(site_id)
            .bind(per_page)
            .bind(offset)
            .fetch_all(&pool)
            .await
            .map_err(internal_error)?;
        (t.0, r)
    } else {
        let t: (i64,) = sqlx::query_as(&count_sql)
            .fetch_one(&pool)
            .await
            .map_err(internal_error)?;
        let r: Vec<Building> = sqlx::query_as(&query_sql)
            .bind(per_page)
            .bind(offset)
            .fetch_all(&pool)
            .await
            .map_err(internal_error)?;
        (t.0, r)
    };

    Ok(Json(ListResponse {
        data: rows,
        total,
        page,
        per_page,
    }))
}

pub async fn create_building(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateBuilding>,
) -> Result<(StatusCode, Json<Building>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();
    let creator = Uuid::nil();

    let building: Building = sqlx::query_as(
        r#"INSERT INTO buildings (id, site_id, profile_id, code, name, name_en, building_type,
            year_built, year_renovated, gross_floor_area, usable_area, floors_above, floors_below,
            height, climate_zone, design_occupancy, bim_model_url, address, latitude, longitude,
            metadata, status, created_at, updated_at, created_by, updated_by)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NULL,$9,$10,$11,$12,$13,$14,$15,NULL,$16,$17,$18,$19,$20,$21,$22,$23,$24)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.site_id)
    .bind(body.profile_id)
    .bind(&body.code)
    .bind(&body.name)
    .bind(&body.name_en)
    .bind(&body.building_type)
    .bind(body.year_built)
    .bind(body.gross_floor_area)
    .bind(body.usable_area)
    .bind(body.floors_above)
    .bind(body.floors_below)
    .bind(body.height)
    .bind(&body.climate_zone)
    .bind(body.design_occupancy)
    .bind(&body.address)
    .bind(body.latitude)
    .bind(body.longitude)
    .bind(&body.metadata)
    .bind(EntityStatus::Active)
    .bind(now)
    .bind(now)
    .bind(creator)
    .bind(creator)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(building)))
}

// ─── Zones ───────────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct ZoneFilter {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub building_id: Option<Uuid>,
    pub floor_id: Option<Uuid>,
}

pub async fn list_zones(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<ZoneFilter>,
) -> Result<Json<ListResponse<Zone>>, (StatusCode, Json<ErrorResponse>)> {
    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let mut where_clauses: Vec<String> = vec![];
    if params.building_id.is_some() {
        where_clauses.push(format!("building_id = ${}", where_clauses.len() + 1));
    }
    if params.floor_id.is_some() {
        where_clauses.push(format!("floor_id = ${}", where_clauses.len() + 1));
    }

    let where_str = if where_clauses.is_empty() {
        String::new()
    } else {
        format!("WHERE {}", where_clauses.join(" AND "))
    };

    let count_sql = format!("SELECT COUNT(*) FROM zones {where_str}");
    let param_offset = where_clauses.len();
    let query_sql = format!(
        "SELECT * FROM zones {where_str} ORDER BY created_at DESC LIMIT ${} OFFSET ${}",
        param_offset + 1,
        param_offset + 2
    );

    let mut count_q = sqlx::query_as::<_, (i64,)>(&count_sql);
    let mut data_q = sqlx::query_as::<_, Zone>(&query_sql);

    if let Some(bid) = params.building_id {
        count_q = count_q.bind(bid);
        data_q = data_q.bind(bid);
    }
    if let Some(fid) = params.floor_id {
        count_q = count_q.bind(fid);
        data_q = data_q.bind(fid);
    }

    let total: (i64,) = count_q.fetch_one(&pool).await.map_err(internal_error)?;
    let rows: Vec<Zone> = data_q
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;

    Ok(Json(ListResponse {
        data: rows,
        total: total.0,
        page,
        per_page,
    }))
}

pub async fn create_zone(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateZone>,
) -> Result<(StatusCode, Json<Zone>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();

    let zone: Zone = sqlx::query_as(
        r#"INSERT INTO zones (id, floor_id, building_id, parent_zone_id, code, name, name_en,
            space_type, area, volume, capacity, is_public, hvac_zone_id, lighting_zone_id,
            fire_zone_id, metadata, status, created_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,NULL,NULL,NULL,$13,$14,$15,$16)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.floor_id)
    .bind(body.building_id)
    .bind(body.parent_zone_id)
    .bind(&body.code)
    .bind(&body.name)
    .bind(&body.name_en)
    .bind(&body.space_type)
    .bind(body.area)
    .bind(body.volume)
    .bind(body.capacity)
    .bind(body.is_public)
    .bind(&body.metadata)
    .bind(EntityStatus::Active)
    .bind(now)
    .bind(now)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(zone)))
}

// ─── Equipment ───────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct EquipmentFilter {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub system_id: Option<Uuid>,
    pub zone_id: Option<Uuid>,
    pub building_id: Option<Uuid>,
}

pub async fn list_equipment(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<EquipmentFilter>,
) -> Result<Json<ListResponse<Equipment>>, (StatusCode, Json<ErrorResponse>)> {
    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let mut where_clauses: Vec<String> = vec![];
    if params.system_id.is_some() {
        where_clauses.push(format!("system_id = ${}", where_clauses.len() + 1));
    }
    if params.zone_id.is_some() {
        where_clauses.push(format!("zone_id = ${}", where_clauses.len() + 1));
    }

    let where_str = if where_clauses.is_empty() {
        String::new()
    } else {
        format!("WHERE {}", where_clauses.join(" AND "))
    };

    let count_sql = format!("SELECT COUNT(*) FROM equipment {where_str}");
    let param_offset = where_clauses.len();
    let query_sql = format!(
        "SELECT * FROM equipment {where_str} ORDER BY created_at DESC LIMIT ${} OFFSET ${}",
        param_offset + 1,
        param_offset + 2
    );

    let mut count_q = sqlx::query_as::<_, (i64,)>(&count_sql);
    let mut data_q = sqlx::query_as::<_, Equipment>(&query_sql);

    if let Some(sid) = params.system_id {
        count_q = count_q.bind(sid);
        data_q = data_q.bind(sid);
    }
    if let Some(zid) = params.zone_id {
        count_q = count_q.bind(zid);
        data_q = data_q.bind(zid);
    }

    let total: (i64,) = count_q.fetch_one(&pool).await.map_err(internal_error)?;
    let rows: Vec<Equipment> = data_q
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;

    Ok(Json(ListResponse {
        data: rows,
        total: total.0,
        page,
        per_page,
    }))
}

pub async fn create_equipment(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateEquipment>,
) -> Result<(StatusCode, Json<Equipment>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();

    let equip: Equipment = sqlx::query_as(
        r#"INSERT INTO equipment (id, system_id, zone_id, parent_equipment_id, code, name,
            equipment_type, sub_type, manufacturer, model, serial_number, rated_power,
            rated_capacity, install_date, warranty_expiry, expected_life_years,
            last_maintenance_date, next_maintenance_date, maintenance_cycle_days,
            barcode, qr_code_url, bim_guid, backup_equipment_id, redundancy_group_id,
            metadata, status, created_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,$15,$16,$17,$18)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.system_id)
    .bind(body.zone_id)
    .bind(body.parent_equipment_id)
    .bind(&body.code)
    .bind(&body.name)
    .bind(&body.equipment_type)
    .bind(&body.sub_type)
    .bind(&body.manufacturer)
    .bind(&body.model)
    .bind(&body.serial_number)
    .bind(body.rated_power)
    .bind(&body.rated_capacity)
    .bind(body.install_date)
    .bind(&body.metadata)
    .bind(EntityStatus::Active)
    .bind(now)
    .bind(now)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(equip)))
}

// ─── Points ──────────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct PointFilter {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub building_id: Option<Uuid>,
    pub equipment_id: Option<Uuid>,
    pub zone_id: Option<Uuid>,
}

pub async fn list_points(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<PointFilter>,
) -> Result<Json<ListResponse<Point>>, (StatusCode, Json<ErrorResponse>)> {
    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let mut where_clauses: Vec<String> = vec![];
    if params.building_id.is_some() {
        where_clauses.push(format!("building_id = ${}", where_clauses.len() + 1));
    }
    if params.equipment_id.is_some() {
        where_clauses.push(format!("equipment_id = ${}", where_clauses.len() + 1));
    }
    if params.zone_id.is_some() {
        where_clauses.push(format!("zone_id = ${}", where_clauses.len() + 1));
    }

    let where_str = if where_clauses.is_empty() {
        String::new()
    } else {
        format!("WHERE {}", where_clauses.join(" AND "))
    };

    let count_sql = format!("SELECT COUNT(*) FROM points {where_str}");
    let param_offset = where_clauses.len();
    let query_sql = format!(
        "SELECT * FROM points {where_str} ORDER BY created_at DESC LIMIT ${} OFFSET ${}",
        param_offset + 1,
        param_offset + 2
    );

    let mut count_q = sqlx::query_as::<_, (i64,)>(&count_sql);
    let mut data_q = sqlx::query_as::<_, Point>(&query_sql);

    if let Some(bid) = params.building_id {
        count_q = count_q.bind(bid);
        data_q = data_q.bind(bid);
    }
    if let Some(eid) = params.equipment_id {
        count_q = count_q.bind(eid);
        data_q = data_q.bind(eid);
    }
    if let Some(zid) = params.zone_id {
        count_q = count_q.bind(zid);
        data_q = data_q.bind(zid);
    }

    let total: (i64,) = count_q.fetch_one(&pool).await.map_err(internal_error)?;
    let rows: Vec<Point> = data_q
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;

    Ok(Json(ListResponse {
        data: rows,
        total: total.0,
        page,
        per_page,
    }))
}

pub async fn create_point(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreatePoint>,
) -> Result<(StatusCode, Json<Point>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();

    let point: Point = sqlx::query_as(
        r#"INSERT INTO points (id, equipment_id, component_id, zone_id, building_id, code, name,
            name_en, point_class, data_type, unit, access, source_protocol, source_address,
            polling_interval_s, cov_enabled, cov_increment, min_value, max_value, default_value,
            alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo, alarm_deadband,
            alarm_delay_s, trend_enabled, trend_interval_s, trend_retention_days,
            display_group, display_order, is_virtual, calc_expression,
            metadata, status, current_value, current_quality, value_timestamp,
            created_at, updated_at)
        VALUES ($1,$2,NULL,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,NULL,NULL,NULL,NULL,NULL,
            $15,NULL,$16,$17,NULL,NULL,NULL,$18,NULL,NULL,NULL,NULL,NULL,NULL,$19,$20,NULL,NULL,NULL,$21,$22)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.equipment_id)
    .bind(body.zone_id)
    .bind(body.building_id)
    .bind(&body.code)
    .bind(&body.name)
    .bind(&body.name_en)
    .bind(&body.point_class)
    .bind(&body.data_type)
    .bind(&body.unit)
    .bind(&body.access)
    .bind(&body.source_protocol)
    .bind(&body.source_address)
    .bind(body.polling_interval_s)
    .bind(body.alarm_enabled)
    .bind(body.alarm_hi)
    .bind(body.alarm_lo)
    .bind(body.trend_enabled)
    .bind(&body.metadata)
    .bind(EntityStatus::Active)
    .bind(now)
    .bind(now)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(point)))
}

// ─── Point Values (time series) ──────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct PointValueQuery {
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub interval: Option<String>, // raw, 5min, 1h, 1d
}

pub async fn get_point_values(
    State(AppState { pool, .. }): State<AppState>,
    Path(point_id): Path<Uuid>,
    Query(params): Query<PointValueQuery>,
) -> Result<Json<Vec<PointValue>>, (StatusCode, Json<ErrorResponse>)> {
    let start = params
        .start_time
        .unwrap_or_else(|| Utc::now() - chrono::Duration::hours(24));
    let end = params.end_time.unwrap_or_else(Utc::now);
    let interval = params.interval.as_deref().unwrap_or("raw");

    let rows: Vec<PointValue> = match interval {
        "5min" => {
            sqlx::query_as(
                r#"SELECT
                    point_id,
                    time_bucket('5 minutes', ts) AS ts,
                    AVG(value_numeric) AS value_numeric,
                    NULL::varchar AS value_text,
                    NULL::boolean AS value_bool,
                    NULL::jsonb AS value_json,
                    'GOOD'::point_quality AS quality
                FROM point_values
                WHERE point_id = $1 AND ts >= $2 AND ts <= $3
                GROUP BY point_id, time_bucket('5 minutes', ts)
                ORDER BY ts"#,
            )
            .bind(point_id)
            .bind(start)
            .bind(end)
            .fetch_all(&pool)
            .await
            .map_err(internal_error)?
        }
        "1h" => {
            sqlx::query_as(
                r#"SELECT
                    point_id,
                    time_bucket('1 hour', ts) AS ts,
                    AVG(value_numeric) AS value_numeric,
                    NULL::varchar AS value_text,
                    NULL::boolean AS value_bool,
                    NULL::jsonb AS value_json,
                    'GOOD'::point_quality AS quality
                FROM point_values
                WHERE point_id = $1 AND ts >= $2 AND ts <= $3
                GROUP BY point_id, time_bucket('1 hour', ts)
                ORDER BY ts"#,
            )
            .bind(point_id)
            .bind(start)
            .bind(end)
            .fetch_all(&pool)
            .await
            .map_err(internal_error)?
        }
        "1d" => {
            sqlx::query_as(
                r#"SELECT
                    point_id,
                    time_bucket('1 day', ts) AS ts,
                    AVG(value_numeric) AS value_numeric,
                    NULL::varchar AS value_text,
                    NULL::boolean AS value_bool,
                    NULL::jsonb AS value_json,
                    'GOOD'::point_quality AS quality
                FROM point_values
                WHERE point_id = $1 AND ts >= $2 AND ts <= $3
                GROUP BY point_id, time_bucket('1 day', ts)
                ORDER BY ts"#,
            )
            .bind(point_id)
            .bind(start)
            .bind(end)
            .fetch_all(&pool)
            .await
            .map_err(internal_error)?
        }
        _ => {
            // raw
            sqlx::query_as(
                r#"SELECT point_id, ts, value_numeric, value_text, value_bool, value_json, quality
                FROM point_values
                WHERE point_id = $1 AND ts >= $2 AND ts <= $3
                ORDER BY ts LIMIT 10000"#,
            )
            .bind(point_id)
            .bind(start)
            .bind(end)
            .fetch_all(&pool)
            .await
            .map_err(internal_error)?
        }
    };

    Ok(Json(rows))
}

// ─── Alarms ──────────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct AlarmFilter {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub building_id: Option<Uuid>,
    pub state: Option<String>,
    pub severity: Option<String>,
}

pub async fn list_alarms(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<AlarmFilter>,
) -> Result<Json<ListResponse<Alarm>>, (StatusCode, Json<ErrorResponse>)> {
    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let mut where_clauses: Vec<String> = vec![];
    if params.building_id.is_some() {
        where_clauses.push(format!("building_id = ${}", where_clauses.len() + 1));
    }
    if params.state.is_some() {
        where_clauses.push(format!("state = ${}", where_clauses.len() + 1));
    }
    if params.severity.is_some() {
        where_clauses.push(format!("severity = ${}", where_clauses.len() + 1));
    }

    let where_str = if where_clauses.is_empty() {
        String::new()
    } else {
        format!("WHERE {}", where_clauses.join(" AND "))
    };

    let count_sql = format!("SELECT COUNT(*) FROM alarms {where_str}");
    let param_offset = where_clauses.len();
    let query_sql = format!(
        "SELECT * FROM alarms {where_str} ORDER BY triggered_at DESC LIMIT ${} OFFSET ${}",
        param_offset + 1,
        param_offset + 2
    );

    let mut count_q = sqlx::query_as::<_, (i64,)>(&count_sql);
    let mut data_q = sqlx::query_as::<_, Alarm>(&query_sql);

    if let Some(bid) = params.building_id {
        count_q = count_q.bind(bid);
        data_q = data_q.bind(bid);
    }
    if let Some(ref s) = params.state {
        count_q = count_q.bind(s);
        data_q = data_q.bind(s);
    }
    if let Some(ref sev) = params.severity {
        count_q = count_q.bind(sev);
        data_q = data_q.bind(sev);
    }

    let total: (i64,) = count_q.fetch_one(&pool).await.map_err(internal_error)?;
    let rows: Vec<Alarm> = data_q
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;

    Ok(Json(ListResponse {
        data: rows,
        total: total.0,
        page,
        per_page,
    }))
}

pub async fn create_alarm(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateAlarm>,
) -> Result<(StatusCode, Json<Alarm>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();

    let alarm: Alarm = sqlx::query_as(
        r#"INSERT INTO alarms (id, building_id, alarm_rule_id, point_id, equipment_id, zone_id,
            alarm_code, severity, category, state, title, description, trigger_value,
            threshold_value, triggered_at, acked_at, acked_by, ack_note, cleared_at,
            closed_at, closed_by, close_note, duration_s, escalation_level, is_suppressed,
            suppressed_by, work_order_id, repeat_count, patient_impact, affected_scope,
            metadata, created_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,
            NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,false,NULL,NULL,1,NULL,NULL,NULL,$16,$17)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.building_id)
    .bind(body.alarm_rule_id)
    .bind(body.point_id)
    .bind(body.equipment_id)
    .bind(body.zone_id)
    .bind(&body.alarm_code)
    .bind(&body.severity)
    .bind(&body.category)
    .bind(AlarmState::ActiveUnacked)
    .bind(&body.title)
    .bind(&body.description)
    .bind(&body.trigger_value)
    .bind(&body.threshold_value)
    .bind(now)
    .bind(now)
    .bind(now)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(alarm)))
}

#[derive(Debug, Deserialize)]
pub struct AckBody {
    pub acked_by: Uuid,
    pub ack_note: Option<String>,
}

pub async fn acknowledge_alarm(
    State(AppState { pool, .. }): State<AppState>,
    Path(alarm_id): Path<Uuid>,
    Json(body): Json<AckBody>,
) -> Result<Json<Alarm>, (StatusCode, Json<ErrorResponse>)> {
    let now = Utc::now();

    let alarm: Alarm = sqlx::query_as(
        r#"UPDATE alarms SET
            state = CASE
                WHEN state = 'ACTIVE_UNACKED' THEN 'ACTIVE_ACKED'::alarm_state
                WHEN state = 'CLEARED_UNACKED' THEN 'CLEARED_ACKED'::alarm_state
                ELSE state
            END,
            acked_at = $2,
            acked_by = $3,
            ack_note = $4,
            updated_at = $2
        WHERE id = $1
        RETURNING *"#,
    )
    .bind(alarm_id)
    .bind(now)
    .bind(body.acked_by)
    .bind(&body.ack_note)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok(Json(alarm))
}

#[derive(Debug, Deserialize)]
pub struct ResolveBody {
    pub closed_by: Uuid,
    pub close_note: Option<String>,
}

pub async fn resolve_alarm(
    State(AppState { pool, .. }): State<AppState>,
    Path(alarm_id): Path<Uuid>,
    Json(body): Json<ResolveBody>,
) -> Result<Json<Alarm>, (StatusCode, Json<ErrorResponse>)> {
    let now = Utc::now();

    let alarm: Alarm = sqlx::query_as(
        r#"UPDATE alarms SET
            state = 'CLOSED'::alarm_state,
            closed_at = $2,
            closed_by = $3,
            close_note = $4,
            duration_s = EXTRACT(EPOCH FROM ($2 - triggered_at))::int,
            updated_at = $2
        WHERE id = $1
        RETURNING *"#,
    )
    .bind(alarm_id)
    .bind(now)
    .bind(body.closed_by)
    .bind(&body.close_note)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok(Json(alarm))
}

// ─── Work Orders ─────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct WorkOrderFilter {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub building_id: Option<Uuid>,
    pub state: Option<String>,
}

pub async fn list_work_orders(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<WorkOrderFilter>,
) -> Result<Json<ListResponse<WorkOrder>>, (StatusCode, Json<ErrorResponse>)> {
    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let (total, rows) = if let Some(bid) = params.building_id {
        let t: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM work_orders WHERE building_id = $1")
                .bind(bid)
                .fetch_one(&pool)
                .await
                .map_err(internal_error)?;
        let r: Vec<WorkOrder> = sqlx::query_as(
            "SELECT * FROM work_orders WHERE building_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3",
        )
        .bind(bid)
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;
        (t.0, r)
    } else {
        let t: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM work_orders")
            .fetch_one(&pool)
            .await
            .map_err(internal_error)?;
        let r: Vec<WorkOrder> = sqlx::query_as(
            "SELECT * FROM work_orders ORDER BY created_at DESC LIMIT $1 OFFSET $2",
        )
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;
        (t.0, r)
    };

    Ok(Json(ListResponse {
        data: rows,
        total,
        page,
        per_page,
    }))
}

pub async fn create_work_order(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateWorkOrder>,
) -> Result<(StatusCode, Json<WorkOrder>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();

    let wo: WorkOrder = sqlx::query_as(
        r#"INSERT INTO work_orders (id, building_id, code, title, description, wo_type, priority,
            state, source, alarm_id, target_type, target_id, zone_id, requested_by,
            assigned_to, assigned_team, sla_response_min, sla_resolve_min,
            sla_response_deadline, sla_resolve_deadline, sla_response_met, sla_resolve_met,
            responded_at, started_at, completed_at, verified_at, closed_at, cancelled_at,
            resolution, root_cause, labor_hours, cost, cost_currency,
            consumed_assets, attachments, comments,
            change_type, risk_level, cab_approval, reviewer_id, reviewed_at,
            metadata, created_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,
            NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
            NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,$17,$18,$19)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.building_id)
    .bind(&body.code)
    .bind(&body.title)
    .bind(&body.description)
    .bind(&body.wo_type)
    .bind(&body.priority)
    .bind(WorkOrderStatus::Open)
    .bind(&body.source)
    .bind(body.alarm_id)
    .bind(&body.target_type)
    .bind(body.target_id)
    .bind(body.zone_id)
    .bind(body.requested_by)
    .bind(body.assigned_to)
    .bind(&body.assigned_team)
    .bind(&body.metadata)
    .bind(now)
    .bind(now)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(wo)))
}

// ─── Schedules ───────────────────────────────────────────────────────────────

pub async fn list_schedules(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<PaginationParams>,
) -> Result<Json<ListResponse<Schedule>>, (StatusCode, Json<ErrorResponse>)> {
    let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM schedules")
        .fetch_one(&pool)
        .await
        .map_err(internal_error)?;

    let rows: Vec<Schedule> =
        sqlx::query_as("SELECT * FROM schedules ORDER BY created_at DESC LIMIT $1 OFFSET $2")
            .bind(params.limit())
            .bind(params.offset())
            .fetch_all(&pool)
            .await
            .map_err(internal_error)?;

    Ok(Json(ListResponse {
        data: rows,
        total: total.0,
        page: params.page.unwrap_or(1),
        per_page: params.limit(),
    }))
}

pub async fn create_schedule(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateSchedule>,
) -> Result<(StatusCode, Json<Schedule>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();

    let sched: Schedule = sqlx::query_as(
        r#"INSERT INTO schedules (id, building_id, code, name, schedule_type, target_type,
            target_ids, target_point_id, timezone, weekly_schedule, yearly_calendar,
            exceptions, effective_from, effective_to, priority, metadata, status,
            created_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.building_id)
    .bind(&body.code)
    .bind(&body.name)
    .bind(&body.schedule_type)
    .bind(&body.target_type)
    .bind(&body.target_ids)
    .bind(body.target_point_id)
    .bind(&body.timezone)
    .bind(&body.weekly_schedule)
    .bind(&body.yearly_calendar)
    .bind(&body.exceptions)
    .bind(body.effective_from)
    .bind(body.effective_to)
    .bind(body.priority)
    .bind(&body.metadata)
    .bind(EntityStatus::Active)
    .bind(now)
    .bind(now)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(sched)))
}

// ─── Tenants ─────────────────────────────────────────────────────────────────

pub async fn list_tenants(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<PaginationParams>,
) -> Result<Json<ListResponse<Tenant>>, (StatusCode, Json<ErrorResponse>)> {
    let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM tenants")
        .fetch_one(&pool)
        .await
        .map_err(internal_error)?;

    let rows: Vec<Tenant> =
        sqlx::query_as("SELECT * FROM tenants ORDER BY created_at DESC LIMIT $1 OFFSET $2")
            .bind(params.limit())
            .bind(params.offset())
            .fetch_all(&pool)
            .await
            .map_err(internal_error)?;

    Ok(Json(ListResponse {
        data: rows,
        total: total.0,
        page: params.page.unwrap_or(1),
        per_page: params.limit(),
    }))
}

pub async fn create_tenant(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateTenant>,
) -> Result<(StatusCode, Json<Tenant>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();

    let tenant: Tenant = sqlx::query_as(
        r#"INSERT INTO tenants (id, org_id, name, tenant_type, contact_name, contact_phone,
            contact_email, lease_start, lease_end, metadata, status, created_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,NULL,NULL,$8,$9,$10,$11)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.org_id)
    .bind(&body.name)
    .bind(&body.tenant_type)
    .bind(&body.contact_name)
    .bind(&body.contact_phone)
    .bind(&body.contact_email)
    .bind(&body.metadata)
    .bind(TenantStatus::Active)
    .bind(now)
    .bind(now)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(tenant)))
}

// ─── Sites ───────────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct SiteFilter {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub org_id: Option<Uuid>,
}

pub async fn list_sites(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<SiteFilter>,
) -> Result<Json<ListResponse<Site>>, (StatusCode, Json<ErrorResponse>)> {
    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let (total, rows) = if let Some(org_id) = params.org_id {
        let t: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM sites WHERE org_id = $1")
            .bind(org_id)
            .fetch_one(&pool)
            .await
            .map_err(internal_error)?;
        let r: Vec<Site> = sqlx::query_as(
            "SELECT * FROM sites WHERE org_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3",
        )
        .bind(org_id)
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;
        (t.0, r)
    } else {
        let t: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM sites")
            .fetch_one(&pool)
            .await
            .map_err(internal_error)?;
        let r: Vec<Site> = sqlx::query_as(
            "SELECT * FROM sites ORDER BY created_at DESC LIMIT $1 OFFSET $2",
        )
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;
        (t.0, r)
    };

    Ok(Json(ListResponse {
        data: rows,
        total,
        page,
        per_page,
    }))
}

pub async fn create_site(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateSite>,
) -> Result<(StatusCode, Json<Site>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();
    let creator = Uuid::nil();

    let site: Site = sqlx::query_as(
        r#"INSERT INTO sites (id, org_id, code, name, name_en, address, city, province, country,
            postal_code, latitude, longitude, altitude, timezone, climate_zone, total_area,
            metadata, status, created_at, updated_at, created_by, updated_by)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,NULL,$13,$14,$15,$16,$17,$18,$19,$20,$21)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.org_id)
    .bind(&body.code)
    .bind(&body.name)
    .bind(&body.name_en)
    .bind(&body.address)
    .bind(&body.city)
    .bind(&body.province)
    .bind(&body.country)
    .bind(&body.postal_code)
    .bind(body.latitude)
    .bind(body.longitude)
    .bind(&body.timezone)
    .bind(&body.climate_zone)
    .bind(body.total_area)
    .bind(&body.metadata)
    .bind(EntityStatus::Active)
    .bind(now)
    .bind(now)
    .bind(creator)
    .bind(creator)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(site)))
}

// ─── Floors ──────────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct FloorFilter {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub building_id: Option<Uuid>,
}

pub async fn list_floors(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<FloorFilter>,
) -> Result<Json<ListResponse<Floor>>, (StatusCode, Json<ErrorResponse>)> {
    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let (total, rows) = if let Some(building_id) = params.building_id {
        let t: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM floors WHERE building_id = $1")
                .bind(building_id)
                .fetch_one(&pool)
                .await
                .map_err(internal_error)?;
        let r: Vec<Floor> = sqlx::query_as(
            "SELECT * FROM floors WHERE building_id = $1 ORDER BY sort_order ASC LIMIT $2 OFFSET $3",
        )
        .bind(building_id)
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;
        (t.0, r)
    } else {
        let t: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM floors")
            .fetch_one(&pool)
            .await
            .map_err(internal_error)?;
        let r: Vec<Floor> = sqlx::query_as(
            "SELECT * FROM floors ORDER BY created_at DESC LIMIT $1 OFFSET $2",
        )
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;
        (t.0, r)
    };

    Ok(Json(ListResponse {
        data: rows,
        total,
        page,
        per_page,
    }))
}

pub async fn create_floor(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateFloor>,
) -> Result<(StatusCode, Json<Floor>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();

    let floor: Floor = sqlx::query_as(
        r#"INSERT INTO floors (id, building_id, code, name, sort_order, elevation, floor_height,
            gross_area, usable_area, is_underground, floor_type, metadata, status, created_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NULL,$11,$12,$13,$14)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.building_id)
    .bind(&body.code)
    .bind(&body.name)
    .bind(body.sort_order)
    .bind(body.elevation)
    .bind(body.floor_height)
    .bind(body.gross_area)
    .bind(body.usable_area)
    .bind(body.is_underground)
    .bind(&body.metadata)
    .bind(EntityStatus::Active)
    .bind(now)
    .bind(now)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(floor)))
}

// ─── Systems ─────────────────────────────────────────────────────────────────

#[derive(Debug, Deserialize)]
pub struct SystemFilter {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
    pub building_id: Option<Uuid>,
}

pub async fn list_systems(
    State(AppState { pool, .. }): State<AppState>,
    Query(params): Query<SystemFilter>,
) -> Result<Json<ListResponse<System>>, (StatusCode, Json<ErrorResponse>)> {
    let page = params.page.unwrap_or(1).max(1);
    let per_page = params.per_page.unwrap_or(20).min(100);
    let offset = (page - 1) * per_page;

    let (total, rows) = if let Some(building_id) = params.building_id {
        let t: (i64,) =
            sqlx::query_as("SELECT COUNT(*) FROM systems WHERE building_id = $1")
                .bind(building_id)
                .fetch_one(&pool)
                .await
                .map_err(internal_error)?;
        let r: Vec<System> = sqlx::query_as(
            "SELECT * FROM systems WHERE building_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3",
        )
        .bind(building_id)
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;
        (t.0, r)
    } else {
        let t: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM systems")
            .fetch_one(&pool)
            .await
            .map_err(internal_error)?;
        let r: Vec<System> = sqlx::query_as(
            "SELECT * FROM systems ORDER BY created_at DESC LIMIT $1 OFFSET $2",
        )
        .bind(per_page)
        .bind(offset)
        .fetch_all(&pool)
        .await
        .map_err(internal_error)?;
        (t.0, r)
    };

    Ok(Json(ListResponse {
        data: rows,
        total,
        page,
        per_page,
    }))
}

pub async fn create_system(
    State(AppState { pool, .. }): State<AppState>,
    Json(body): Json<CreateSystem>,
) -> Result<(StatusCode, Json<System>), (StatusCode, Json<ErrorResponse>)> {
    let id = Uuid::new_v4();
    let now = Utc::now();

    let system: System = sqlx::query_as(
        r#"INSERT INTO systems (id, building_id, code, name, system_type, sub_type, description,
            design_capacity, commissioning_date, metadata, status, created_at, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
        RETURNING *"#,
    )
    .bind(id)
    .bind(body.building_id)
    .bind(&body.code)
    .bind(&body.name)
    .bind(&body.system_type)
    .bind(&body.sub_type)
    .bind(&body.description)
    .bind(&body.design_capacity)
    .bind(body.commissioning_date)
    .bind(&body.metadata)
    .bind(EntityStatus::Active)
    .bind(now)
    .bind(now)
    .fetch_one(&pool)
    .await
    .map_err(internal_error)?;

    Ok((StatusCode::CREATED, Json(system)))
}

// ─── GET by ID ───────────────────────────────────────────────────────────────

pub async fn get_organization(
    State(AppState { pool, .. }): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Organization>, (StatusCode, Json<ErrorResponse>)> {
    let org: Organization = sqlx::query_as("SELECT * FROM organizations WHERE id = $1")
        .bind(id)
        .fetch_optional(&pool)
        .await
        .map_err(internal_error)?
        .ok_or_else(|| {
            (
                StatusCode::NOT_FOUND,
                Json(ErrorResponse {
                    error: "Organization not found".to_string(),
                }),
            )
        })?;
    Ok(Json(org))
}

pub async fn get_building(
    State(AppState { pool, .. }): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Building>, (StatusCode, Json<ErrorResponse>)> {
    let building: Building = sqlx::query_as("SELECT * FROM buildings WHERE id = $1")
        .bind(id)
        .fetch_optional(&pool)
        .await
        .map_err(internal_error)?
        .ok_or_else(|| {
            (
                StatusCode::NOT_FOUND,
                Json(ErrorResponse {
                    error: "Building not found".to_string(),
                }),
            )
        })?;
    Ok(Json(building))
}

pub async fn get_equipment(
    State(AppState { pool, .. }): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Equipment>, (StatusCode, Json<ErrorResponse>)> {
    let equip: Equipment = sqlx::query_as("SELECT * FROM equipment WHERE id = $1")
        .bind(id)
        .fetch_optional(&pool)
        .await
        .map_err(internal_error)?
        .ok_or_else(|| {
            (
                StatusCode::NOT_FOUND,
                Json(ErrorResponse {
                    error: "Equipment not found".to_string(),
                }),
            )
        })?;
    Ok(Json(equip))
}

pub async fn get_point(
    State(AppState { pool, .. }): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Point>, (StatusCode, Json<ErrorResponse>)> {
    let point: Point = sqlx::query_as("SELECT * FROM points WHERE id = $1")
        .bind(id)
        .fetch_optional(&pool)
        .await
        .map_err(internal_error)?
        .ok_or_else(|| {
            (
                StatusCode::NOT_FOUND,
                Json(ErrorResponse {
                    error: "Point not found".to_string(),
                }),
            )
        })?;
    Ok(Json(point))
}

pub async fn get_alarm(
    State(AppState { pool, .. }): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Alarm>, (StatusCode, Json<ErrorResponse>)> {
    let alarm: Alarm = sqlx::query_as("SELECT * FROM alarms WHERE id = $1")
        .bind(id)
        .fetch_optional(&pool)
        .await
        .map_err(internal_error)?
        .ok_or_else(|| {
            (
                StatusCode::NOT_FOUND,
                Json(ErrorResponse {
                    error: "Alarm not found".to_string(),
                }),
            )
        })?;
    Ok(Json(alarm))
}

// ─── Soft DELETE ─────────────────────────────────────────────────────────────

pub async fn delete_building(
    State(AppState { pool, .. }): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, Json<ErrorResponse>)> {
    let result = sqlx::query("UPDATE buildings SET status = 'DELETED' WHERE id = $1")
        .bind(id)
        .execute(&pool)
        .await
        .map_err(internal_error)?;

    if result.rows_affected() == 0 {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "Building not found".to_string(),
            }),
        ));
    }
    Ok(StatusCode::NO_CONTENT)
}

pub async fn delete_equipment(
    State(AppState { pool, .. }): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, Json<ErrorResponse>)> {
    let result = sqlx::query("UPDATE equipment SET status = 'DELETED' WHERE id = $1")
        .bind(id)
        .execute(&pool)
        .await
        .map_err(internal_error)?;

    if result.rows_affected() == 0 {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "Equipment not found".to_string(),
            }),
        ));
    }
    Ok(StatusCode::NO_CONTENT)
}

pub async fn delete_point(
    State(AppState { pool, .. }): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, (StatusCode, Json<ErrorResponse>)> {
    let result = sqlx::query("UPDATE points SET status = 'DELETED' WHERE id = $1")
        .bind(id)
        .execute(&pool)
        .await
        .map_err(internal_error)?;

    if result.rows_affected() == 0 {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                error: "Point not found".to_string(),
            }),
        ));
    }
    Ok(StatusCode::NO_CONTENT)
}

// ─── WebSocket ───────────────────────────────────────────────────────────────

pub async fn ws_points_handler(
    State(state): State<AppState>,
    ws: WebSocketUpgrade,
) -> impl IntoResponse {
    let rx = state.broadcast_tx.subscribe();
    ws.on_upgrade(move |socket| handle_ws_connection(socket, rx))
}

async fn handle_ws_connection(
    mut socket: WebSocket,
    mut rx: tokio::sync::broadcast::Receiver<String>,
) {
    // Send a welcome message
    if socket
        .send(Message::Text(
            serde_json::json!({"type": "connected", "message": "Subscribed to point updates"})
                .to_string()
                .into(),
        ))
        .await
        .is_err()
    {
        return;
    }

    loop {
        tokio::select! {
            // Forward broadcast messages to the WebSocket client
            result = rx.recv() => {
                match result {
                    Ok(msg) => {
                        if socket.send(Message::Text(msg.into())).await.is_err() {
                            break;
                        }
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(n)) => {
                        tracing::warn!("WebSocket client lagged, skipped {n} messages");
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Closed) => {
                        break;
                    }
                }
            }
            // Handle incoming messages from the WebSocket client
            msg = socket.recv() => {
                match msg {
                    Some(Ok(Message::Text(text))) => {
                        let ack = serde_json::json!({
                            "type": "ack",
                            "message": text.to_string()
                        });
                        if socket.send(Message::Text(ack.to_string().into())).await.is_err() {
                            break;
                        }
                    }
                    Some(Ok(Message::Close(_))) | None | Some(Err(_)) => break,
                    _ => {}
                }
            }
        }
    }
}
