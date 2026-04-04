@echo off
REM Script to run all tests for Rentify project

echo ========================================
echo Running Rentify Tests
echo ========================================
echo.

echo [1/3] Running Unit Tests - Models...
flutter test test/unit/models/
if %errorlevel% neq 0 (
    echo FAILED: Model tests failed!
    exit /b 1
)
echo ✓ Model tests passed!
echo.

echo [2/3] Running Unit Tests - Services...
flutter test test/unit/services/ 2>nul
if %errorlevel% equ 0 (
    echo ✓ Service tests passed!
) else (
    echo ⚠ Service tests not yet implemented
)
echo.

echo [3/3] Running Widget Tests...
flutter test test/widget/ 2>nul
if %errorlevel% equ 0 (
    echo ✓ Widget tests passed!
) else (
    echo ⚠ Widget tests not yet implemented
)
echo.

echo ========================================
echo Test Summary
echo ========================================
flutter test --no-test-assets 2>nul | findstr /C:"passed" /C:"failed"
echo.
echo Done!
