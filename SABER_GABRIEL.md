# Saber Gabriel

Responsavel por CO2, join, qualidade, window functions, MLlib e Q5-Q8.

## Papel na apresentacao

- Explicar a parte mais analitica e avancada do trabalho.
- Conectar temperatura com CO2.
- Defender Q5-Q8.
- Mostrar que o projeto nao ficou so em media simples: teve join, Pearson, window functions e MLlib.

## Roteiro Gabriel - 30 minutos

### Entrada recomendada

- Depois do Rodrigo explicar arquitetura, limpeza e Q1-Q4, entrar dizendo:

```text
A partir da base limpa, minha parte usa a temperatura agregada e cruza com CO2. Aqui entram as partes mais especificas do Spark: join entre bases, window functions e MLlib.
```

### Tempo sugerido

| Tempo | Tema | Fala principal |
|---:|---|---|
| 18:00-19:00 | Ponte | Temperatura mensal vira pais/ano para cruzar com CO2. |
| 19:00-20:30 | Q5 | Qualidade de dados por incerteza. |
| 20:30-22:30 | Q6 | Join temperatura + CO2 e Pearson. |
| 22:30-24:00 | Q7 | Window functions para aceleracao termica. |
| 24:00-25:30 | Q8 | MLlib com regressao linear. |
| 25:30-27:00 | Limitacoes | Correlacao fraca, decada parcial, previsao simples. |

## Conceitos que preciso dominar

### Join

- Join cruza duas tabelas por uma chave comum.
- Problema do trabalho:
  - temperatura: cidade + mes;
  - CO2: pais + ano.
- Solucao:
  - agregar temperatura para `country_norm + year`;
  - limpar CO2 para `country_norm + year`;
  - fazer join pelas duas colunas.
- Frase pronta:
  - O principal desafio do join foi compatibilizar granularidades diferentes: cidade/mes contra pais/ano.

### Pearson

- Coeficiente entre -1 e 1.
- Perto de 1: relacao positiva forte.
- Perto de 0: relacao fraca.
- Perto de -1: relacao negativa forte.
- No projeto, Q6 deu `0.0797`, entao a correlacao no recorte usado ficou fraca.
- Defesa:
  - Isso nao invalida o trabalho, porque o requisito tecnico era fazer join e correlacao estatistica. CO2 anual absoluto por pais nao isola populacao, economia, latitude, CO2 acumulado nem causalidade climatica.

### Window Function

- Window function calcula uma linha olhando outras linhas relacionadas.
- Na Q7, usamos `lag()` para olhar a decada anterior do mesmo pais.
- Sem window, seria mais dificil comparar decada atual e anterior mantendo o contexto por pais.
- Frase pronta:
  - A window partitiona por pais e ordena por decada. Assim cada pais compara sua propria evolucao historica.

### MLlib

- MLlib e a biblioteca de machine learning do Spark.
- Na Q8 usamos `LinearRegression`.
- `VectorAssembler` transforma `year` em vetor de features.
- Label: `avg_temperature`.
- O modelo aprende uma tendencia simples ano -> temperatura.
- Defesa:
  - E uma regressao linear simples para demonstrar MLlib, nao uma previsao climatica profissional.

## Q5 - Qualidade de dados

- Pergunta: identificar registros onde a incerteza da medicao passa de 10% da media historica.
- Logica:
  - calcular media historica absoluta por cidade;
  - limite = 10% dessa media;
  - marcar `high_uncertainty` quando `AverageTemperatureUncertainty` passa do limite;
  - contar true/false.
- Spark/codigo:
  - limpeza: `clean_city_temperatures()`;
  - resumo: `high_uncertainty_summary(city_clean)`;
  - usa `groupBy("high_uncertainty")` e `count()`.
- Resultado:
  - Alta incerteza: `1.608.419` registros.
  - Confiaveis: `6.626.663` registros.
- Fala pronta:
  - Essa pergunta avalia qualidade dos dados. Em vez de assumir que toda medicao e igualmente confiavel, criamos uma regra objetiva de incerteza baseada na media historica da cidade.

## Q6 - CO2 vs aquecimento

- Pergunta: existe correlacao entre aumento de CO2 e aumento de temperatura por pais nos ultimos 50 anos?
- Logica:
  - temperatura limpa -> media anual por pais;
  - CO2 limpo -> pais/ano;
  - remover agregados como `World`, `Asia`, `Europe`;
  - fazer join por `country_norm + year`;
  - pegar primeiro e ultimo ano disponivel por pais;
  - calcular `co2_delta` e `temperature_delta`;
  - aplicar Pearson.
- Spark/codigo:
  - `annual_country_temperatures()`;
  - `clean_co2()`;
  - `join_temperature_co2()`;
  - `co2_temperature_correlation()`;
  - usa `join`, `Window.partitionBy("Country")`, `first`, `last`, `corr`.
- Resultado:
  - Pearson = `0.0797`.
- Fala pronta:
  - A correlacao ficou fraca nesse recorte. Isso e esperado porque emissoes anuais absolutas por pais misturam tamanho economico, populacao e geografia. O ponto tecnico foi demonstrar o join entre duas bases e a correlacao no Spark.

## Q7 - Ranking de aceleracao termica

- Pergunta: quais paises tiveram maior aceleracao de aquecimento na ultima decada em comparacao com a anterior?
- Logica:
  - temperatura anual por pais;
  - agregar por decada;
  - manter decadas completas;
  - usar `lag()` para pegar temperatura da decada anterior;
  - calcular delta e aceleracao;
  - ordenar top 10.
- Spark/codigo:
  - `decade_country_temperatures(annual_country)`;
  - `acceleration_ranking(..., complete_decades_only=True)`;
  - usa `Window.partitionBy("Country").orderBy("decade")` e `lag()`.
- Resultado:
  - Top: Azerbaijan, Kazakhstan, Uzbekistan, Tajikistan, Afghanistan.
- Defesa:
  - A decada de 2010 e parcial porque a base termina por volta de 2013. Por isso usamos a ultima decada completa, 2000-2009.

## Q8 - Previsao com MLlib

- Pergunta: prever a temperatura dos proximos 5 anos para uma cidade/pais usando historico dos ultimos 20 anos.
- Logica:
  - temperatura anual por cidade/pais;
  - filtrar cidade e pais;
  - pegar ultimos 20 anos;
  - treinar regressao linear simples;
  - prever 5 anos apos o ultimo ano disponivel.
- Spark/codigo:
  - `forecast_temperature(annual_city, city, country)`;
  - `VectorAssembler(inputCols=["year"], outputCol="features")`;
  - `LinearRegression(featuresCol="features", labelCol="avg_temperature")`.
- Resultado para Sao Paulo:
  - 2014: `20.5780`;
  - 2015: `20.5762`;
  - 2016: `20.5745`;
  - 2017: `20.5727`;
  - 2018: `20.5710`.
- Defesa:
  - A base termina antes dos anos atuais. Por isso os anos previstos sao os 5 anos depois do ultimo ano disponivel para Sao Paulo.

## Perguntas provaveis do professor

**Por que remover World/Asia/Europe da OWID?**  
Porque sao agregados, nao paises. Se entrassem no join, distorceriam Pearson e rankings.

**Por que Pearson baixo nao invalida Q6?**  
Porque o requisito era fazer join e correlacao estatistica. O resultado baixo e uma interpretacao valida do recorte escolhido.

**Por que usar CO2 absoluto e nao per capita?**  
Porque o enunciado pedia emissoes de CO2 de um pais. A base tambem tem `co2_per_capita`, mas usamos `co2` anual absoluto para manter a regra direta.

**Por que usar regressao linear simples?**  
Porque o requisito pedia regressao linear simples com MLlib. Modelos climaticos reais seriam muito mais complexos.

**Por que usar window na Q7?**  
Porque precisamos comparar cada pais com sua propria decada anterior. `lag()` resolve exatamente esse caso.

## Frase final Gabriel

- Minha parte mostra a integracao e as tecnicas avancadas: qualidade de dados, join entre bases diferentes, Pearson, window functions e MLlib. O resultado nao tenta provar causalidade climatica completa; ele demonstra um pipeline Spark defensavel para responder as perguntas propostas.
