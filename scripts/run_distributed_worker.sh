#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Uso: scripts/run_distributed_worker.sh <IP_DO_PC_1>"
  exit 1
fi

cd "$(dirname "$0")/.."

# IP do PC1 onde o master Spark escuta na porta 7077.
MASTER_IP="$1"

mkdir -p output
chmod 777 output

# Usa a imagem oficial apache/spark-py fixada por digest.
# Worker LAN nao precisa da imagem customizada do projeto, porque so roda executor Spark.
docker pull apache/spark-py@sha256:bec1fed7818dd775c8a88224d5b2550c9a85ff81860f76b44e5357abdd849bb5

# Remove worker antigo para evitar conflito de nome.
docker rm -f climate-spark-worker-lan >/dev/null 2>&1 || true

# Sobe um Spark Worker conectado ao master do PC1.
# --network host usa a rede real da maquina, mais simples para LAN.
# -v "$PWD:/app" monta dados/codigo no mesmo caminho esperado pelo job.
docker run -d \
  --network host \
  --user root \
  --name climate-spark-worker-lan \
  -v "$PWD:/app" \
  -w /app \
  apache/spark-py@sha256:bec1fed7818dd775c8a88224d5b2550c9a85ff81860f76b44e5357abdd849bb5 \
  /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker "spark://$MASTER_IP:7077" --cores 2 --memory 2G --work-dir /tmp/spark-worker

echo "Worker conectado em spark://$MASTER_IP:7077"
echo "Veja no PC 1: http://$MASTER_IP:8080"
