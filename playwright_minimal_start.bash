#!/usr/bin/env bash
set -euo pipefail

# ==============================
# Usage:
#   ./playwright_minimal_start.bash <test_file|nom_sans_ext> [--headed]
# ==============================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ $# -lt 1 ]]; then
  echo "❌ Aucun fichier de test fourni"
  echo "Usage: $0 <test_file> [--headed]"
  exit 1
fi

TEST_INPUT="$1"; shift || true
HEADED=false
for arg in "$@"; do
  [[ "$arg" == "--headed" ]] && HEADED=true
done

# --- Recherche simple ---
find_test_file() {
  local input="$1"
  [[ -f "$input" ]] && { echo "$input"; return; }

  local base="$(basename "$input")"
  local name="${base%.*}"
  local -a search_dirs=( "tests" "specs" "e2e" "." )
  local -a exts=( ".spec.ts" ".test.ts" ".spec.js" ".test.js" )

  for d in "${search_dirs[@]}"; do
    [[ -f "$d/$base" ]] && { echo "$d/$base"; return; }
    for ext in "${exts[@]}"; do
      [[ -f "$d/${name}${ext}" ]] && { echo "$d/${name}${ext}"; return; }
    done
  done
}

TEST_FILE="$(find_test_file "$TEST_INPUT" || true)"
if [[ -z "$TEST_FILE" ]]; then
  echo "❌ Fichier introuvable: $TEST_INPUT"
  echo "👉 Vérifiez dans tests/, specs/, e2e/"
  exit 1
fi

echo "✅ Test trouvé: $TEST_FILE"

# --- Vérifier npx ---
if ! command -v npx >/dev/null; then
  echo "❌ npx non installé (Node.js/npm requis)"
  exit 127
fi

# --- Vérifier navigateurs Playwright ---
if ! npx playwright --version >/dev/null 2>&1; then
  echo "📦 Installation des navigateurs Playwright..."
  npx playwright install
fi

# --- Exécution ---
if $HEADED; then
  echo "🎭 Lancement en mode --headed"
  npx playwright test "$TEST_FILE" --headed
else
  echo "🎭 Lancement en mode headless"
  npx playwright test "$TEST_FILE"
fi
