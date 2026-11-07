$yaml = @"
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.1.50/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
"@

$yaml = $yaml -replace "`r`n", "`n"

$path = Join-Path (Get-Location) "network-config"
[System.IO.File]::WriteAllText($path, $yaml + "`n", (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Geschreven: $path"