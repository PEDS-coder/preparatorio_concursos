@echo off
echo ===================================================
echo Limpeza completa de cache e execucao do aplicativo
echo ===================================================

echo.
echo Fechando processos Flutter...
taskkill /f /im flutter.exe 2>nul
taskkill /f /im dart.exe 2>nul
taskkill /f /im concursos_ia.exe 2>nul

echo.
echo Limpando diretorio de build...
rmdir /s /q build 2>nul
echo Diretorio build removido.

echo.
echo Limpando cache do Flutter...
flutter clean

echo.
echo Limpando cache do aplicativo...
rmdir /s /q "%APPDATA%\com.example.concursos_ia" 2>nul
rmdir /s /q "%LOCALAPPDATA%\com.example.concursos_ia" 2>nul

echo.
echo Limpando cache antigo (OneDrive)...
set DOCUMENTS_DIR=%USERPROFILE%\OneDrive\Documentos
set CACHE_DIR=%DOCUMENTS_DIR%\analysis_cache
if exist "%CACHE_DIR%" (
    rmdir /s /q "%CACHE_DIR%"
    echo Cache antigo removido: %CACHE_DIR%
) else (
    echo Cache antigo nao encontrado: %CACHE_DIR%
)

echo.
echo Limpando cache temporario...
set TEMP_DIR=%LOCALAPPDATA%\Temp
if exist "%TEMP_DIR%\concursos_ia_data" (
    rmdir /s /q "%TEMP_DIR%\concursos_ia_data"
    echo Cache temporario removido: %TEMP_DIR%\concursos_ia_data
) else (
    echo Cache temporario nao encontrado: %TEMP_DIR%\concursos_ia_data
)

if exist "%TEMP_DIR%\analysis_cache" (
    rmdir /s /q "%TEMP_DIR%\analysis_cache"
    echo Cache de analises removido: %TEMP_DIR%\analysis_cache
) else (
    echo Cache de analises nao encontrado: %TEMP_DIR%\analysis_cache
)

if exist "%TEMP_DIR%\advanced_cache" (
    rmdir /s /q "%TEMP_DIR%\advanced_cache"
    echo Cache avancado removido: %TEMP_DIR%\advanced_cache
) else (
    echo Cache avancado nao encontrado: %TEMP_DIR%\advanced_cache
)

if exist "%TEMP_DIR%\image_cache" (
    rmdir /s /q "%TEMP_DIR%\image_cache"
    echo Cache de imagens removido: %TEMP_DIR%\image_cache
) else (
    echo Cache de imagens nao encontrado: %TEMP_DIR%\image_cache
)

echo.
echo Obtendo dependencias...
flutter pub get

echo.
echo Limpeza concluida!
echo.
echo Executando aplicativo...
flutter run -d windows

echo.
echo ===================================================
