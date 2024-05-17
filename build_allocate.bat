@echo off
setlocal

:: Fill these in if building for online use
set SUPABASE_URL=your-url-here
set SUPABASE_ANNON_KEY=your-key-here

:: targets: ios, apk, aab, macos, windows, linux
set TARGET_OS=your-target-os

:: Set to true if building offline only
set OFFLINE=false

:: Check for Flutter
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Install Flutter and add to PATH before running this script.
    exit /b 1
)

:: Check for Supabase CLI
where supabase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Install Supabase CLI and add to PATH before running this script.
    exit /b 1
)

:: Flutter
flutter pub clean
flutter pub get

:: Enter 1 (delete old) if prompted
dart run build_runner build
dart run icons_launcher:create
dart run flutter_native_splash:create

flutter build %TARGET_OS% --release ^
    --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
    --dart-define=SUPABASE_ANNON_KEY=%SUPABASE_ANNON_KEY% ^
    --dart-define=OFFLINE=%OFFLINE%

if %ERRORLEVEL% NEQ 0 (
    echo Build Failure: See above build output for errors
    exit /b 1
)

if "%OFFLINE%"=="true" (
    echo Build Successful: See "Installation" for next steps
    exit /b 0
)

:: SUPABASE

supabase login
supabase init
supabase link

robocopy supabase_config\functions supabase\functions /E

supabase functions deploy delete_user_account

if %ERRORLEVEL% NEQ 0 (
    echo Supabase Failure: See the above output for errors
    exit /b 1
)

echo Build Successful: See "Installation" for next steps
exit /b 0
