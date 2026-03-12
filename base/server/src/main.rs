use governance_base::alarm::AlarmEngine;
use governance_base::api::{create_router, AppState};
use governance_base::config::AppConfig;
use governance_base::db::create_pool;
use governance_base::mqtt::start_mqtt_client;
use tokio::net::TcpListener;
use tokio::signal;
use tokio::sync::broadcast;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "governance_base=info,tower_http=info".into()),
        )
        .init();

    // Load configuration
    let config = AppConfig::from_env();
    tracing::info!("Starting governance-base server on port {}", config.server_port);

    // Create database connection pool
    let pool = create_pool(&config.database_url).await;
    tracing::info!("Database connection pool created");

    // Create broadcast channel for real-time point updates (MQTT → WebSocket)
    let (broadcast_tx, _) = broadcast::channel::<String>(1024);

    // Create alarm engine with 5-minute suppression window
    let alarm_engine = AlarmEngine::new(300);

    // Start MQTT client in background
    let mqtt_pool = pool.clone();
    let mqtt_host = config.mqtt_host.clone();
    let mqtt_port = config.mqtt_port;
    let mqtt_alarm_engine = alarm_engine.clone();
    let mqtt_broadcast_tx = broadcast_tx.clone();
    tokio::spawn(async move {
        start_mqtt_client(mqtt_pool, &mqtt_host, mqtt_port, mqtt_alarm_engine, mqtt_broadcast_tx).await;
    });
    tracing::info!("MQTT client started in background");

    // Build the Axum router
    let state = AppState { pool, broadcast_tx };
    let app = create_router(state)
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http());

    // Start the HTTP server
    let addr = format!("0.0.0.0:{}", config.server_port);
    let listener = TcpListener::bind(&addr)
        .await
        .expect("Failed to bind TCP listener");
    tracing::info!("HTTP server listening on {addr}");

    // Serve with graceful shutdown
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .expect("Server error");

    tracing::info!("Server shut down gracefully");
}

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("Failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("Failed to install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => tracing::info!("Received Ctrl+C, shutting down..."),
        _ = terminate => tracing::info!("Received SIGTERM, shutting down..."),
    }
}
