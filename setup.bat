@echo off
REM Voice Stack Setup Script for Windows
REM This script helps initialize the Matrix Synapse voice server stack

echo === Voice Stack Setup ===

REM Check if .env exists
if not exist .env (
    echo Creating .env file from template...
    copy .env.example .env
    echo Please edit .env file with your configuration before proceeding!
    echo At minimum, update SERVER_NAME and TURN_SECRET
    pause
    exit /b 1
)

echo Setting up directories...
if not exist synapse\data mkdir synapse\data
if not exist media_store mkdir media_store
if not exist logs mkdir logs

REM Generate secrets if they don't exist
if not exist synapse\signing.key (
    echo Generating Synapse signing key...
    docker run --rm -v "%cd%/synapse:/data" matrixdotorg/synapse:latest generate_signing_key.py -o /data/signing.key
)

echo === Setup Complete ===
echo You can now run: docker-compose up -d
echo.
echo Services will be available at:
echo - Matrix Synapse: http://localhost:8008
echo - Element Web: http://localhost:8080
echo - TURN server: localhost:3478 (UDP/TCP)
echo.
echo Remember to:
echo 1. Update your DNS to point your SERVER_NAME to this server
echo 2. Set up SSL certificates for production use
echo 3. Configure your firewall to allow the required ports
echo 4. Edit .env file with your actual configuration values
pause
