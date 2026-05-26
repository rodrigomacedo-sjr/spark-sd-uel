#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Benchmark compara tempo total do comando com tempo medido dentro do Spark.
# Saida: output/benchmark/cluster_modes.csv
MODE="${1:-}"
if [ -z "$MODE" ]; then
  echo "Uso:"
  echo "  scripts/benchmark_cluster_modes.sh local-compose [sample|raw]"
  echo "  scripts/benchmark_cluster_modes.sh lan-cluster <IP_DO_PC1> [sample|raw]"
  exit 1
fi

DATA_MODE="raw"
PC1_IP=""
RUN_LABEL="$MODE"

# Dois modos:
# local-compose: master + 2 workers no mesmo PC via docker-compose.
# lan-cluster: master/driver no PC1 e worker remoto no PC2.
if [ "$MODE" = "local-compose" ]; then
  DATA_MODE="${2:-raw}"
elif [ "$MODE" = "lan-cluster" ]; then
  if [ $# -lt 2 ]; then
    echo "Uso: scripts/benchmark_cluster_modes.sh lan-cluster <IP_DO_PC1> [sample|raw]"
    exit 1
  fi
  PC1_IP="$2"
  DATA_MODE="${3:-raw}"
else
  echo "Modo invalido: $MODE"
  echo "Use local-compose ou lan-cluster"
  exit 1
fi

mkdir -p output/benchmark

# Comeca cronometro externo: inclui Docker, submit, leitura/escrita e overhead.
START_EPOCH="$(date +%s)"

if [ "$MODE" = "local-compose" ]; then
  # Modo local padrao da entrega: usa docker-compose.yml com 2 workers fixos.
  if [ "$DATA_MODE" = "raw" ]; then
    scripts/setup_data.sh
  elif [ "$DATA_MODE" != "sample" ]; then
    echo "DATA_MODE invalido: $DATA_MODE"
    exit 1
  fi

  mkdir -p output
  chmod 777 output
  docker compose up -d --build spark-master spark-worker-1 spark-worker-2
  docker compose run --rm -e MPLCONFIGDIR=/tmp/matplotlib spark-app /opt/spark/bin/spark-submit \
    --master spark://spark-master:7077 \
    /app/src/climate_spark/main.py \
    --mode "$DATA_MODE" \
    --cache on \
    --city "Rio De Janeiro" \
    --country Brazil \
    --master spark://spark-master:7077 \
    --output /app/output
fi

if [ "$MODE" = "lan-cluster" ]; then
  # Modo 2 PCs: reaproveita o script de submit distribuido.
  scripts/run_distributed_submit_pc1.sh "$PC1_IP" "$DATA_MODE"
fi

# Fim do cronometro externo.
END_EPOCH="$(date +%s)"
WALL_SECONDS="$((END_EPOCH - START_EPOCH))"

# main.py grava tempos por pergunta em output/results/timings_cache_on.
# Aqui somamos Q1-Q8 para estimar tempo de computacao Spark medido no app.
TIMINGS_FILE="$(find output/results/timings_cache_on -name 'part-*.csv' | head -n 1 || true)"
SPARK_COMPUTE_SECONDS="0"
if [ -n "$TIMINGS_FILE" ] && [ -f "$TIMINGS_FILE" ]; then
  SPARK_COMPUTE_SECONDS="$(awk -F, 'NR > 1 {sum += $2} END {printf "%.4f", sum + 0}' "$TIMINGS_FILE")"
fi

# Overhead aproximado: tudo que ficou fora da soma dos tempos Q1-Q8.
OVERHEAD_SECONDS="$(awk -v wall="$WALL_SECONDS" -v compute="$SPARK_COMPUTE_SECONDS" 'BEGIN {printf "%.4f", wall - compute}')"
NETWORK_ORCHESTRATION_OVERHEAD="$OVERHEAD_SECONDS"

# Acrescenta linha no CSV para comparar varias rodadas.
OUT="output/benchmark/cluster_modes.csv"
if [ ! -f "$OUT" ]; then
  echo "run_label,data_mode,wall_seconds,spark_compute_seconds,overhead_seconds,network_orchestration_overhead" > "$OUT"
fi

echo "$RUN_LABEL,$DATA_MODE,$WALL_SECONDS,$SPARK_COMPUTE_SECONDS,$OVERHEAD_SECONDS,$NETWORK_ORCHESTRATION_OVERHEAD" >> "$OUT"

echo "Benchmark salvo em $OUT"
echo "Modo: $RUN_LABEL"
echo "Dados: $DATA_MODE"
echo "wall_seconds: $WALL_SECONDS"
echo "spark_compute_seconds: $SPARK_COMPUTE_SECONDS"
echo "overhead_seconds: $OVERHEAD_SECONDS"
echo "network_orchestration_overhead: $NETWORK_ORCHESTRATION_OVERHEAD"
