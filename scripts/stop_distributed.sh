#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

docker rm -f climate-spark-master-lan climate-spark-worker-lan >/dev/null 2>&1 || true
docker compose down >/dev/null 2>&1 || true
echo "Containers Spark parados."
