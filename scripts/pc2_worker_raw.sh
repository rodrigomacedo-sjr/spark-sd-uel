#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Uso: scripts/pc2_worker_raw.sh <IP_DO_PC1>"
  exit 1
fi

cd "$(dirname "$0")/.."

# PC2: prepara dados raw e sobe um worker remoto conectado ao master do PC1.
PC1_IP="$1"
MASTER_URL="spark://$PC1_IP:7077"
WORKER_CONTAINER="climate-spark-worker-lan"
SPARK_BASE_IMAGE="apache/spark-py@sha256:bec1fed7818dd775c8a88224d5b2550c9a85ff81860f76b44e5357abdd849bb5"
WORKER_CORES="${SPARK_WORKER_CORES:-2}"
WORKER_MEMORY="${SPARK_WORKER_MEMORY:-2G}"

# 1. Garante que PC2 tambem tem data/raw.
# Nao usamos HDFS; cada maquina le seus arquivos locais em /app/data/raw.
scripts/setup_data.sh

# 2. Testa rede ate o master Spark do PC1.
# 7077 e a porta do protocolo Spark, nao a UI.
echo "Testando conexao com $MASTER_URL ..."
if ! timeout 5 bash -c "</dev/tcp/$PC1_IP/7077" 2>/dev/null; then
  echo "PC2 nao conseguiu acessar $PC1_IP:7077"
  echo "Confira IP, rede, firewall e se o PC1 rodou scripts/pc1_start_raw.sh."
  exit 1
fi

# 3. Sobe um Spark Worker no PC2.
# --network host usa rede real da maquina, simples para LAN.
docker pull "$SPARK_BASE_IMAGE" >/dev/null
docker rm -f "$WORKER_CONTAINER" >/dev/null 2>&1 || true
docker run -d \
  --network host \
  --user root \
  --name "$WORKER_CONTAINER" \
  -v "$PWD:/app" \
  -w /app \
  "$SPARK_BASE_IMAGE" \
  /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker "$MASTER_URL" \
    --cores "$WORKER_CORES" \
    --memory "$WORKER_MEMORY" \
    --work-dir /tmp/spark-worker >/dev/null

sleep 3

echo "Worker do PC2 conectado em $MASTER_URL"
echo "UI do Spark no PC1: http://$PC1_IP:8080"
echo "Logs recentes:"
docker logs --tail 40 "$WORKER_CONTAINER" || true
