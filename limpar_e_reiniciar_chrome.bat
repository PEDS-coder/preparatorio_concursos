@echo off
echo ===================================================
echo Limpeza completa de caches e reinicio no Chrome
echo ===================================================
echo.

echo Limpando caches do Flutter...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo Erro ao executar flutter clean
    pause
    exit /b 1
)
echo.

echo Limpando pasta .dart_tool...
if exist .dart_tool (
    rmdir /s /q .dart_tool
    echo Pasta .dart_tool removida com sucesso
) else (
    echo Pasta .dart_tool nao encontrada
)
echo.

echo Limpando pasta build...
if exist build (
    rmdir /s /q build
    echo Pasta build removida com sucesso
) else (
    echo Pasta build nao encontrada
)
echo.

echo Reinstalando dependencias...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Erro ao executar flutter pub get
    pause
    exit /b 1
)
echo.

echo ===================================================
echo Limpeza concluida! Iniciando a aplicacao no Chrome...
echo ===================================================
echo.

call flutter run -d chrome
pause
