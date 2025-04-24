# Widgets Obsoletos

Esta pasta contém widgets que foram substituídos por versões mais recentes ou que não são mais utilizados no fluxo atual da aplicação.

## Motivo da Obsolescência

Os widgets nesta pasta foram substituídos por implementações mais eficientes, mais modulares ou que seguem melhor as práticas de desenvolvimento atuais. Alguns foram substituídos devido a mudanças nos requisitos do projeto.

## Como Lidar com Estes Widgets

1. **Não use estes widgets em novo código**: Estes widgets são mantidos apenas para referência histórica e não devem ser usados em novo código.
2. **Não modifique estes widgets**: Se você precisar de funcionalidade semelhante, use as implementações atuais ou crie novas implementações.
3. **Referência histórica**: Estes widgets podem ser úteis para entender como a aplicação evoluiu ao longo do tempo.

## Alternativas Atuais

Para cada widget obsoleto, há uma alternativa atual que deve ser usada em seu lugar:

- `ResumoPlanoCard` → Use os widgets específicos como `ConcursoInfoWidget`, `CargoInfoWidget`, etc.
- `ResumoPlanoSection` → Use os widgets específicos como `PlanoInfoWidget`, `ConteudoProgramaticoWidget`, etc.

## Fluxo Atual da Aplicação

O fluxo atual da aplicação é:

1. Splash > Login > Configuração API
2. Carregamento Edital > Escolha Cargo
3. Questionário > Resumo > Dashboard

Qualquer widget que não se encaixe neste fluxo pode ser considerado obsoleto.
