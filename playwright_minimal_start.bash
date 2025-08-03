#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Script pour lancer un fichier de test spécifique
# Usage: ./run_test.sh <nom_du_fichier_test> [--headed]

# Vérifier si un paramètre a été fourni
if [ $# -eq 0 ]; then
    echo "❌ Erreur: Aucun nom de fichier fourni"
    echo "Usage: $0 <nom_du_fichier_test> [--headed]"
    echo "Exemple: $0 faire_une_connexion.spec.ts"
    echo "Exemple: $0 faire_une_connexion --headed"
    echo "Exemple: $0 faire_une_connexion.spec.ts --headed"
    exit 1
fi

# Récupérer le nom du fichier et les options
TEST_INPUT="$1"
HEADED_MODE=false

# Vérifier si --headed est dans les paramètres
for arg in "$@"; do
    if [ "$arg" = "--headed" ]; then
        HEADED_MODE=true
        break
    fi
done

if [ "$HEADED_MODE" = true ]; then
    echo "🔍 Recherche du fichier de test: $TEST_INPUT (mode --headed activé)"
else
    echo "🔍 Recherche du fichier de test: $TEST_INPUT"
fi

# Fonction pour chercher le fichier de test
find_test_file() {
    local input="$1"
    
    # Si le fichier existe déjà tel quel (chemin complet donné)
    if [ -f "$input" ]; then
        echo "$input"
        return 0
    fi
    
    # Extraire juste le nom du fichier si un chemin a été donné
    local base_name=$(basename "$input")
    
    # Enlever l'extension si elle est présente pour chercher avec différentes extensions
    local name_without_ext="${base_name%.*}"
    
    # Définir les chemins possibles où chercher les fichiers de test
    local search_paths=(
        "tests"
        "test-results" 
        "."
        "pages"
        "specs"
        "e2e"
    )
    
    # Extensions possibles pour les fichiers de test
    local extensions=(
        ".spec.ts"
        ".test.ts" 
        ".spec.js"
        ".test.js"
    )
    
    # Chercher dans tous les chemins possibles
    for path in "${search_paths[@]}"; do
        if [ -d "$path" ]; then
            # 1. Chercher le fichier exact avec le nom donné
            if [ -f "$path/$base_name" ]; then
                echo "$path/$base_name"
                return 0
            fi
            
            # 2. Si le nom n'a pas d'extension, essayer avec les extensions
            if [[ "$base_name" != *.* ]]; then
                for ext in "${extensions[@]}"; do
                    if [ -f "$path/${base_name}${ext}" ]; then
                        echo "$path/${base_name}${ext}"
                        return 0
                    fi
                done
            fi
            
            # 3. Chercher avec le nom sans extension + extensions
            for ext in "${extensions[@]}"; do
                if [ -f "$path/${name_without_ext}${ext}" ]; then
                    echo "$path/${name_without_ext}${ext}"
                    return 0
                fi
            done
            
            # 4. Chercher récursivement dans les sous-dossiers
            local found_file=$(find "$path" -name "$base_name" -type f 2>/dev/null | head -1)
            if [ -n "$found_file" ]; then
                echo "$found_file"
                return 0
            fi
            
            # 5. Chercher récursivement avec les extensions
            for ext in "${extensions[@]}"; do
                found_file=$(find "$path" -name "${name_without_ext}${ext}" -type f 2>/dev/null | head -1)
                if [ -n "$found_file" ]; then
                    echo "$found_file"
                    return 0
                fi
            done
        fi
    done
    
    return 1
}

# Chercher le fichier de test
TEST_FILE=$(find_test_file "$TEST_INPUT")

if [ -z "$TEST_FILE" ]; then
    echo "❌ Fichier de test non trouvé: $TEST_INPUT"
    echo ""
    echo "Fichiers de test disponibles:"
    find . -name "*.spec.ts" -o -name "*.test.ts" -o -name "*.spec.js" -o -name "*.test.js" 2>/dev/null | sed 's|^\./||' | sort
    echo ""
    echo "💡 Essayez avec:"
    echo "  - Juste le nom: $0 faire_une_connexion"
    echo "  - Avec extension: $0 faire_une_connexion.spec.ts"
    echo "  - Chemin complet: $0 tests/faire_une_connexion.spec.ts"
    echo "  - Mode headed: $0 faire_une_connexion --headed"
    exit 1
fi

echo "✅ Fichier trouvé: $TEST_FILE"

# Déterminer la commande à utiliser selon le type de projet
if [ -f "playwright.config.js" ] || [ -f "playwright.config.ts" ]; then
    # Projet Playwright
    if [ "$HEADED_MODE" = true ]; then
        echo "🎭 Lancement du test Playwright en mode --headed..."
    else
        echo "🎭 Lancement du test Playwright..."
    fi
    
    if command -v npx &> /dev/null; then
        if [ "$HEADED_MODE" = true ]; then
            echo "Commande: npx playwright test \"$TEST_FILE\" --headed"
            npx playwright test "$TEST_FILE" --headed
        else
            echo "Commande: npx playwright test \"$TEST_FILE\""
            npx playwright test "$TEST_FILE"
        fi
    else
        echo "❌ npx n'est pas installé. Veuillez installer Node.js et npm"
        exit 1
    fi
    
elif [ -f "package.json" ]; then
    # Projet Node.js générique
    echo "📦 Lancement du test Node.js..."
    if command -v npm &> /dev/null; then
        npm test "$TEST_FILE"
    elif command -v yarn &> /dev/null; then
        yarn test "$TEST_FILE"
    else
        echo "❌ npm ou yarn n'est pas installé"
        exit 1
    fi
    
else
    # Essayer d'exécuter directement le fichier
    echo "🚀 Exécution directe du fichier..."
    if [[ "$TEST_FILE" == *.js ]]; then
        if command -v node &> /dev/null; then
            node "$TEST_FILE"
        else
            echo "❌ Node.js n'est pas installé"
            exit 1
        fi
    elif [[ "$TEST_FILE" == *.ts ]]; then
        if command -v ts-node &> /dev/null; then
            ts-node "$TEST_FILE"
        elif command -v npx &> /dev/null; then
            npx ts-node "$TEST_FILE"
        else
            echo "❌ ts-node n'est pas installé. Installez-le avec: npm install -g ts-node"
            exit 1
        fi
    else
        echo "❌ Type de fichier non supporté: $TEST_FILE"
        exit 1
    fi
fi

echo "✨ Test terminé!"