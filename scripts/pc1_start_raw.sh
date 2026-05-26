#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# PC1: prepara dados raw, sobe o Spark Master LAN e sobe um worker local.
# Este script nao roda a analise; ele so monta a infraestrutura do cluster.
MASTER_CONTAINER="climate-spark-master-lan"
LOCAL_WORKER_CONTAINER="climate-spark-worker-pc1"
IMAGE="climate-spark:local"
SPARK_BASE_IMAGE="apache/spark-py@sha256:bec1fed7818dd775c8a88224d5b2550c9a85ff81860f76b44e5357abdd849bb5"
WORKER_CORES="${SPARK_WORKER_CORES:-2}"
WORKER_MEMORY="${SPARK_WORKER_MEMORY:-2G}"

port_is_busy() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn | awk '{print $4}' | grep -Eq "(^|:)${port}$"
  else
    docker ps --format '{{.Ports}}' | grep -Eq "0\.0\.0\.0:${port}->|:::${port}->"
  fi
}

ensure_port_free() {
  local port="$1"
  if port_is_busy "$port"; then
    echo "Porta ocupada: $port"
    echo "Rode scripts/stop_distributed.sh e tente de novo."
    exit 1
  fi
}

# 1. Garante que data/raw existe no PC1.
scripts/setup_data.sh

# 2. Cria a imagem do projeto pelo Dockerfile.
# O master e o driver usam essa imagem customizada.
docker build -t "$IMAGE" .

# 3. Limpa clusters antigos para evitar conflito de porta/nome.
docker compose down >/dev/null 2>&1 || true
docker rm -f "$MASTER_CONTAINER" "$LOCAL_WORKER_CONTAINER" climate-spark-worker-lan >/dev/null 2>&1 || true
ensure_port_free 7077
ensure_port_free 8080

# 4. Sobe o Spark Master Standalone.
# 7077 = protocolo Spark; 8080 = UI do master.
docker run -d \
  --name "$MASTER_CONTAINER" \
  -p 7077:7077 \
  -p 8080:8080 \
  "$IMAGE" \
  /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master --host 0.0.0.0 >/dev/null

PC1_IP="$(hostname -I | awk '{print $1}')"
MASTER_URL="spark://$PC1_IP:7077"

# 5. Sobe um worker no proprio PC1.
# Usa network host porque este modo representa cluster LAN real.
docker pull "$SPARK_BASE_IMAGE" >/dev/null
docker run -d \
  --network host \
  --user root \
  --name "$LOCAL_WORKER_CONTAINER" \
  -v "$PWD:/app" \
  -w /app \
  "$SPARK_BASE_IMAGE" \
  /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker "$MASTER_URL" \
    --cores "$WORKER_CORES" \
    --memory "$WORKER_MEMORY" \
    --work-dir /tmp/spark-worker >/dev/null

# 6. Salva o IP para o benchmark do PC1 ler depois.
cat > cluster.env <<EOF
SPARK_MASTER_IP=$PC1_IP
SPARK_DATA_MODE=raw
EOF

echo "PC1 pronto: master + worker local"
echo "IP do PC1: $PC1_IP"
echo "Master Spark: $MASTER_URL"
echo "UI do Spark: http://$PC1_IP:8080"
echo "Proximo passo no PC2: scripts/pc2_worker_raw.sh $PC1_IP"
