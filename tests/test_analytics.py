from climate_spark.analytics import (
    acceleration_ranking,
    forecast_temperature,
    global_decade_trend,
    min_max_correlation_value,
)


def test_global_decade_trend_groups_by_decade(spark):
    df = spark.createDataFrame(
        [
            (2000, 2000, 10.0),
            (2001, 2000, 12.0),
            (2010, 2010, 20.0),
        ],
        ["year", "decade", "AverageTemperature"],
    )

    rows = global_decade_trend(df).orderBy("decade").collect()

    assert rows[0].decade == 2000
    assert rows[0].avg_temperature == 11.0
    assert rows[1].decade == 2010


def test_min_max_correlation_value_returns_positive_number(spark):
    df = spark.createDataFrame(
        [
            (2000, 10.0, 20.0),
            (2001, 11.0, 21.0),
            (2002, 12.0, 22.0),
        ],
        ["year", "LandMinTemperature", "LandMaxTemperature"],
    )

    assert min_max_correlation_value(df) > 0.99


def test_acceleration_ranking_compares_last_two_decades(spark):
    df = spark.createDataFrame(
        [
            ("Brazil", 2000, 20.0),
            ("Brazil", 2010, 21.0),
            ("Brazil", 2020, 23.0),
            ("France", 2000, 10.0),
            ("France", 2010, 11.0),
            ("France", 2020, 12.0),
        ],
        ["Country", "decade", "avg_temperature"],
    )

    rows = acceleration_ranking(df, limit=2).collect()

    assert rows[0].Country == "Brazil"
    assert rows[0].acceleration == 1.0


def test_forecast_temperature_returns_next_five_years(spark):
    df = spark.createDataFrame(
        [
            (2019, 20.0, "Sao Paulo", "Brazil"),
            (2020, 21.0, "Sao Paulo", "Brazil"),
            (2021, 22.0, "Sao Paulo", "Brazil"),
            (2022, 23.0, "Sao Paulo", "Brazil"),
        ],
        ["year", "avg_temperature", "City", "Country"],
    )

    rows = forecast_temperature(df, city="Sao Paulo", country="Brazil").collect()

    assert [row.year for row in rows] == [2023, 2024, 2025, 2026, 2027]
    assert rows[0].predicted_temperature > 23.0
