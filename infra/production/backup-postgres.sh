#!/usr/bin/env bash
set -euo pipefail

stamp="$(date +%Y%m%d-%H%M%S)"
compose_file="/opt/lanxin/app/infra/production/docker-compose.yml"
env_file="/opt/lanxin/env/api.env"
backup_dir="/opt/lanxin/backups"

mkdir -p "$backup_dir"
docker compose --env-file "$env_file" -f "$compose_file" exec -T postgres \
  pg_dump -U lanxin -d lanxin_travelmate \
  | gzip > "$backup_dir/lanxin-${stamp}.sql.gz"

find "$backup_dir" -name "lanxin-*.sql.gz" -mtime +14 -delete
