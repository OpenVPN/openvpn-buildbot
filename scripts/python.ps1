Write-Host "Installing python"
& choco.exe install -y python
# some of our python scripts do not work with 3.13+, yet
& choco.exe install -y python312
