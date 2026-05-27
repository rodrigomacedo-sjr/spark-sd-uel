#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

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

if [ "$MODE" = "local-compose" ]; then
  # scripts/run_all.sh usa docker compose para subir master e workers locais.
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

START_EPOCH="$(date +%s)"

if [ "$MODE" = "local-compose" ]; then
  # scripts/run_all.sh usa docker compose para subir master e workers locais.
  if [ "$DATA_MODE" = "raw" ]; then
    scripts/run_all.sh
  elif [ "$DATA_MODE" = "sample" ]; then
    scripts/run_demo.sh
  else
    echo "DATA_MODE invalido: $DATA_MODE"
    exit 1
  fi
fi

if [ "$MODE" = "lan-cluster" ]; then
  scripts/run_distributed_submit_pc1.sh "$PC1_IP" "$DATA_MODE"
fi

END_EPOCH="$(date +%s)"
WALL_SECONDS="$((END_EPOCH - START_EPOCH))"

TIMINGS_FILE="$(find output/results/timings_cache_on -name 'part-*.csv' | head -n 1 || true)"
SPARK_COMPUTE_SECONDS="0"
if [ -n "$TIMINGS_FILE" ] && [ -f "$TIMINGS_FILE" ]; then
  SPARK_COMPUTE_SECONDS="$(awk -F, 'NR > 1 {sum += $2} END {printf "%.4f", sum + 0}' "$TIMINGS_FILE")"
fi

OVERHEAD_SECONDS="$(awk -v wall="$WALL_SECONDS" -v compute="$SPARK_COMPUTE_SECONDS" 'BEGIN {printf "%.4f", wall - compute}')"
NETWORK_ORCHESTRATION_OVERHEAD="$OVERHEAD_SECONDS"

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
