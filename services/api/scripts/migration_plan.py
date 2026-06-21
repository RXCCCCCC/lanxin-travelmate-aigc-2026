from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
VERSIONS_DIR = ROOT / "migrations" / "versions"


@dataclass(frozen=True)
class RevisionInfo:
    revision: str
    down_revision: str | None
    path: Path
    has_downgrade: bool


def _read_revision(path: Path) -> RevisionInfo:
    text = path.read_text(encoding="utf-8")
    revision_match = re.search(r'^revision:\s*str\s*=\s*["\']([^"\']+)["\']', text, re.MULTILINE)
    if not revision_match:
        raise ValueError(f"missing revision in {path.name}")
    down_match = re.search(
        r'^down_revision:\s*[^=]+?=\s*(None|["\']([^"\']+)["\'])',
        text,
        re.MULTILINE,
    )
    down_revision = None
    if down_match and down_match.group(1) != "None":
        down_revision = down_match.group(2)
    downgrade_match = re.search(r'def downgrade\(\) -> None:\s*(.+?)(?:\n\ndef |\Z)', text, re.DOTALL)
    has_downgrade = bool(downgrade_match and "pass" not in downgrade_match.group(1).strip())
    return RevisionInfo(
        revision=revision_match.group(1),
        down_revision=down_revision,
        path=path,
        has_downgrade=has_downgrade,
    )


def load_revisions() -> list[RevisionInfo]:
    return [_read_revision(path) for path in sorted(VERSIONS_DIR.glob("*.py"))]


def validate_revision_chain(revisions: list[RevisionInfo]) -> None:
    if not revisions:
        raise ValueError("no Alembic revision files found")
    by_revision = {item.revision: item for item in revisions}
    if len(by_revision) != len(revisions):
        raise ValueError("duplicate Alembic revision ids found")
    roots = [item for item in revisions if item.down_revision is None]
    if len(roots) != 1:
        raise ValueError(f"expected one root revision, found {len(roots)}")
    for item in revisions:
        if item.down_revision and item.down_revision not in by_revision:
            raise ValueError(f"{item.revision} points to missing down_revision {item.down_revision}")
        if not item.has_downgrade:
            raise ValueError(f"{item.revision} has no executable downgrade")


def latest_revision(revisions: list[RevisionInfo]) -> str:
    referenced = {item.down_revision for item in revisions if item.down_revision}
    leaves = [item.revision for item in revisions if item.revision not in referenced]
    if len(leaves) != 1:
        raise ValueError(f"expected one leaf revision, found {len(leaves)}")
    return leaves[0]


def render_plan(args: argparse.Namespace) -> str:
    backup = args.backup_path or "<required-backup-file>"
    rollback_to = args.rollback_to or "<revision-before-upgrade>"
    return "\n".join(
        [
            "# Production migration plan (manual execution)",
            f"# database env: {args.database_url_env}",
            f"# target revision: {args.target}",
            "",
            "# 1. Confirm the API is drained or in maintenance mode.",
            f"# 2. Create and verify a backup: {backup}",
            "uv run alembic current",
            f"uv run alembic upgrade {args.target}",
            "uv run alembic current",
            "",
            "# Rollback command if smoke checks fail after deploy:",
            f"uv run alembic downgrade {rollback_to}",
            "# Restore the verified backup if data was mutated after the migration.",
        ]
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Validate and print safe Alembic migration plans.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    check_parser = subparsers.add_parser("check", help="Validate revision chain and safety docs.")
    check_parser.set_defaults(func=handle_check)

    plan_parser = subparsers.add_parser("plan", help="Print manual migration and rollback commands.")
    plan_parser.add_argument("--target", default="head")
    plan_parser.add_argument("--rollback-to")
    plan_parser.add_argument("--backup-path")
    plan_parser.add_argument("--database-url-env", default="LANXIN_DATABASE_URL")
    plan_parser.set_defaults(func=handle_plan)
    return parser


def handle_check(_args: argparse.Namespace) -> int:
    revisions = load_revisions()
    validate_revision_chain(revisions)
    print(f"OK: {len(revisions)} revisions, head={latest_revision(revisions)}")
    return 0


def handle_plan(args: argparse.Namespace) -> int:
    revisions = load_revisions()
    validate_revision_chain(revisions)
    print(render_plan(args))
    return 0


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())