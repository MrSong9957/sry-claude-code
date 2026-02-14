# =============================================================================
# Claude Code Statusline Plugin - Windows Installation Script
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# Get script directory (reliable method)
$SCRIPT_DIR = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Definition
}

# Configuration
$PLUGIN_NAME = "show-last-prompt"
$PLUGIN_VERSION = "2.3.0"
$PLUGIN_DIR = "$env:USERPROFILE\.claude\plugins\custom\$PLUGIN_NAME"
$STATUSLINE_DIR = "$PLUGIN_DIR\statusline"
$SETTINGS_FILE = "$env:USERPROFILE\.claude\settings.json"

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Info {
    Write-ColorOutput "[INFO] $args" Green
}

function Show-Warn {
    Write-ColorOutput "[WARN] $args" Yellow
}

function Show-Error {
    Write-ColorOutput "[ERROR] $args" Red
}

# Detect Python command
function Test-PythonCommand {
    $pythonCmd = $null

    # Try python first (more common on Windows)
    try {
        $null = Get-Command python -ErrorAction Stop
        $pythonCmd = "python"
    }
    catch {
        # Fallback to python3
        try {
            $null = Get-Command python3 -ErrorAction Stop
            $pythonCmd = "python3"
        }
        catch {
            Show-Error "Python 3 not found"
            exit 1
        }
    }

    Show-Info "Detected Python: $pythonCmd"
    return $pythonCmd
}

# Create directory structure
function New-PluginDirectories {
    Show-Info "Creating plugin directories..."
    $null = New-Item -ItemType Directory -Force -Path $STATUSLINE_DIR
    $null = New-Item -ItemType Directory -Force -Path "$PLUGIN_DIR\.claude-plugin"
}

# Install plugin files
function Install-PluginFiles {
    param([string]$PythonCmd)

    Show-Info "Copying plugin files..."

    # Use the script directory from global variable
    Copy-Item "$SCRIPT_DIR\statusline\show-prompt.py" -Destination $STATUSLINE_DIR -Force

    # Create plugin.json
    $pluginJson = @{
        name       = $PLUGIN_NAME
        version    = $PLUGIN_VERSION
        description = "Display simplified version of last user input in statusline"
        license    = "MIT"
        homepage   = "https://github.com/MrSong9957/claude-code-statusline-plugin"
    } | ConvertTo-Json

    Set-Content -Path "$PLUGIN_DIR\.claude-plugin\plugin.json" -Value $pluginJson

    Show-Info "Files installed to: $PLUGIN_DIR"
}

# Configure settings.json
function Update-SettingsFile {
    param([string]$PythonCmd)

    Show-Info "Configuring settings.json..."

    # Backup existing settings
    if (Test-Path $SETTINGS_FILE) {
        $backupPath = "$SETTINGS_FILE.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $SETTINGS_FILE $backupPath
        Show-Info "Backed up settings.json to: $backupPath"
    }

    # Read existing settings (without -AsHashtable)
    $settings = $null
    if (Test-Path $SETTINGS_FILE) {
        try {
            $settings = Get-Content $SETTINGS_FILE -Raw | ConvertFrom-Json
        }
        catch {
            Show-Warn "Cannot parse existing settings.json, creating new file"
            $settings = @{}
        }
    } else {
        $settings = @{}
    }

    # Convert to Hashtable if it's a PSCustomObject
    if ($settings -is [PSCustomObject]) {
        $settingsHash = @{}
        $settings.PSObject.Properties | ForEach-Object {
            $settingsHash[$_.Name] = $_.Value
        }
        $settings = $settingsHash
    }

    # Add/update statusLine configuration
    # Convert path to forward slashes (JSON compatible)
    $statuslinePath = $STATUSLINE_DIR.Replace('\', '/')
    $settings.statusLine = @{
        type    = "command"
        command = "$PythonCmd $statuslinePath/show-prompt.py"
    }

    # Write settings file with proper formatting
    $jsonOutput = $settings | ConvertTo-Json -Depth 10
    $jsonOutput | Set-Content -Path $SETTINGS_FILE

    Show-Info "settings.json updated"
}

# Main installation flow
function Install-Plugin {
    param([string]$PythonCmd)

    Show-Info "Installing $PLUGIN_NAME plugin..."
    Show-Info "Version: $PLUGIN_VERSION"
    Write-Host ""

    New-PluginDirectories
    Install-PluginFiles -PythonCmd $PythonCmd
    Update-SettingsFile -PythonCmd $PythonCmd

    Write-Host ""
    Show-Info "========================================"
    Show-Info "Installation completed!"
    Show-Info "========================================"
    Show-Info "Please restart Claude Code"
    Write-Host ""
}

# Uninstall
function Uninstall-Plugin {
    Show-Info "Uninstalling plugin..."

    # Remove statusLine from settings.json
    if (Test-Path $SETTINGS_FILE) {
        try {
            $settings = Get-Content $SETTINGS_FILE -Raw | ConvertFrom-Json

            # Convert to Hashtable if it's a PSCustomObject
            if ($settings -is [PSCustomObject]) {
                $settingsHash = @{}
                $settings.PSObject.Properties | ForEach-Object {
                    if ($_.Name -ne "statusLine") {
                        $settingsHash[$_.Name] = $_.Value
                    }
                }
                $settings = $settingsHash
            } elseif ($settings -is [Hashtable]) {
                $settings.Remove("statusLine")
            }

            # Write back
            $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SETTINGS_FILE
            Show-Info "Removed statusLine from settings.json"
        }
        catch {
            Show-Warn "Cannot remove statusLine automatically, please manually edit $SETTINGS_FILE"
        }
    }

    # Delete plugin directory
    if (Test-Path $PLUGIN_DIR) {
        Remove-Item -Recurse -Force $PLUGIN_DIR
        Show-Info "Deleted plugin directory"
    }

    Show-Info "Uninstallation completed"
}

# Main function
function Main {
    if ($Uninstall) {
        Uninstall-Plugin
    }
    else {
        $pythonCmd = Test-PythonCommand
        Install-Plugin -PythonCmd $pythonCmd
    }
}

# Execute main function
Main
