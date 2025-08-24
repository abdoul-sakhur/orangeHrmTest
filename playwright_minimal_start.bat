@echo off
setlocal enabledelayedexpansion

REM --- Contexte d'execution ---
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

REM --- Aide / Args ---
if "%~1"=="" (
    echo Usage: %0 ^<test_name^|path^> [--headed]
    exit /b 1
)

set HEADED=false
set TEST_INPUT=

:parse_args
if "%~1"=="" goto args_done
if "%~1"=="--headed" (
    set HEADED=true
) else (
    if "!TEST_INPUT!"=="" set TEST_INPUT=%~1
)
shift
goto parse_args
:args_done

if "!TEST_INPUT!"=="" (
    echo ❌ Aucun test fourni
    exit /b 1
)

if "!HEADED!"=="true" (
    echo 🔎 Recherche du test: !TEST_INPUT! (--headed)
) else (
    echo 🔎 Recherche du test: !TEST_INPUT!
)

REM --- Resolution du fichier de test ---
set TEST_FILE=
call :resolve_test "!TEST_INPUT!"

if "!TEST_FILE!"=="" (
    echo ❌ Fichier de test introuvable: !TEST_INPUT!
    echo Exemples: %0 faire_une_connexion ^| %0 tests\faire_une_connexion.spec.ts ^| %0 faire_une_connexion --headed
    echo Disponibles:
    for /r %%f in (*.spec.ts *.test.ts *.spec.js *.test.js) do echo %%~nxf
    exit /b 1
)

echo ✅ Fichier: !TEST_FILE!

set EXIT_CODE=0
set REPORT_DIR=playwright-report

REM --- Lancement des tests ---
if exist "playwright.config.js" goto run_playwright
if exist "playwright.config.ts" goto run_playwright
goto check_package_json

:run_playwright
where npx >nul 2>&1
if errorlevel 1 (
    echo ❌ npx non trouvé (installe Node.js/npm)
    exit /b 1
)
if "!HEADED!"=="true" (
    echo 🎭 Playwright --headed
    npx playwright test "!TEST_FILE!" --headed
) else (
    echo 🎭 Playwright
    npx playwright test "!TEST_FILE!"
)
set EXIT_CODE=!errorlevel!
echo 📊 Rapport: !REPORT_DIR! (npx playwright show-report)
goto summary

:check_package_json
if not exist "package.json" goto direct_execution
echo 📦 Projet Node.js
where npm >nul 2>&1
if not errorlevel 1 (
    npm test "!TEST_FILE!"
    set EXIT_CODE=!errorlevel!
    goto summary
)
where yarn >nul 2>&1
if not errorlevel 1 (
    yarn test "!TEST_FILE!"
    set EXIT_CODE=!errorlevel!
    goto summary
)
echo ❌ npm/yarn non trouvé
exit /b 1

:direct_execution
echo 🚀 Exécution directe
if "!TEST_FILE:~-3!"==".js" (
    where node >nul 2>&1
    if errorlevel 1 (
        echo ❌ Node.js non trouvé
        exit /b 1
    )
    node "!TEST_FILE!"
    set EXIT_CODE=!errorlevel!
    goto summary
)
if "!TEST_FILE:~-3!"==".ts" (
    where ts-node >nul 2>&1
    if not errorlevel 1 (
        ts-node "!TEST_FILE!"
        set EXIT_CODE=!errorlevel!
        goto summary
    )
    where npx >nul 2>&1
    if errorlevel 1 (
        echo ❌ ts-node non disponible (npm i -g ts-node)
        exit /b 1
    )
    npx ts-node "!TEST_FILE!"
    set EXIT_CODE=!errorlevel!
    goto summary
)
echo ❌ Type non supporté: !TEST_FILE!
exit /b 1

:summary
echo.
if !EXIT_CODE! equ 0 (
    echo ✨ Tests OK
) else (
    echo 💥 Échec (code: !EXIT_CODE!)
)

REM --- Integration Jenkins (optionnelle) ---
if not "%WORKSPACE%"=="" (
    echo 🔄 Préparation rapport pour Jenkins…
    set SRC=!REPORT_DIR!
    set DEST=%WORKSPACE%\playwright-report

    if exist "!SRC!" (
        if not exist "!DEST!" mkdir "!DEST!"
        xcopy /E /Y "!SRC!\*" "!DEST!\" >nul
        echo ✅ Copié: !DEST!\index.html
    ) else (
        echo ⚠️ Rapport introuvable: !SRC!
    )

    set META=%WORKSPACE%\email_metadata.properties
    (
        echo TEST_NAME=!TEST_INPUT!
        if !EXIT_CODE! equ 0 (
            echo TEST_STATUS=SUCCESS
        ) else (
            echo TEST_STATUS=FAILED
        )
        echo EXIT_CODE=!EXIT_CODE!
        echo REPORT_PATH=!DEST!\index.html
        echo BUILD_NUMBER=%BUILD_NUMBER%
        echo BUILD_URL=%BUILD_URL%
        echo WORKSPACE_PATH=%WORKSPACE%
        for /f "tokens=1-3 delims=/ " %%a in ("%date%") do set current_date=%%c-%%b-%%a
        for /f "tokens=1-2 delims=: " %%a in ("%time%") do set current_time=%%a:%%b
        echo TIMESTAMP=!current_date! !current_time!
    ) > "!META!"
    echo 📧 Métadonnées: !META!
) else (
    echo ℹ️ Environnement Jenkins non détecté (pas de copie rapport).
)

exit /b !EXIT_CODE!

REM --- Fonction resolve_test ---
:resolve_test
set input_path=%~1
set TEST_FILE=

REM 1) chemin donné tel quel
if exist "%input_path%" (
    set TEST_FILE=%input_path%
    goto :eof
)

REM Extraire le nom de base et le stem
for %%f in ("%input_path%") do (
    set base=%%~nxf
    set stem=%%~nf
)

REM Chemins et motifs fréquents
set roots=tests specs e2e . pages test-results
set names=!base! !stem!.spec.ts !stem!.test.ts !stem!.spec.js !stem!.test.js !base!.spec.ts !base!.test.ts !base!.spec.js !base!.test.js

for %%r in (!roots!) do (
    if exist "%%r" (
        for %%n in (!names!) do (
            if exist "%%r\%%n" (
                set TEST_FILE=%%r\%%n
                goto :eof
            )
        )
    )
)
goto :eof