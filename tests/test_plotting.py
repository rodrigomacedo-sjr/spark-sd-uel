from pathlib import Path

from climate_spark.plotting import plot_temperature_forecast


def test_forecast_plot_uses_unconnected_history_points(spark, tmp_path):
    annual_city = spark.createDataFrame(
        [
            ("Rio De Janeiro", "Brazil", 2000, 23.0),
            ("Rio De Janeiro", "Brazil", 2001, 23.4),
            ("Rio De Janeiro", "Brazil", 2002, 23.8),
            ("Rio De Janeiro", "Brazil", 2003, 24.2),
        ],
        ["City", "Country", "year", "avg_temperature"],
    )
    forecast = spark.createDataFrame(
        [
            (2004, 24.6),
            (2005, 25.0),
        ],
        ["year", "predicted_temperature"],
    )

    plot_temperature_forecast(
        annual_city,
        forecast,
        tmp_path,
        city="Rio De Janeiro",
        country="Brazil",
        history_years=4,
    )

    assert (tmp_path / "temperature_forecast_Rio_De_Janeiro_Brazil.png").exists()


def test_forecast_plot_source_documents_required_layers():
    source = Path("src/climate_spark/plotting.py").read_text(encoding="utf-8")

    assert "plt.scatter" in source
    assert "Historico observado" in source
    assert "Linha de regressao historica" in source
    assert "Previsao MLlib" in source
