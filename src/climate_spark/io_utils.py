from __future__ import annotations

from pathlib import Path

from pyspark.sql import DataFrame, SparkSession


def ensure_dirs(*paths: Path) -> None:
    for path in paths:
        path.mkdir(parents=True, exist_ok=True)


def read_csv(spark: SparkSession, path: Path) -> DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"Missing input file: {path}")
    return spark.read.csv(str(path), header=True, inferSchema=True)


def write_result(df: DataFrame, output_dir: Path, name: str) -> None:
    path = output_dir / "results" / name
    path.parent.mkdir(parents=True, exist_ok=True)
    df.coalesce(1).write.mode("overwrite").option("header", True).csv(str(path))



def write_parquet_sample(df: DataFrame, output_dir: Path, name: str, rows: int = 1000) -> None:
    path = output_dir / "parquet" / name
    path.parent.mkdir(parents=True, exist_ok=True)
    df.limit(rows).write.mode("overwrite").parquet(str(path))
