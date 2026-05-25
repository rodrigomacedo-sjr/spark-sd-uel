# Saber Gabriel

Responsavel por CO2, join, qualidade, window functions, MLlib e Q5-Q8.

## Flashcards

**Qual problema do join?**  
Temperatura vem por cidade/mes. CO2 vem por pais/ano. Primeiro agregamos temperatura para pais/ano, depois fazemos join por `country_norm + year`.

**Por que remover World/Asia/Europe da OWID?**  
Porque sao agregados, nao paises. Se entrassem no join, distorceriam Pearson e rankings.

**O que e Pearson?**  
Coeficiente entre -1 e 1. Perto de 1 = relacao positiva forte. Perto de 0 = relacao fraca.

**Por que Q6 deu baixo?**  
Porque usamos CO2 anual absoluto por pais e delta simples. Isso mistura tamanho do pais, economia e latitude. O objetivo do requisito e mostrar join + correlacao no Spark.

**Como Q7 usa window?**  
`lag()` pega a decada anterior por pais. Calculamos delta de aquecimento e aceleracao.

**Por que Q7 usa 2000?**  
Porque a base termina por volta de 2013; 2010 e parcial. Usamos a ultima decada completa, 2000-2009.

**Como Q8 usa MLlib?**  
`VectorAssembler` transforma `year` em feature. `LinearRegression` aprende tendencia e preve 5 anos apos o ultimo ano disponivel.

## Q5

Alta incerteza: 1.608.419 registros. Confiaveis: 6.626.663 registros. Regra: incerteza maior que 10% da media historica da cidade.

## Q6

Calculamos aumento por pais nos ultimos 50 anos: `co2_delta` e `temp_delta`. Pearson = 0.0797.

## Q7

Top do ranking: Azerbaijan, Kazakhstan, Uzbekistan, Tajikistan, Afghanistan. Todos na decada completa de 2000.

## Q8

Para São Paulo, previsoes: 2014 a 2018, porque esses sao os 5 anos depois do ultimo ano disponivel para essa cidade na base.
