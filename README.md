# Analise Global de Mudancas Climaticas com Spark


Autores: Rodrigo Macedo (RodrigoMacedo) e Gabriel Peres.
Projeto de Sistemas Distribuidos usando Apache Spark para processar dados historicos de temperatura e CO2. O foco e mostrar limpeza, agregacoes distribuidas, join entre bases, window functions, cache e MLlib.

## Requisitos

Em cada Ubuntu usado:

```bash
sudo apt update
sudo apt install -y git curl python3 docker.io docker-compose-plugin
sudo usermod -aG docker "$USER"
```

Depois saia e entre novamente na sessao para o grupo `docker` valer. Teste:

```bash
docker --version
docker compose version
```

Os dois PCs precisam ter internet para baixar imagens Docker. O PC 1 tambem precisa de internet para baixar CO2; no modo raw, o PC 2 precisa baixar ou receber a mesma pasta data/raw/. Para execucao real, coloque o arquivo Kaggle na raiz do projeto:

```text
temperatura_kaggle.zip
```

O zip deve conter `GlobalLandTemperaturesByCity.csv` e `GlobalTemperatures.csv`.

## Rodar demo rapida local

Usa dados pequenos versionados em `data/sample/`.

```bash
cd spark
scripts/run_demo.sh
```

Verifique:

```text
Spark UI: http://localhost:18080
Resultados: output/results/
Graficos: output/plots/
```

## Preparar dados reais

```bash
cd spark
scripts/setup_data.sh
```

O script extrai os CSVs do zip Kaggle para `data/raw/` e baixa `owid-co2-data.csv` da OWID.

## Rodar dados reais em um computador

```bash
cd spark
scripts/run_all.sh
```

Esse modo sobe 1 master e 2 workers via Docker Compose. Ele roda com cache e sem cache para comparar tempo. A UI local fica em `http://localhost:18080`.

## Rodar em dois computadores Ubuntu

Assumimos que os dois PCs estao na mesma rede e conseguem se acessar pelo IP local.

### PC 1: preparar dados e subir master

```bash
cd spark
scripts/setup_data.sh
scripts/run_distributed_master_pc1.sh
```

Anote o IP mostrado, exemplo:

```text
Spark master URL: spark://192.168.0.10:7077
Spark UI: http://192.168.0.10:8080
```

Se firewall estiver ativo:

```bash
sudo ufw allow 7077/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 40444/tcp
sudo ufw allow 40445/tcp
```

### PC 2: clonar projeto e subir worker

```bash
git clone https://github.com/rodrigomacedo-sjr/spark-sd-uel.git spark
cd spark
scripts/run_distributed_worker_pc2.sh 192.168.0.10
```

Para modo `raw`, o PC 2 tambem precisa ter `temperatura_kaggle.zip` e rodar:

```bash
scripts/setup_data.sh
```

Motivo: executores Spark leem arquivos em `/app/data/...`, entao PC1 e PC2 precisam enxergar os mesmos dados locais.

### PC 1: submeter job ao cluster LAN

Demo pequena:

```bash
scripts/run_distributed_submit_pc1.sh 192.168.0.10 sample
```

Dados reais:

```bash
scripts/run_distributed_submit_pc1.sh 192.168.0.10 raw
```

Abra:

```text
http://192.168.0.10:8080
```

E confira se o worker do PC 2 aparece registrado.

## Perguntas respondidas

1. Media anual global agregada por decada, com media movel.
2. Top 10 anos mais quentes por continente nos ultimos 50 anos disponiveis.
3. Cidades com maior desvio padrao de temperatura no ultimo seculo.
4. Correlacao tropical entre minima/maxima anual aproximadas a partir das medias mensais.
5. Registros onde incerteza passa de 10% da media historica da cidade.
6. Pearson entre aumento de CO2 e aumento de temperatura por pais nos ultimos 50 anos disponiveis.
7. Ranking de aceleracao termica usando window functions e ultimas decadas completas.
8. Previsao dos proximos 5 anos disponiveis para uma cidade/pais usando Spark MLlib.

## Arquivos principais

- `src/climate_spark/main.py`: orquestra pipeline.
- `src/climate_spark/cleaning.py`: limpeza de dados.
- `src/climate_spark/analytics.py`: respostas das 8 perguntas.
- `RELATORIO.md`: relatorio final.
- `SABER_ROGER.md` e `SABER_GABRIEL.md`: preparacao para defesa.
- `PLANO_DIVISAO_APRESENTACAO.md`: ordem sugerida para apresentacao.

## Parar containers

```bash
scripts/stop_distributed.sh
```
