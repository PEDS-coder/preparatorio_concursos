/// Configuração para desabilitar o Firebase em plataformas não suportadas
/// Este arquivo é usado para substituir a inicialização do Firebase
/// quando o aplicativo é executado em plataformas que não têm suporte completo.

// Constante para verificar se o Firebase deve ser inicializado
const bool INITIALIZE_FIREBASE = false;

// Função para inicializar o Firebase de forma segura
Future<void> initializeFirebaseSafely() async {
  // Não faz nada, pois o Firebase está desabilitado
  print('Firebase desabilitado para esta plataforma.');
  return;
}
