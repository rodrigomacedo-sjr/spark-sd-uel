# Relatorio Tecnico - Analise Climática com Spark


Autores: Rodrigo Macedo (RodrigoMacedo) e Gabriel Peres.
## Arquitetura

O projeto usa Apache Spark com DataFrames em PySpark. No modo local, `docker-compose.yml` sobe um master e dois workers. No modo distribuido de apresentacao, o PC 1 roda o master, tambem roda um worker local e submete o job. O PC 2 roda outro worker conectado por `spark://<IP_DO_PC_1>:7077`. Assim a Spark UI mostra dois workers vivos, um em cada maquina, e o job pode distribuir particoes entre os dois PCs.

Portas usadas no modo 2 PCs:

- `7077`: master Spark.
- `8080`: Spark UI do master.
- `40444`: driver do job.
- `40445`: block manager.

A Spark UI mostra workers, executores, jobs, stages e DAG. Essa e a evidencia visual principal de processamento distribuido.

## Bases usadas

Temperatura:

- Kaggle/Berkeley Earth: `GlobalLandTemperaturesByCity.csv`.
- Apoio do mesmo zip: `GlobalTemperatures.csv`, mantido disponivel, mas a resposta final da Q4 usa o arquivo por cidade para ficar alinhada com zonas tropicais.

CO2:

- OWID: `owid-co2-data.csv`.

## ETL

A limpeza de temperatura faz:

- remove `AverageTemperature` nulo;
- converte `dt` para data;
- extrai `year`, `month`, `decade`;
- converte coordenadas como `23.55S` para `-23.55`;
- remove temperaturas fisicamente absurdas fora de `-90 C` a `70 C`;
- cria `country_norm` para join;
- calcula media historica por cidade;
- marca `high_uncertainty` quando `AverageTemperatureUncertainty > 10%` da media historica absoluta da cidade.

A limpeza de CO2 faz:

- remove agregados como `World`, `Asia`, `Europe`;
- filtra anos a partir de 1900;
- remove linhas sem `co2`;
- normaliza pais em `country_norm`.

Antes do join, temperatura mensal por cidade vira temperatura anual por pais:

```text
country_norm + year -> avg_temperature
```

Depois juntamos com CO2 por:

```text
country_norm + year
```

## Cache

O modo `--cache on` persiste DataFrames reutilizados:

- temperatura limpa;
- CO2 limpo;
- temperatura anual por pais;
- temperatura anual por cidade;
- join temperatura + CO2.

O ganho aparece porque varias perguntas reutilizam as mesmas bases limpas. Nos dados reais, Q6 caiu de `14.3876s` sem cache para `0.6194s` com cache.

## Respostas

### 1. Media anual global por decada

Primeiro calculamos a media anual global; depois agregamos por decada e aplicamos media movel.

| Decada | Media anual | Media movel |
|---|---:|---:|
| 1980 | 17.9578 | 17.8420 |
| 1990 | 18.2497 | 18.0012 |
| 2000 | 18.5268 | 18.2448 |
| 2010 | 18.6335 | 18.4700 |

O resultado mostra aumento nas decadas recentes.

### 2. Anos mais quentes por continente

A funcao mapeia pais para continente, agrega por ano e ranqueia com `row_number()`.

| Continente | Ano mais quente | Media |
|---|---:|---:|
| Africa | 2010 | 24.1887 |
| Asia | 2013 | 21.3166 |
| Europe | 2007 | 9.9243 |
| North America | 2013 | 18.2733 |
| Oceania | 1998 | 16.3499 |
| South America | 2002 | 21.9883 |

### 3. Cidades em risco

A definicao do enunciado e desvio padrao de temperatura. As cidades no topo ficam em regioes continentais frias, com grande amplitude sazonal.

| Cidade | Pais | Desvio padrao |
|---|---|---:|
| Heihe | Russia | 16.4134 |
| Blagoveshchensk | Russia | 16.4134 |
| Kyzyl | Russia | 16.3454 |
| Hailar | China | 16.3026 |
| Yakeshi | China | 16.3026 |

### 4. Correlacao entre minima e maxima em zonas tropicais

O arquivo por cidade nao tem colunas reais de minima e maxima. Para responder usando zonas tropicais, filtramos cidades entre `-23.5` e `23.5` de latitude e usamos uma proxy anual:

- minima anual aproximada: menor media mensal daquele ano;
- maxima anual aproximada: maior media mensal daquele ano.

Pearson encontrado:

```text
0.4220268963949332
```

Isso indica correlacao positiva moderada entre meses mais frios e mais quentes nas cidades tropicais.

### 5. Qualidade dos dados

Regra aplicada:

```text
AverageTemperatureUncertainty > 0.10 * abs(media historica da cidade)
```

| Alta incerteza | Registros |
|---|---:|
| true | 1.608.419 |
| false | 6.626.663 |

### 6. Aumento de CO2 vs aumento de temperatura

Para cada pais nos ultimos 50 anos disponiveis, pegamos primeiro e ultimo ano e calculamos:

```text
co2_delta = co2_final - co2_inicial
temp_delta = temp_final - temp_inicial
```

Pearson entre os deltas:

```text
0.07968357901250334
```

A correlacao ficou fraca. Isso e defensavel: emissoes absolutas anuais por pais misturam tamanho economico, latitude e geografia. O requisito principal aqui e demonstrar join entre bases e correlacao estatistica no Spark.

### 7. Ranking de aceleracao termica

Usamos window functions (`lag`) por pais e comparamos a ultima decada completa com a anterior. Como a base Berkeley termina por volta de 2013, a ultima decada completa usada foi `2000-2009`.

| Pais | Decada | Aceleracao |
|---|---:|---:|
| Azerbaijan | 2000 | 0.4929 |
| Kazakhstan | 2000 | 0.4900 |
| Uzbekistan | 2000 | 0.4680 |
| Tajikistan | 2000 | 0.4657 |
| Afghanistan | 2000 | 0.4562 |

### 8. Previsao com MLlib

Usamos `LinearRegression` do Spark MLlib. Feature: `year`. Label: `avg_temperature`. Para `Rio De Janeiro, Brazil`, a base termina antes dos anos atuais; por isso os 5 anos previstos sao os 5 anos seguintes ao ultimo ano disponivel. O grafico da previsao deve mostrar pontos historicos nao conectados, uma linha de regressao historica e uma linha de previsao.

| Ano | Temperatura prevista |
|---:|---:|
| 2014 | 20.5780 |
| 2015 | 20.5762 |
| 2016 | 20.5745 |
| 2017 | 20.5727 |
| 2018 | 20.5710 |

## Graficos

O pipeline gera:

- `output/plots/global_decade_temperature.png`.
- `output/plots/co2_temperature_scatter.png`.

## Comparativo de tempo

| Pergunta | Com cache (s) | Sem cache (s) |
|---|---:|---:|
| Q1 | 2.3362 | 5.5426 |
| Q2 | 3.9009 | 12.3879 |
| Q3 | 1.7852 | 12.7051 |
| Q4 | 2.4746 | 12.0828 |
| Q5 | 0.9610 | 14.3473 |
| Q6 | 0.6194 | 14.3876 |
| Q7 | 4.3224 | 24.9529 |
| Q8 | 3.9533 | 22.0286 |


## Analise de workers e eficiencia

A configuracao principal do trabalho usa 2 workers. Isso e suficiente para demonstrar processamento distribuido e manter a apresentacao controlada. Testes com 3 workers e 4 workers servem como analise de escalabilidade, nao como requisito da entrega base.

### por que demora

O tempo vem de varias partes: leitura de CSV, inferencia de schema, limpeza, agregacoes, join entre temperatura e CO2, window functions, treino MLlib, escrita de CSV com `coalesce(1)` e geracao de graficos no driver. Nem tudo escala com mais workers.

### mais recursos por worker

Os workers locais estao em `docker-compose.yml`. Cada worker usa:

```text
--cores 2
--memory 2G
```

Para testar mais recursos por worker, pode-se mudar para `--cores 4` e `--memory 4G`, desde que a maquina tenha CPU e memoria suficientes. No modo 2 PCs, a mesma configuracao fica no script `scripts/run_distributed_worker.sh`.

### 3 workers e 4 workers

No Compose atual, os workers estao nomeados como `spark-worker-1` e `spark-worker-2`. Para 3 workers, duplica-se o bloco do worker e cria-se `spark-worker-3`, com porta `8083:8081`. Para 4 workers, cria-se `spark-worker-4`, com porta `8084:8081`.

Se o Compose for refatorado para um servico generico `spark-worker`, a escala poderia ser feita com:

```bash
SPARK_WORKER_CORES=2 SPARK_WORKER_MEMORY=2G docker compose up -d --scale spark-worker=3
SPARK_WORKER_CORES=2 SPARK_WORKER_MEMORY=2G docker compose up -d --scale spark-worker=4
```

As variaveis usadas para documentar o experimento sao:

```text
SPARK_WORKER_CORES
SPARK_WORKER_MEMORY
SPARK_WORKER_INSTANCES
```

### Eficiencia

A comparacao deve ser feita com o script `scripts/benchmark_cluster_modes.sh`, que grava `wall_seconds`, `spark_compute_seconds`, `overhead_seconds` e `network_orchestration_overhead`.

Para comparar N workers contra a base de 2 workers:

```text
speedup = tempo_2_workers / tempo_N_workers
eficiencia = speedup / (N / 2)
constante de rede aproximada = network_orchestration_overhead
```

Se 3 ou 4 workers nao diminuirem o tempo, os motivos provaveis sao: dataset pequeno, poucas particoes, workers competindo pelo mesmo disco no mesmo PC, shuffle alto, escrita final serializada por `coalesce(1)` ou gargalo no driver.

## Limitacoes assumidas

- Q4 usa proxy de minima/maxima anual porque a base por cidade so tem temperatura media mensal.
- Q6 mede relacao estatistica simples, nao causalidade climatica.
- A base termina antes dos anos atuais em varios recortes; por isso Q7 usa decadas completas e Q8 preve anos logo apos o ultimo disponivel.
