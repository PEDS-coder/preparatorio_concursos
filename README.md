# Concurseiro Pro

Aplicativo multiplataforma para preparação de concursos públicos com recursos de análise de editais, planos de estudo e ferramentas de IA.

## Funcionalidades

- **Análise de Editais**: Extração e análise automática de editais de concursos
- **Planos de Estudo**: Criação e gerenciamento de planos de estudo personalizados
- **Sessões de Estudo**: Acompanhamento e registro de sessões de estudo
- **Flashcards**: Criação e revisão de flashcards para memorização
- **Integração com IA**: Utilização de modelos de IA para análise e geração de conteúdo
- **Gamificação**: Sistema de recompensas e troféus para motivar os estudos

## Requisitos

- Flutter SDK: >=2.12.0 <3.0.0
- Dart SDK: >=2.12.0 <3.0.0
- Chaves de API para serviços de IA (Gemini, OpenAI, etc.)
- Configuração do Firebase (opcional)

## Configuração

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/preparatorio_concursos.git
cd preparatorio_concursos
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure o arquivo `.env` com suas chaves de API:
```
# Credenciais da API Unstract
UNSTRACT_API_URL=https://llmwhisperer-api.us-central.unstract.com
UNSTRACT_API_KEY=sua_chave_api_aqui

# Credenciais das APIs de IA
OPENAI_API_KEY=sua_chave_openai_aqui
GEMINI_API_KEY=sua_chave_gemini_aqui

# Configurações do Firebase
FIREBASE_API_KEY=sua_chave_firebase_aqui
FIREBASE_APP_ID=seu_app_id_aqui
FIREBASE_MESSAGING_SENDER_ID=seu_sender_id_aqui
FIREBASE_PROJECT_ID=preparatorio-concursos-dev
FIREBASE_STORAGE_BUCKET=preparatorio-concursos-dev.appspot.com
FIREBASE_AUTH_DOMAIN=preparatorio-concursos-dev.firebaseapp.com
FIREBASE_MEASUREMENT_ID=seu_measurement_id_aqui

# Configurações do aplicativo
APP_ENV=development
```

4. Execute o gerador de código para injeção de dependência:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. Execute o aplicativo:
```bash
flutter run
```

## Estrutura do Projeto

- `lib/`: Código fonte principal
  - `core/`: Componentes centrais do aplicativo
    - `auth/`: Autenticação e gerenciamento de usuários
    - `data/`: Modelos de dados e repositórios
    - `di/`: Injeção de dependência
    - `navigation/`: Navegação e rotas
    - `services/`: Serviços compartilhados
    - `theme/`: Temas e estilos
    - `utils/`: Utilitários e helpers
    - `widgets/`: Widgets reutilizáveis
  - `features/`: Funcionalidades específicas do aplicativo
  - `app.dart`: Configuração do aplicativo
  - `main.dart`: Ponto de entrada do aplicativo

- `assets/`: Recursos estáticos
  - `images/`: Imagens e ícones
  - `data/`: Arquivos de dados
  - `fonts/`: Fontes personalizadas
  - `i18n/`: Arquivos de internacionalização
  - `audio_explanations/`: Arquivos de áudio para explicações

- `test/`: Testes automatizados

## Modo de Desenvolvimento

Para facilitar o desenvolvimento sem depender de APIs externas, o aplicativo possui um modo de cache forçado que pode ser ativado no `IAService`. Isso permite testar funcionalidades que dependem de IA sem consumir créditos das APIs.

## Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Faça commit das suas alterações (`git commit -m 'Adiciona nova funcionalidade'`)
4. Faça push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para mais detalhes.
