# Plano de Finalizacao do Trabalho Spark

Objetivo: deixar o trabalho correto no codigo, limpo para apresentacao, honesto nas limitacoes e pronto para versionar no repositorio `git@github.com:rodrigomacedo-sjr/spark-sd-uel.git`.

## 1. Corrigir a semantica das respostas

### Q1: Media anual global por decada

Problema atual: o calculo agrupava diretamente por decada usando registros mensais por cidade. Funciona como tendencia, mas nao expressa claramente "media anual global por decada".

Correcao:

1. Calcular media anual global: `year -> avg(AverageTemperature)`.
2. Agrupar anos por decada: `decade -> avg(annual_avg_temperature)`.
3. Calcular media movel sobre as decadas.

Resultado esperado: tabela com `decade`, `avg_annual_temperature`, `moving_avg_temperature`.

### Q4: Correlacao minima/maxima em zonas tropicais

Problema atual: usava `GlobalTemperatures.csv`, que tem minima/maxima globais, mas a pergunta fala de zonas tropicais.

Correcao:

1. Filtrar cidades com `latitude_value` entre `-23.5` e `23.5`.
2. Para cada cidade/ano, interpretar:
   - minima anual aproximada = menor media mensal do ano;
   - maxima anual aproximada = maior media mensal do ano.
3. Calcular Pearson entre minima e maxima anuais aproximadas.

Justificativa: o dataset por cidade nao possui Tmin/Tmax reais. Essa interpretacao usa as medias mensais disponiveis para criar uma proxy tropical defensavel, sem inventar coluna inexistente.

### Q5: Incerteza superior a 10% da media historica

Problema atual: a regra de alta incerteza era ambigua e combinava media historica de incerteza com limite absoluto.

Correcao:

1. Calcular media historica absoluta de temperatura por cidade/pais.
2. Marcar registro quando:

```text
AverageTemperatureUncertainty > 0.10 * abs(historical_avg_temperature)
```

3. Gerar resumo com registros confiaveis e filtrados.

Resultado esperado: regra bate diretamente com "incerteza superior a 10% da media historica".

### Q6: Correlacao entre aumento de CO2 e aumento de temperatura

Problema atual: correlacionava CO2 absoluto com temperatura absoluta.

Correcao:

1. Fazer join pais/ano entre temperatura anual e CO2.
2. Filtrar ultimos 50 anos disponiveis.
3. Para cada pais, pegar primeiro e ultimo ano disponivel no periodo.
4. Calcular:

```text
co2_delta = co2_final - co2_inicial
temp_delta = temp_final - temp_inicial
```

5. Calcular Pearson entre `co2_delta` e `temp_delta` entre paises.

Resultado esperado: responde literalmente "aumento das emissoes" vs "aumento da temperatura".

### Q7: Ultima decada completa vs decada anterior

Problema atual: a "ultima decada" podia ser parcial, pois Berkeley termina por volta de 2013.

Correcao:

1. Detectar a ultima decada completa no dataset.
2. Comparar essa decada com a anterior.
3. Calcular ranking por pais.

Se a ultima decada completa for `2000-2009`, comparar com `1990-1999`.

## 2. Testes antes da implementacao

Criar/ajustar testes para:

- Q1 agregando anos antes de decadas.
- Q4 usando apenas cidades tropicais e min/max anual aproximado.
- Q5 marcando alta incerteza com `10% * abs(media historica)`.
- Q6 calculando deltas por pais antes do Pearson.
- Q7 ignorando decada parcial.

Rodar teste e verificar falha antes da implementacao quando aplicavel.

## 3. Corrigir Docker e 2 PCs

### Local Docker

- Manter `scripts/local_workers_raw.sh 2` para Compose local.
- Manter `scripts/local_workers_raw.sh 2` para Compose local com dados reais.
- Garantir output gravavel no container.
- Fixar imagem Spark em uma tag unica.

### Dois computadores

Criar script separado:

- `scripts/pc1_benchmark_raw.sh`

Fluxo:

1. PC1 sobe master LAN.
2. PC2 sobe worker LAN montando o mesmo caminho do projeto em `/app`.
3. PC1 submete job com `--network host`.
4. Driver anuncia `spark.driver.host=<IP_DO_PC_1>` e portas fixas.

Portas documentadas:

- `7077`: Spark master.
- `8080`: Spark UI master LAN.
- `40444`: driver.
- `40445`: block manager.

## 4. Reescrever documentacao final

### README

Adicionar:

- Instalacao do zero em Ubuntu.
- Como colocar `temperatura_kaggle.zip`.
- Como rodar demo.
- Como rodar real local.
- Como rodar 2 PCs sem conflito.
- Como validar que funcionou.

### RELATORIO

Transformar de scaffold para texto final:

- Incluir resultados numericos reais.
- Incluir tabelas de Q1-Q8.
- Explicar cache com tempos.
- Explicar limitacoes sem parecer desculpa.
- Explicar Spark UI e evidencias.

### SABER_ROGER / SABER_GABRIEL

Transformar em flashcards curtos:

- Roger: Spark arquitetura, limpeza temperatura, Q1-Q4, cache.
- Gabriel: CO2, join, Q5-Q8, Pearson, windows, MLlib.

## 5. Higiene de repositorio

Atualizar `.gitignore` para excluir:

- `.venv/`
- `data/raw/`
- `temperatura_kaggle.zip`
- `output/`
- `output_real/`
- `output_verify/`
- caches Python/Spark
- `docs/superpowers/`
- logs

Nao versionar dados grandes nem artefatos gerados.

## 6. Verificacao final

Rodar:

```bash
bash -n scripts/*.sh
docker compose config
.venv/bin/python -m pytest -q -p no:cacheprovider
docker compose run --rm spark-app python3 -m pytest tests -q
scripts/local_workers_raw.sh 2
scripts/setup_data.sh
```

Se houver tempo:

```bash
scripts/local_workers_raw.sh 2
```

Para 2 PCs, testar no dia:

```bash
# PC1
scripts/pc1_start_raw.sh

# PC2
scripts/pc2_worker_raw.sh <IP_DO_PC1>

# PC1
scripts/pc1_benchmark_raw.sh
```

## 7. Revisao final por subagentes

Depois da implementacao:

1. Subagente runtime: revisar scripts, Docker, 2 PCs e codigo Spark.
2. Subagente docs: revisar README, relatorio, saberes e apresentacao.
3. Subagente repo: revisar gitignore, arquivos a versionar e riscos.

So considerar completo depois de tratar achados criticos/importantes.
