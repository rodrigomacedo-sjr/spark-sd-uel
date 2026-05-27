from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pyspark.sql import DataFrame
from pyspark.sql import functions as F


def plot_global_decade_temperature(df: DataFrame, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    pdf = df.orderBy("decade").toPandas()
    plt.figure(figsize=(9, 5))
    plt.plot(pdf["decade"], pdf["avg_temperature"], marker="o", label="Media por decada")
    plt.plot(
        pdf["decade"],
        pdf["moving_avg_temperature"],
        marker="s",
        label="Media movel",
    )
    plt.xlabel("Decada")
    plt.ylabel("Temperatura media (C)")
    plt.title("Evolucao da temperatura media global por decada")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_dir / "global_decade_temperature.png", dpi=140)
    plt.close()


def plot_co2_temperature_scatter(df: DataFrame, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    pdf = df.select("co2", "avg_temperature", "Country").dropna().limit(5000).toPandas()
    plt.figure(figsize=(9, 5))
    plt.scatter(pdf["co2"], pdf["avg_temperature"], alpha=0.65)
    plt.xlabel("Emissoes de CO2 (milhoes de toneladas)")
    plt.ylabel("Temperatura media anual (C)")
    plt.title("Correlacao CO2 vs temperatura media")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_dir / "co2_temperature_scatter.png", dpi=140)
    plt.close()


def plot_temperature_forecast(
    annual_city_df: DataFrame,
    forecast_df: DataFrame,
    output_dir: Path,
    city: str,
    country: str,
    history_years: int = 20,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    target = (
        annual_city_df.filter(F.col("City") == F.lit(city))
        .filter(F.col("Country") == F.lit(country))
        .orderBy("year")
    )
    max_year = target.agg(F.max("year")).first()[0]
    if max_year is None:
        return

    history = target.filter(F.col("year") >= F.lit(int(max_year) - history_years + 1))
    history_pdf = history.select("year", "avg_temperature").orderBy("year").toPandas()
    forecast_pdf = forecast_df.select("year", "predicted_temperature").orderBy("year").toPandas()
    if history_pdf.empty or forecast_pdf.empty:
        return

    years = [float(year) for year in history_pdf["year"]]
    temps = [float(temp) for temp in history_pdf["avg_temperature"]]
    slope, intercept = _linear_fit(years, temps)
    regression = [slope * year + intercept for year in years]

    plt.figure(figsize=(9, 5))
    plt.scatter(
        history_pdf["year"],
        history_pdf["avg_temperature"],
        label="Historico observado",
        color="#1f77b4",
    )
    plt.plot(
        history_pdf["year"],
        regression,
        label="Linha de regressao historica",
        color="#111827",
        linewidth=2,
    )
    plt.plot(
        forecast_pdf["year"],
        forecast_pdf["predicted_temperature"],
        label="Previsao MLlib",
        color="#dc2626",
        marker="o",
        linewidth=2,
    )
    plt.xlabel("Ano")
    plt.ylabel("Temperatura media anual (C)")
    plt.title(f"Previsao de temperatura: {city}, {country}")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    filename = f"temperature_forecast {_safe_plot_name(city)} {_safe_plot_name(country)}.png".replace(" ", "_")
    plt.savefig(output_dir / filename, dpi=140)
    plt.close()


def _linear_fit(x_values: list[float], y_values: list[float]) -> tuple[float, float]:
    x_mean = sum(x_values) / len(x_values)
    y_mean = sum(y_values) / len(y_values)
    numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_values, y_values))
    denominator = sum((x - x_mean) ** 2 for x in x_values)
    if denominator == 0:
        return 0.0, y_mean
    slope = numerator / denominator
    intercept = y_mean - slope * x_mean
    return slope, intercept


def _safe_plot_name(value: str) -> str:
    return value.replace(" ", "_").replace("/", "_")

