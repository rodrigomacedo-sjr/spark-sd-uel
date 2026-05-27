#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Uso: scripts/run_distributed_worker.sh <IP_DO_PC_1>"
  exit 1
fi

cd "$(dirname "$0")/.."

MASTER_IP="$1"

mkdir -p output
chmod 777 output

docker pull apache/spark-py@sha256:bec1fed7818dd775c8a88224d5b2550c9a85ff81860f76b44e5357abdd849bb5
docker rm -f climate-spark-worker-lan >/dev/null 2>&1 || true
docker run -d \
  --network host \
  --user root \
  --name climate-spark-worker-lan \
  -v "$PWD:/app" \
  -w /app \
  apache/spark-py@sha256:bec1fed7818dd775c8a88224d5b2550c9a85ff81860f76b44e5357abdd849bb5 \
  /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker "spark://$MASTER_IP:7077" --cores 2 --memory 2G --work-dir /tmp/spark-worker

echo "Worker conectado em spark://$MASTER_IP:7077"
echo "Veja no PC 1: http://$MASTER_IP:8080"
