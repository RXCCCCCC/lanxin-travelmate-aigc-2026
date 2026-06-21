"""Read-only Docker Compose preflight for local handoff.

This script validates the compose file shape and, when Docker is available,
delegates syntax normalization to `docker compose config` without starting
containers or building images.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any


def collect_docker_compose_preflight(repo_root: Path, *, run_docker_config: bool = True) -> dict[str, Any]:
    compose_path = repo_root / "infra" / "docker-compose.yml"
    dockerfile_path = repo_root / "services" / "api" / "Dockerfile"
    compose_text = compose_path.read_text(encoding="utf-8") if compose_path.exists() else ""
    dockerfile_text = dockerfile_path.read_text(encoding="utf-8") if dockerfile_path.exists() else ""

    docker_config = {
        "ok": False,
        "detail": "docker executable not found",
        "manual": True,
    }
    if run_docker_config and shutil.which("docker"):
        result = subprocess.run(
            ["docker", "compose", "-f", str(compose_path), "config"],
            cwd=repo_root,
            capture_output=True,
            text=True,
        )
        docker_config = {
            "ok": result.returncode == 0,
            "detail": (result.stdout or result.stderr).strip()[:500],
        }

    checks = {
        "compose_file_exists": {
            "ok": compose_path.exists(),
            "detail": str(compose_path),
        },
        "api_service_builds_from_services_api": {
            "ok": "context: ../services/api" in compose_text,
            "detail": "api build context",
        },
        "api_points_to_postgres": {
            "ok": "LANXIN_DATABASE_URL: postgresql+psycopg://lanxin:lanxin_dev@postgres:5432/lanxin_travelmate" in compose_text,
            "detail": "LANXIN_DATABASE_URL",
        },
        "api_waits_for_postgres_health": {
            "ok": "condition: service_healthy" in compose_text,
            "detail": "depends_on postgres service_healthy",
        },
        "postgres_healthcheck": {
            "ok": "pg_isready -U lanxin -d lanxin_travelmate" in compose_text,
            "detail": "pg_isready",
        },
        "postgres_named_volume": {
            "ok": "postgres_data:" in compose_text and "/var/lib/postgresql/data" in compose_text,
            "detail": "postgres_data volume",
        },
        "api_runs_migrations_before_server": {
            "ok": "uv run alembic upgrade head" in dockerfile_text and "uv run uvicorn app.main:app" in dockerfile_text,
            "detail": "Dockerfile CMD",
        },
        "docker_compose_config": docker_config,
    }
    return {
        "repoRoot": str(repo_root),
        "checks": checks,
        "ok": all(item["ok"] or item.get("manual") for item in checks.values()),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=Path(__file__).resolve().parents[1])
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--no-docker-config", action="store_true")
    args = parser.parse_args()

    report = collect_docker_compose_preflight(
        Path(args.repo_root).resolve(),
        run_docker_config=not args.no_docker_config,
    )
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"Docker Compose preflight for {report['repoRoot']}")
        for name, item in report["checks"].items():
            status = "OK" if item["ok"] else ("MANUAL" if item.get("manual") else "FAIL")
            print(f"[{status}] {name}: {item['detail']}")

    if args.strict:
        failed = [
            name
            for name, item in report["checks"].items()
            if not item["ok"] and not item.get("manual")
        ]
        if failed:
            print("Failed checks: " + ", ".join(failed), file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
