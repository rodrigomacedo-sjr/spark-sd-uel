# Plano de Divisao da Apresentacao

## Ordem sugerida

1. Roger abre com arquitetura Spark e Docker.
2. Roger mostra limpeza da temperatura e cache.
3. Roger apresenta Q1-Q4.
4. Gabriel explica CO2, granularidade e join.
5. Gabriel apresenta Q5-Q8.
6. Os dois mostram Spark UI e, se possivel, o worker do PC 2.

## Roger

Dominar:

- master, worker, driver e executor;
- lazy evaluation, DAG, transformations e actions;
- limpeza de temperatura;
- cache e comparativo de tempo;
- Q1, Q2, Q3, Q4.

Perguntas provaveis:

**Por que Q4 e proxy?**  
Porque o dataset por cidade nao tem Tmin/Tmax. A proxy usa menor e maior media mensal por ano em cidades tropicais. E mais fiel a zonas tropicais do que usar temperatura global.

**Por que cidades frias lideram Q3?**  
Porque a metrica pedida e desvio padrao. Regioes continentais frias tem grande variacao sazonal.

## Gabriel

Dominar:

- dataset OWID CO2;
- normalizacao de paises;
- join pais/ano;
- Q5 regra de 10%;
- Q6 deltas e Pearson;
- Q7 window functions;
- Q8 MLlib.

Perguntas provaveis:

**Por que Pearson de Q6 e baixo?**  
Porque o calculo usa delta de CO2 anual absoluto por pais. Isso nao controla populacao, economia, latitude nem CO2 acumulado. Ainda assim cumpre o requisito de join e correlacao estatistica.

**Por que Q7 usa 2000 e nao 2010?**  
Porque 2010 e parcial no dataset. Para comparar decadas de forma justa, usamos a ultima decada completa.

## Demonstracao 2 PCs

PC 1:

```bash
scripts/setup_data.sh
scripts/run_distributed_master_pc1.sh
```

PC 2:

```bash
git clone https://github.com/rodrigomacedo-sjr/spark-sd-uel.git spark
cd spark
scripts/run_distributed_worker_pc2.sh <IP_DO_PC_1>
```

PC 1 submete:

```bash
scripts/run_distributed_submit_pc1.sh <IP_DO_PC_1> sample
```

Para dados reais, PC1 e PC2 precisam ter `temperatura_kaggle.zip` e rodar `scripts/setup_data.sh`.
