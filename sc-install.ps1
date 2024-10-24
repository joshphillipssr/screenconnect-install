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

# Check if ScreenConnect service exists
Log "Checking if ScreenConnect is already installed..."
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service) {
    Log "ScreenConnect service found. Attempting to uninstall..."
    
    # Search for the uninstall string in the registry
    $uninstallString = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*ScreenConnect*" } | 
        Select-Object -ExpandProperty UninstallString -First 1) -or
        (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*ScreenConnect*" } | 
        Select-Object -ExpandProperty UninstallString -First 1)

    if ($uninstallString) {
        # Ensure the format is /X {GUID}
        $uninstallString = $uninstallString -replace '/X', '/X '
        Log "Uninstall string found: $uninstallString. Running uninstaller..."
        try {
            # Run the uninstaller silently
            Start-Process msiexec.exe -ArgumentList "$uninstallString /quiet /norestart" -Wait -NoNewWindow
            Log "ScreenConnect uninstalled successfully."
        } catch {
            Log "ERROR: Failed to uninstall ScreenConnect. Exception: $_"
            exit 1
        }
    } else {
        Log "ERROR: Could not find the uninstaller in the registry."
    }
} else {
    Log "ScreenConnect is not installed. Proceeding with installation..."
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
    Start-Process msiexec.exe -ArgumentList "/i `"$tempPath`" /quiet /norestart" -Wait -NoNewWindow
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