#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Script de alto nivel para o PC2.
# O PC2 so precisa saber o IP do master Spark que roda no PC1.
if [ $# -ge 1 ]; then
  # Caminho normal da apresentacao: recebe IP do PC1 por argumento.
  SPARK_MASTER_IP="$1"
  SPARK_DATA_MODE="${SPARK_DATA_MODE:-sample}"
  cat > cluster.env <<EOF
SPARK_MASTER_IP=$SPARK_MASTER_IP
SPARK_DATA_MODE=$SPARK_DATA_MODE
EOF
elif [ -f cluster.env ]; then
  # Plano B: se o IP ja foi salvo antes, reutiliza cluster.env.
  # shellcheck disable=SC1091
  source cluster.env
else
  echo "Uso: scripts/run_cluster_pc2.sh <IP_DO_PC1>"
  echo "Exemplo: scripts/run_cluster_pc2.sh 192.168.1.9"
  exit 1
fi

# Protecao contra rodar worker sem IP de master definido.
if [ -z "${SPARK_MASTER_IP:-}" ]; then
  echo "SPARK_MASTER_IP nao definido. Rode: scripts/run_cluster_pc2.sh <IP_DO_PC1>"
  exit 1
fi

# Teste simples de rede: o PC2 precisa conseguir abrir TCP no master Spark.
# Porta 7077 e a porta de comunicacao do cluster, nao a UI.
echo "Testando conexao com spark://$SPARK_MASTER_IP:7077 ..."
if ! timeout 5 bash -c "</dev/tcp/$SPARK_MASTER_IP/7077" 2>/dev/null; then
  echo "ERRO: PC2 nao consegue acessar $SPARK_MASTER_IP:7077."
  echo "Confira:"
  echo "  1. O master esta rodando no PC1: scripts/run_cluster_pc1.sh master"
  echo "  2. O IP do PC1 esta correto: $SPARK_MASTER_IP"
  echo "  3. Os dois PCs estao na mesma rede"
  echo "  4. Firewall do PC1 liberou 7077 e 8080"
  echo "     sudo ufw allow 7077/tcp"
  echo "     sudo ufw allow 8080/tcp"
  exit 1
fi

# Se a porta 7077 respondeu, sobe o worker remoto.
# O script chamado abaixo usa docker run com network host.
echo "Conexao OK. Subindo worker no PC2..."
scripts/run_distributed_worker.sh "$SPARK_MASTER_IP"

echo
sleep 3
# Mostra logs para confirmar que o worker registrou no master.
echo "Logs recentes do worker:"
docker logs --tail 80 climate-spark-worker-lan || true

echo
echo "Agora veja no PC1: http://$SPARK_MASTER_IP:8080"
echo "Deve aparecer pelo menos 1 worker vivo."
