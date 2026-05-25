from __future__ import annotations

from pyspark.ml.feature import VectorAssembler
from pyspark.ml.regression import LinearRegression
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F
from pyspark.sql.window import Window

from climate_spark.continents import CONTINENT_BY_COUNTRY


def with_continent(df: DataFrame, country_col: str = "Country") -> DataFrame:
    mapping = F.create_map([F.lit(x) for pair in CONTINENT_BY_COUNTRY.items() for x in pair])
    return df.withColumn("continent", F.coalesce(mapping[F.col(country_col)], F.lit("Other")))


def annual_country_temperatures(city_df: DataFrame) -> DataFrame:
    return (
        city_df.groupBy("country_norm", "Country", "year")
        .agg(F.avg("AverageTemperature").alias("avg_temperature"))
        .filter(F.col("avg_temperature").isNotNull())
    )


def annual_city_temperatures(city_df: DataFrame) -> DataFrame:
    return (
        city_df.groupBy("City", "Country", "year")
        .agg(F.avg("AverageTemperature").alias("avg_temperature"))
        .filter(F.col("avg_temperature").isNotNull())
    )


def global_decade_trend(city_df: DataFrame) -> DataFrame:
    annual = (
        city_df.groupBy("year", "decade")
        .agg(F.avg("AverageTemperature").alias("annual_avg_temperature"))
        .filter(F.col("decade").isNotNull())
    )
    by_decade = annual.groupBy("decade").agg(
        F.avg("annual_avg_temperature").alias("avg_annual_temperature")
    )
    by_decade = by_decade.withColumn("avg_temperature", F.col("avg_annual_temperature"))
    window = Window.orderBy("decade").rowsBetween(-2, 0)
    return by_decade.withColumn(
        "moving_avg_temperature", F.avg("avg_annual_temperature").over(window)
    )


def hottest_years_by_continent(city_df: DataFrame, limit_per_continent: int = 10) -> DataFrame:
    max_year = city_df.agg(F.max("year")).first()[0]
    min_year = int(max_year) - 49
    annual = (
        with_continent(city_df)
        .filter(F.col("year") >= F.lit(min_year))
        .groupBy("continent", "year")
        .agg(F.avg("AverageTemperature").alias("avg_temperature"))
    )
    window = Window.partitionBy("continent").orderBy(F.desc("avg_temperature"), F.desc("year"))
    return annual.withColumn("rank", F.row_number().over(window)).filter(
        F.col("rank") <= F.lit(limit_per_continent)
    )


def riskiest_cities(city_df: DataFrame, limit: int = 20) -> DataFrame:
    max_year = city_df.agg(F.max("year")).first()[0]
    min_year = int(max_year) - 99
    return (
        city_df.filter(F.col("year") >= F.lit(min_year))
        .groupBy("City", "Country")
        .agg(
            F.stddev_pop("AverageTemperature").alias("temperature_stddev"),
            F.count("*").alias("records"),
        )
        .filter(F.col("records") >= F.lit(2))
        .orderBy(F.desc("temperature_stddev"))
        .limit(limit)
    )


def min_max_correlation_value(global_df: DataFrame) -> float:
    value = global_df.agg(F.corr("LandMinTemperature", "LandMaxTemperature")).first()[0]
    return float(value) if value is not None else float("nan")


def min_max_correlation_df(global_df: DataFrame) -> DataFrame:
    spark = global_df.sparkSession
    value = min_max_correlation_value(global_df)
    return spark.createDataFrame(
        [("LandMinTemperature_vs_LandMaxTemperature", value)],
        ["metric", "pearson_correlation"],
    )


def tropical_min_max_correlation_value(city_df: DataFrame) -> float:
    annual_min_max = (
        city_df.filter(F.col("latitude_value").between(-23.5, 23.5))
        .groupBy("City", "Country", "year")
        .agg(
            F.min("AverageTemperature").alias("annual_min_temperature_proxy"),
            F.max("AverageTemperature").alias("annual_max_temperature_proxy"),
        )
        .filter(F.col("annual_min_temperature_proxy").isNotNull())
        .filter(F.col("annual_max_temperature_proxy").isNotNull())
    )
    value = annual_min_max.agg(
        F.corr("annual_min_temperature_proxy", "annual_max_temperature_proxy")
    ).first()[0]
    return float(value) if value is not None else float("nan")


def tropical_min_max_correlation_df(city_df: DataFrame) -> DataFrame:
    spark = city_df.sparkSession
    value = tropical_min_max_correlation_value(city_df)
    return spark.createDataFrame(
        [("tropical_monthly_min_proxy_vs_max_proxy", value)],
        ["metric", "pearson_correlation"],
    )


def high_uncertainty_summary(city_df: DataFrame) -> DataFrame:
    return city_df.groupBy("high_uncertainty").agg(F.count("*").alias("records")).orderBy(
        F.desc("high_uncertainty")
    )


def join_temperature_co2(annual_country_df: DataFrame, co2_df: DataFrame) -> DataFrame:
    return (
        annual_country_df.join(co2_df, ["country_norm", "year"], "inner")
        .select(
            annual_country_df["Country"],
            "country_norm",
            "year",
            "avg_temperature",
            "co2",
            "co2_per_capita",
            "total_ghg",
        )
        .filter(F.col("co2").isNotNull())
    )


def co2_temperature_delta_correlation(joined_df: DataFrame) -> DataFrame:
    max_year = joined_df.agg(F.max("year")).first()[0]
    min_year = int(max_year) - 50
    recent = joined_df.filter(F.col("year") >= F.lit(min_year))
    window = Window.partitionBy("Country").orderBy("year")
    bounds = (
        recent.withColumn("first_year", F.first("year").over(window.rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)))
        .withColumn("last_year", F.last("year").over(window.rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)))
        .withColumn("first_temp", F.first("avg_temperature").over(window.rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)))
        .withColumn("last_temp", F.last("avg_temperature").over(window.rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)))
        .withColumn("first_co2", F.first("co2").over(window.rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)))
        .withColumn("last_co2", F.last("co2").over(window.rowsBetween(Window.unboundedPreceding, Window.unboundedFollowing)))
        .filter(F.col("year") == F.col("last_year"))
        .withColumn("temperature_delta", F.col("last_temp") - F.col("first_temp"))
        .withColumn("co2_delta", F.col("last_co2") - F.col("first_co2"))
        .filter(F.col("first_year") < F.col("last_year"))
    )
    return bounds.agg(F.corr("co2_delta", "temperature_delta").alias("pearson_correlation")).withColumn(
        "metric", F.lit("co2_delta_vs_temperature_delta")
    ).select("metric", "pearson_correlation")


def co2_temperature_correlation(joined_df: DataFrame) -> DataFrame:
    return co2_temperature_delta_correlation(joined_df)


def acceleration_ranking(
    decade_country_df: DataFrame, limit: int = 10, complete_decades_only: bool = False
) -> DataFrame:
    source = decade_country_df
    if complete_decades_only and "years_in_decade" in source.columns:
        complete_source = source.filter(F.col("years_in_decade") >= F.lit(10))
        source = complete_source if not complete_source.rdd.isEmpty() else source
    window = Window.partitionBy("Country").orderBy("decade")
    enriched = (
        source.withColumn("previous_temperature", F.lag("avg_temperature").over(window))
        .withColumn("previous_decade", F.lag("decade").over(window))
        .withColumn("warming_delta", F.col("avg_temperature") - F.col("previous_temperature"))
        .withColumn("previous_delta", F.lag("warming_delta").over(window))
        .withColumn(
            "acceleration",
            F.when(F.col("previous_delta").isNull(), F.col("warming_delta")).otherwise(
                F.col("warming_delta") - F.col("previous_delta")
            ),
        )
    )
    max_decade = enriched.agg(F.max("decade")).first()[0]
    return (
        enriched.filter(F.col("decade") == F.lit(max_decade))
        .filter(F.col("acceleration").isNotNull())
        .orderBy(F.desc("acceleration"))
        .limit(limit)
    )


def decade_country_temperatures(annual_country_df: DataFrame) -> DataFrame:
    return (
        annual_country_df.withColumn("decade", (F.floor(F.col("year") / 10) * 10).cast("int"))
        .groupBy("Country", "decade")
        .agg(
            F.avg("avg_temperature").alias("avg_temperature"),
            F.countDistinct("year").alias("years_in_decade"),
        )
    )


def forecast_temperature(
    annual_city_df: DataFrame,
    city: str,
    country: str,
    years_ahead: int = 5,
    history_years: int = 20,
) -> DataFrame:
    target = (
        annual_city_df.filter(F.col("City") == F.lit(city))
        .filter(F.col("Country") == F.lit(country))
        .orderBy("year")
    )
    max_year = target.agg(F.max("year")).first()[0]
    if max_year is None:
        raise ValueError(f"No data for city={city!r}, country={country!r}")
    training = target.filter(F.col("year") >= F.lit(int(max_year) - history_years + 1))
    assembler = VectorAssembler(inputCols=["year"], outputCol="features")
    train_features = assembler.transform(training.select("year", "avg_temperature"))
    model = LinearRegression(featuresCol="features", labelCol="avg_temperature").fit(train_features)
    spark: SparkSession = annual_city_df.sparkSession
    future = spark.createDataFrame(
        [(year,) for year in range(int(max_year) + 1, int(max_year) + years_ahead + 1)],
        ["year"],
    )
    predictions = model.transform(assembler.transform(future))
    return predictions.select(
        "year", F.col("prediction").alias("predicted_temperature")
    ).orderBy("year")
