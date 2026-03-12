use chrono::Utc;
use rumqttc::{AsyncClient, Event, MqttOptions, Packet, QoS};
use sqlx::PgPool;
use uuid::Uuid;

use crate::alarm::AlarmEngine;

/// Start the MQTT client that subscribes to building point topics,
/// writes incoming values to the `point_values` table, and checks alarm rules.
pub async fn start_mqtt_client(
    pool: PgPool,
    host: &str,
    port: u16,
    alarm_engine: AlarmEngine,
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
                    r#"INSERT INTO point_values (point_id, ts, value_float, value_string, quality)
                    VALUES ($1, $2, $3, $4, 'good')"#,
                )
                .bind(point_id)
                .bind(now)
                .bind(value_float)
                .bind(&payload)
                .execute(&pool)
                .await;

                if let Err(e) = insert_result {
                    tracing::error!("Failed to insert point value: {e}");
                    continue;
                }

                // Update current value cache on the point record
                let _ = sqlx::query(
                    r#"UPDATE points SET current_value = $1, current_timestamp = $2,
                        current_quality = 'good' WHERE id = $3"#,
                )
                .bind(&payload)
                .bind(now)
                .bind(point_id)
                .execute(&pool)
                .await;

                // Check alarm rules
                if let Some(val) = value_float {
                    if let Err(e) = alarm_engine.check_point(point_id, val, &pool).await {
                        tracing::error!("Alarm check failed for point {point_id}: {e}");
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
