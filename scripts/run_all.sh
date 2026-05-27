#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ $# -gt 0 ]; then
  echo "run_all.sh e apenas para Docker Compose local. Para 2 PCs use scripts/run_distributed_submit_pc1.sh."
  exit 1
fi

MASTER_URL="spark://spark-master:7077"

scripts/setup_data.sh
mkdir -p output
chmod 777 output

docker compose up -d --build spark-master spark-worker-1 spark-worker-2
docker compose run --rm -e MPLCONFIGDIR=/tmp/matplotlib spark-app /opt/spark/bin/spark-submit \
  --master "$MASTER_URL" \
  /app/src/climate_spark/main.py \
  --mode raw \
  --cache on \
  --city "Rio De Janeiro" \
  --master "$MASTER_URL" \
  --output /app/output

docker compose run --rm -e MPLCONFIGDIR=/tmp/matplotlib spark-app /opt/spark/bin/spark-submit \
  --master "$MASTER_URL" \
  /app/src/climate_spark/main.py \
  --mode raw \
  --cache off \
  --city "Rio De Janeiro" \
  --master "$MASTER_URL" \
  --output /app/output

echo "Resultados: output/"
echo "Spark UI: http://localhost:18080"
