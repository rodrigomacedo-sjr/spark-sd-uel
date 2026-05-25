#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p data/raw data/sample output/results output/plots output/timings

if [ -f temperatura_kaggle.zip ]; then
  python3 -c 'import zipfile, pathlib
root = pathlib.Path("data/raw")
needed = {"GlobalLandTemperaturesByCity.csv", "GlobalTemperatures.csv"}
with zipfile.ZipFile("temperatura_kaggle.zip") as z:
    for name in z.namelist():
        if name in needed and not (root / name).exists():
            print(f"extract {name}")
            z.extract(name, root)
'
else
  echo "ERRO: temperatura_kaggle.zip nao encontrado em spark/"
  exit 1
fi

if [ ! -f data/raw/owid-co2-data.csv ]; then
  curl -L --fail --retry 3 \
    https://owid-public.owid.io/data/co2/owid-co2-data.csv \
    -o data/raw/owid-co2-data.csv
fi

python3 -c 'from pathlib import Path
required = [
    "data/raw/GlobalLandTemperaturesByCity.csv",
    "data/raw/GlobalTemperatures.csv",
    "data/raw/owid-co2-data.csv",
]
missing = [p for p in required if not Path(p).exists()]
if missing:
    raise SystemExit("Arquivos faltando: " + ", ".join(missing))
print("Dados prontos em data/raw/")
'

