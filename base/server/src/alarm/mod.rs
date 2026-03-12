use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::enums::{AlarmCategory, AlarmSeverity, AlarmState};

/// Holds alarm engine state, including suppression tracking.
#[derive(Debug, Clone)]
pub struct AlarmEngine {
    /// Minimum seconds between repeated alarms for the same point
    pub suppression_window_s: i64,
}

impl AlarmEngine {
    pub fn new(suppression_window_s: i64) -> Self {
        Self {
            suppression_window_s,
        }
    }

    /// Check a point's current value against its alarm thresholds.
    /// If a threshold is breached, create or update an alarm record.
    /// If the value returns to normal, auto-resolve any active alarm.
    pub async fn check_point(
        &self,
        point_id: Uuid,
        value: f64,
        pool: &PgPool,
    ) -> Result<(), sqlx::Error> {
        // Fetch the point's alarm configuration
        let point_row: Option<PointAlarmConfig> = sqlx::query_as(
            r#"SELECT id, building_id, equipment_id, zone_id, code, name,
                alarm_enabled, alarm_hi_hi, alarm_hi, alarm_lo, alarm_lo_lo,
                alarm_deadband, alarm_delay_s
            FROM points WHERE id = $1"#,
        )
        .bind(point_id)
        .fetch_optional(pool)
        .await?;

        let point = match point_row {
            Some(p) if p.alarm_enabled => p,
            _ => return Ok(()), // alarm not enabled or point not found
        };

        let deadband = point.alarm_deadband.unwrap_or(0.0);

        // Determine alarm severity based on thresholds
        let alarm_info = if let Some(hi_hi) = point.alarm_hi_hi {
            if value >= hi_hi {
                Some((AlarmSeverity::Critical, "hi_hi", hi_hi))
            } else {
                None
            }
        } else {
            None
        }
        .or_else(|| {
            point
                .alarm_hi
                .filter(|&hi| value >= hi)
                .map(|hi| (AlarmSeverity::Major, "hi", hi))
        })
        .or_else(|| {
            point
                .alarm_lo_lo
                .filter(|&lo_lo| value <= lo_lo)
                .map(|lo_lo| (AlarmSeverity::Critical, "lo_lo", lo_lo))
        })
        .or_else(|| {
            point
                .alarm_lo
                .filter(|&lo| value <= lo)
                .map(|lo| (AlarmSeverity::Major, "lo", lo))
        });

        // Check for existing active alarm on this point
        let existing_alarm: Option<ExistingAlarm> = sqlx::query_as(
            r#"SELECT id, state, triggered_at FROM alarms
            WHERE point_id = $1 AND state IN ('active_unacked', 'active_acked')
            ORDER BY triggered_at DESC LIMIT 1"#,
        )
        .bind(point_id)
        .fetch_optional(pool)
        .await?;

        let now = Utc::now();

        match (alarm_info, existing_alarm) {
            // Threshold breached and no active alarm -> create new alarm (with suppression check)
            (Some((severity, alarm_type, threshold)), None) => {
                // Check suppression: was there a recently closed alarm for this point?
                let recent: Option<(Uuid,)> = sqlx::query_as(
                    r#"SELECT id FROM alarms
                    WHERE point_id = $1 AND closed_at IS NOT NULL
                        AND closed_at > $2
                    LIMIT 1"#,
                )
                .bind(point_id)
                .bind(now - chrono::Duration::seconds(self.suppression_window_s))
                .fetch_optional(pool)
                .await?;

                if recent.is_some() {
                    tracing::debug!(
                        "Alarm suppressed for point {point_id}: within suppression window"
                    );
                    return Ok(());
                }

                let alarm_id = Uuid::new_v4();
                let alarm_code = format!("ALM-{}-{}", point.code, alarm_type.to_uppercase());
                let title = format!("{} - {} alarm (value: {value}, threshold: {threshold})", point.name, alarm_type);

                sqlx::query(
                    r#"INSERT INTO alarms (id, building_id, point_id, equipment_id, zone_id,
                        alarm_code, severity, category, state, title, description,
                        trigger_value, threshold_value, triggered_at, escalation_level,
                        is_suppressed, repeat_count, metadata, created_at, updated_at)
                    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,0,false,1,NULL,$15,$16)"#,
                )
                .bind(alarm_id)
                .bind(point.building_id)
                .bind(point_id)
                .bind(point.equipment_id)
                .bind(point.zone_id)
                .bind(&alarm_code)
                .bind(&severity)
                .bind(AlarmCategory::Process)
                .bind(AlarmState::ActiveUnacked)
                .bind(&title)
                .bind(format!(
                    "Point {} value {value} exceeded {alarm_type} threshold {threshold}",
                    point.code
                ))
                .bind(value.to_string())
                .bind(threshold.to_string())
                .bind(now)
                .bind(now)
                .bind(now)
                .execute(pool)
                .await?;

                tracing::info!("Created alarm {alarm_code} for point {point_id}");
            }

            // Threshold still breached and active alarm exists -> update repeat count
            (Some(_), Some(existing)) => {
                sqlx::query(
                    r#"UPDATE alarms SET
                        repeat_count = COALESCE(repeat_count, 0) + 1,
                        trigger_value = $2,
                        updated_at = $3
                    WHERE id = $1"#,
                )
                .bind(existing.id)
                .bind(value.to_string())
                .bind(now)
                .execute(pool)
                .await?;
            }

            // Value returned to normal with deadband and there is an active alarm -> auto-resolve
            (None, Some(existing)) => {
                // Verify the value is truly back in normal range (with deadband)
                let within_normal = point
                    .alarm_hi
                    .map_or(true, |hi| value < hi - deadband)
                    && point
                        .alarm_lo
                        .map_or(true, |lo| value > lo + deadband);

                if within_normal {
                    sqlx::query(
                        r#"UPDATE alarms SET
                            state = CASE
                                WHEN state = 'active_unacked' THEN 'cleared_unacked'::alarm_state
                                WHEN state = 'active_acked' THEN 'cleared_acked'::alarm_state
                                ELSE state
                            END,
                            cleared_at = $2,
                            duration_s = EXTRACT(EPOCH FROM ($2 - triggered_at))::int,
                            updated_at = $2
                        WHERE id = $1"#,
                    )
                    .bind(existing.id)
                    .bind(now)
                    .execute(pool)
                    .await?;

                    tracing::info!("Auto-cleared alarm {} for point {point_id}", existing.id);
                }
            }

            // No alarm condition, no existing alarm -> nothing to do
            (None, None) => {}
        }

        Ok(())
    }
}

// ─── Internal query structs ──────────────────────────────────────────────────

#[derive(Debug, sqlx::FromRow)]
#[allow(dead_code)]
struct PointAlarmConfig {
    pub id: Uuid,
    pub building_id: Uuid,
    pub equipment_id: Option<Uuid>,
    pub zone_id: Option<Uuid>,
    pub code: String,
    pub name: String,
    pub alarm_enabled: bool,
    pub alarm_hi_hi: Option<f64>,
    pub alarm_hi: Option<f64>,
    pub alarm_lo: Option<f64>,
    pub alarm_lo_lo: Option<f64>,
    pub alarm_deadband: Option<f64>,
    pub alarm_delay_s: Option<i32>,
}

#[derive(Debug, sqlx::FromRow)]
#[allow(dead_code)]
struct ExistingAlarm {
    pub id: Uuid,
    pub state: AlarmState,
    pub triggered_at: chrono::DateTime<chrono::Utc>,
}
