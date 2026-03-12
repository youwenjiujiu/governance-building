use chrono::Utc;
use rumqttc::{AsyncClient, Event, MqttOptions, Packet, QoS};
use sqlx::PgPool;
use tokio::sync::broadcast;
use uuid::Uuid;

use crate::alarm::AlarmEngine;
use crate::models::enums::PointQuality;

/// Start the MQTT client that subscribes to building point topics,
/// writes incoming values to the `point_values` table, checks alarm rules,
/// and broadcasts point updates and alarm events to WebSocket clients.
pub async fn start_mqtt_client(
    pool: PgPool,
    host: &str,
    port: u16,
    alarm_engine: AlarmEngine,
    broadcast_tx: broadcast::Sender<String>,
) {
    let client_id = format!("governance-base-{}", Uuid::new_v4());
    let mut mqttoptions = MqttOptions::new(&client_id, host, port);
    mqttoptions.set_keep_alive(std::time::Duration::from_secs(30));
    mqttoptions.set_clean_session(true);

    let (client, mut eventloop) = AsyncClient::new(mqttoptions, 256);

    // Subscribe to the point data topic: building/+/point/+
    if let Err(e) = client
        .subscribe("building/+/point/+", QoS::AtLeastOnce)
        .await
    {
        tracing::error!("Failed to subscribe to MQTT topic: {e}");
        return;
    }

    tracing::info!("MQTT client connected, subscribed to building/+/point/+");

    loop {
        match eventloop.poll().await {
            Ok(Event::Incoming(Packet::Publish(publish))) => {
                let topic = &publish.topic;
                let payload = match std::str::from_utf8(&publish.payload) {
                    Ok(s) => s.to_string(),
                    Err(_) => {
                        tracing::warn!("Non-UTF8 MQTT payload on topic {topic}");
                        continue;
                    }
                };

                // Parse topic: building/{building_id}/point/{point_id}
                let parts: Vec<&str> = topic.split('/').collect();
                if parts.len() != 4 {
                    tracing::warn!("Unexpected MQTT topic format: {topic}");
                    continue;
                }

                let point_id = match Uuid::parse_str(parts[3]) {
                    Ok(id) => id,
                    Err(_) => {
                        tracing::warn!("Invalid point_id in topic: {}", parts[3]);
                        continue;
                    }
                };

                // Try to parse value as float for storage and alarm checking
                let value_float: Option<f64> = payload.trim().parse().ok();
                let now = Utc::now();

                // Write to point_values table
                let insert_result = sqlx::query(
                    r#"INSERT INTO point_values (point_id, ts, value_numeric, value_text, quality)
                    VALUES ($1, $2, $3, $4, $5)"#,
                )
                .bind(point_id)
                .bind(now)
                .bind(value_float)
                .bind(&payload)
                .bind(PointQuality::Good)
                .execute(&pool)
                .await;

                if let Err(e) = insert_result {
                    tracing::error!("Failed to insert point value: {e}");
                    continue;
                }

                // Update current value cache on the point record
                let _ = sqlx::query(
                    r#"UPDATE points SET current_value = $1, value_timestamp = $2,
                        current_quality = $3 WHERE id = $4"#,
                )
                .bind(&payload)
                .bind(now)
                .bind(PointQuality::Good)
                .bind(point_id)
                .execute(&pool)
                .await;

                // Broadcast point update to WebSocket clients
                let point_update = serde_json::json!({
                    "type": "point_update",
                    "point_id": point_id.to_string(),
                    "value": &payload,
                    "value_float": value_float,
                    "ts": now.to_rfc3339(),
                    "quality": "good"
                });
                // Ignore send errors (no active receivers is fine)
                let _ = broadcast_tx.send(point_update.to_string());

                // Check alarm rules
                if let Some(val) = value_float {
                    match alarm_engine.check_point(point_id, val, &pool).await {
                        Ok(Some(alarm_event)) => {
                            // Broadcast alarm event to WebSocket clients
                            let alarm_msg = serde_json::json!({
                                "type": "alarm",
                                "alarm_code": alarm_event.alarm_code,
                                "point_id": alarm_event.point_id.to_string(),
                                "severity": alarm_event.severity,
                                "title": alarm_event.title,
                            });
                            let _ = broadcast_tx.send(alarm_msg.to_string());
                        }
                        Ok(None) => {}
                        Err(e) => {
                            tracing::error!("Alarm check failed for point {point_id}: {e}");
                        }
                    }
                }

                tracing::debug!("Processed point {point_id} = {payload}");
            }
            Ok(_) => {}
            Err(e) => {
                tracing::error!("MQTT connection error: {e}");
                // Reconnect after a brief delay
                tokio::time::sleep(std::time::Duration::from_secs(5)).await;
            }
        }
    }
}
