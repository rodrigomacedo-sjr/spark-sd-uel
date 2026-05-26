#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Uso: scripts/run_distributed_submit_pc1.sh <IP_DO_PC_1> [sample|raw]"
  exit 1
fi

cd "$(dirname "$0")/.."

# IP do PC1 e modo de dados. O driver tambem roda no PC1.
PC1_IP="$1"
MODE="${2:-sample}"
CITY="Rio De Janeiro"
if [ "$MODE" = "sample" ]; then
  CITY="Rio De Janeiro"
fi
MASTER_URL="spark://$PC1_IP:7077"

# No modo raw, garante que data/raw existe no PC1 antes do submit.
# O PC2 tambem precisa ter rodado setup_data.sh para o worker remoto ler /app/data/raw.
if [ "$MODE" = "raw" ]; then
  scripts/setup_data.sh
elif [ "$MODE" != "sample" ]; then
  echo "Modo invalido: $MODE. Use sample ou raw."
  exit 1
fi

mkdir -p output
chmod 777 output

# Constroi a imagem customizada do projeto a partir do Dockerfile.
# Essa imagem roda o driver/spark-submit e precisa de dependencias Python.
docker build -t climate-spark:local .

# Roda o driver Spark em container temporario.
# Portas 40444 e 40445 ficam fixas para workers remotos conseguirem voltar no driver.
docker run --rm \
  -p 4040:4040 \
  -p 40444:40444 \
  -p 40445:40445 \
  -e PYTHONPATH=/app/src \
  -e MPLCONFIGDIR=/tmp/matplotlib \
  -v "$PWD:/app" \
  -w /app \
  climate-spark:local \
  /opt/spark/bin/spark-submit \
    --master "$MASTER_URL" \
    --conf "spark.driver.host=$PC1_IP" \
    --conf "spark.driver.bindAddress=0.0.0.0" \
    --conf "spark.driver.port=40444" \
    --conf "spark.blockManager.port=40445" \
    /app/src/climate_spark/main.py \
    --mode "$MODE" \
    --cache on \
    --city "$CITY" \
    --country Brazil \
    --master "$MASTER_URL" \
    --output /app/output

echo "Job distribuido finalizado. Resultados: output/"
echo "Spark UI: http://$PC1_IP:8080"
