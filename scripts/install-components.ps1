# Script de instalación automática para Rclone + NSSM + WinFsp
# Ejecutar como Administrador

param(
    [string]$InstallPath = "C:\rclone",
    [string]$MountPath = "C:\mnt",
    [switch]$SkipDownloads = $false
)

Write-Host "=== Instalación automática Rclone + NSSM + WinFsp ===" -ForegroundColor Green
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray

# Verificar permisos de administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script requiere permisos de Administrador. Ejecute PowerShell como Administrador."
    exit 1
}

# Crear estructura de directorios
Write-Host "Creando estructura de directorios..." -ForegroundColor Yellow

$directories = @(
    $InstallPath,
    "$InstallPath\cache",
    "$InstallPath\cache\vfs",
    "$InstallPath\cache\vfsMeta", 
    "$InstallPath\logs",
    "$InstallPath\bin"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✅ Creado: $dir" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️  Ya existe: $dir" -ForegroundColor Blue
    }
}

# Función de descarga
function Download-File {
    param($Url, $Output)
    try {
        Write-Host "  Descargando desde: $Url" -ForegroundColor Gray
        Invoke-WebRequest -Uri $Url -OutFile $Output -UseBasicParsing
        Write-Host "  ✅ Descargado: $(Split-Path $Output -Leaf)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  ❌ Error descargando: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

if (-not $SkipDownloads) {
    Write-Host "`nDescargando componentes..." -ForegroundColor Yellow
    
    # URLs de descarga (actualizar según necesidad)
    $downloads = @{
        "Rclone" = @{
            "Url" = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"
            "Output" = "$env:TEMP\rclone.zip"
        }
        "NSSM" = @{
            "Url" = "https://nssm.cc/release/nssm-2.24.zip"
            "Output" = "$env:TEMP\nssm.zip"
        }
        "WinFsp" = @{
            "Url" = "https://github.com/winfsp/winfsp/releases/latest/download/winfsp-2.0.23075.msi"
            "Output" = "$env:TEMP\winfsp.msi"
        }
    }
    
    foreach ($component in $downloads.Keys) {
        Write-Host "Descargando $component..." -ForegroundColor Cyan
        $success = Download-File -Url $downloads[$component].Url -Output $downloads[$component].Output
        if (-not $success) {
            Write-Warning "Fallo al descargar $component. Continúe manualmente."
        }
    }
    
    # Extraer Rclone
    if (Test-Path "$env:TEMP\rclone.zip") {
        Write-Host "Extrayendo Rclone..." -ForegroundColor Cyan
        Expand-Archive -Path "$env:TEMP\rclone.zip" -DestinationPath "$env:TEMP\rclone_extract" -Force
        $rcloneExe = Get-ChildItem -Path "$env:TEMP\rclone_extract" -Name "rclone.exe" -Recurse | Select-Object -First 1
        if ($rcloneExe) {
            $rcloneFullPath = Get-ChildItem -Path "$env:TEMP\rclone_extract" -Name "rclone.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
            Copy-Item $rcloneFullPath "$InstallPath\rclone.exe" -Force
            Write-Host "  ✅ Rclone instalado en $InstallPath\rclone.exe" -ForegroundColor Green
        }
    }
    
    # Extraer NSSM
    if (Test-Path "$env:TEMP\nssm.zip") {
        Write-Host "Extrayendo NSSM..." -ForegroundColor Cyan
        Expand-Archive -Path "$env:TEMP\nssm.zip" -DestinationPath "$env:TEMP\nssm_extract" -Force
        $nssmExe = Get-ChildItem -Path "$env:TEMP\nssm_extract" -Name "nssm.exe" -Recurse | Where-Object { $_.FullName -match "win64" } | Select-Object -First 1
        if ($nssmExe) {
            Copy-Item $nssmExe.FullName "$InstallPath\bin\nssm.exe" -Force
            Write-Host "  ✅ NSSM instalado en $InstallPath\bin\nssm.exe" -ForegroundColor Green
        }
    }
    
    # Instalar WinFsp
    if (Test-Path "$env:TEMP\winfsp.msi") {
        Write-Host "Instalando WinFsp..." -ForegroundColor Cyan
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$env:TEMP\winfsp.msi`" /quiet" -Wait
        Write-Host "  ✅ WinFsp instalado (reinicio puede ser necesario)" -ForegroundColor Green
    }
}

# Agregar al PATH
Write-Host "`nConfigurando variables de entorno..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$InstallPath*") {
    $newPath = $currentPath + ";$InstallPath;$InstallPath\bin"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "  ✅ Agregado al PATH del sistema" -ForegroundColor Green
}

# Crear archivo de configuración de ejemplo
Write-Host "`nCreando archivo de configuración de ejemplo..." -ForegroundColor Yellow
$configExample = @"
# Configuración de Rclone - EJEMPLO
# Edite este archivo con sus credenciales reales

[ucmovie]
type = drive
client_id = TU_CLIENT_ID
client_secret = TU_CLIENT_SECRET
scope = drive
token = {"access_token":"TU_TOKEN","token_type":"Bearer","refresh_token":"TU_REFRESH_TOKEN","expiry":"2025-12-31T23:59:59Z"}
team_drive = TU_TEAM_DRIVE_ID

[ucserie]
type = drive
client_id = TU_CLIENT_ID
client_secret = TU_CLIENT_SECRET
scope = drive
token = {"access_token":"TU_TOKEN","token_type":"Bearer","refresh_token":"TU_REFRESH_TOKEN","expiry":"2025-12-31T23:59:59Z"}
team_drive = TU_TEAM_DRIVE_ID

[ucarr]
type = drive
client_id = TU_CLIENT_ID
client_secret = TU_CLIENT_SECRET
scope = drive
token = {"access_token":"TU_TOKEN","token_type":"Bearer","refresh_token":"TU_REFRESH_TOKEN","expiry":"2025-12-31T23:59:59Z"}
team_drive = TU_TEAM_DRIVE_ID
"@

$configExample | Out-File -FilePath "$InstallPath\rclone.conf.example" -Encoding UTF8
Write-Host "  ✅ Archivo de ejemplo creado: $InstallPath\rclone.conf.example" -ForegroundColor Green

# Configurar permisos
Write-Host "`nConfigurando permisos de seguridad..." -ForegroundColor Yellow
try {
    $acl = Get-Acl $InstallPath
    $acl.SetAccessRuleProtection($true, $false) # Deshabilitar herencia
    
    # Permisos para Administradores
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administradores", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($adminRule)
    
    # Permisos para SYSTEM
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($systemRule)
    
    Set-Acl -Path $InstallPath -AclObject $acl
    Write-Host "  ✅ Permisos configurados correctamente" -ForegroundColor Green
} catch {
    Write-Warning "No se pudieron configurar permisos automáticamente: $($_.Exception.Message)"
}

Write-Host "`n=== INSTALACIÓN COMPLETADA ===" -ForegroundColor Green
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Reiniciar el sistema (recomendado para WinFsp)" -ForegroundColor White
Write-Host "2. Configurar rclone.conf con sus credenciales" -ForegroundColor White
Write-Host "3. Ejecutar setup-services.ps1 para crear los servicios NSSM" -ForegroundColor White
Write-Host "4. Verificar funcionamiento con test-mounts.ps1" -ForegroundColor White

Write-Host "`nUbicaciones importantes:" -ForegroundColor Yellow
Write-Host "  Rclone: $InstallPath\rclone.exe" -ForegroundColor White
Write-Host "  NSSM: $InstallPath\bin\nssm.exe" -ForegroundColor White
Write-Host "  Config: $InstallPath\rclone.conf (debe crear)" -ForegroundColor White
Write-Host "  Logs: $InstallPath\logs\" -ForegroundColor White

Read-Host "`nPresione Enter para salir"