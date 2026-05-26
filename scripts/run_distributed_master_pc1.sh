#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Verifica se uma porta local esta ocupada.
# O master LAN precisa das portas 7077 e 8080 livres no PC1.
port_is_busy() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn | awk '{print $4}' | grep -Eq "(^|:)${port}$"
  else
    docker ps --format '{{.Ports}}' | grep -Eq "0\.0\.0\.0:${port}->|:::${port}->"
  fi
}

# Falha se a porta ja estiver em uso.
ensure_port_free() {
  local port="$1"
  if port_is_busy "$port"; then
    echo "ERRO: porta $port ainda esta ocupada."
    echo "Pare o processo/container que usa essa porta e rode novamente:"
    echo "  scripts/stop_distributed.sh"
    echo "  docker ps"
    exit 1
  fi
}

# Constroi a imagem do projeto a partir do Dockerfile.
# Imagem resultante: climate-spark:local.
docker build -t climate-spark:local .

# Evita conflito com o cluster local do docker-compose, que tambem usa 7077.
docker compose down >/dev/null 2>&1 || true
docker rm -f climate-spark-master-lan climate-spark-worker-lan >/dev/null 2>&1 || true

# Confere portas antes de subir o master LAN.
# 7077: protocolo Spark. 8080: Spark master UI.
ensure_port_free 7077
ensure_port_free 8080

# Sobe somente o master Spark em container Docker.
docker run -d \
  --name climate-spark-master-lan \
  -p 7077:7077 \
  -p 8080:8080 \
  climate-spark:local \
  /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master --host 0.0.0.0

# IP que o PC2 deve usar para conectar no master.
IP="$(hostname -I | awk '{print $1}')"
echo "Master iniciado."
echo "Passe este IP para o PC 2: $IP"
echo "Spark master URL: spark://$IP:7077"
echo "Spark UI: http://$IP:8080"
