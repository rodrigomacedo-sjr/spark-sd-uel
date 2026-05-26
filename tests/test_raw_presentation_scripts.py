from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"


def test_raw_presentation_scripts_are_the_only_demo_entrypoints():
    expected = {
        "pc1_start_raw.sh",
        "pc2_worker_raw.sh",
        "pc1_benchmark_raw.sh",
        "local_workers_raw.sh",
    }
    for name in expected:
        path = SCRIPTS / name
        assert path.exists(), name
        assert path.stat().st_mode & 0o111, name

    removed = {
        "run_all.sh",
        "run_demo.sh",
        "run_cluster_pc1.sh",
        "run_cluster_pc2.sh",
        "run_distributed_master_pc1.sh",
        "run_distributed_worker.sh",
        "run_distributed_worker_pc2.sh",
        "run_distributed_submit_pc1.sh",
        "benchmark_cluster_modes.sh",
        "run_local_workers.sh",
    }
    for name in removed:
        assert not (SCRIPTS / name).exists(), name


def test_raw_scripts_are_readable_and_raw_only():
    joined = "\n".join((SCRIPTS / name).read_text(encoding="utf-8") for name in [
        "pc1_start_raw.sh",
        "pc2_worker_raw.sh",
        "pc1_benchmark_raw.sh",
        "local_workers_raw.sh",
    ])

    assert "--mode raw" in joined
    assert "sample" not in joined
    assert "Tempo total:" in joined
    assert "Processamento Spark:" in joined
    assert "Overhead:" in joined
    assert "output/benchmark/cluster_modes.csv" in joined
    assert "output/benchmark/local_workers.csv" in joined
