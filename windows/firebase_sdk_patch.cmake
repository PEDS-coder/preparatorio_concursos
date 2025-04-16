# Patch para o CMakeLists.txt do Firebase SDK
# Este arquivo é executado após a extração do Firebase SDK para corrigir problemas de compatibilidade

file(GLOB_RECURSE FIREBASE_CMAKE_FILES "${CMAKE_BINARY_DIR}/*/firebase_cpp_sdk_windows/CMakeLists.txt")

foreach(FIREBASE_CMAKE_FILE ${FIREBASE_CMAKE_FILES})
  message(STATUS "Patching Firebase SDK CMakeLists.txt: ${FIREBASE_CMAKE_FILE}")

  # Ler o conteúdo do arquivo
  file(READ "${FIREBASE_CMAKE_FILE}" FIREBASE_CMAKE_CONTENT)

  # Substituir a versão mínima do CMake
  string(REGEX REPLACE "cmake_minimum_required\\(VERSION ([0-9]\\.[0-9])\\)"
                      "cmake_minimum_required(VERSION 3.14)"
                      FIREBASE_CMAKE_CONTENT_PATCHED
                      "${FIREBASE_CMAKE_CONTENT}")

  # Escrever o conteúdo modificado de volta para o arquivo
  file(WRITE "${FIREBASE_CMAKE_FILE}" "${FIREBASE_CMAKE_CONTENT_PATCHED}")
endforeach()
