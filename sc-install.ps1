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

# Uninstall ScreenConnect if already installed
Log "Checking if ScreenConnect is already installed..."
$existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($existingService) {
    Log "ScreenConnect is already installed. Attempting to uninstall..."

    try {
        # Get the installation path from the registry
        $uninstallKey = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                        Where-Object { $_.DisplayName -like "ScreenConnect*" }
        
        if ($uninstallKey) {
            # Uninstall using msiexec
            $uninstallCommand = "/x `"$($uninstallKey.PSChildName)`" /quiet /norestart"
            Start-Process "msiexec.exe" -ArgumentList $uninstallCommand -Wait
            Log "ScreenConnect uninstalled successfully."
        } else {
            Log "ERROR: Could not find the uninstaller in the registry."
        }
    } catch {
        Log "ERROR: Failed to uninstall ScreenConnect. Exception: $_"
        exit 1
    }
} else {
    Log "ScreenConnect is not installed."
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
