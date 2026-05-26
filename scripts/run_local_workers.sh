#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Script auxiliar de apresentacao.
# Varia 1, 2 ou 3 workers locais sem editar docker-compose.yml.
usage() {
  echo "Uso: scripts/run_local_workers.sh <workers> [sample|raw]"
  echo "Exemplos:"
  echo "  scripts/run_local_workers.sh 1 raw"
  echo "  scripts/run_local_workers.sh 2 raw"
  echo "  scripts/run_local_workers.sh 3 raw"
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  usage
  exit 1
fi

WORKERS="$1"
MODE="${2:-raw}"

# Recursos por worker. Podem ser sobrescritos no terminal:
# SPARK_WORKER_CORES=4 SPARK_WORKER_MEMORY=4G scripts/run_local_workers.sh 3 raw
SPARK_WORKER_CORES="${SPARK_WORKER_CORES:-2}"
SPARK_WORKER_MEMORY="${SPARK_WORKER_MEMORY:-2G}"

# Rede criada pelo docker-compose. Dentro dela, o DNS "spark-master" funciona.
NETWORK_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$PWD")}_default"
MASTER_URL="spark://spark-master:7077"

case "$WORKERS" in
  1|2|3) ;;
  *)
    echo "Workers invalido: $WORKERS. Use 1, 2 ou 3."
    usage
    exit 1
    ;;
esac

case "$MODE" in
  sample|raw) ;;
  *)
    echo "Modo invalido: $MODE. Use sample ou raw."
    usage
    exit 1
    ;;
esac

# Em raw, prepara data/raw antes de subir o job.
if [ "$MODE" = "raw" ]; then
  scripts/setup_data.sh
fi

mkdir -p output output/benchmark
chmod 777 output

# Limpa qualquer cluster local anterior para o numero de workers ficar exato.
echo "Parando cluster local anterior..."
for i in 1 2 3; do
  docker rm -f "climate-spark-local-worker-$i" >/dev/null 2>&1 || true
done
docker compose down >/dev/null 2>&1 || true

# Usa o docker-compose apenas para criar a rede e subir o master.
# Nao usa os workers fixos spark-worker-1/spark-worker-2 do compose.
echo "Subindo master local..."
docker compose up -d --build spark-master

# Cria N workers temporarios com docker run.
# Todos conectam no mesmo master em spark://spark-master:7077.
echo "Subindo $WORKERS worker(s) local(is)..."
for i in $(seq 1 "$WORKERS"); do
  docker run -d \
    --name "climate-spark-local-worker-$i" \
    --network "$NETWORK_NAME" \
    -v "$PWD:/app" \
    -w /app \
    climate-spark:local \
    /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker \
      "$MASTER_URL" \
      --cores "$SPARK_WORKER_CORES" \
      --memory "$SPARK_WORKER_MEMORY" \
      --work-dir /tmp/spark-worker >/dev/null
done

echo "Aguardando workers registrarem..."
sleep 5

# Roda o driver/spark-submit via servico spark-app do compose.
# --no-deps evita o compose subir os workers fixos definidos no YAML.
echo "Rodando job: mode=$MODE, cache=on, workers=$WORKERS"
START_EPOCH="$(date +%s)"
docker compose run --rm --no-deps -e MPLCONFIGDIR=/tmp/matplotlib spark-app /opt/spark/bin/spark-submit \
  --master "$MASTER_URL" \
  /app/src/climate_spark/main.py \
  --mode "$MODE" \
  --cache on \
  --city "Rio De Janeiro" \
  --country Brazil \
  --master "$MASTER_URL" \
  --output /app/output
END_EPOCH="$(date +%s)"
WALL_SECONDS="$((END_EPOCH - START_EPOCH))"

# Soma os tempos por pergunta gravados pelo main.py.
TIMINGS_FILE="$(find output/results/timings_cache_on -name 'part-*.csv' | head -n 1 || true)"
SPARK_COMPUTE_SECONDS="0"
if [ -n "$TIMINGS_FILE" ] && [ -f "$TIMINGS_FILE" ]; then
  SPARK_COMPUTE_SECONDS="$(awk -F, 'NR > 1 {sum += $2} END {printf "%.4f", sum + 0}' "$TIMINGS_FILE")"
fi

# Salva benchmark local para comparar 1, 2 e 3 workers no mesmo PC.
OVERHEAD_SECONDS="$(awk -v wall="$WALL_SECONDS" -v compute="$SPARK_COMPUTE_SECONDS" 'BEGIN {printf "%.4f", wall - compute}')"
BENCHMARK_FILE="output/benchmark/local_workers.csv"
if [ ! -f "$BENCHMARK_FILE" ]; then
  echo "workers,mode,wall_seconds,spark_compute_seconds,overhead_seconds" > "$BENCHMARK_FILE"
fi
echo "$WORKERS,$MODE,$WALL_SECONDS,$SPARK_COMPUTE_SECONDS,$OVERHEAD_SECONDS" >> "$BENCHMARK_FILE"

echo "Workers: $WORKERS"
echo "Modo: $MODE"
echo "wall_seconds: $WALL_SECONDS"
echo "spark_compute_seconds: $SPARK_COMPUTE_SECONDS"
echo "overhead_seconds: $OVERHEAD_SECONDS"
echo "Benchmark: $BENCHMARK_FILE"
echo "Resultados: output/"
echo "Spark UI: http://localhost:18080"
