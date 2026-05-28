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

## Notebook principal da apresentacao

O material principal da apresentacao esta em:

```text
notebooks/apresentacao_spark_clima.ipynb
```

Ele explica arquivo por arquivo, mostra onde cada etapa esta feita, prova a divisao por particoes, detalha o join temperatura+CO2 e responde Q1-Q8 passo a passo. Tambem tem parametros faceis de mudar para iterar percentuais, cidade, pais, limites de ranking, anos de previsao e numero de particoes.

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


## Benchmark local vs cluster LAN

Para comparar tempo total local contra tempo no cluster de 2 PCs, use:

```bash
scripts/benchmark_cluster_modes.sh local-compose raw
scripts/benchmark_cluster_modes.sh lan-cluster <IP_DO_PC1> raw
```

O resultado fica em `output/benchmark/cluster_modes.csv`, com `wall_seconds`, `spark_compute_seconds`, `overhead_seconds` e `network_orchestration_overhead`. A analise completa de quando vale a pena usar cluster esta no notebook principal da apresentacao.

Medicao real com base `raw`, cache ligado, 2 workers e arquivo Kaggle identico nos dois PCs:

| Modo | Workers | Tempo total | Tempo Spark medido | Overhead aproximado | Leitura |
|---|---:|---:|---:|---:|---|
| `local-compose` | 2 no mesmo PC | 158s | 35.4613s | 122.5387s | Menor overhead, sem rede LAN entre PCs |
| `lan-cluster` | 1 no PC1 + 1 no PC2 | 188s | 43.8593s | 144.1407s | Distribuiu processamento, mas pagou custo de rede/orquestracao |

Nesta medicao, o cluster LAN ficou cerca de 30s mais lento que o Compose local. Isso nao invalida a distribuicao: a Spark UI mostrou dois workers vivos e executores em hosts diferentes. A conclusao correta e que cluster vale quando o ganho de CPU e memoria supera rede, shuffle, Docker, leitura/escrita e trechos seriais.

Durante a execucao apareceu o aviso `WindowExec: No Partition Defined`. Isso indica que algumas operacoes de janela movem dados para uma unica particao, reduzindo o paralelismo e explicando por que mais workers nem sempre reduzem o tempo.


## Workers, recursos e eficiencia

A entrega principal usa 2 workers, como esta em `docker-compose.yml`. Para testar 3 workers no Docker Compose atual, duplique o bloco `spark-worker-2`, crie `spark-worker-3`, troque `container_name` para `climate-spark-worker-3` e exponha `8083:8081`. Para 4 workers, crie tambem `spark-worker-4` com `8084:8081`. Depois confira na Spark UI:

```text
Alive Workers: 3
Total Cores: soma dos cores dos workers
Total Memory: soma da memoria dos workers
```

Aparecer 3 workers vivos prova que o cluster registrou os workers. Para provar que o job usou todos, abra a aplicacao `climate-spark-analysis` e confira tasks executadas em executors diferentes.

Para mais recursos por worker, altere nos comandos dos workers:

```text
--cores 2
--memory 2G
```

Exemplo:

```text
--cores 4
--memory 4G
```

No modo 2 PCs, esses valores ficam em `scripts/run_distributed_worker.sh`. Para padronizar os testes, use estes valores como referencia antes de editar ou rodar:

```text
SPARK_WORKER_CORES=2
SPARK_WORKER_MEMORY=2G
SPARK_WORKER_INSTANCES=2
--cores ${SPARK_WORKER_CORES}
--memory ${SPARK_WORKER_MEMORY}
```

Se o Compose for refatorado para um unico servico `spark-worker`, o teste de 3 ou 4 workers pode ser feito com:

```bash
SPARK_WORKER_CORES=2 SPARK_WORKER_MEMORY=2G docker compose up -d --scale spark-worker=3
SPARK_WORKER_CORES=2 SPARK_WORKER_MEMORY=2G docker compose up -d --scale spark-worker=4
```

No arquivo atual ha workers nomeados individualmente, entao o caminho mais direto para a apresentacao e duplicar o bloco do worker.

### Por que demora

O pipeline demora porque le CSV, infere schema, limpa dados, calcula agregacoes, faz join, usa window functions, treina MLlib, salva CSV com `coalesce(1)` e gera graficos no driver. Mesmo com workers em paralelo, algumas partes continuam seriais ou dependem de shuffle.

### Por que 3 workers podem nao reduzir o tempo

- Dataset pequeno nao ocupa todos os cores.
- Poucas particoes geram poucas tasks.
- Workers no mesmo PC dividem o mesmo disco, CPU e memoria fisica.
- `groupBy`, `join` e `Window` podem gastar tempo em shuffle.
- `coalesce(1)` reduz paralelismo na escrita final.
- O driver e os graficos nao escalam com workers.

### Como medir eficiencia

Rode 2, 3 e 4 workers e compare `output/benchmark/cluster_modes.csv`:

```text
speedup = tempo_com_2_workers / tempo_com_N_workers
eficiencia = speedup / (N / 2)
constante de rede aproximada = network_orchestration_overhead
```

Se a eficiencia cair ao adicionar workers, o ganho foi consumido por overhead, shuffle, disco ou rede.


## Configuracao simples para 2 PCs

O essencial e o PC2 saber o IP do PC1. Para evitar digitar o IP varias vezes, use `cluster.env`.

Nos dois PCs:

```bash
cp cluster.env.example cluster.env
```

No PC1, descubra o IP:

```bash
hostname -I | awk '{print $1}'
```

Edite `cluster.env` nos dois PCs:

```text
SPARK_MASTER_IP=<IP_DO_PC1>
SPARK_DATA_MODE=sample
```

PC1 sobe o master e o worker local:

```bash
scripts/run_cluster_pc1.sh master
```

A Spark UI deve mostrar 1 worker vivo no PC1. Depois, no PC2, suba o worker remoto usando o IP impresso pelo PC1:

```bash
scripts/run_cluster_pc2.sh <IP_DO_PC1>
```

A Spark UI deve passar para 2 workers vivos. Esse e o ponto visual que mostra os dois PCs disponiveis para executar tarefas.

PC1 submete o job:

```bash
scripts/run_cluster_pc1.sh submit
```

PC1 mede o tempo LAN:

```bash
scripts/run_cluster_pc1.sh benchmark
```

Para dados reais, troque no `cluster.env`:

```text
SPARK_DATA_MODE=raw
```

Nesse caso, rode `scripts/setup_data.sh` nos dois PCs antes.

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
scripts/run_distributed_worker.sh 192.168.0.10
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
