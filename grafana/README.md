# Grafana Enterprise on Oracle Linux 8 (arm64)

This directory contains a Grafana Enterprise container build based on the `ol8-cli` image.

## Prerequisites

- Docker Desktop for Mac
- `ol8-cli` image available locally (`docker images | grep ol8-cli`)

## Select Grafana Enterprise RPM (ARM64)

Use the Grafana download page to pick the Enterprise Linux ARM64 RPM and note
the version/build number. The Dockerfile downloads the RPM via `dnf` using the
pattern below.

Example values:

```bash
GRAFANA_VERSION=12.3.1
GRAFANA_BUILD=20271043721
GRAFANA_ARCH=arm64
```

Use `arm64` for `aarch64` containers. For `x86_64`, set `GRAFANA_ARCH=amd64`
and pick the matching Linux RPM from the download page.

## Build the image

```bash
docker build -f grafana/Dockerfile-grafana \
  --build-arg GRAFANA_VERSION=${GRAFANA_VERSION} \
  --build-arg GRAFANA_BUILD=${GRAFANA_BUILD} \
  --build-arg GRAFANA_ARCH=${GRAFANA_ARCH} \
  -t grafana-ol8:${GRAFANA_VERSION} grafana
```

## Run Grafana

```bash
docker run --rm -p 3000:3000 grafana-ol8:${GRAFANA_VERSION}
```

Open `http://localhost:3000` and log in with `admin` / `admin`.

## Docker Compose (Grafana + Prometheus + OTel Collector)

The `compose.yaml` file starts Grafana, Prometheus, and an OTel Collector that
exports metrics for Prometheus to scrape. The compose file expects a local
image tag of `grafana-ol8:latest`, so build it with that tag first:

```bash
docker build -f Dockerfile-grafana -t grafana-ol8:latest .
```

Start the stack:

```bash
docker compose up -d
```

Stop and remove containers, networks, and volumes:

```bash
docker compose down
```

The compose file uses internal-only `expose` ports. If you want to access the
Grafana or Prometheus UI from the host, add `ports` mappings to `compose.yaml`
and restart the stack.

## Connect to Prometheus (manual)

Run Prometheus and Grafana on the same Docker network so Grafana can reach it by
container name.

```bash
docker network create monitoring

docker run -d --name prometheus --network monitoring -p 9090:9090 \
  prom/prometheus:latest

docker run --rm --name grafana --network monitoring -p 3000:3000 \
  grafana-ol8:${GRAFANA_VERSION}
```

In Grafana, add a Prometheus data source with URL `http://prometheus:9090`.

## Prometheus provisioning (baked in)

This image includes a provisioning file at
`grafana/provisioning/datasources/prometheus.yaml` that pre-configures a
Prometheus data source pointing to `http://prometheus:9090`.

If you want a different URL or name, edit that file and rebuild the image.
