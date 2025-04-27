@echo off
echo ===================================================
echo Limpeza completa de caches da aplicacao
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

echo Limpando caches temporarios...
if exist %TEMP%\flutter_tools (
    rmdir /s /q %TEMP%\flutter_tools
    echo Cache temporario do Flutter removido com sucesso
) else (
    echo Cache temporario do Flutter nao encontrado
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
echo Limpeza concluida! Agora voce pode iniciar a aplicacao.
echo Para iniciar a aplicacao, execute: flutter run -d windows
echo ===================================================
echo.

pause
