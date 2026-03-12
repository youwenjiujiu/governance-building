# Stage 1: Build the Rust binary
FROM rust:1.88-slim AS builder

RUN apt-get update && apt-get install -y \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src/ src/

RUN cargo build --release

# Stage 2: Minimal runtime image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/governance-base /usr/local/bin/governance-base

EXPOSE 3001

ENV DATABASE_URL=postgres://postgres:postgres@timescaledb:5432/governance_building
ENV MQTT_HOST=mosquitto
ENV MQTT_PORT=1883
ENV SERVER_PORT=3001

CMD ["governance-base"]
