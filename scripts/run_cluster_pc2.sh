#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f cluster.env ]; then
  echo "cluster.env nao existe. Copie cluster.env.example para cluster.env e configure SPARK_MASTER_IP."
  exit 1
fi

# shellcheck disable=SC1091
source cluster.env

if [ -z "${SPARK_MASTER_IP:-}" ]; then
  echo "SPARK_MASTER_IP nao definido em cluster.env"
  exit 1
fi

scripts/run_distributed_worker_pc2.sh "$SPARK_MASTER_IP"
