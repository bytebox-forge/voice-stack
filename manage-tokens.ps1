# Registration Token Management Script for Voice Stack (Windows)
# This script helps you create, list, and delete registration tokens

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [string]$Name = "New User",
    
    [Parameter(Position=2)]
    [int]$Uses = 1,
    
    [Parameter(Position=1)]
    [string]$Token
)

$SYNAPSE_CONTAINER = "voice-stack-synapse"
$SERVER_NAME = "matrix.byte-box.org"

function Show-Help {
    Write-Host "Voice Stack Registration Token Manager" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Usage: .\manage-tokens.ps1 [COMMAND] [OPTIONS]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  create [NAME] [USES]    Create a new registration token"
    Write-Host "                          NAME: Optional name/description"
    Write-Host "                          USES: Number of uses (default: 1)"
    Write-Host "  list                    List all registration tokens"
    Write-Host "  delete [TOKEN]          Delete a specific token"
    Write-Host "  help                    Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host '  .\manage-tokens.ps1 create "Family Friend" 1'
    Write-Host '  .\manage-tokens.ps1 create "Relatives" 5'
    Write-Host '  .\manage-tokens.ps1 list'
    Write-Host '  .\manage-tokens.ps1 delete abc123xyz'
}

function New-RegistrationToken {
    param(
        [string]$TokenName = "New User",
        [int]$UsesAllowed = 1
    )
    
    Write-Host "Creating registration token..." -ForegroundColor Yellow
    Write-Host "Name: $TokenName"
    Write-Host "Uses: $UsesAllowed"
    
    # Generate a random token
    $RandomBytes = New-Object byte[] 16
    [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($RandomBytes)
    $GeneratedToken = [System.Convert]::ToHexString($RandomBytes).ToLower()
    
    # Create the JSON payload
    $JsonPayload = @{
        token = $GeneratedToken
        uses_allowed = $UsesAllowed
        pending = 0
        completed = 0
        expiry_time = $null
    } | ConvertTo-Json
    
    try {
        # Use docker to call the admin API
        $Result = docker exec $SYNAPSE_CONTAINER curl -X POST `
            "http://localhost:8008/_synapse/admin/v1/registration_tokens/new" `
            -H "Content-Type: application/json" `
            -d $JsonPayload `
            --silent
        
        Write-Host "✅ Token created successfully!" -ForegroundColor Green
        Write-Host "Registration Token: " -ForegroundColor Blue -NoNewline
        Write-Host $GeneratedToken -ForegroundColor Green
        Write-Host "Share this token with: $TokenName" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Instructions for users:" -ForegroundColor Blue
        Write-Host "1. Go to: http://your-server-ip:8080"
        Write-Host "2. Click 'Create Account'"
        Write-Host "3. Enter the registration token: $GeneratedToken"
        Write-Host "4. Complete registration normally"
        
        # Save token info to a file for reference
        $TokenInfo = @{
            Token = $GeneratedToken
            Name = $TokenName
            Uses = $UsesAllowed
            Created = (Get-Date).ToString()
        }
        
        $TokensFile = "registration-tokens.json"
        $ExistingTokens = @()
        
        if (Test-Path $TokensFile) {
            $ExistingTokens = Get-Content $TokensFile | ConvertFrom-Json
        }
        
        $ExistingTokens += $TokenInfo
        $ExistingTokens | ConvertTo-Json -Depth 3 | Set-Content $TokensFile
        
        Write-Host "Token info saved to: $TokensFile" -ForegroundColor Gray
        
    } catch {
        Write-Host "❌ Failed to create token: $_" -ForegroundColor Red
    }
}

function Get-RegistrationTokens {
    Write-Host "Listing all registration tokens..." -ForegroundColor Yellow
    
    try {
        $Result = docker exec $SYNAPSE_CONTAINER curl -X GET `
            "http://localhost:8008/_synapse/admin/v1/registration_tokens" `
            -H "Content-Type: application/json" `
            --silent
        
        $Tokens = $Result | ConvertFrom-Json
        
        if ($Tokens.registration_tokens) {
            Write-Host "Active Registration Tokens:" -ForegroundColor Green
            Write-Host "="*50
            
            foreach ($Token in $Tokens.registration_tokens) {
                Write-Host "Token: " -NoNewline -ForegroundColor Blue
                Write-Host $Token.token -ForegroundColor Green
                Write-Host "Uses: $($Token.completed)/$($Token.uses_allowed)" -ForegroundColor Yellow
                Write-Host "Status: " -NoNewline
                if ($Token.completed -ge $Token.uses_allowed) {
                    Write-Host "EXHAUSTED" -ForegroundColor Red
                } else {
                    Write-Host "ACTIVE" -ForegroundColor Green
                }
                Write-Host ""
            }
        } else {
            Write-Host "No registration tokens found." -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "❌ Failed to list tokens: $_" -ForegroundColor Red
    }
}

function Remove-RegistrationToken {
    param([string]$TokenToDelete)
    
    if (-not $TokenToDelete) {
        Write-Host "❌ Please specify a token to delete" -ForegroundColor Red
        return
    }
    
    Write-Host "Deleting token: $TokenToDelete" -ForegroundColor Yellow
    
    try {
        $Result = docker exec $SYNAPSE_CONTAINER curl -X DELETE `
            "http://localhost:8008/_synapse/admin/v1/registration_tokens/$TokenToDelete" `
            -H "Content-Type: application/json" `
            --silent
        
        Write-Host "✅ Token deleted successfully!" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to delete token: $_" -ForegroundColor Red
    }
}

# Main script logic
switch ($Command.ToLower()) {
    "create" {
        New-RegistrationToken -TokenName $Name -UsesAllowed $Uses
    }
    "list" {
        Get-RegistrationTokens
    }
    "delete" {
        Remove-RegistrationToken -TokenToDelete $Token
    }
    default {
        Show-Help
    }
}
