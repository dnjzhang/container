# Repository Guidelines

## Project Structure & Module Organization
- `Dockerfile-grafana` defines the Grafana Enterprise image build based on `ol8-cli`.
- `provisioning/datasources/prometheus.yaml` contains the baked-in Prometheus datasource.
- `grafana-enterprise.tar.gz` is the required Grafana Enterprise arm64 tarball input.

## Build, Test, and Development Commands
Run from the repository root.
- Download the tarball (update the version as needed):
  ```bash
  GRAFANA_VERSION=10.4.5
  curl -L -o grafana-enterprise.tar.gz \
    "https://dl.grafana.com/enterprise/release/grafana-enterprise-${GRAFANA_VERSION}.linux-arm64.tar.gz"
  ```
- Build the image:
  ```bash
  docker build -f Dockerfile-grafana -t grafana-ol8:10.4.5 .
  ```
- Run Grafana locally:
  ```bash
  docker run --rm -p 3000:3000 grafana-ol8:10.4.5
  ```
- Optional: run with Prometheus on a shared network:
  ```bash
  docker network create monitoring
  docker run -d --name prometheus --network monitoring -p 9090:9090 prom/prometheus:latest
  docker run --rm --name grafana --network monitoring -p 3000:3000 grafana-ol8:10.4.5
  ```

## Coding Style & Naming Conventions
- YAML in `provisioning/` uses 2-space indentation; keep keys lowercase where Grafana expects it.
- Datasource files follow `provisioning/datasources/<name>.yaml` with a Title Case `name:` value.
- Image tags follow `grafana-ol8:<grafana-version>`.

## Testing Guidelines
- No automated tests are included in this repository.
- Manual check: build the image, run the container, log in at `http://localhost:3000` with `admin/admin`, and verify the Prometheus datasource if you use the `monitoring` network.

## Commit & Pull Request Guidelines
- No `.git` history is present in this directory, so commit conventions are unknown.
- If you open a PR, include the Grafana version you updated, the image tag used, and the commands you ran. Keep tarball and provisioning changes in sync with README instructions.

## Configuration & Security Tips
- The Enterprise tarball is a licensed artifact; avoid committing additional binaries unless required.
- Keep provisioning files free of secrets; use environment variables or external configs for credentials.
