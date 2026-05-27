#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f cluster.env ]; then
  cp cluster.env.example cluster.env
fi

# shellcheck disable=SC1091
source cluster.env

case "${1:-master}" in
  master)
    scripts/run_distributed_master_pc1.sh
    ;;
  submit)
    scripts/run_distributed_submit_pc1.sh "$SPARK_MASTER_IP" "${SPARK_DATA_MODE:-sample}"
    ;;
  benchmark)
    scripts/benchmark_cluster_modes.sh lan-cluster "$SPARK_MASTER_IP" "${SPARK_DATA_MODE:-sample}"
    ;;
  *)
    echo "Uso: scripts/run_cluster_pc1.sh [master|submit|benchmark]"
    exit 1
    ;;
esac
