import json
from pathlib import Path


NOTEBOOK = Path(__file__).resolve().parents[1] / "notebooks" / "apresentacao_spark_clima.ipynb"


def _notebook_text() -> str:
    data = json.loads(NOTEBOOK.read_text(encoding="utf-8"))
    chunks: list[str] = []
    for cell in data["cells"]:
        source = cell.get("source", [])
        chunks.append("".join(source) if isinstance(source, list) else source)
    return "\n".join(chunks)


def test_presentation_notebook_has_required_storyline():
    text = _notebook_text()

    required_sections = [
        "# Apresentacao: Analise Global de Mudancas Climaticas com Spark",
        "## 1. Como usar este notebook na apresentacao",
        "## 2. Mapa dos arquivos do projeto",
        "## 3. Arquitetura: Docker local e 2 PCs",
        "## 4. Onde a divisao acontece",
        "## 5. Preparacao e imports",
        "## 6. Leitura dos dados com Spark",
        "## 7. Limpeza dos dados, como e por que",
        "## 8. Prova de distribuicao: particoes, hosts e tasks",
        "## 9. Cruzamento entre temperatura e CO2",
        "## 10. Cache e plano fisico",
        "## 11. Questoes do trabalho, passo a passo",
        "## 12. Graficos informativos",
        "## 13. Spark UI: o que mostrar para provar",
        "## 14. Roteiro Docker local",
        "## 15. Roteiro em 2 PCs",
        "## 16. Defesa tecnica curta",
    ]
    for section in required_sections:
        assert section in text


def test_presentation_notebook_references_real_code_and_all_questions():
    text = _notebook_text()

    required_terms = [
        "src/climate_spark/main.py",
        "src/climate_spark/io_utils.py",
        "src/climate_spark/cleaning.py",
        "src/climate_spark/analytics.py",
        "src/climate_spark/plotting.py",
        "docker-compose.yml",
        "scripts/run_demo.sh",
        "scripts/run_all.sh",
        "scripts/run_distributed_master_pc1.sh",
        "scripts/run_distributed_worker_pc2.sh",
        "scripts/run_distributed_submit_pc1.sh",
        "RELATORIO.md",
        "PLANO_DIVISAO_APRESENTACAO.md",
    ]
    for term in required_terms:
        assert term in text

    for question in range(1, 9):
        assert f"### Q{question}" in text


def test_presentation_notebook_proves_distribution_and_avoids_em_dash():
    text = _notebook_text()

    required_distribution_terms = [
        "inspect_partition",
        "mapPartitionsWithIndex",
        "repartition(8, \"Country\")",
        "getNumPartitions()",
        "spark.sparkContext.defaultParallelism",
        "explain(True)",
        "Exchange",
        "HashAggregate",
        "SortMergeJoin",
        "Window",
    ]
    for term in required_distribution_terms:
        assert term in text

    assert "\u2014" not in text
    assert "\u2013" not in text


def test_presentation_markdown_points_to_notebook():
    root = Path(__file__).resolve().parents[1]
    readme = (root / "README.md").read_text(encoding="utf-8")
    plan = (root / "PLANO_DIVISAO_APRESENTACAO.md").read_text(encoding="utf-8")

    notebook_path = "notebooks/apresentacao_spark_clima.ipynb"
    assert notebook_path in readme
    assert notebook_path in plan
    assert "bulk da apresentacao" in plan


def test_presentation_notebook_has_iteration_knobs():
    text = _notebook_text()

    required_terms = [
        "## 5.1 Parametros faceis de mudar",
        "UNCERTAINTY_RATIO",
        "PARTITION_COUNT",
        "TOP_N_PER_CONTINENT",
        "RISKIEST_CITY_LIMIT",
        "FORECAST_YEARS_AHEAD",
        "FORECAST_HISTORY_YEARS",
        "FORECAST_CITY",
        "FORECAST_COUNTRY",
        "high_uncertainty_custom",
        "se aumentar",
        "se diminuir",
    ]
    for term in required_terms:
        assert term in text



def test_presentation_notebook_explains_two_pc_demo():
    text = _notebook_text()

    required_terms = [
        "scripts/run_distributed_master_pc1.sh",
        "scripts/run_distributed_worker_pc2.sh",
        "scripts/run_distributed_submit_pc1.sh",
        "docker logs climate-spark-worker-lan",
        "docker ps",
        "partition_evidence.groupBy(\"host\")",
        "Workers",
        "Executors",
        "Running Applications",
        "Alive Workers",
        "Total Cores",
        "Total Memory",
        "PC2 trabalhou",
        "worker do PC2",
        "http://<IP_DO_PC1>:8080",
    ]
    for term in required_terms:
        assert term in text



def test_cluster_economics_analysis_exists():
    root = Path(__file__).resolve().parents[1]
    text = _notebook_text()
    script = root / "scripts" / "benchmark_cluster_modes.sh"

    assert script.exists()
    script_text = script.read_text(encoding="utf-8")
    required_script_terms = [
        "local-compose",
        "lan-cluster",
        "wall_seconds",
        "spark_compute_seconds",
        "overhead_seconds",
        "scripts/run_distributed_submit_pc1.sh",
        "docker compose",
    ]
    for term in required_script_terms:
        assert term in script_text

    required_notebook_terms = [
        "## 17. Analise de tempo: quando cluster vale a pena",
        "scripts/benchmark_cluster_modes.sh local-compose raw",
        "scripts/benchmark_cluster_modes.sh lan-cluster <IP_DO_PC1> raw",
        "wall_seconds",
        "spark_compute_seconds",
        "overhead_seconds",
        "network_orchestration_overhead",
        "speedup",
        "eficiencia",
        "Amdahl",
        "shuffle",
        "quando vale a pena usar cluster",
        "quantos workers fazem sentido",
    ]
    for term in required_notebook_terms:
        assert term in text



def test_live_pipeline_outputs_and_graphs_exist():
    text = _notebook_text()

    required_terms = [
        "## 18. Execucao ao vivo: tempo total, outputs e graficos",
        "LIVE_PIPELINE_COMMAND",
        "pipeline_wall_seconds",
        "output_live_measure",
        "timings_df",
        "plot(kind=\"barh\")",
        "27.77",
        "scripts/benchmark_cluster_modes.sh local-compose sample",
        "Saida esperada para acompanhar",
        "Grafico de tempo por pergunta",
        "display(Image",
    ]
    for term in required_terms:
        assert term in text



def test_worker_resources_and_efficiency_docs_are_complete():
    root = Path(__file__).resolve().parents[1]
    text = _notebook_text()
    readme = (root / "README.md").read_text(encoding="utf-8")
    report = (root / "RELATORIO.md").read_text(encoding="utf-8")
    compose = (root / "docker-compose.yml").read_text(encoding="utf-8")
    worker_script = (root / "scripts" / "run_distributed_worker_pc2.sh").read_text(encoding="utf-8")

    required_config_terms = [
        "SPARK_WORKER_CORES",
        "SPARK_WORKER_MEMORY",
        "SPARK_WORKER_INSTANCES",
        "--scale spark-worker",
        "--cores ${SPARK_WORKER_CORES}",
        "--memory ${SPARK_WORKER_MEMORY}",
    ]
    for term in required_config_terms:
        assert term in compose or term in worker_script or term in readme

    required_doc_terms = [
        "por que demora",
        "mais recursos por worker",
        "3 workers",
        "4 workers",
        "eficiencia",
        "constante de rede",
        "workers adicionais",
        "Rio De Janeiro",
        "pontos historicos nao conectados",
        "linha de regressao",
        "linha de previsao",
    ]
    combined = "\n".join([text, readme, report])
    for term in required_doc_terms:
        assert term in combined
