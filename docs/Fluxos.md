# Fluxos Principais do Aplicativo

Este documento descreve os principais fluxos de usuário no aplicativo, desde o login até a utilização das ferramentas de estudo.

## 1. Fluxo de Login e Configuração

### 1.1. Login

```
+-------------------+     +-------------------+     +-------------------+
|   Tela Inicial    |---->|   Tela de Login   |---->| Tela de Cadastro  |
+-------------------+     +-------------------+     +-------------------+
                                   |
                                   v
                          +-------------------+
                          |  Tela de Config.  |
                          |      da API       |
                          +-------------------+
                                   |
                                   v
                          +-------------------+
                          |   Tela Inicial    |
                          |   do Aplicativo   |
                          +-------------------+
```

**Descrição:**
1. O usuário inicia o aplicativo e é direcionado para a tela inicial
2. O usuário seleciona "Login" ou "Cadastro"
3. Após o login/cadastro, o usuário é direcionado para a tela de configuração da API
4. O usuário configura a API (Gemini)
5. Após a configuração, o usuário é direcionado para a tela inicial do aplicativo

### 1.2. Configuração da API

```
+-------------------+     +-------------------+     +-------------------+
|  Tela de Config.  |---->|  Instruções para  |---->|   Validação da    |
|      da API       |     |   Gerar Chave     |     |       Chave       |
+-------------------+     +-------------------+     +-------------------+
                                                             |
                                                             v
                                                    +-------------------+
                                                    |   Tela Inicial    |
                                                    |   do Aplicativo   |
                                                    +-------------------+
```

**Descrição:**
1. O usuário acessa a tela de configuração da API
2. O aplicativo exibe instruções para gerar uma chave API
3. O usuário insere a chave API
4. O aplicativo valida a chave API
5. Após a validação, o usuário é direcionado para a tela inicial do aplicativo

## 2. Fluxo de Análise de Edital

```
+-------------------+     +-------------------+     +-------------------+
|   Tela Inicial    |---->|  Tela de Análise  |---->| Seleção de Arquivo|
|   do Aplicativo   |     |     de Edital     |     |       PDF         |
+-------------------+     +-------------------+     +-------------------+
                                                             |
                                                             v
+-------------------+     +-------------------+     +-------------------+
|  Tela de Seleção  |<----|  Processamento e  |<----| Análise com IA do |
|     de Cargos     |     |  Extração de Dados|     |      Edital       |
+-------------------+     +-------------------+     +-------------------+
         |
         v
+-------------------+
|  Tela de Conteúdo |
|   Programático    |
+-------------------+
```

**Descrição:**
1. O usuário acessa a tela de análise de edital a partir da tela inicial
2. O usuário seleciona um arquivo PDF do edital
3. O aplicativo inicia a análise do edital com IA
4. O aplicativo processa e extrai os dados do edital
5. O usuário seleciona os cargos de interesse
6. O aplicativo exibe o conteúdo programático dos cargos selecionados

## 3. Fluxo de Criação de Plano de Estudo

```
+-------------------+     +-------------------+     +-------------------+
|  Tela de Conteúdo |---->| Tela de Preferên- |---->|  Processamento e  |
|   Programático    |     | cias de Estudo    |     | Geração do Plano  |
+-------------------+     +-------------------+     +-------------------+
                                                             |
                                                             v
                                                    +-------------------+
                                                    |  Tela de Resumo   |
                                                    |    do Plano       |
                                                    +-------------------+
```

**Descrição:**
1. Após selecionar os cargos e visualizar o conteúdo programático, o usuário acessa a tela de preferências de estudo
2. O usuário configura suas preferências de estudo (horários, prioridades, etc.)
3. O aplicativo processa e gera um plano de estudo personalizado
4. O aplicativo exibe o resumo do plano de estudo

## 4. Fluxo de Estudo

```
+-------------------+     +-------------------+     +-------------------+
|  Tela de Resumo   |---->|  Tela de Matérias |---->|  Tela de Assuntos |
|    do Plano       |     |     do Plano      |     |    da Matéria     |
+-------------------+     +-------------------+     +-------------------+
                                                             |
                                                             v
+-------------------+     +-------------------+     +-------------------+
|  Tela de Resumo   |<----|  Tela de Sessão   |<----|  Seleção de Ferra-|
|    da Sessão      |     |     de Estudo     |     |  menta de Estudo  |
+-------------------+     +-------------------+     +-------------------+
```

**Descrição:**
1. O usuário acessa a tela de matérias do plano a partir do resumo do plano
2. O usuário seleciona uma matéria
3. O aplicativo exibe os assuntos da matéria
4. O usuário seleciona um assunto
5. O usuário seleciona uma ferramenta de estudo (flashcards, resumos, mapas mentais, questões)
6. O aplicativo inicia uma sessão de estudo
7. Após a sessão, o aplicativo exibe um resumo da sessão

## 5. Fluxo de Gamificação

```
+-------------------+     +-------------------+     +-------------------+
|  Tela de Resumo   |---->|  Tela de Progresso|---->|  Tela de Troféus  |
|    da Sessão      |     |     de Estudo     |     |    e Conquistas   |
+-------------------+     +-------------------+     +-------------------+
                                   |
                                   v
                          +-------------------+
                          |  Tela de Mercado  |
                          |    de Recompensas |
                          +-------------------+
```

**Descrição:**
1. Após uma sessão de estudo, o usuário pode acessar a tela de progresso
2. O aplicativo exibe o progresso do usuário, incluindo streaks, horas estudadas, etc.
3. O usuário pode visualizar seus troféus e conquistas
4. O usuário pode acessar o mercado de recompensas para trocar moedas por recompensas

## 6. Fluxo de Geração de Conteúdo com IA

```
+-------------------+     +-------------------+     +-------------------+
|  Tela de Assuntos |---->| Seleção de Ferra- |---->|  Processamento e  |
|    da Matéria     |     |  menta de Estudo  |     | Geração de Conteúdo|
+-------------------+     +-------------------+     +-------------------+
                                                             |
                                                             v
+-------------------+     +-------------------+
|  Tela de Conteúdo |---->|  Tela de Sessão   |
|     Gerado        |     |     de Estudo     |
+-------------------+     +-------------------+
```

**Descrição:**
1. O usuário seleciona um assunto e uma ferramenta de estudo
2. O aplicativo processa e gera conteúdo com IA (flashcards, resumos, mapas mentais, questões)
3. O aplicativo exibe o conteúdo gerado
4. O usuário estuda o conteúdo em uma sessão de estudo

## 7. Fluxo de Mercado de Recompensas

```
+-------------------+     +-------------------+     +-------------------+
|  Tela de Mercado  |---->|  Tela de Detalhes |---->|  Confirmação de   |
|    de Recompensas |     |    da Recompensa  |     |      Compra       |
+-------------------+     +-------------------+     +-------------------+
                                                             |
                                                             v
+-------------------+     +-------------------+
|  Tela de Minhas   |<----|  Processamento da |
|    Recompensas    |     |      Compra       |
+-------------------+     +-------------------+
```

**Descrição:**
1. O usuário acessa a tela de mercado de recompensas
2. O usuário seleciona uma recompensa
3. O aplicativo exibe os detalhes da recompensa
4. O usuário confirma a compra
5. O aplicativo processa a compra
6. O aplicativo exibe a tela de recompensas do usuário

## 8. Fluxo de Áudio Explicativo

```
+-------------------+     +-------------------+     +-------------------+
|   Qualquer Tela   |---->|  Botão de Áudio   |---->| Reprodução de Áudio|
|   do Aplicativo   |     |    Explicativo    |     |    Explicativo    |
+-------------------+     +-------------------+     +-------------------+
                                                             |
                                                             v
                                                    +-------------------+
                                                    |   Controles de    |
                                                    |    Reprodução     |
                                                    +-------------------+
```

**Descrição:**
1. O usuário pode acessar o botão de áudio explicativo em qualquer tela do aplicativo
2. O usuário clica no botão de áudio explicativo
3. O aplicativo reproduz um áudio explicando a tela atual
4. O usuário pode controlar a reprodução (pausar, retomar, parar)

## Conclusão

Estes são os principais fluxos de usuário no aplicativo. Cada fluxo foi projetado para ser intuitivo e eficiente, permitindo que o usuário aproveite ao máximo as funcionalidades do aplicativo.
