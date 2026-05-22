@echo off
setlocal enabledelayedexpansion

:: ==================================================
:: FUCKINGFAST Upload Script for Windows
:: Features:
:: - Live upload progress
:: - Upload speed
:: - Upload time
:: - Final download link
:: ==================================================

set API_URL=https://w.fuckingfast.net
set BASE_DOWNLOAD=https://fuckingfast.net

:: Optional token
set TOKEN=YOUR_ACCOUNT_ID

set TARGET=%~1
set PARENT_ID=%~2

if "%TARGET%"=="" (
    echo Usage:
    echo   ffupload.bat file_or_folder [parentId]
    exit /b 1
)

if exist "%TARGET%\" (
    for /r "%TARGET%" %%F in (*) do (
        call :upload "%%F"
    )
) else (
    call :upload "%TARGET%"
)

echo.
echo ==================================================
echo Finished
echo ==================================================
pause
exit /b

:upload

set FILE=%~1
set BASENAME=%~nx1

echo.
echo ==================================================
echo Uploading : %BASENAME%
echo ==================================================

set START=%time%

if "%PARENT_ID%"=="" (
    curl ^
        -T "%FILE%" ^
        --progress-bar ^
        -o response.json ^
        "%API_URL%/%BASENAME%"
) else (
    curl ^
        -T "%FILE%" ^
        -H "Authorization: Bearer %TOKEN%" ^
        --progress-bar ^
        -o response.json ^
        "%API_URL%/%PARENT_ID%/%BASENAME%"
)

for /f "tokens=2 delims=:," %%A in ('findstr /c:"\"id\"" response.json') do (
    set ID=%%~A
)

set ID=%ID:"=%
set ID=%ID: =%

echo.
echo [✓] Upload completed
echo Link:
echo %BASE_DOWNLOAD%/%ID%

del response.json >nul 2>&1

exit /b