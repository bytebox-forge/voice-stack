@echo off
REM Portainer Git Integration Setup Script for Windows
REM This script helps configure webhook integration between GitHub and Portainer

echo === Portainer Git Integration Setup ===
echo.

REM Get Portainer details
set /p PORTAINER_URL="Portainer URL (e.g., https://portainer.example.com): "
set /p PORTAINER_USER="Portainer Username: "
set /p PORTAINER_PASS="Portainer Password: "

REM Get stack details
set /p STACK_NAME="Stack name (default: voice-stack): "
if "%STACK_NAME%"=="" set STACK_NAME=voice-stack

REM Get GitHub details
set /p GITHUB_REPO="GitHub repository (default: anykolaiszyn/voice-stack): "
if "%GITHUB_REPO%"=="" set GITHUB_REPO=anykolaiszyn/voice-stack

echo.
echo === Configuration Summary ===
echo Portainer URL: %PORTAINER_URL%
echo Stack Name: %STACK_NAME%
echo GitHub Repository: %GITHUB_REPO%
echo.

REM Instructions for manual setup
echo === Manual Setup Instructions ===
echo.
echo 1. Create Stack in Portainer:
echo    - Go to Stacks → Add stack
echo    - Choose 'Repository' tab
echo    - Repository URL: https://github.com/%GITHUB_REPO%.git
echo    - Reference: main
echo    - Compose path: docker-compose.portainer.yml
echo.
echo 2. Set Environment Variables:
echo    - SERVER_NAME=matrix.byte-box.org
echo    - TURN_SECRET=^(generate with: openssl rand -base64 32^)
echo    - REGISTRATION_SECRET=^(generate with: openssl rand -base64 32^)
echo    - POSTGRES_PASSWORD=secure_db_password
echo.
echo 3. Enable Auto-Updates:
echo    - Check 'Enable auto-update'
echo    - Set polling interval: 5m
echo.
echo 4. Deploy the stack
echo.
echo 5. Configure GitHub Webhook ^(optional^):
echo    - In Portainer, go to your stack → Editor tab
echo    - Enable 'GitOps updates'
echo    - Copy the webhook URL
echo    - In GitHub: Settings → Webhooks → Add webhook
echo    - Paste the webhook URL
echo    - Content type: application/json
echo    - Trigger: Just the push event
echo.
echo === Next Steps ===
echo 1. Follow the manual setup instructions above
echo 2. Verify all services are running in Portainer
echo 3. Test connectivity to your Matrix server
echo 4. Set up DNS records as described in DNS-SETUP.md
echo.
echo For detailed documentation, see PORTAINER.md
echo.
pause
