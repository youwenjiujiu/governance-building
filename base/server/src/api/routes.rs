use axum::routing::{get, patch};
use axum::Router;

use super::handlers;
use super::state::AppState;

pub fn create_router(state: AppState) -> Router {
    Router::new()
        // Organizations
        .route(
            "/api/v1/organizations",
            get(handlers::list_organizations).post(handlers::create_organization),
        )
        .route(
            "/api/v1/organizations/{id}",
            get(handlers::get_organization),
        )
        // Sites
        .route(
            "/api/v1/sites",
            get(handlers::list_sites).post(handlers::create_site),
        )
        // Buildings
        .route(
            "/api/v1/buildings",
            get(handlers::list_buildings).post(handlers::create_building),
        )
        .route(
            "/api/v1/buildings/{id}",
            get(handlers::get_building).delete(handlers::delete_building),
        )
        // Floors
        .route(
            "/api/v1/floors",
            get(handlers::list_floors).post(handlers::create_floor),
        )
        // Systems
        .route(
            "/api/v1/systems",
            get(handlers::list_systems).post(handlers::create_system),
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
        .route(
            "/api/v1/equipment/{id}",
            get(handlers::get_equipment).delete(handlers::delete_equipment),
        )
        // Points
        .route(
            "/api/v1/points",
            get(handlers::list_points).post(handlers::create_point),
        )
        .route(
            "/api/v1/points/{id}",
            get(handlers::get_point).delete(handlers::delete_point),
        )
        // Point values (time series)
        .route(
            "/api/v1/points/{id}/values",
            get(handlers::get_point_values),
        )
        // Alarms
        .route(
            "/api/v1/alarms",
            get(handlers::list_alarms).post(handlers::create_alarm),
        )
        .route("/api/v1/alarms/{id}", get(handlers::get_alarm))
        .route(
            "/api/v1/alarms/{id}/acknowledge",
            patch(handlers::acknowledge_alarm),
        )
        .route(
            "/api/v1/alarms/{id}/resolve",
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
        .with_state(state)
}
