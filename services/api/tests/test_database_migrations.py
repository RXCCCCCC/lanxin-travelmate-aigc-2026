import subprocess
import sys
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

    assert "LANXIN_DATABASE_URL: postgresql+psycopg://lanxin:lanxin_dev@postgres:5432/lanxin_travelmate" in compose_text
    assert "condition: service_healthy" in compose_text
    assert "pg_isready" in compose_text

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
    assert "head=0006_add_avatar_state_events" in result.stdout


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
