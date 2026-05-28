# Saber Roger

Responsavel por abertura, arquitetura, Docker, Spark UI, pipeline de temperatura, cache, Q1-Q4, benchmark e defesa de distribuicao.

## Estado final da entrega

Material principal de avaliacao:

```text
relatorio_latex/relatorio.pdf
```

Material executavel:

```text
notebooks/apresentacao_spark_clima.ipynb
notebooks/apresentacao_spark_clima_com_outputs.ipynb
```

Entrega zipada:

```text
entrega_spark_sd_uel.zip
```

O notebook limpo nao tem outputs. O notebook `com_outputs` foi executado com:

```text
DATA_MODE=raw
SPARK_MASTER=local[2]
tempo: 337.14s
```

Commits finais:

```text
612cc63 docs: add final report and notebooks
f46f8fd chore: add final delivery zip
```

## Abertura

```text
Este e o trabalho proposto pelo professor. O objetivo foi construir um pipeline Spark real para analisar dados climaticos e CO2, responder as perguntas pedidas, mostrar Docker, validar dois PCs pela Spark UI e discutir desempenho com cache, workers e overhead.
```

Frase curta:

```text
O PDF e o material principal de avaliacao. O notebook mostra o mesmo fluxo rodando passo a passo.
```

## Arquitetura

| Componente | Papel |
|---|---|
| Driver | Submete o job, cria a SparkSession e coordena actions |
| Master | Registra workers e agenda recursos |
| Worker | Oferece CPU e memoria |
| Executor | Roda tasks nos workers |
| Spark UI | Mostra workers, executors, jobs, stages e tasks |

Docker local:

```text
spark-master
spark-worker-1
spark-worker-2
spark-app
```

Frase pronta:

```text
Docker cria o ambiente isolado. Spark e quem distribui o processamento. No Compose local, simulamos um cluster com master, workers e app em containers separados.
```

Dois PCs:

```text
PC1: master Spark, worker local e driver
PC2: worker remoto conectado ao master do PC1
URL: spark://<IP_DO_PC1>:7077
UI: http://<IP_DO_PC1>:8080
```

Ponto essencial:

```text
O projeto nao usa HDFS. No modo raw, os dados precisam estar replicados nos dois PCs em /app/data/raw. O processamento e distribuido em particoes e tasks, mas os arquivos precisam existir localmente para os executors lerem.
```

## Onde esta a divisao

A divisao e interna do Spark, nas particoes dos DataFrames.

| Operacao | Como divide |
|---|---|
| `spark.read.csv` | Cria particoes |
| `repartition(8, "Country")` | Forca particoes por pais |
| `groupBy` | Redistribui por chave |
| `join` | Coloca chaves iguais juntas |
| `Window.partitionBy` | Calcula janelas por grupo |
| `cache` | Mantem particoes nos executors |
| `count`, `show`, `write` | Disparam jobs, stages e tasks |

Frase pronta:

```text
DataFrame e uma tabela distribuida. Transformacoes montam o plano. Actions disparam execucao. O Spark quebra o plano em jobs, stages e tasks. Cada task processa uma particao em um executor.
```

## O que mostrar na Spark UI

1. `Workers`: quantos workers estao vivos.
2. `Alive Workers`: deve mostrar 2 no modo 2 PCs.
3. `Total Cores` e `Total Memory`: recursos somados.
4. `Running Applications`: aplicacao `climate-spark-analysis`.
5. Aba da aplicacao: executors, jobs, stages e tasks.
6. Stages com shuffle: custo de redistribuicao.

Se perguntarem se worker vivo prova processamento:

```text
Worker vivo prova que o cluster aceitou a maquina. Para provar processamento, olhamos executors, tasks, hosts e stages durante o job.
```

## Fluxo do pipeline

```text
ler CSV
limpar temperatura
limpar CO2
criar year, month, decade e country_norm
agregar temperatura por cidade, pais, ano e decada
cruzar temperatura e CO2 por country_norm + year
responder Q1-Q8
gerar CSVs, Parquet, graficos e notebook com outputs
```

## Q1 a Q4

### Q1: media global por decada

- Funcao: `global_decade_trend`.
- Logica: media anual global, depois media por decada, depois media movel.
- Spark: `groupBy`, `avg`, `Window`.
- Resultado: 1980 = 17.9578, 1990 = 18.2497, 2000 = 18.5268, 2010 = 18.6335.

Defesa:

```text
Agregamos por ano antes da decada para evitar misturar diretamente todos os meses. A media movel suaviza ruido.
```

### Q2: anos mais quentes por continente

- Funcao: `hottest_years_by_continent`.
- Logica: mapear pais para continente, agregar por continente e ano, ranquear.
- Spark: `groupBy`, `avg`, `row_number`, `Window.partitionBy`.
- Exemplos: Africa 2010, Asia 2013, Europe 2007, North America 2013, Oceania 1998, South America 2002.

### Q3: cidades em risco

- Funcao: `riskiest_cities`.
- Logica: risco = maior desvio padrao de temperatura.
- Spark: `stddev_pop`, `groupBy`, `orderBy`.
- Top: Heihe, Blagoveshchensk, Kyzyl, Hailar, Yakeshi.

Defesa:

```text
O ranking mede instabilidade, nao aquecimento recente. Cidades frias continentais aparecem porque variam muito entre inverno e verao.
```

### Q4: tropical minima e maxima

- Funcao: `tropical_min_max_correlation_df`.
- Problema: a base nao tem Tmin e Tmax reais.
- Proxy: menor media mensal anual e maior media mensal anual em latitudes entre -23.5 e 23.5.
- Resultado: Pearson = 0.4220.

Defesa:

```text
Nao inventamos coluna inexistente. Usamos uma aproximacao defensavel com a base disponivel. Isso suaviza extremos diarios, mas responde com coerencia.
```

## Performance e cache

| Caso | Tempo |
|---|---:|
| Q1-Q8 com cache | 20.3530s |
| Q1-Q8 sem cache | 118.4348s |
| Ganho aproximado | 5.82x |

Frase pronta:

```text
Nesta carga, cache foi mais importante que adicionar outro computador, porque varias perguntas reutilizam as mesmas bases limpas e joins.
```

## Benchmark local vs LAN

| Modo | Workers | Wall | Spark | Overhead |
|---|---:|---:|---:|---:|
| local-compose | 2 no PC1 | 158s | 35.4613s | 122.5387s |
| lan-cluster | 1 no PC1 + 1 no PC2 | 188s | 43.8593s | 144.1407s |

```text
speedup_lan_vs_local = 158 / 188 = 0.84
eficiencia_lan = 0.84 / 2 = 0.42
diferenca_de_overhead = 21.6020s
```

Defesa:

```text
O processamento foi distribuido, mas nao foi mais rapido nesta rodada. A Spark UI mostrou dois workers vivos e executors em hosts diferentes. O custo de rede, Docker, submit, shuffle, escrita e trechos seriais superou o ganho de CPU.
```

## Por que mais workers podem nao acelerar

```text
Mais workers so ajudam se houver particoes suficientes, CPU ocupada e overhead menor que o ganho. Se o gargalo for shuffle, disco, rede, driver, coalesce(1), graficos no driver ou Window sem partitionBy, o tempo pode ficar parecido.
```

Aviso visto:

```text
WindowExec: No Partition Defined for Window operation
```

## Comandos

```bash
scripts/run_demo.sh
scripts/run_all.sh
scripts/run_distributed_master_pc1.sh
scripts/run_distributed_worker_pc2.sh <IP_DO_PC1>
scripts/run_distributed_submit_pc1.sh <IP_DO_PC1> sample
scripts/run_distributed_submit_pc1.sh <IP_DO_PC1> raw
scripts/benchmark_cluster_modes.sh local-compose raw
scripts/benchmark_cluster_modes.sh lan-cluster <IP_DO_PC1> raw
scripts/stop_distributed.sh
```

## Perguntas provaveis

**Docker distribui?**  
Nao. Docker cria containers. Spark distribui processamento.

**Onde os dados sao distribuidos?**  
Os arquivos raw sao replicados nos PCs. O processamento e distribuido em particoes e tasks.

**O que prova a distribuicao?**  
Spark UI, workers vivos, executors, stages, tasks e hosts.

**Por que o cluster LAN foi mais lento?**  
Porque overhead de rede, Docker, submit, shuffle e partes seriais superou o ganho.

**Por que cache ajudou tanto?**  
Porque evita recalcular limpeza, agregacoes e joins usados por varias perguntas.

## Fechamento

```text
O trabalho mostra um pipeline Spark completo: leitura de CSVs reais, limpeza, normalizacao, agregacoes, join entre temperatura e CO2, window functions, cache, MLlib, graficos, PDF, notebook executado, Docker local, dois PCs e analise de desempenho. A parte distribuida aparece porque as operacoes viram planos Spark, jobs, stages e tasks executadas nos workers.
```
