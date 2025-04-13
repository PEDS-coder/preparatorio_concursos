#!/bin/bash
echo "Gerando documentação..."

# Limpar diretório de documentação anterior
if [ -d "doc/api" ]; then
  rm -rf doc/api
fi

# Executar dartdoc
dart pub global activate dartdoc
dart pub global run dartdoc

echo "Documentação gerada com sucesso em doc/api/index.html"
