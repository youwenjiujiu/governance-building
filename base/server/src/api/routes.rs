use axum::routing::{get, patch};
use axum::Router;
use sqlx::PgPool;

use super::handlers;

pub fn create_router(pool: PgPool) -> Router {
    Router::new()
        // Organizations
        .route(
            "/api/v1/organizations",
            get(handlers::list_organizations).post(handlers::create_organization),
        )
        // Buildings
        .route(
            "/api/v1/buildings",
            get(handlers::list_buildings).post(handlers::create_building),
        )
        // Zones
        .route(
            "/api/v1/zones",
            get(handlers::list_zones).post(handlers::create_zone),
        )
        // Equipment
        .route(
            "/api/v1/equipment",
            get(handlers::list_equipment).post(handlers::create_equipment),
        )
        // Points
        .route(
            "/api/v1/points",
            get(handlers::list_points).post(handlers::create_point),
        )
        // Point values (time series)
        .route(
            "/api/v1/points/:id/values",
            get(handlers::get_point_values),
        )
        // Alarms
        .route(
            "/api/v1/alarms",
            get(handlers::list_alarms).post(handlers::create_alarm),
        )
        .route(
            "/api/v1/alarms/:id/acknowledge",
            patch(handlers::acknowledge_alarm),
        )
        .route(
            "/api/v1/alarms/:id/resolve",
            patch(handlers::resolve_alarm),
        )
        // Work Orders
        .route(
            "/api/v1/work-orders",
            get(handlers::list_work_orders).post(handlers::create_work_order),
        )
        // Schedules
        .route(
            "/api/v1/schedules",
            get(handlers::list_schedules).post(handlers::create_schedule),
        )
        // Tenants
        .route(
            "/api/v1/tenants",
            get(handlers::list_tenants).post(handlers::create_tenant),
        )
        // WebSocket for real-time point updates
        .route("/ws/points", get(handlers::ws_points_handler))
        .with_state(pool)
}
