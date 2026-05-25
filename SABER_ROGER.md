# Saber Roger

Responsavel por arquitetura, temperatura, cache e Q1-Q4.

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
