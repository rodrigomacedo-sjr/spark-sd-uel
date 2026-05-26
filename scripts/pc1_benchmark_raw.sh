#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# PC1: submete a analise raw no cluster de 2 PCs e mede os tempos.
if [ ! -f cluster.env ]; then
  echo "cluster.env nao encontrado. Rode primeiro: scripts/pc1_start_raw.sh"
  exit 1
fi

# shellcheck disable=SC1091
source cluster.env

PC1_IP="${SPARK_MASTER_IP:?SPARK_MASTER_IP ausente em cluster.env}"
MASTER_URL="spark://$PC1_IP:7077"
IMAGE="climate-spark:local"
BENCHMARK_FILE="output/benchmark/cluster_modes.csv"


ensure_benchmark_header() {
  local file="$1"
  local expected="ambiente,workers,dados,total_seconds,processamento_spark_seconds,overhead_seconds"
  if [ -f "$file" ] && [ "$(head -n 1 "$file")" != "$expected" ]; then
    mv "$file" "$file.legacy.$(date +%Y%m%d%H%M%S)"
  fi
  if [ ! -f "$file" ]; then
    echo "$expected" > "$file"
  fi
}

# 1. Garante raw no PC1 e imagem atualizada para o driver.
scripts/setup_data.sh
mkdir -p output output/benchmark
chmod 777 output
docker build -t "$IMAGE" .

# 2. Roda o driver/spark-submit.
# Portas fixas permitem workers LAN falarem de volta com o driver.
echo "Rodando raw no cluster 2 PCs..."
START_EPOCH="$(date +%s)"
docker run --rm \
  -p 4040:4040 \
  -p 40444:40444 \
  -p 40445:40445 \
  -e PYTHONPATH=/app/src \
  -e MPLCONFIGDIR=/tmp/matplotlib \
  -v "$PWD:/app" \
  -w /app \
  "$IMAGE" \
  /opt/spark/bin/spark-submit \
    --master "$MASTER_URL" \
    --conf "spark.driver.host=$PC1_IP" \
    --conf "spark.driver.bindAddress=0.0.0.0" \
    --conf "spark.driver.port=40444" \
    --conf "spark.blockManager.port=40445" \
    /app/src/climate_spark/main.py \
    --mode raw \
    --cache on \
    --city "Rio De Janeiro" \
    --country Brazil \
    --master "$MASTER_URL" \
    --output /app/output
END_EPOCH="$(date +%s)"

# 3. Calcula tempo total, processamento Spark medido no app e overhead.
WALL_SECONDS="$((END_EPOCH - START_EPOCH))"
TIMINGS_FILE="$(find output/results/timings_cache_on -name 'part-*.csv' | head -n 1 || true)"
SPARK_COMPUTE_SECONDS="0"
if [ -n "$TIMINGS_FILE" ] && [ -f "$TIMINGS_FILE" ]; then
  SPARK_COMPUTE_SECONDS="$(awk -F, 'NR > 1 {sum += $2} END {printf "%.4f", sum + 0}' "$TIMINGS_FILE")"
fi
OVERHEAD_SECONDS="$(awk -v total="$WALL_SECONDS" -v spark="$SPARK_COMPUTE_SECONDS" 'BEGIN {printf "%.4f", total - spark}')"

ensure_benchmark_header "$BENCHMARK_FILE"
echo "2-pcs,2,raw,$WALL_SECONDS,$SPARK_COMPUTE_SECONDS,$OVERHEAD_SECONDS" >> "$BENCHMARK_FILE"

echo "Benchmark salvo: $BENCHMARK_FILE"
echo "Ambiente: 2 PCs"
echo "Workers: 2"
echo "Dados: raw"
echo "Tempo total: ${WALL_SECONDS}s"
echo "Processamento Spark: ${SPARK_COMPUTE_SECONDS}s"
echo "Overhead: ${OVERHEAD_SECONDS}s"
echo "UI do Spark: http://$PC1_IP:8080"
