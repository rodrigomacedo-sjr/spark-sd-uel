from __future__ import annotations

from pyspark.sql import DataFrame
from pyspark.sql import functions as F

from climate_spark.config import COUNTRY_RENAMES, GLOBAL_AGGREGATES


def parse_coordinate_value(value: str | None) -> float | None:
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    hemisphere = text[-1].upper()
    try:
        number = float(text[:-1])
    except ValueError:
        return None
    if hemisphere in {"S", "W"}:
        return -number
    return number


def _coordinate_expr(column_name: str):
    raw = F.trim(F.col(column_name))
    number = F.regexp_extract(raw, r"([0-9]+(?:\.[0-9]+)?)", 1).cast("double")
    hemisphere = F.upper(F.regexp_extract(raw, r"([NSEW])$", 1))
    return F.when(hemisphere.isin("S", "W"), -number).otherwise(number)


def normalize_country_column(df: DataFrame, input_col: str, output_col: str = "country_norm") -> DataFrame:
    expr = F.trim(F.col(input_col))
    for source, target in COUNTRY_RENAMES.items():
        expr = F.when(F.lower(F.trim(F.col(input_col))) == source, F.lit(target)).otherwise(expr)
    return df.withColumn(output_col, expr)


def add_date_parts(df: DataFrame, date_col: str = "dt") -> DataFrame:
    return (
        df.withColumn("date", F.to_date(F.col(date_col)))
        .withColumn("year", F.year("date"))
        .withColumn("month", F.month("date"))
        .withColumn("decade", (F.floor(F.col("year") / F.lit(10)) * F.lit(10)).cast("int"))
    )


def clean_city_temperatures(df: DataFrame) -> DataFrame:
    base = (
        add_date_parts(df)
        .filter(F.col("AverageTemperature").isNotNull())
        .filter(F.col("date").isNotNull())
        .filter(F.col("AverageTemperature").between(-90.0, 70.0))
        .withColumn("AverageTemperature", F.col("AverageTemperature").cast("double"))
        .withColumn(
            "AverageTemperatureUncertainty",
            F.col("AverageTemperatureUncertainty").cast("double"),
        )
        .withColumn("latitude_value", _coordinate_expr("Latitude"))
        .withColumn("longitude_value", _coordinate_expr("Longitude"))
    )
    normalized = normalize_country_column(base, "Country", "country_norm")
    history = normalized.groupBy("City", "Country").agg(
        F.avg(F.abs(F.col("AverageTemperature"))).alias("historical_avg_temperature")
    )
    with_threshold = normalized.join(history, ["City", "Country"], "left").withColumn(
        "uncertainty_threshold",
        F.abs(F.col("historical_avg_temperature")) * F.lit(0.10),
    )
    return with_threshold.withColumn(
        "high_uncertainty",
        F.col("AverageTemperatureUncertainty") > F.col("uncertainty_threshold"),
    )


def clean_global_temperatures(df: DataFrame) -> DataFrame:
    return (
        add_date_parts(df)
        .withColumn("LandMinTemperature", F.col("LandMinTemperature").cast("double"))
        .withColumn("LandMaxTemperature", F.col("LandMaxTemperature").cast("double"))
        .withColumn("LandAverageTemperature", F.col("LandAverageTemperature").cast("double"))
        .filter(F.col("LandMinTemperature").isNotNull())
        .filter(F.col("LandMaxTemperature").isNotNull())
    )


def clean_co2(df: DataFrame, min_year: int = 1900) -> DataFrame:
    aggregates = list(GLOBAL_AGGREGATES)
    cleaned = (
        df.withColumn("year", F.col("year").cast("int"))
        .withColumn("co2", F.col("co2").cast("double"))
        .withColumn("co2_per_capita", F.col("co2_per_capita").cast("double"))
        .withColumn("total_ghg", F.col("total_ghg").cast("double"))
        .filter(F.col("year") >= F.lit(min_year))
        .filter(F.col("co2").isNotNull())
        .filter(~F.col("country").isin(aggregates))
    )
    return normalize_country_column(cleaned, "country", "country_norm")


def filter_reliable_temperatures(df: DataFrame) -> DataFrame:
    return df.filter(~F.col("high_uncertainty"))
