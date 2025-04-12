@echo off
echo Limpando o cache da aplicacao...

REM Limpar o cache do Flutter
call flutter clean

REM Limpar o cache do Pub
call flutter pub cache clean

REM Limpar o cache da aplicacao
rmdir /s /q %LOCALAPPDATA%\preparatorio_concursos 2>nul
echo Cache da aplicacao limpo com sucesso!

REM Obter dependencias
call flutter pub get

REM Iniciar a aplicacao
echo Iniciando a aplicacao...
call flutter run -d windows
