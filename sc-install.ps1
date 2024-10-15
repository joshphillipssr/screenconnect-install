# Variables
$installerUrl = "https://joshphillipssr.screenconnect.com/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest&c=Goodyear%20AZ"
$tempPath = "$env:TEMP\ScreenConnect.ClientSetup.msi"
$logPath = "C:\Windows\Temp\ScreenConnect_Install_Log.txt"

# Logging Function
function Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    $logMessage | Out-File -Append -FilePath $logPath
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
