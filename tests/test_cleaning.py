from climate_spark.cleaning import (
    add_date_parts,
    clean_city_temperatures,
    parse_coordinate_value,
)


def test_parse_coordinate_value_uses_hemisphere_signs():
    assert parse_coordinate_value("42.59N") == 42.59
    assert parse_coordinate_value("23.55S") == -23.55
    assert parse_coordinate_value("1.44E") == 1.44
    assert parse_coordinate_value("46.63W") == -46.63
    assert parse_coordinate_value(None) is None


def test_add_date_parts_extracts_year_month_and_decade(spark):
    df = spark.createDataFrame([("1999-07-01", 20.0)], ["dt", "AverageTemperature"])

    result = add_date_parts(df).collect()[0]

    assert result.year == 1999
    assert result.month == 7
    assert result.decade == 1990


def test_clean_city_temperatures_removes_nulls_and_marks_high_uncertainty(spark):
    df = spark.createDataFrame(
        [
            ("2000-01-01", 20.0, 1.0, "Sao Paulo", "Brazil", "23.55S", "46.63W"),
            ("2000-02-01", None, 1.0, "Sao Paulo", "Brazil", "23.55S", "46.63W"),
            ("2000-03-01", 21.0, 10.0, "Sao Paulo", "Brazil", "23.55S", "46.63W"),
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

    result = clean_city_temperatures(df).orderBy("month").collect()

    assert len(result) == 2
    assert result[0].latitude_value == -23.55
    assert result[0].longitude_value == -46.63
    assert result[1].high_uncertainty is True
