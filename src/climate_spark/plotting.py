from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pyspark.sql import DataFrame


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

