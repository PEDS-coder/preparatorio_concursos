@echo off
echo ===================================================
echo Verificando compilador C++
echo ===================================================

echo.
echo Verificando Visual Studio Enterprise...
set "VS_ENTERPRISE=C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
set "CL_ENTERPRISE=%VS_ENTERPRISE%\VC\Tools\MSVC\14.39.33519\bin\Hostx64\x64\cl.exe"

if exist "%VS_ENTERPRISE%" (
    echo Visual Studio Enterprise encontrado em: %VS_ENTERPRISE%
    
    if exist "%CL_ENTERPRISE%" (
        echo Compilador C++ encontrado em: %CL_ENTERPRISE%
    ) else (
        echo Compilador C++ NAO encontrado no caminho padrao!
        echo Procurando em outras pastas...
        
        for /d %%i in ("%VS_ENTERPRISE%\VC\Tools\MSVC\*") do (
            if exist "%%i\bin\Hostx64\x64\cl.exe" (
                echo Compilador C++ encontrado em: %%i\bin\Hostx64\x64\cl.exe
            )
        )
    )
) else (
    echo Visual Studio Enterprise NAO encontrado!
)

echo.
echo Verificando Visual Studio Preview...
set "VS_PREVIEW=C:\Program Files\Microsoft Visual Studio\2022\Preview"
set "CL_PREVIEW=%VS_PREVIEW%\VC\Tools\MSVC\14.44.34918\bin\Hostx64\x64\cl.exe"

if exist "%VS_PREVIEW%" (
    echo Visual Studio Preview encontrado em: %VS_PREVIEW%
    
    if exist "%CL_PREVIEW%" (
        echo Compilador C++ encontrado em: %CL_PREVIEW%
    ) else (
        echo Compilador C++ NAO encontrado no caminho padrao!
        echo Procurando em outras pastas...
        
        for /d %%i in ("%VS_PREVIEW%\VC\Tools\MSVC\*") do (
            if exist "%%i\bin\Hostx64\x64\cl.exe" (
                echo Compilador C++ encontrado em: %%i\bin\Hostx64\x64\cl.exe
            )
        )
    )
) else (
    echo Visual Studio Preview NAO encontrado!
)

echo.
echo ===================================================
