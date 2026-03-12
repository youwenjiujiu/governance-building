use axum::extract::FromRef;
use sqlx::PgPool;
use tokio::sync::broadcast;

/// Shared application state passed to all Axum handlers.
#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub broadcast_tx: broadcast::Sender<String>,
}

impl FromRef<AppState> for PgPool {
    fn from_ref(state: &AppState) -> Self {
        state.pool.clone()
    }
}
