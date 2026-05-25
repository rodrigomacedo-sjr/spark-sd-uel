# Resultados Reais Gerados

Execucao validada em 2026-05-25 com os dados reais extraidos de `temperatura_kaggle.zip` e CO2 OWID baixado por `scripts/setup_data.sh`.

## Q1: Media anual global por decada

O pipeline calcula media anual primeiro e depois agrega por decada.

| Decada | Media anual | Media movel |
|---|---:|---:|
| 1980 | 17.9578 | 17.8420 |
| 1990 | 18.2497 | 18.0012 |
| 2000 | 18.5268 | 18.2448 |
| 2010 | 18.6335 | 18.4700 |

## Q2: Anos mais quentes por continente

Primeiros colocados:

| Continente | Ano | Media |
|---|---:|---:|
| Africa | 2010 | 24.1887 |
| Asia | 2013 | 21.3166 |
| Europe | 2007 | 9.9243 |
| North America | 2013 | 18.2733 |
| Oceania | 1998 | 16.3499 |
| South America | 2002 | 21.9883 |

## Q3: Cidades com maior desvio padrao

| Cidade | Pais | Desvio padrao |
|---|---|---:|
| Heihe | Russia | 16.4134 |
| Blagoveshchensk | Russia | 16.4134 |
| Kyzyl | Russia | 16.3454 |
| Hailar | China | 16.3026 |
| Yakeshi | China | 16.3026 |

## Q4: Correlacao tropical minima/maxima aproximada

Como o CSV por cidade nao tem Tmin/Tmax reais, usamos proxy: menor e maior media mensal de cada cidade tropical em cada ano.

```text
Pearson = 0.4220268963949332
```

## Q5: Qualidade por incerteza

Regra: `AverageTemperatureUncertainty > 0.10 * abs(media historica da cidade)`.

| Alta incerteza | Registros |
|---|---:|
| true | 1.608.419 |
| false | 6.626.663 |

## Q6: Aumento de CO2 vs aumento de temperatura

Calculamos delta por pais nos ultimos 50 anos disponiveis:

```text
co2_delta = co2_final - co2_inicial
temp_delta = temp_final - temp_inicial
Pearson = 0.07968357901250334
```

Interpretacao: no recorte pais/ano e usando CO2 anual absoluto, a relacao entre aumentos fica fraca. Isso mostra o join e a correlacao pedidos, mas nao e um modelo climatico causal.

## Q7: Aceleracao termica

Comparamos a ultima decada completa disponivel com a anterior.

| Pais | Decada | Aceleracao |
|---|---:|---:|
| Azerbaijan | 2000 | 0.4929 |
| Kazakhstan | 2000 | 0.4900 |
| Uzbekistan | 2000 | 0.4680 |
| Tajikistan | 2000 | 0.4657 |
| Afghanistan | 2000 | 0.4562 |

## Q8: Previsao MLlib

Para `São Paulo, Brazil`, a base termina antes dos anos atuais. O modelo projeta os 5 anos seguintes ao ultimo ano disponivel.

| Ano | Temperatura prevista |
|---:|---:|
| 2014 | 20.5780 |
| 2015 | 20.5762 |
| 2016 | 20.5745 |
| 2017 | 20.5727 |
| 2018 | 20.5710 |

## Comparativo cache

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
