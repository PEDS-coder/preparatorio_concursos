@echo off
echo ===================================================
echo Limpeza completa de caches e reinicio da aplicacao
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

echo Reinstalando dependencias...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Erro ao executar flutter pub get
    pause
    exit /b 1
)
echo.

echo Executando script de limpeza de caches internos...
call flutter run -d windows limpar_caches.dart
echo.

echo ===================================================
echo Limpeza concluida! Iniciando a aplicacao...
echo ===================================================
echo.

call flutter run -d windows
pause
