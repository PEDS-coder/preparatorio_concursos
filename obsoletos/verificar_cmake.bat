@echo off
echo ===================================================
echo Verificando configuração do CMake
echo ===================================================

echo.
echo Verificando versão do CMake...
where cmake
cmake --version

echo.
echo Verificando versão do Visual Studio...
echo Visual Studio Enterprise:
if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
    echo Visual Studio Enterprise 2022 encontrado
) else (
    echo Visual Studio Enterprise 2022 não encontrado
)

echo.
echo Visual Studio Preview:
if exist "C:\Program Files\Microsoft Visual Studio\2022\Preview\MSBuild\Current\Bin\MSBuild.exe" (
    echo Visual Studio Preview 2022 encontrado
) else (
    echo Visual Studio Preview 2022 não encontrado
)

echo.
echo Verificando configuração do Flutter...
flutter doctor -v

echo.
echo ===================================================
