#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p output/evidence
{
  echo "Spark UI local: http://localhost:18080"
  echo "Data: $(date -Is)"
  echo
  echo "Arquivos de resultado:"
  find output -maxdepth 3 -type f | sort
} > output/evidence/evidence.txt

echo "Evidencias em output/evidence/evidence.txt"
