# Voice Stack Deployment Script for Windows/PowerShell
# Provides cross-platform deployment for Portainer environments

param(
    [Parameter(Position=0)]
    [string]$Command = "start",
    
    [Parameter(Position=1)]
    [string]$Service = ""
)

# Colors for output
$Green = "Green"
$Red = "Red" 
$Yellow = "Yellow"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Error ".env file not found. Please copy .env.example to .env and configure it."
    exit 1
}

# Determine Docker Compose command
$DockerComposeCmd = $null

# Try docker compose (v2) first
try {
    $null = docker compose version 2>$null
    $DockerComposeCmd = "docker compose"
    Write-Info "Using Docker Compose v2: docker compose"
} catch {
    # Try docker-compose (v1)
    try {
        $null = docker-compose --version 2>$null
        $DockerComposeCmd = "docker-compose"
        Write-Info "Using Docker Compose v1: docker-compose"
    } catch {
        Write-Error "Neither 'docker compose' nor 'docker-compose' found. Please install Docker Compose."
        exit 1
    }
}

# Function to run docker-compose with environment
function Invoke-Compose {
    param([string[]]$Arguments)
    
    # Check if user has docker permissions
    try {
        $null = docker ps 2>$null
    } catch {
        Write-Error "Cannot access Docker. Please ensure:"
        Write-Host "  1. Docker Desktop is running"
        Write-Host "  2. Current user has Docker access"
        Write-Host "  3. Try running as Administrator if needed"
        exit 1
    }
    
    # Execute docker-compose command
    if ($DockerComposeCmd -eq "docker compose") {
        & docker compose @Arguments
    } else {
        & docker-compose @Arguments
    }
}

# Handle commands
switch ($Command.ToLower()) {
    "start" {
        Write-Info "Starting Voice Stack services..."
        Invoke-Compose @("up", "-d")
    }
    "stop" {
        Write-Info "Stopping Voice Stack services..."
        Invoke-Compose @("down")
    }
    "restart" {
        Write-Info "Restarting Voice Stack services..."
        Invoke-Compose @("down")
        Start-Sleep -Seconds 2
        Invoke-Compose @("up", "-d")
    }
    "logs" {
        Write-Info "Showing logs for all services..."
        if ($Service) {
            Invoke-Compose @("logs", "-f", $Service)
        } else {
            Invoke-Compose @("logs", "-f")
        }
    }
    "status" {
        Write-Info "Checking service status..."
        Invoke-Compose @("ps")
    }
    "health" {
        Write-Info "Checking health status..."
        docker ps --filter "name=voice-stack" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    }
    "clean" {
        Write-Warning "This will remove all containers and networks (but keep volumes)"
        $confirmation = Read-Host "Are you sure? (y/N)"
        if ($confirmation -eq "y" -or $confirmation -eq "Y") {
            Invoke-Compose @("down", "--remove-orphans")
            Write-Info "Cleaned up containers and networks"
        }
    }
    "destroy" {
        Write-Error "This will remove EVERYTHING including data volumes!"
        $confirmation = Read-Host "Are you absolutely sure? Type 'yes' to confirm"
        if ($confirmation -eq "yes") {
            Invoke-Compose @("down", "-v", "--remove-orphans")
            Write-Info "Destroyed all containers, networks, and volumes"
        } else {
            Write-Info "Cancelled destruction"
        }
    }
    default {
        Write-Host "Usage: .\deploy.ps1 {start|stop|restart|logs [service]|status|health|clean|destroy}"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  start    - Start all services"
        Write-Host "  stop     - Stop all services"
        Write-Host "  restart  - Restart all services"
        Write-Host "  logs     - Show logs (optionally for specific service)"
        Write-Host "  status   - Show service status"
        Write-Host "  health   - Show health status"
        Write-Host "  clean    - Remove containers and networks (keep volumes)"
        Write-Host "  destroy  - Remove everything including volumes"
        exit 1
    }
}
