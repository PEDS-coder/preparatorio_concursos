# Limpeza de Caches e Reinicialização da Aplicação

Este documento explica como limpar todos os caches da aplicação e reiniciá-la corretamente.

## Scripts Disponíveis

Foram criados vários scripts para facilitar a limpeza de caches e reinicialização da aplicação:

### 1. `limpar_caches_simples.bat`

Este é o script mais simples e recomendado para a maioria dos casos. Ele:

- Limpa os caches do Flutter com `flutter clean`
- Remove a pasta `.dart_tool`
- Remove a pasta `build`
- Limpa caches temporários do Flutter
- Reinstala as dependências com `flutter pub get`

**Como usar:**
1. Feche a aplicação se estiver em execução
2. Dê um duplo clique no arquivo `limpar_caches_simples.bat`
3. Após a conclusão, execute `flutter run -d windows` para iniciar a aplicação

### 2. `limpar_e_reiniciar.bat`

Este script é mais completo e tenta limpar também os caches internos da aplicação. Ele:

- Executa todas as limpezas do script simples
- Tenta executar um script Dart para limpar caches internos
- Inicia automaticamente a aplicação após a limpeza

**Como usar:**
1. Feche a aplicação se estiver em execução
2. Dê um duplo clique no arquivo `limpar_e_reiniciar.bat`

### 3. `limpar_e_reiniciar_chrome.bat`

Este script é semelhante ao anterior, mas inicia a aplicação no navegador Chrome. Ele:

- Executa todas as limpezas do script simples
- Inicia automaticamente a aplicação no Chrome após a limpeza

**Como usar:**
1. Feche a aplicação se estiver em execução
2. Dê um duplo clique no arquivo `limpar_e_reiniciar_chrome.bat`

## Limpeza Manual

Se os scripts não funcionarem, você pode executar os seguintes comandos manualmente:

```bash
# Fechar a aplicação se estiver em execução

# Limpar caches do Flutter
flutter clean

# Remover pasta .dart_tool
rmdir /s /q .dart_tool

# Remover pasta build
rmdir /s /q build

# Reinstalar dependências
flutter pub get

# Iniciar a aplicação
flutter run -d windows  # Para Windows
# ou
flutter run -d chrome   # Para navegador Chrome
```

## Observações Importantes

- Sempre feche a aplicação antes de limpar os caches
- Após a limpeza, a primeira inicialização pode ser mais lenta
- Se encontrar erros após a limpeza, tente reiniciar o computador e executar novamente os comandos
