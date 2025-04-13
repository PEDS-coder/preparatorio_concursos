@echo off
echo Gerando documentação...

REM Limpar diretório de documentação anterior
if exist doc\api rmdir /s /q doc\api

REM Executar dartdoc
dart pub global activate dartdoc
dart pub global run dartdoc

echo Documentação gerada com sucesso em doc\api\index.html
