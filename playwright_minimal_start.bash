#!/usr/bin/env bash
set -u

# --- Contexte d'exécution ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Aide / Args ---
if [ $# -eq 0 ]; then
  echo "Usage: $0 <test_name|path> [--headed]"
  exit 1
fi

HEADED=false
TEST_INPUT=""

for arg in "$@"; do
  case "$arg" in
    --headed) HEADED=true ;;
    *)        [ -z "${TEST_INPUT:-}" ] && TEST_INPUT="$arg" ;;
  esac
done

[ -z "$TEST_INPUT" ] && { echo "❌ Aucun test fourni"; exit 1; }

echo "🔎 Recherche du test: $TEST_INPUT $($HEADED && echo '(--headed)')"

# --- Résolution du fichier de test ---
resolve_test() {
  local in="$1"
  # 1) chemin donné tel quel
  [ -f "$in" ] && { echo "$in"; return 0; }

  local base; base="$(basename "$in")"
  local stem="${base%.*}"

  # chemins et motifs fréquents
  local roots=(tests specs e2e . pages test-results)
  local names=(
    "$base"
    "$stem.spec.ts" "$stem.test.ts" "$stem.spec.js" "$stem.test.js"
    "${base}.spec.ts" "${base}.test.ts" "${base}.spec.js" "${base}.test.js"
  )

  for r in "${roots[@]}"; do
    [ -d "$r" ] || continue
    for n in "${names[@]}"; do
      [ -f "$r/$n" ] && { echo "$r/$n"; return 0; }
    done
    # fallback find (rapide: s'arrête au 1er)
    found="$(find "$r" -type f \( -name "$base" -o -name "$stem.spec.ts" -o -name "$stem.test.ts" -o -name "$stem.spec.js" -o -name "$stem.test.js" \) -print -quit 2>/dev/null)"
    [ -n "${found:-}" ] && { echo "$found"; return 0; }
  done
  return 1
}

TEST_FILE="$(resolve_test "$TEST_INPUT" || true)"

if [ -z "${TEST_FILE:-}" ]; then
  echo "❌ Fichier de test introuvable: $TEST_INPUT"
  echo "Exemples: $0 faire_une_connexion | $0 tests/faire_une_connexion.spec.ts | $0 faire_une_connexion --headed"
  echo "Disponibles:"
  find . -type f \( -name "*.spec.ts" -o -name "*.test.ts" -o -name "*.spec.js" -o -name "*.test.js" \) -printf "%P\n" | sort
  exit 1
fi

echo "✅ Fichier: $TEST_FILE"

EXIT_CODE=0
REPORT_DIR="playwright-report"

# --- Lancement des tests ---
if [ -f "playwright.config.js" ] || [ -f "playwright.config.ts" ]; then
  command -v npx >/dev/null 2>&1 || { echo "❌ npx non trouvé (installe Node.js/npm)"; exit 1; }
  echo "🎭 Playwright $( $HEADED && echo '--headed' || true )"
  if $HEADED; then
    npx playwright test "$TEST_FILE" --headed; EXIT_CODE=$?
  else
    npx playwright test "$TEST_FILE"; EXIT_CODE=$?
  fi
  echo "📊 Rapport: $REPORT_DIR (npx playwright show-report)"

elif [ -f "package.json" ]; then
  echo "📦 Projet Node.js"
  if command -v npm >/dev/null 2>&1; then
    npm test "$TEST_FILE"; EXIT_CODE=$?
  elif command -v yarn >/dev/null 2>&1; then
    yarn test "$TEST_FILE"; EXIT_CODE=$?
  else
    echo "❌ npm/yarn non trouvé"; exit 1
  fi

else
  echo "🚀 Exécution directe"
  case "$TEST_FILE" in
    *.js)
      command -v node >/dev/null 2>&1 || { echo "❌ Node.js non trouvé"; exit 1; }
      node "$TEST_FILE"; EXIT_CODE=$?
      ;;
    *.ts)
      if command -v ts-node >/dev/null 2>&1; then
        ts-node "$TEST_FILE"; EXIT_CODE=$?
      else
        command -v npx >/dev/null 2>&1 || { echo "❌ ts-node non disponible (npm i -g ts-node)"; exit 1; }
        npx ts-node "$TEST_FILE"; EXIT_CODE=$?
      fi
      ;;
    *)
      echo "❌ Type non supporté: $TEST_FILE"; exit 1 ;;
  esac
fi

# --- Résumé console ---
echo
if [ $EXIT_CODE -eq 0 ]; then
  echo "✨ Tests OK"
else
  echo "💥 Échec (code: $EXIT_CODE)"
fi

# --- Intégration Jenkins (optionnelle) ---
if [ -n "${WORKSPACE:-}" ]; then
  echo "🔄 Préparation rapport pour Jenkins…"
  SRC="$REPORT_DIR"
  DEST="$WORKSPACE/playwright-report"

  if [ -d "$SRC" ]; then
    mkdir -p "$DEST"
    cp -r "$SRC"/* "$DEST"/
    echo "✅ Copié: $DEST/index.html"
  else
    echo "⚠️ Rapport introuvable: $SRC"
  fi

  META="$WORKSPACE/email_metadata.properties"
  {
    echo "TEST_NAME=${TEST_INPUT}"
    echo "TEST_STATUS=$([ $EXIT_CODE -eq 0 ] && echo SUCCESS || echo FAILED)"
    echo "EXIT_CODE=${EXIT_CODE}"
    echo "REPORT_PATH=${DEST}/index.html"
    echo "BUILD_NUMBER=${BUILD_NUMBER:-N/A}"
    echo "BUILD_URL=${BUILD_URL:-N/A}"
    echo "WORKSPACE_PATH=${WORKSPACE}"
    echo "TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')"
  } > "$META"
  echo "📧 Métadonnées: $META"
else
  echo "ℹ️ Environnement Jenkins non détecté (pas de copie rapport)."
fi

exit $EXIT_CODE
