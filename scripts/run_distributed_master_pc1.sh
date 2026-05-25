#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

docker build -t climate-spark:local .
docker rm -f climate-spark-master-lan >/dev/null 2>&1 || true
docker run -d \
  --name climate-spark-master-lan \
  -p 7077:7077 \
  -p 8080:8080 \
  climate-spark:local \
  /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master --host 0.0.0.0

IP="$(hostname -I | awk '{print $1}')"
echo "Master iniciado."
echo "Passe este IP para o PC 2: $IP"
echo "Spark master URL: spark://$IP:7077"
echo "Spark UI: http://$IP:8080"
