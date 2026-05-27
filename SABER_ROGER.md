# Saber Roger

Responsavel por arquitetura, temperatura, cache e Q1-Q4.

## Visao perfeita para explicar na hora

### Docker + Spark

- Ideia central:

```text
Docker = cria os computadores/processos isolados
Spark = distribui o processamento entre eles
```

- No projeto, o Docker Compose sobe:

```text
spark-master
spark-worker-1
spark-worker-2
spark-app
```

- `spark-master`: coordena o cluster.
- `spark-worker-1` e `spark-worker-2`: executam tarefas.
- `spark-app`: roda o `spark-submit`, que envia o `main.py` para o cluster.

### O que acontece quando roda `scripts/run_demo.sh`

```text
1. cria output/
2. sobe master + workers com docker compose
3. roda spark-submit
4. Spark executa src/climate_spark/main.py
5. main.py le dados sample
6. limpa os dados
7. responde Q1-Q8
8. salva CSVs em output/results/
9. gera graficos em output/plots/
```

### Frase pronta sobre Docker + Spark

- O Docker garante o ambiente com Spark configurado.
- O Spark faz o processamento distribuido.
- O Docker Compose simula o cluster local, separando master, workers e aplicacao em containers.

### Como falar de qualquer pergunta

Use sempre este modelo:

```text
A pergunta pedia X.
A gente transformou os dados para Y.
No Spark usamos Z.
O resultado foi W.
```

### Q1 - Media por decada

- Pedia: evolucao da temperatura media global por decada.
- Logica: media anual global -> media por decada -> media movel.
- Spark: `groupBy`, `avg`, Window.
- Funcao: `global_decade_trend`.
- Resultado: decadas recentes sobem; 1980, 1990, 2000 e 2010 aumentam.

### Q2 - Anos mais quentes por continente

- Pedia: anos mais quentes por continente.
- Logica: pais -> continente, media por continente/ano, ranking.
- Spark: `groupBy`, `avg`, `row_number`, `Window.partitionBy`.
- Funcao: `hottest_years_by_continent`.
- Defesa: dataset nao tinha continente, entao usamos mapeamento pais -> continente.

### Q3 - Cidades em risco

- Pedia: cidades com maior instabilidade.
- Logica: instabilidade = desvio padrao da temperatura.
- Spark: `stddev_pop`, `groupBy`, `orderBy`.
- Funcao: `riskiest_cities`.
- Defesa: cidades frias aparecem porque tem grande variacao entre inverno e verao.

### Q4 - Correlacao tropical minima/maxima

- Pedia: correlacao entre minima e maxima em zonas tropicais.
- Problema: dataset por cidade nao tem Tmin/Tmax reais.
- Logica: proxy = menor media mensal do ano e maior media mensal do ano.
- Spark: filtro por latitude tropical, `min`, `max`, `corr`.
- Funcao: `tropical_min_max_correlation_df`.
- Resultado: Pearson aproximadamente `0.4220`.

### Q5 - Qualidade por incerteza

- Pedia: qualidade de dados por incerteza.
- Logica: incerteza > 10% da media historica da cidade.
- Spark: cria `high_uncertainty`, depois `groupBy` e `count`.
- Funcao: `high_uncertainty_summary`.
- Resultado: alta incerteza `1.608.419`; confiaveis `6.626.663`.

### Q6 - CO2 vs temperatura

- Pedia: correlacao CO2 vs temperatura.
- Problema: temperatura e cidade/mes; CO2 e pais/ano.
- Logica: agregar temperatura por pais/ano, limpar CO2, fazer join, calcular deltas e Pearson.
- Spark: `groupBy`, `join`, Window, `corr`.
- Funcoes: `join_temperature_co2`, `co2_temperature_correlation`.
- Resultado: Pearson `0.0797`, fraco.
- Defesa: nao prova causalidade climatica; demonstra join entre bases e correlacao estatistica pedida.

### Q7 - Aceleracao termica

- Pedia: ranking de aceleracao termica.
- Logica: comparar decada atual com decada anterior por pais.
- Spark: Window Function com `lag`.
- Funcoes: `decade_country_temperatures`, `acceleration_ranking`.
- Resultado: topo inclui Azerbaijan, Kazakhstan, Uzbekistan, Tajikistan, Afghanistan.
- Defesa: usamos ultima decada completa, porque 2010 estava parcial.

### Q8 - Previsao com MLlib

- Pedia: previsao com MLlib.
- Logica: usar ultimos 20 anos de uma cidade/pais e prever proximos 5.
- Spark: `VectorAssembler` + `LinearRegression`.
- Funcao: `forecast_temperature`.
- Resultado: para Sao Paulo, preve 2014 a 2018.
- Defesa: regressao linear simples para demonstrar MLlib, nao modelo climatico completo.

### Frase final forte

- O trabalho inteiro segue o mesmo padrao: limpar dados, padronizar chaves, agregar na granularidade correta, aplicar funcao Spark adequada e salvar resultado.
- A parte distribuida aparece porque essas operacoes rodam como jobs, stages e tasks nos workers do Spark.

## Guia de consulta rapida

### O que dizer sobre sua parte

- Eu fiquei mais na parte de Python, logica basica do Spark, arquitetura local, leitura dos CSVs, limpeza da temperatura, cache e perguntas Q1-Q4.
- O Gabriel ficou mais com CO2, join, qualidade de dados, window functions, MLlib e Q5-Q8.
- Como ele nao vai apresentar, eu consigo explicar a ideia geral da parte dele, principalmente o fluxo e as decisoes tecnicas.
- Se perguntarem algo muito especifico de formula, responda pela logica: limpar dados, padronizar chave, agregar, aplicar funcao Spark e salvar resultado.

### Como rodar a demo rapida

- Comando principal:

```bash
cd /home/roger/uel/sistemas-distribuidos/spark
scripts/run_demo.sh
```

- Esse modo usa `data/sample/`, entao e rapido e seguro para mostrar na frente do professor.
- Ele sobe um cluster Spark local via Docker Compose.
- No fim, olhar:
  - Spark UI: `http://localhost:18080`
  - resultados: `output/results/`
  - graficos: `output/plots/`
- Para parar tudo depois:

```bash
scripts/stop_distributed.sh
```

### Como o Docker entra no projeto

- Docker empacota o ambiente para nao depender do Spark instalado direto na maquina.
- O `Dockerfile` cria a imagem `climate-spark:local` a partir de `apache/spark-py`.
- O `docker-compose.yml` sobe os servicos:
  - `spark-master`: coordena o cluster.
  - `spark-worker-1`: executa tarefas.
  - `spark-worker-2`: executa tarefas.
  - `spark-app`: container usado para submeter o job com `spark-submit`.
- A pasta do projeto e montada dentro dos containers como volume em `/app`.
- Por isso o container enxerga:
  - codigo em `/app/src`;
  - dados em `/app/data`;
  - saidas em `/app/output`.
- Portas importantes no modo local:
  - `7077`: porta do Spark master, usada pelo `spark-submit`.
  - `18080`: Spark UI do master no navegador.
  - `8081` e `8082`: UIs dos workers.

### O que acontece quando roda `run_demo.sh`

- Cria a pasta `output/` e libera permissao de escrita.
- Executa `docker compose up -d --build spark-master spark-worker-1 spark-worker-2`.
- Isso constroi a imagem e sobe 1 master + 2 workers.
- Depois roda `spark-submit` dentro do container `spark-app`.
- O comando envia `src/climate_spark/main.py` para o master `spark://spark-master:7077`.
- O driver monta o plano do Spark.
- O master aloca recursos nos workers.
- Os executors processam as particoes.
- O resultado volta para `output/results/` e os graficos para `output/plots/`.

### Frase pronta sobre Docker + Spark

- O Docker nao e o processamento distribuido em si. Ele so cria o ambiente isolado.
- O Spark e quem distribui o processamento entre master, workers, executors, jobs, stages e tasks.
- No nosso caso, o Docker Compose simula um cluster local com containers separados.

### Fluxo geral do pipeline

- Entrada:
  - `GlobalLandTemperaturesByCity.csv`: temperatura por cidade e mes.
  - `GlobalTemperatures.csv`: temperatura global auxiliar.
  - `owid-co2-data.csv`: CO2 por pais e ano.
- Processo:
  - ler CSV com Spark DataFrame;
  - limpar nulos e tipos;
  - criar `year`, `month`, `decade`;
  - limpar coordenadas;
  - padronizar pais em `country_norm`;
  - remover outliers;
  - marcar alta incerteza;
  - agregar por ano, decada, cidade, pais e continente;
  - cruzar temperatura com CO2 por `country_norm + year`;
  - aplicar correlacao, ranking e regressao linear.
- Saida:
  - CSVs pequenos em `output/results/`;
  - graficos em `output/plots/`.

### Frase pronta sobre ETL

- O projeto e um pipeline ETL: extrai CSVs brutos, transforma com limpeza e agregacao no Spark, e carrega resultados em arquivos CSV e graficos.
- A maior parte do trabalho e limpeza, porque bases reais vem com nulos, granularidades diferentes, nomes divergentes e registros pouco confiaveis.

### Spark basico para responder

- DataFrame: tabela distribuida com schema.
- Transformacao: monta plano, nao executa ainda. Exemplos: `filter`, `select`, `withColumn`, `groupBy`, `join`.
- Action: forca execucao. Exemplos: `count`, `collect`, `write`.
- Lazy evaluation: Spark espera uma action para otimizar o plano inteiro antes de rodar.
- Particao: pedaco do DataFrame.
- Task: trabalho sobre uma particao.
- Stage: fase do job.
- Shuffle: redistribuicao de dados entre particoes, comum em `groupBy`, `join`, `orderBy` e window.
- Cache: guarda DataFrames reutilizados para evitar recalcular limpeza e agregacoes.

### Parte do Gabriel em resumo

- Q5 qualidade: marca registros onde a incerteza passa de 10% da media historica absoluta da cidade.
- Q6 CO2 + temperatura: agrega temperatura por pais/ano, limpa CO2 por pais/ano e faz join por `country_norm + year`. Depois calcula Pearson entre aumento de CO2 e aumento de temperatura.
- Q7 aceleracao termica: usa window function com `lag()` para comparar a decada atual com a decada anterior por pais.
- Q8 previsao: usa Spark MLlib com regressao linear simples. O ano vira feature e a temperatura vira label. O modelo preve os 5 anos seguintes.
- Explicacao defensavel: a parte dele usa tecnicas mais avancadas do Spark, mas a logica geral segue o mesmo pipeline: limpar, agregar, cruzar, calcular e salvar.

### Perguntas dificeis e respostas curtas

- Por que Q4 usa proxy?
  - A base por cidade nao tem Tmin/Tmax reais. Usamos menor e maior media mensal por cidade/ano em zonas tropicais como aproximacao defensavel.
- Por que Q6 deu correlacao fraca?
  - Porque CO2 anual absoluto por pais mistura tamanho economico, populacao, geografia e latitude. O objetivo tecnico era demonstrar join e Pearson no Spark.
- Por que Q7 ignora a decada de 2010?
  - Porque a base termina por volta de 2013, entao 2010 e parcial. Para comparar justo, usamos a ultima decada completa.
- Por que cidades frias aparecem na Q3?
  - Porque a metrica e desvio padrao. Cidades continentais frias tem grande variacao entre inverno e verao.
- Por que remover World/Asia/Europe do CO2?
  - Porque sao agregados, nao paises. Se entrassem, distorceriam analise por pais.

## Perguntas do trabalho: resposta + logica + Spark/codigo

### Q1 - Media movel de temperatura por decada

- Pergunta: qual a evolucao da temperatura media anual global por decada?
- Logica:
  - pegar temperatura limpa;
  - calcular media anual global por `year`;
  - agrupar por `decade`;
  - calcular media movel nas decadas.
- Spark/codigo:
  - funcao: `global_decade_trend(reliable_city)` em `analytics.py`;
  - usa `groupBy("year", "decade")`, `avg("AverageTemperature")`, outro `groupBy("decade")` e window `rowsBetween(-2, 0)`.
- Resultado para falar:
  - ultimas decadas subiram: 1980 = 17.9578, 1990 = 18.2497, 2000 = 18.5268, 2010 = 18.6335.
- Defesa curta:
  - primeiro agregamos por ano para nao misturar diretamente todos os meses; depois a decada resume a tendencia.

### Q2 - 10 anos mais quentes por continente

- Pergunta: quais foram os anos mais quentes para cada continente nos ultimos 50 anos?
- Logica:
  - adicionar continente a partir do pais;
  - filtrar ultimos 50 anos disponiveis;
  - calcular media por `continent + year`;
  - ranquear por continente.
- Spark/codigo:
  - funcoes: `with_continent()` e `hottest_years_by_continent(reliable_city)`;
  - usa `groupBy("continent", "year")`, `avg`, `Window.partitionBy("continent")` e `row_number()`.
- Resultado para falar:
  - exemplos de primeiros: Africa 2010, Asia 2013, Europe 2007, North America 2013, South America 2002.
- Defesa curta:
  - como a base nao tem continente, criamos mapeamento pais -> continente.

### Q3 - Cidades em risco / instabilidade climatica

- Pergunta: quais cidades tiveram maior desvio padrao de temperatura no ultimo seculo?
- Logica:
  - filtrar ultimos 100 anos disponiveis;
  - agrupar por cidade e pais;
  - calcular desvio padrao populacional da temperatura;
  - ordenar desc e pegar top.
- Spark/codigo:
  - funcao: `riskiest_cities(reliable_city)`;
  - usa `filter(year >= max_year - 99)`, `groupBy("City", "Country")`, `stddev_pop`, `count`, `orderBy(desc)`.
- Resultado para falar:
  - topo: Heihe, Blagoveshchensk, Kyzyl, Hailar, Yakeshi.
- Defesa curta:
  - risco aqui foi definido pelo enunciado como instabilidade, entao usamos desvio padrao. Cidades frias continentais aparecem porque variam muito entre inverno e verao.

### Q4 - Correlacao entre minima e maxima em zonas tropicais

- Pergunta: existe correlacao entre aumento da temperatura minima e maxima em zonas tropicais?
- Logica:
  - base por cidade nao tem Tmin/Tmax reais;
  - filtrar zonas tropicais por latitude entre -23.5 e 23.5;
  - usar proxy anual: menor media mensal = minima aproximada, maior media mensal = maxima aproximada;
  - calcular Pearson.
- Spark/codigo:
  - funcao: `tropical_min_max_correlation_df(reliable_city)`;
  - usa `filter(latitude_value.between(-23.5, 23.5))`, `groupBy("City", "Country", "year")`, `min`, `max`, `corr`.
- Resultado para falar:
  - Pearson = 0.4220.
- Defesa curta:
  - nao inventamos coluna inexistente; usamos proxy baseada nas medias mensais disponiveis.

### Q5 - Qualidade de dados por incerteza

- Pergunta: identificar registros onde a incerteza passa de 10% da media historica.
- Logica:
  - durante limpeza, calcular media historica absoluta por cidade;
  - criar limite = 10% dessa media;
  - marcar `high_uncertainty` quando a incerteza passa do limite;
  - contar confiaveis vs alta incerteza.
- Spark/codigo:
  - limpeza em `clean_city_temperatures()`;
  - resumo em `high_uncertainty_summary(city_clean)`;
  - usa `groupBy("high_uncertainty")` e `count()`.
- Resultado para falar:
  - alta incerteza: 1.608.419 registros;
  - confiaveis: 6.626.663 registros.
- Defesa curta:
  - isso separa registros menos confiaveis sem apagar o dado bruto original.

### Q6 - Correlacao CO2 vs aquecimento com join

- Pergunta: existe correlacao Pearson entre aumento de CO2 e aumento de temperatura por pais nos ultimos 50 anos?
- Logica:
  - temperatura vem por cidade/mes;
  - CO2 vem por pais/ano;
  - primeiro agregamos temperatura para pais/ano;
  - limpamos CO2 e removemos agregados como World/Asia/Europe;
  - fazemos join por `country_norm + year`;
  - para cada pais, calculamos delta de CO2 e delta de temperatura nos ultimos 50 anos;
  - aplicamos Pearson entre esses deltas.
- Spark/codigo:
  - funcoes: `annual_country_temperatures()`, `clean_co2()`, `join_temperature_co2()`, `co2_temperature_correlation()`;
  - usa `groupBy`, `join`, `Window.partitionBy("Country")`, `first`, `last`, `corr`.
- Resultado para falar:
  - Pearson = 0.0797, correlacao fraca.
- Defesa curta:
  - tecnicamente cumpre join + Pearson. Cientificamente, CO2 anual absoluto por pais mistura economia, populacao, latitude e geografia; nao e modelo causal climatico.

### Q7 - Ranking de aceleracao termica com Window Functions

- Pergunta: quais paises aqueceram mais rapido na ultima decada completa comparada com a anterior?
- Logica:
  - partir da temperatura anual por pais;
  - agregar por pais e decada;
  - ignorar decada parcial;
  - usar `lag()` para pegar decada anterior;
  - calcular delta de aquecimento e aceleracao;
  - ordenar top 10.
- Spark/codigo:
  - funcoes: `decade_country_temperatures(annual_country)` e `acceleration_ranking(..., complete_decades_only=True)`;
  - usa `withColumn("decade")`, `groupBy("Country", "decade")`, `Window.partitionBy("Country").orderBy("decade")`, `lag`, `orderBy(desc)`.
- Resultado para falar:
  - topo: Azerbaijan, Kazakhstan, Uzbekistan, Tajikistan, Afghanistan.
- Defesa curta:
  - usamos 2000-2009 como ultima decada completa porque 2010 estava parcial na base.

### Q8 - Previsao com Spark MLlib

- Pergunta: prever temperatura dos proximos 5 anos para cidade/pais usando ultimos 20 anos.
- Logica:
  - agregar temperatura anual por cidade/pais;
  - filtrar cidade e pais escolhidos;
  - usar ultimos 20 anos como treino;
  - treinar regressao linear simples;
  - prever 5 anos depois do ultimo ano disponivel.
- Spark/codigo:
  - funcao: `forecast_temperature(annual_city, args.city, args.country)`;
  - usa `VectorAssembler(inputCols=["year"], outputCol="features")` e `LinearRegression(featuresCol="features", labelCol="avg_temperature")`.
- Resultado para falar:
  - para Sao Paulo/Brazil, previsoes 2014 a 2018: 20.5780, 20.5762, 20.5745, 20.5727, 20.5710.
- Defesa curta:
  - e uma regressao linear simples para demonstrar MLlib, nao uma previsao climatica robusta. Ela aprende tendencia historica de `year -> temperatura`.

### Onde isso aparece no `main.py`

- `main.py` cria os DataFrames base:
  - `reliable_city`: temperatura limpa e confiavel;
  - `annual_country`: temperatura anual por pais;
  - `annual_city`: temperatura anual por cidade;
  - `joined`: temperatura + CO2 por pais/ano.
- Depois chama Q1 a Q8 e salva tudo com `write_result()` em `output/results/`.
- Com cache ligado, materializa `reliable_city`, `annual_country`, `annual_city` e `joined` com `count()` para reaproveitar nas perguntas.

## Flashcards

**Qual e a arquitetura?**  
Spark master coordena. Workers executam. Driver monta o plano e submete jobs. Executors rodam tasks nos workers.

**Onde aparece distribuicao?**  
Na Spark UI: workers registrados, executores, stages e tasks.

**O que e lazy evaluation?**  
`filter`, `select` e `groupBy` montam plano. Nada roda ate uma action, como `count`, `write` ou `collect`.

**O que causa shuffle?**  
`groupBy`, `join`, `orderBy` e window quando precisa reorganizar dados entre particoes.

**Por que DataFrame e nao RDD puro?**  
DataFrame tem otimizador Catalyst, schema, funcoes prontas e SQL-like API. Para este trabalho, fica mais limpo e rapido.

**Como limpamos temperatura?**  
Removemos nulos, convertemos data, criamos ano/mes/decada, convertemos coordenadas, removemos outliers fisicos e marcamos alta incerteza.

**Qual regra de incerteza?**  
`AverageTemperatureUncertainty > 10% * abs(media historica da cidade)`.

**Por que cache ajuda?**  
As perguntas reutilizam temperatura limpa e joins. Com cache, Spark nao recalcula tudo a cada pergunta.

## Q1

Media anual global primeiro, depois media por decada e media movel. Ultimas decadas mostram aumento: 1980 = 17.9578, 1990 = 18.2497, 2000 = 18.5268, 2010 = 18.6335.

## Q2

Mapeamos pais para continente e ranqueamos anos com `row_number`. Exemplos: Africa 2010, Asia 2013, Europa 2007.

## Q3

Risco = desvio padrao. Cidades frias continentais aparecem no topo porque variam muito entre inverno e verao.

## Q4

A base por cidade nao tem Tmin/Tmax reais. Usamos proxy tropical: menor e maior media mensal por cidade/ano entre latitudes -23.5 e 23.5. Pearson = 0.4220.
