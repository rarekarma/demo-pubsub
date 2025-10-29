#!/usr/bin/env bash
# Two-step deploy helper: deploy platform objects/objects first, then deploy the rest (Apex, triggers, permission sets, etc.)
# Usage: ./scripts/deploy.sh -o <org-alias>
set -euo pipefail

ORG="${1:-ci-scratch}"
WAIT=${WAIT:-10}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OBJ_DIR="$ROOT_DIR/force-app/main/default/objects"

echo "[deploy] Deploying objects from $OBJ_DIR to $ORG"
sf project deploy start --target-org "$ORG" --source-dir "$OBJ_DIR" --wait "$WAIT" --json > /tmp/deploy-objects.json 2>&1 || true
jq . /tmp/deploy-objects.json || true

echo "[deploy] Deploying remaining source to $ORG"
sf project deploy start --target-org "$ORG" --wait "$WAIT" --json > /tmp/deploy-rest.json 2>&1 || true
jq . /tmp/deploy-rest.json || true

exit 0
