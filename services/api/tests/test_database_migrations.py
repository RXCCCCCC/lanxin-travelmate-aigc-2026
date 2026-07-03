import subprocess
import sys
import importlib.util
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]


def test_alembic_configuration_points_to_migrations():
    alembic_ini = ROOT / "alembic.ini"
    env_py = ROOT / "migrations" / "env.py"

    assert alembic_ini.exists()
    assert "script_location = migrations" in alembic_ini.read_text(encoding="utf-8")
    env_text = env_py.read_text(encoding="utf-8")
    assert "SQLModel.metadata" in env_text
    assert "LANXIN_DATABASE_URL" in env_text


def test_migrations_contain_current_core_tables():
    versions = sorted((ROOT / "migrations" / "versions").glob("*.py"))
    assert versions
    migration_text = "\n".join(path.read_text(encoding="utf-8") for path in versions)

    for table_name in [
        "users",
        "auth_credentials",
        "cloud_memories",
        "cloud_user_profiles",
        "cloud_trips",
        "sync_records",
        "model_call_logs",
        "tool_cache_entries",
        "tool_call_logs",
        "uploaded_files",
        "photo_candidates",
        "reminder_events",
        "group_coordination_records",
        "blind_box_task_records",
        "trip_route_points",
        "avatar_state_events",
    ]:
        assert f'"{table_name}"' in migration_text


def test_docker_compose_wires_api_to_postgres_with_healthcheck():
    compose_text = (REPO_ROOT / "infra" / "docker-compose.yml").read_text(encoding="utf-8")
    dockerfile_text = (ROOT / "Dockerfile").read_text(encoding="utf-8")

    assert "LANXIN_DATABASE_URL: postgresql+psycopg://lanxin:lanxin_dev@postgres:5432/lanxin_travelmate" in compose_text
    assert "condition: service_healthy" in compose_text
    assert "pg_isready" in compose_text
    assert "uv run alembic upgrade head" in dockerfile_text
    assert "uv run uvicorn app.main:app" in dockerfile_text


def test_docker_compose_preflight_script_validates_static_contract():
    script = REPO_ROOT / "scripts" / "docker_compose_preflight.py"
    spec = importlib.util.spec_from_file_location("docker_compose_preflight", script)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    report = module.collect_docker_compose_preflight(REPO_ROOT, run_docker_config=False)
    checks = report["checks"]

    assert checks["compose_file_exists"]["ok"] is True
    assert checks["api_points_to_postgres"]["ok"] is True
    assert checks["api_waits_for_postgres_health"]["ok"] is True
    assert checks["postgres_healthcheck"]["ok"] is True
    assert checks["api_runs_migrations_before_server"]["ok"] is True

def test_migration_plan_script_validates_revision_chain():
    script = ROOT / "scripts" / "migration_plan.py"
    assert script.exists()

    result = subprocess.run(
        [sys.executable, str(script), "check"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )

    assert "OK: " in result.stdout
    assert "head=0007_tool_call_user_id" in result.stdout


def test_alembic_revision_ids_fit_default_version_table():
    versions = sorted((ROOT / "migrations" / "versions").glob("*.py"))
    assert versions

    for path in versions:
        text = path.read_text(encoding="utf-8")
        revision_line = next(line for line in text.splitlines() if line.startswith("revision: str = "))
        revision = revision_line.split("=", 1)[1].strip().strip('"')
        assert len(revision) <= 32, f"{path.name} revision id is too long for alembic_version"


def test_database_migration_rollback_documentation_exists():
    doc = REPO_ROOT / "docs" / "engineering" / "database-migrations.md"
    assert doc.exists()
    text = doc.read_text(encoding="utf-8")
    for phrase in [
        "uv run python scripts/migration_plan.py check",
        "uv run alembic current",
        "uv run alembic downgrade",
        "备份",
        "真实 Postgres 容器启动",
    ]:
        assert phrase in text
