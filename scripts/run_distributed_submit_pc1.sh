#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Uso: scripts/run_distributed_submit_pc1.sh <IP_DO_PC_1> [sample|raw]"
  exit 1
fi

cd "$(dirname "$0")/.."

PC1_IP="$1"
MODE="${2:-sample}"
CITY="Rio De Janeiro"
if [ "$MODE" = "sample" ]; then
  CITY="Rio De Janeiro"
fi
MASTER_URL="spark://$PC1_IP:7077"

if [ "$MODE" = "raw" ]; then
  scripts/setup_data.sh
elif [ "$MODE" != "sample" ]; then
  echo "Modo invalido: $MODE. Use sample ou raw."
  exit 1
fi

mkdir -p output
chmod 777 output

docker build -t climate-spark:local .
docker run --rm \
  --network host \
  -e PYTHONPATH=/app/src \
  -e MPLCONFIGDIR=/tmp/matplotlib \
  -v "$PWD:/app" \
  -w /app \
  climate-spark:local \
  /opt/spark/bin/spark-submit \
    --master "$MASTER_URL" \
    --conf "spark.driver.host=$PC1_IP" \
    --conf "spark.driver.port=40444" \
    --conf "spark.blockManager.port=40445" \
    /app/src/climate_spark/main.py \
    --mode "$MODE" \
    --cache on \
    --city "$CITY" \
    --country Brazil \
    --master "$MASTER_URL" \
    --output /app/output

echo "Job distribuido finalizado. Resultados: output/"
echo "Spark UI: http://$PC1_IP:8080"
