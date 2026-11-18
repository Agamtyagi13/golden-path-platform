#!/usr/bin/env bash
# Creates a Backstage app next to this repo and wires in the golden-path config.
# Needs Node 20/22 + yarn. Takes ~5-10 min the first time.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="${1:-$HERE/../backstage-app}"

[ -d "$APP_DIR" ] || (cd "$(dirname "$APP_DIR")" && npx --yes @backstage/create-app@latest --path "$(basename "$APP_DIR")" )
cp "$HERE/backstage/app-config.golden-path.yaml" "$APP_DIR/app-config.golden-path.yaml"

echo "Backstage app ready at $APP_DIR"
echo "  export GITHUB_TOKEN=<fine-grained PAT>   K8S_API_URL=<api url>   K8S_SA_TOKEN=<token>"
echo "  cd $APP_DIR && yarn dev --config ../app-config.yaml  (see docs/deployment.md)"
