from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "run_local_workers.sh"


def test_run_local_workers_script_documents_interface():
    text = SCRIPT.read_text(encoding="utf-8")

    assert "Uso: scripts/run_local_workers.sh <workers> [sample|raw]" in text
    assert "SPARK_WORKER_CORES" in text
    assert "SPARK_WORKER_MEMORY" in text
    assert "climate-spark-local-worker-$i" in text
    assert "spark://spark-master:7077" in text
    assert "output/benchmark/local_workers.csv" in text
    assert "wall_seconds" in text
    assert "spark_compute_seconds" in text
    assert "overhead_seconds" in text
