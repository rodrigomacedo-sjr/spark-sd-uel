from __future__ import annotations

import argparse
import time
from pathlib import Path

from pyspark.sql import SparkSession

from climate_spark.analytics import (
    acceleration_ranking,
    annual_city_temperatures,
    annual_country_temperatures,
    co2_temperature_correlation,
    decade_country_temperatures,
    forecast_temperature,
    global_decade_trend,
    high_uncertainty_summary,
    hottest_years_by_continent,
    join_temperature_co2,
    tropical_min_max_correlation_df,
    riskiest_cities,
)
from climate_spark.cleaning import clean_city_temperatures, clean_co2, clean_global_temperatures, filter_reliable_temperatures
from climate_spark.config import CO2_FILE, GLOBAL_TEMPERATURE_FILE, OUTPUT_DIR, PROJECT_ROOT, TEMPERATURE_CITY_FILE
from climate_spark.io_utils import ensure_dirs, read_csv, write_parquet_sample, write_result
from climate_spark.plotting import plot_co2_temperature_scatter, plot_global_decade_temperature, plot_temperature_forecast


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Spark climate analysis assignment")
    parser.add_argument("--mode", choices=["sample", "raw"], default="sample")
    parser.add_argument("--cache", choices=["on", "off"], default="on")
    parser.add_argument("--master", default=None)
    parser.add_argument("--city", default="Rio De Janeiro")
    parser.add_argument("--country", default="Brazil")
    parser.add_argument("--output", default=str(OUTPUT_DIR))
    return parser.parse_args()


def build_spark(master: str | None) -> SparkSession:
    builder = SparkSession.builder.appName("climate-spark-analysis")
    if master:
        builder = builder.master(master)
    spark = builder.getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")
    return spark


def timed(name: str, rows: list[tuple[str, float]], fn):
    start = time.perf_counter()
    result = fn()
    result.count()
    elapsed = time.perf_counter() - start
    rows.append((name, round(elapsed, 4)))
    return result


def main() -> None:
    args = parse_args()
    spark = build_spark(args.master)
    output_dir = Path(args.output).resolve()
    input_dir = PROJECT_ROOT / "data" / args.mode
    ensure_dirs(output_dir / "results", output_dir / "plots", output_dir / "timings")

    city_raw = read_csv(spark, input_dir / TEMPERATURE_CITY_FILE)
    global_raw = read_csv(spark, input_dir / GLOBAL_TEMPERATURE_FILE)
    co2_raw = read_csv(spark, input_dir / CO2_FILE)

    city_clean = clean_city_temperatures(city_raw)
    global_clean = clean_global_temperatures(global_raw)
    co2_clean = clean_co2(co2_raw)

    if args.cache == "on":
        city_clean = city_clean.cache()
        global_clean = global_clean.cache()
        co2_clean = co2_clean.cache()
        city_clean.count()
        global_clean.count()
        co2_clean.count()

    reliable_city = filter_reliable_temperatures(city_clean)
    if args.cache == "on":
        reliable_city = reliable_city.cache()
        reliable_city.count()

    annual_country = annual_country_temperatures(reliable_city)
    annual_city = annual_city_temperatures(reliable_city)
    joined = join_temperature_co2(annual_country, co2_clean)

    if args.cache == "on":
        annual_country = annual_country.cache()
        annual_city = annual_city.cache()
        joined = joined.cache()
        annual_country.count()
        annual_city.count()
        joined.count()

    timings: list[tuple[str, float]] = []

    # Pergunta 1: media movel de temperatura por decada.
    q1 = timed("q1_global_decade_trend", timings, lambda: global_decade_trend(reliable_city))
    write_result(q1, output_dir, "q1_global_decade_trend")

    # Pergunta 2: 10 anos mais quentes por continente nos ultimos 50 anos.
    q2 = timed("q2_hottest_years_by_continent", timings, lambda: hottest_years_by_continent(reliable_city))
    write_result(q2, output_dir, "q2_hottest_years_by_continent")

    # Pergunta 3: cidades com maior instabilidade no ultimo seculo.
    q3 = timed("q3_riskiest_cities", timings, lambda: riskiest_cities(reliable_city))
    write_result(q3, output_dir, "q3_riskiest_cities")

    # Pergunta 4: correlacao Pearson entre temperatura minima e maxima.
    q4 = timed("q4_min_max_correlation", timings, lambda: tropical_min_max_correlation_df(reliable_city))
    write_result(q4, output_dir, "q4_min_max_correlation")

    # Pergunta 5: qualidade dos dados por incerteza.
    q5 = timed("q5_quality_summary", timings, lambda: high_uncertainty_summary(city_clean))
    write_result(q5, output_dir, "q5_quality_summary")

    # Pergunta 6: correlacao entre CO2 e temperatura apos join pais/ano.
    q6 = timed("q6_co2_temperature_correlation", timings, lambda: co2_temperature_correlation(joined))
    write_result(q6, output_dir, "q6_co2_temperature_correlation")
    write_result(joined, output_dir, "joined_temperature_co2")
    write_parquet_sample(joined, output_dir, "joined_temperature_co2_sample")

    # Pergunta 7: ranking de aceleracao termica com window functions.
    decade_country = decade_country_temperatures(annual_country)
    q7 = timed("q7_acceleration_ranking", timings, lambda: acceleration_ranking(decade_country, complete_decades_only=True))
    write_result(q7, output_dir, "q7_acceleration_ranking")

    # Pergunta 8: previsao MLlib para cidade/pais configuravel.
    q8 = timed(
        "q8_temperature_forecast",
        timings,
        lambda: forecast_temperature(annual_city, args.city, args.country),
    )
    write_result(q8, output_dir, "q8_temperature_forecast")

    timing_df = spark.createDataFrame(timings, ["question", "seconds"])
    write_result(timing_df, output_dir, f"timings_cache_{args.cache}")

    plot_global_decade_temperature(q1, output_dir / "plots")
    plot_co2_temperature_scatter(joined, output_dir / "plots")
    plot_temperature_forecast(annual_city, q8, output_dir / "plots", args.city, args.country)
    spark.stop()


if __name__ == "__main__":
    main()
