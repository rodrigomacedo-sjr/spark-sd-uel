# Saber Gabriel

Responsavel por qualidade dos dados, CO2, join, Pearson, window functions, MLlib, Q5-Q8 e interpretacao dos resultados analiticos.

## Estado final que preciso saber

Material principal:

```text
relatorio_latex/relatorio.pdf
```

Notebooks:

```text
notebooks/apresentacao_spark_clima.ipynb
notebooks/apresentacao_spark_clima_com_outputs.ipynb
```

Notebook com outputs:

```text
DATA_MODE=raw
SPARK_MASTER=local[2]
tempo: 337.14s
```

Zip de entrega:

```text
entrega_spark_sd_uel.zip
```

## Entrada na apresentacao

```text
A partir da base limpa, minha parte usa os dados agregados para analisar qualidade, cruzar temperatura com CO2, calcular correlacao, comparar decadas com window functions e fazer uma previsao simples com MLlib.
```

## Conceitos

### Join

```text
temperatura: cidade + mes
CO2: pais + ano
```

Solucao:

```text
temperatura mensal por cidade -> temperatura anual por pais
CO2 anual por pais -> CO2 anual por pais
join por country_norm + year
```

Frase:

```text
O principal desafio do join foi compatibilizar granularidades diferentes. A temperatura precisava chegar no mesmo nivel do CO2: pais e ano.
```

### Pearson

```text
perto de 1: relacao positiva forte
perto de 0: relacao fraca
perto de -1: relacao negativa forte
```

No projeto:

```text
Q4: 0.4220, positiva moderada
Q6: 0.0797, fraca
```

### Window Function

```text
Window.partitionBy("Country").orderBy("decade")
lag()
```

Frase:

```text
A window separa a historia de cada pais e compara cada decada com a anterior dentro do mesmo pais.
```

### MLlib

```text
VectorAssembler
LinearRegression
feature = year
label = avg_temperature
```

Defesa:

```text
E uma regressao linear simples para demonstrar MLlib no Spark. Nao e um modelo climatico profissional.
```

## Q5: qualidade dos dados

- Funcoes: `clean_city_temperatures`, `high_uncertainty_summary`.
- Regra: `AverageTemperatureUncertainty > 0.10 * abs(media_historica_da_cidade)`.
- Resultado: alta incerteza = 1.608.419; confiaveis = 6.626.663.

Defesa:

```text
A regra nao apaga os dados. Ela cria uma marcacao de qualidade para saber quais registros sao menos confiaveis.
```

Se o professor pedir para mudar percentual:

```text
No notebook, alteramos UNCERTAINTY_RATIO. Se aumentar, menos registros entram como alta incerteza. Se diminuir, mais registros entram.
```

## Q6: CO2 vs aquecimento

- Funcoes: `annual_country_temperatures`, `clean_co2`, `join_temperature_co2`, `co2_temperature_correlation`.
- Join: `country_norm + year`.
- Remove agregados: `World`, `Asia`, `Europe`.
- Calcula `co2_delta` e `temperature_delta`.
- Resultado: Pearson = 0.0797.

Defesa:

```text
A correlacao ficou fraca nesse recorte. Isso nao invalida o trabalho, porque o requisito tecnico era fazer join e correlacao estatistica. CO2 anual absoluto por pais mistura economia, populacao, latitude, geografia e matriz energetica.
```

## Q7: ranking de aceleracao termica

- Funcoes: `decade_country_temperatures`, `acceleration_ranking`.
- Usa `lag()` para comparar decada atual com anterior.
- Mantem decadas completas.
- Top: Azerbaijan, Kazakhstan, Uzbekistan, Tajikistan, Afghanistan.

Defesa:

```text
Usamos 2000-2009 como ultima decada completa porque a base termina por volta de 2013. Comparar 2010-2013 com uma decada cheia seria injusto.
```

Aviso importante:

```text
WindowExec: No Partition Defined for Window operation
```

Como explicar:

```text
Quando uma window nao tem partitionBy, o Spark pode concentrar dados em uma unica particao. Isso reduz paralelismo e ajuda a explicar por que mais workers podem nao reduzir tempo.
```

## Q8: previsao com MLlib

Cidade final:

```text
Rio De Janeiro, Brazil
```

- Funcao: `forecast_temperature`.
- Usa ultimos 20 anos disponiveis.
- `VectorAssembler` transforma `year` em vetor.
- `LinearRegression` treina `year -> avg_temperature`.
- Preve 5 anos depois do ultimo ano da base.

Resultado:

```text
2014: 20.5780
2015: 20.5762
2016: 20.5745
2017: 20.5727
2018: 20.5710
```

Defesa:

```text
A base termina antes dos anos atuais. Por isso a previsao e para os 5 anos apos o ultimo ano disponivel, nao necessariamente para 2026 em diante.
```

Grafico:

```text
Os pontos historicos nao sao conectados. O grafico mostra pontos historicos, linha de regressao e linha de previsao.
```

## Performance

Cache:

| Caso | Tempo |
|---|---:|
| Q1-Q8 com cache | 20.3530s |
| Q1-Q8 sem cache | 118.4348s |
| Ganho | 5.82x |

Benchmark:

| Modo | Wall | Spark | Overhead |
|---|---:|---:|---:|
| local-compose | 158s | 35.4613s | 122.5387s |
| lan-cluster | 188s | 43.8593s | 144.1407s |

Frase:

```text
O cluster distribuiu, mas nao acelerou nessa carga. O cache foi o maior ganho pratico medido.
```

## Perguntas provaveis

**Por que remover World, Asia e Europe da OWID?**  
Porque sao agregados, nao paises. Eles distorceriam analise por pais.

**Por que Pearson baixo nao invalida Q6?**  
Porque o resultado baixo e uma conclusao valida do recorte. O requisito era fazer join e correlacao, nao provar causalidade climatica.

**Por que usar decadas completas na Q7?**  
Para nao comparar 2010-2013 com uma decada cheia.

**Por que usar regressao linear simples?**  
Porque o requisito pedia regressao linear simples com MLlib.

**Por que Rio de Janeiro preve 2014-2018?**  
Porque a base historica termina antes dos anos atuais nesse recorte.

**Por que mais workers podem nao acelerar?**  
Porque overhead, shuffle, rede, driver, coalesce(1), dados pequenos ou window sem partitionBy podem limitar o paralelismo.

## Frase final Gabriel

```text
Minha parte mostra as tecnicas analiticas mais fortes do projeto: qualidade dos dados, join entre bases diferentes, Pearson, window functions e MLlib. Os resultados sao interpretados com cuidado: Q6 nao prova causalidade, Q7 usa decadas completas e Q8 e uma regressao simples para demonstrar MLlib dentro do pipeline Spark.
```
