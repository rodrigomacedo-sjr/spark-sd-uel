#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Uso: scripts/local_workers_raw.sh <1|2|3>"
  exit 1
fi

cd "$(dirname "$0")/.."

# Um PC: sobe master local, N workers locais e roda raw com cache ligado.
WORKERS="$1"
IMAGE="climate-spark:local"
NETWORK_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$PWD")}_default"
MASTER_URL="spark://spark-master:7077"
BENCHMARK_FILE="output/benchmark/local_workers.csv"
SPARK_WORKER_CORES="${SPARK_WORKER_CORES:-2}"
SPARK_WORKER_MEMORY="${SPARK_WORKER_MEMORY:-2G}"


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

case "$WORKERS" in
  1|2|3) ;;
  *)
    echo "Workers invalido: $WORKERS. Use 1, 2 ou 3."
    exit 1
    ;;
esac

# 1. Garante raw e limpa cluster local anterior.
scripts/setup_data.sh
mkdir -p output output/benchmark
chmod 777 output
for i in 1 2 3; do
  docker rm -f "climate-spark-local-worker-$i" >/dev/null 2>&1 || true
done
docker compose down >/dev/null 2>&1 || true

# 2. Usa compose apenas para buildar imagem, criar rede e subir master.
# Os workers fixos do docker-compose.yml nao sao usados aqui.
docker compose up -d --build spark-master

# 3. Cria N workers temporarios na rede do compose.
for i in $(seq 1 "$WORKERS"); do
  docker run -d \
    --name "climate-spark-local-worker-$i" \
    --network "$NETWORK_NAME" \
    -v "$PWD:/app" \
    -w /app \
    "$IMAGE" \
    /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker "$MASTER_URL" \
      --cores "$SPARK_WORKER_CORES" \
      --memory "$SPARK_WORKER_MEMORY" \
      --work-dir /tmp/spark-worker >/dev/null
done
sleep 5

# 4. Roda o driver/spark-submit sem subir dependencias do compose.
echo "Rodando raw local com $WORKERS worker(s)..."
START_EPOCH="$(date +%s)"
docker compose run --rm --no-deps -e MPLCONFIGDIR=/tmp/matplotlib spark-app /opt/spark/bin/spark-submit \
  --master "$MASTER_URL" \
  /app/src/climate_spark/main.py \
  --mode raw \
  --cache on \
  --city "Rio De Janeiro" \
  --country Brazil \
  --master "$MASTER_URL" \
  --output /app/output
END_EPOCH="$(date +%s)"

# 5. Calcula tempo total, processamento Spark medido no app e overhead.
WALL_SECONDS="$((END_EPOCH - START_EPOCH))"
TIMINGS_FILE="$(find output/results/timings_cache_on -name 'part-*.csv' | head -n 1 || true)"
SPARK_COMPUTE_SECONDS="0"
if [ -n "$TIMINGS_FILE" ] && [ -f "$TIMINGS_FILE" ]; then
  SPARK_COMPUTE_SECONDS="$(awk -F, 'NR > 1 {sum += $2} END {printf "%.4f", sum + 0}' "$TIMINGS_FILE")"
fi
OVERHEAD_SECONDS="$(awk -v total="$WALL_SECONDS" -v spark="$SPARK_COMPUTE_SECONDS" 'BEGIN {printf "%.4f", total - spark}')"

ensure_benchmark_header "$BENCHMARK_FILE"
echo "local,$WORKERS,raw,$WALL_SECONDS,$SPARK_COMPUTE_SECONDS,$OVERHEAD_SECONDS" >> "$BENCHMARK_FILE"

echo "Benchmark salvo: $BENCHMARK_FILE"
echo "Ambiente: local"
echo "Workers: $WORKERS"
echo "Dados: raw"
echo "Tempo total: ${WALL_SECONDS}s"
echo "Processamento Spark: ${SPARK_COMPUTE_SECONDS}s"
echo "Overhead: ${OVERHEAD_SECONDS}s"
echo "UI do Spark: http://localhost:18080"
