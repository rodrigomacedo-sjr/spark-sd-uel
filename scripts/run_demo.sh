#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p output
chmod 777 output

docker compose up -d --build spark-master spark-worker-1 spark-worker-2
docker compose run --rm -e MPLCONFIGDIR=/tmp/matplotlib spark-app /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  /app/src/climate_spark/main.py \
  --mode sample \
  --cache on \
  --master spark://spark-master:7077 \
  --output /app/output

echo "Resultados: output/"
echo "Spark UI: http://localhost:18080"
