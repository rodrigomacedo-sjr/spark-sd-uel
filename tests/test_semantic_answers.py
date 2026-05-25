from climate_spark.analytics import (
    acceleration_ranking,
    co2_temperature_delta_correlation,
    global_decade_trend,
    tropical_min_max_correlation_value,
)
from climate_spark.cleaning import clean_city_temperatures


def test_q1_averages_years_before_decades(spark):
    df = spark.createDataFrame(
        [
            (2000, 2000, 10.0),
            (2000, 2000, 30.0),
            (2001, 2000, 20.0),
            (2010, 2010, 40.0),
        ],
        ["year", "decade", "AverageTemperature"],
    )

    rows = global_decade_trend(df).orderBy("decade").collect()

    assert rows[0].decade == 2000
    assert rows[0].avg_annual_temperature == 20.0
    assert rows[0].avg_temperature == 20.0
    assert rows[1].decade == 2010


def test_q4_uses_tropical_city_monthly_min_max_proxy(spark):
    df = spark.createDataFrame(
        [
            ("Manaus", "Brazil", 2000, 1, 24.0, -3.1),
            ("Manaus", "Brazil", 2000, 7, 28.0, -3.1),
            ("Manaus", "Brazil", 2001, 1, 25.0, -3.1),
            ("Manaus", "Brazil", 2001, 7, 30.0, -3.1),
            ("Oslo", "Norway", 2000, 1, -5.0, 59.9),
            ("Oslo", "Norway", 2000, 7, 18.0, 59.9),
        ],
        ["City", "Country", "year", "month", "AverageTemperature", "latitude_value"],
    )

    assert tropical_min_max_correlation_value(df) > 0.99


def test_q5_uncertainty_threshold_is_10_percent_of_historical_temperature(spark):
    df = spark.createDataFrame(
        [
            ("2000-01-01", 20.0, 1.0, "Sao Paulo", "Brazil", "23.55S", "46.63W"),
            ("2000-02-01", 22.0, 3.0, "Sao Paulo", "Brazil", "23.55S", "46.63W"),
            ("2000-03-01", 18.0, 2.0, "Sao Paulo", "Brazil", "23.55S", "46.63W"),
        ],
        [
            "dt",
            "AverageTemperature",
            "AverageTemperatureUncertainty",
            "City",
            "Country",
            "Latitude",
            "Longitude",
        ],
    )

    rows = clean_city_temperatures(df).orderBy("month").collect()

    assert [row.high_uncertainty for row in rows] == [False, True, False]
    assert rows[0].historical_avg_temperature == 20.0
    assert rows[0].uncertainty_threshold == 2.0


def test_q6_correlates_country_level_increases(spark):
    df = spark.createDataFrame(
        [
            ("Brazil", 1970, 20.0, 100.0),
            ("Brazil", 2020, 22.0, 300.0),
            ("France", 1970, 10.0, 200.0),
            ("France", 2020, 11.0, 300.0),
            ("India", 1970, 25.0, 50.0),
            ("India", 2020, 28.0, 350.0),
        ],
        ["Country", "year", "avg_temperature", "co2"],
    )

    rows = co2_temperature_delta_correlation(df).collect()

    assert rows[0].metric == "co2_delta_vs_temperature_delta"
    assert rows[0].pearson_correlation > 0.99


def test_q7_ignores_partial_latest_decade_when_requested(spark):
    df = spark.createDataFrame(
        [
            ("Brazil", 1990, 19.0, 10),
            ("Brazil", 2000, 20.0, 10),
            ("Brazil", 2010, 21.0, 4),
            ("France", 1990, 10.0, 10),
            ("France", 2000, 10.5, 10),
            ("France", 2010, 15.0, 4),
        ],
        ["Country", "decade", "avg_temperature", "years_in_decade"],
    )

    rows = acceleration_ranking(df, limit=2, complete_decades_only=True).collect()

    assert [row.decade for row in rows] == [2000, 2000]
    assert rows[0].Country == "Brazil"
