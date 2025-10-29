#!/usr/bin/env bash
# Check for Salesforce metadata files missing accompanying -meta.xml
# Exits non-zero if missing files are found.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT_DIR/force-app/main/default"

# Patterns that require -meta.xml
patterns=(
  "classes/*.cls"
  "triggers/*.trigger"
  "objects/*.object"
  "lwc/*/*.js"
  "aura/*/*.cmp"
  "permissionsets/*.permissionset"
  "flexipages/*.flexipage"
  "layouts/*.layout"
)

missing=()

for pat in "${patterns[@]}"; do
  for file in "$SRC_DIR"/$pat; do
    # handle glob with no matches
    [ -e "$file" ] || continue
    base="$file"
    case "$file" in
      *.cls)
        # Apex classes use the pattern ClassName.cls-meta.xml
        metafile="${file%-}.cls-meta.xml"
        # safer construction: replace trailing .cls with .cls-meta.xml
        metafile="${file%.cls}.cls-meta.xml"
        ;;
      *.trigger)
        metafile="${file}-meta.xml"
        ;;
      *.object)
        metafile="${file}-meta.xml"
        ;;
      *.js)
        # LWC has separate meta file in same folder named <component>.js-meta.xml
        compdir="$(dirname "$file")"
        compname="$(basename "$file" .js)"
        metafile="$compdir/${compname}.js-meta.xml"
        ;;
      *.cmp)
        metafile="${file}-meta.xml"
        ;;
      *.permissionset)
        metafile="${file}-meta.xml"
        ;;
      *.flexipage)
        metafile="${file}-meta.xml"
        ;;
      *.layout)
        metafile="${file}-meta.xml"
        ;;
      *)
        metafile=""
        ;;
    esac

    if [ -n "$metafile" ] && [ ! -f "$metafile" ]; then
      missing+=("$file -> $metafile")
    fi
  done
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "Found files missing -meta.xml:" >&2
  for m in "${missing[@]}"; do
    echo "  $m" >&2
  done
  exit 2
fi

exit 0
