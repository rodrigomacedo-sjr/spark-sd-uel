# Dicionario de Dados

## Entradas

### GlobalLandTemperaturesByCity.csv

- `dt`: data mensal.
- `AverageTemperature`: temperatura media mensal em Celsius.
- `AverageTemperatureUncertainty`: incerteza da medicao.
- `City`: cidade.
- `Country`: pais.
- `Latitude`, `Longitude`: coordenadas com hemisferio.

### owid-co2-data.csv

- `country`: pais ou agregado.
- `year`: ano.
- `co2`: emissoes anuais de CO2.
- `co2_per_capita`: CO2 por habitante.
- `total_ghg`: gases de efeito estufa totais.

## Colunas criadas

- `date`: data convertida.
- `year`: ano.
- `month`: mes.
- `decade`: decada.
- `latitude_value`, `longitude_value`: coordenadas numericas.
- `country_norm`: pais normalizado para join.
- `historical_avg_temperature`: media historica absoluta por cidade.
- `uncertainty_threshold`: 10% da media historica.
- `high_uncertainty`: true quando incerteza passa do limite.
- `avg_temperature`: temperatura media agregada.
- `avg_annual_temperature`: media anual antes da agregacao por decada.
- `pearson_correlation`: correlacao Pearson.
- `warming_delta`: aquecimento entre duas decadas.
- `acceleration`: mudanca do ritmo de aquecimento.
- `predicted_temperature`: previsao MLlib.

## Saidas

- `q1_global_decade_trend`: media anual por decada e media movel.
- `q2_hottest_years_by_continent`: anos mais quentes por continente.
- `q3_riskiest_cities`: cidades com maior desvio padrao.
- `q4_min_max_correlation`: Pearson da proxy tropical minima/maxima.
- `q5_quality_summary`: resumo de alta incerteza.
- `q6_co2_temperature_correlation`: Pearson entre aumento de CO2 e aumento de temperatura.
- `q7_acceleration_ranking`: ranking por window functions.
- `q8_temperature_forecast`: previsao dos 5 anos seguintes ao ultimo disponivel.
