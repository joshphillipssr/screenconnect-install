# Variables
$installerUrl = "https://joshphillipssr.screenconnect.com/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
$tempPath = "$env:TEMP\ScreenConnect.ClientSetup.msi"
$logPath = "C:\Windows\Temp\ScreenConnect_Install_Log.txt"
$serviceName = "ScreenConnect Client*"

# Logging Function
function Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    $logMessage | Out-File -Append -FilePath $logPath
}

# Function to find the uninstallation string for ScreenConnect in the registry
function Get-UninstallString {
    Log "Searching the registry for the ScreenConnect uninstaller..."

    # Check 64-bit registry
    $uninstallEntry = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                      Where-Object { $_.DisplayName -like "*ScreenConnect*" }
    if ($uninstallEntry) {
        Log "Found ScreenConnect uninstaller in 64-bit registry."
        return $uninstallEntry.UninstallString
    }

    # Check 32-bit registry
    $uninstallEntry = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                      Where-Object { $_.DisplayName -like "*ScreenConnect*" }
    if ($uninstallEntry) {
        Log "Found ScreenConnect uninstaller in 32-bit registry."
        return $uninstallEntry.UninstallString
    }

    Log "ERROR: Could not find the uninstaller in the registry."
    return $null
}

# Check if ScreenConnect is already installed
Log "Checking if ScreenConnect is already installed..."
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Log "ScreenConnect is already installed. Attempting to uninstall..."

    # Find the uninstall string from the registry
    $uninstallString = Get-UninstallString
    if ($uninstallString) {
        try {
            # Attempt to uninstall ScreenConnect using the found UninstallString
            Log "Running uninstall command: $uninstallString"
            Start-Process -FilePath "msiexec.exe" -ArgumentList "$uninstallString /quiet /norestart" -Wait -PassThru
            Log "ScreenConnect uninstalled successfully."
        } catch {
            Log "ERROR: Failed to uninstall ScreenConnect. Exception: $_"
            exit 1
        }
    } else {
        Log "ERROR: Uninstall string not found. Cannot uninstall ScreenConnect."
    }
}

# Download the installer
Log "Downloading ScreenConnect installer from $installerUrl..."
try {
    Invoke-WebRequest -Uri $installerUrl -OutFile $tempPath -UseBasicParsing
    Log "Download completed successfully."
} catch {
    Log "ERROR: Failed to download the installer. Exception: $_"
    exit 1
}

# Install the ScreenConnect agent
Log "Starting ScreenConnect agent installation..."
try {
    Start-Process msiexec.exe -ArgumentList "/i `"$tempPath`" /quiet /norestart" -Wait
    Log "ScreenConnect agent installed successfully."
} catch {
    Log "ERROR: Failed to install the agent. Exception: $_"
    exit 1
}

# Clean up
Log "Cleaning up temporary files..."
try {
    Remove-Item $tempPath -Force
    Log "Temporary files removed."
} catch {
    Log "ERROR: Failed to remove temporary files. Exception: $_"
}

Log "Script execution completed."
