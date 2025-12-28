@echo off
echo Starting Coral NPU Development Environment...
echo ---------------------------------------------

REM Check if Docker is running
docker info >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Docker is not running. Please start Docker Desktop and try again.
    pause
    exit /b
)

REM Build and start the container in background
echo Building and starting container...
docker compose up -d --build

REM Enter the container
echo Entering Linux environment...
echo Type 'exit' to close the session (container will keep running).
docker compose exec dev /bin/bash -lc "git config --global --add safe.directory /workspace; exec /bin/bash"

pause
