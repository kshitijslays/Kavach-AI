# Kavach Development Setup Script
# Run this once after connecting your physical device via USB

Write-Host "Configuring ADB Reverse Port Forwarding for Kavach..." -ForegroundColor Green

# Reverse port forward 5000 (Backend)
adb reverse tcp:5000 tcp:5000

# Optional: You can add 8000 if you have other services
# adb reverse tcp:8000 tcp:8000

Write-Host "Success! You can now use http://127.0.0.1:5000/api in constants.dart" -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
