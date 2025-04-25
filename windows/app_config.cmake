# Configuração personalizada para o aplicativo
# Este arquivo contém configurações específicas do aplicativo

# Definições do aplicativo
# Usar o nome do binário já definido no CMakeLists.txt principal
set(APP_NAME ${BINARY_NAME})
set(APP_DESCRIPTION "Aplicativo de preparação para concursos públicos")
set(APP_VERSION "1.0.0")
set(APP_COMPANY "Preparatório Concursos")

# Configurações de compilação personalizadas
set(APP_ENABLE_OPTIMIZATION TRUE)
set(APP_ENABLE_PROFILING FALSE)

# Configurações de recursos do aplicativo
# Firebase temporariamente desabilitado
set(APP_ENABLE_ANALYTICS FALSE)
set(APP_ENABLE_CRASHLYTICS FALSE)
set(APP_ENABLE_PERFORMANCE FALSE)
set(APP_ENABLE_REMOTE_CONFIG FALSE)

# Configurações de tema
set(APP_DARK_THEME_ENABLED TRUE)
set(APP_HIGH_CONTRAST_ENABLED FALSE)

# Outras configurações personalizadas podem ser adicionadas aqui
