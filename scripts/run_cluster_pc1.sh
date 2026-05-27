#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ACTION="${1:-master}"
DATA_MODE="${SPARK_DATA_MODE:-sample}"

local_ip() {
  hostname -I | awk '{print $1}'
}

write_cluster_env() {
  local ip="$1"
  local mode="$2"
  cat > cluster.env <<EOF
SPARK_MASTER_IP=$ip
SPARK_DATA_MODE=$mode
EOF
}

case "$ACTION" in
  master)
    IP="$(local_ip)"
    write_cluster_env "$IP" "$DATA_MODE"
    scripts/run_distributed_master_pc1.sh
    echo
    echo "PC1 pronto. Agora rode no PC2:"
    echo "  git pull origin main"
    echo "  scripts/run_cluster_pc2.sh $IP"
    echo
    echo "Depois rode no PC1:"
    echo "  scripts/run_cluster_pc1.sh submit"
    echo
    echo "Spark UI: http://$IP:8080"
    ;;
  submit)
    if [ ! -f cluster.env ]; then
      echo "cluster.env nao existe. Rode primeiro: scripts/run_cluster_pc1.sh master"
      exit 1
    fi
    # shellcheck disable=SC1091
    source cluster.env
    scripts/run_distributed_submit_pc1.sh "$SPARK_MASTER_IP" "${SPARK_DATA_MODE:-sample}"
    ;;
  benchmark)
    if [ ! -f cluster.env ]; then
      echo "cluster.env nao existe. Rode primeiro: scripts/run_cluster_pc1.sh master"
      exit 1
    fi
    # shellcheck disable=SC1091
    source cluster.env
    scripts/benchmark_cluster_modes.sh lan-cluster "$SPARK_MASTER_IP" "${SPARK_DATA_MODE:-sample}"
    ;;
  status)
    docker ps --filter name=climate-spark --format '{{.Names}} {{.Status}} {{.Ports}}'
    ;;
  *)
    echo "Uso: scripts/run_cluster_pc1.sh [master|submit|benchmark|status]"
    exit 1
    ;;
esac
