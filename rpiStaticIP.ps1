param(
    [Parameter(Mandatory = $true)]
    [string]$IPAddress,

    [int]$PrefixLength = 24,

    [Parameter(Mandatory = $true)]
    [string]$Gateway,

    [string[]]$DNS = @("1.1.1.1", "8.8.8.8"),

    [string]$Interface = "eth0"
)

$ErrorActionPreference = "Stop"

# 1. YAML opbouwen (Netplan v2 / cloud-init)
$lines = @(
    "network:"
    "  version: 2"
    "  ethernets:"
    "    ${Interface}:"
    "      dhcp4: false"
    "      addresses:"
    "        - $IPAddress/$PrefixLength"
    "      routes:"
    "        - to: default"
    "          via: $Gateway"
    "      nameservers:"
    "        addresses:"
)
foreach ($server in $DNS) {
    $lines += "          - $server"
}

# Linux-regeleindes: enkel LF
$yaml = ($lines -join "`n") + "`n"

# 2. Boot-partitie met label 'bootfs' zoeken
$disks = @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter "VolumeName = 'bootfs'")

if ($disks.Count -eq 0) {
    Write-Host "Geen schijf met label 'bootfs' gevonden. Steek het SD-kaartje in." -ForegroundColor Red
    exit 1
}
if ($disks.Count -gt 1) {
    Write-Host "Meerdere 'bootfs'-schijven gevonden: $(($disks.DeviceID) -join ', '). Laat er maar een zitten." -ForegroundColor Red
    exit 1
}

$bootRoot = $disks[0].DeviceID + "\"
$path = Join-Path $bootRoot "network-config"
Write-Host "Boot-partitie gevonden: $bootRoot"

# 3. Niet bevuilen: identieke inhoud = niets doen, anders volledig overschrijven
if ((Test-Path $path) -and ([System.IO.File]::ReadAllText($path) -ceq $yaml)) {
    Write-Host "network-config is al up-to-date, niets gewijzigd." -ForegroundColor Yellow
}
else {
    # WriteAllText overschrijft het hele bestand; UTF-8 zonder BOM
    [System.IO.File]::WriteAllText($path, $yaml, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Geschreven: $path" -ForegroundColor Green
}

# 4. Controle: geen CR-tekens (Windows-regeleindes)
$bytes = [System.IO.File]::ReadAllBytes($path)
if ($bytes -contains 13) {
    Write-Host "FOUT: bestand bevat Windows-regeleindes (CRLF)!" -ForegroundColor Red
    exit 1
}
Write-Host "Controle OK: Linux-tekstbestand (enkel LF)." -ForegroundColor Green