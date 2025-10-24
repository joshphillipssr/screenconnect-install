# Detection Script for ScreenConnect

# Check 64-bit uninstall registry
$screenConnectInstalled64 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*ScreenConnect*" }

# Check 32-bit uninstall registry (for 64-bit systems)
$screenConnectInstalled32 = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*ScreenConnect*" }

if ($screenConnectInstalled64 -or $screenConnectInstalled32) {
    Write-Output "ScreenConnect is installed."
    exit 0  # Compliant – No remediation needed
} else {
    Write-Output "ScreenConnect is NOT installed."
    exit 1  # Not compliant – Trigger remediation
}
