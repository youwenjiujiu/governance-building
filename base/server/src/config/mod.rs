use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
pub struct AppConfig {
    pub database_url: String,
    pub mqtt_host: String,
    pub mqtt_port: u16,
    pub server_port: u16,
}

impl AppConfig {
    pub fn from_env() -> Self {
        dotenvy::dotenv().ok();

        Self {
            database_url: std::env::var("DATABASE_URL")
                .unwrap_or_else(|_| "postgres://localhost:5432/governance".to_string()),
            mqtt_host: std::env::var("MQTT_HOST").unwrap_or_else(|_| "localhost".to_string()),
            mqtt_port: std::env::var("MQTT_PORT")
                .ok()
                .and_then(|p| p.parse().ok())
                .unwrap_or(1883),
            server_port: std::env::var("SERVER_PORT")
                .ok()
                .and_then(|p| p.parse().ok())
                .unwrap_or(3000),
        }
    }
}
