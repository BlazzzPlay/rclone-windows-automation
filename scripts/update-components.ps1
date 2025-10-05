# Script de actualización automática de componentes
# Mantiene Rclone, NSSM y WinFsp actualizados

param(
    [switch]$CheckOnly = $false,
    [switch]$Force = $false,
    [string]$InstallPath = "C:\rclone"
)

Write-Host "=== Actualización de Componentes Rclone ===" -ForegroundColor Green
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray

# Verificar permisos de administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

function Get-LatestGitHubRelease {
    param($Repository)
    
    try {
        $uri = "https://api.github.com/repos/$Repository/releases/latest"
        $response = Invoke-RestMethod -Uri $uri -Method Get
        return $response.tag_name -replace '^v', ''
    } catch {
        Write-Warning "No se pudo obtener la última versión de $Repository"
        return $null
    }
}

function Get-CurrentVersion {
    param($Component)
    
    switch ($Component) {
        "rclone" {
            if (Test-Path "$InstallPath\rclone.exe") {
                $output = & "$InstallPath\rclone.exe" version 2>$null
                if ($output -match "rclone v(\d+\.\d+\.\d+)") {
                    return $matches[1]
                }
            }
            return $null
        }
        
        "nssm" {
            if (Test-Path "$InstallPath\bin\nssm.exe") {
                # NSSM no tiene comando de versión confiable
                return "2.24.101"  # Asumir versión mínima si existe
            }
            return $null
        }
        
        "winfsp" {
            $winfsp = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
                     Where-Object { $_.DisplayName -like "*WinFsp*" }
            if ($winfsp) {
                return $winfsp.DisplayVersion
            }
            return $null
        }
    }
}

function Update-Component {
    param($Component, $CurrentVersion, $LatestVersion)
    
    Write-Host "`nActualizando $Component de $CurrentVersion a $LatestVersion..." -ForegroundColor Cyan
    
    switch ($Component) {
        "rclone" {
            # Detener servicios que usan Rclone
            Write-Host "Deteniendo servicios..." -ForegroundColor Yellow
            $services = @("rclone-movies", "rclone-series", "rclone-arr")
            foreach ($service in $services) {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq "Running") {
                    Stop-Service -Name $service -Force
                    Write-Host "  Detenido: $service" -ForegroundColor Gray
                }
            }
            
            # Descargar nueva versión
            $downloadUrl = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"
            $downloadPath = "$env:TEMP\rclone-update.zip"
            
            Write-Host "Descargando Rclone $LatestVersion..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
            
            # Respaldar versión actual
            $backupPath = "$InstallPath\rclone.exe.backup"
            if (Test-Path "$InstallPath\rclone.exe") {
                Copy-Item "$InstallPath\rclone.exe" $backupPath -Force
            }
            
            # Extraer nueva versión
            $extractPath = "$env:TEMP\rclone-update"
            if (Test-Path $extractPath) {
                Remove-Item $extractPath -Recurse -Force
            }
            Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
            
            # Encontrar y copiar ejecutable
            $newRclone = Get-ChildItem -Path $extractPath -Name "rclone.exe" -Recurse | Select-Object -First 1
            if ($newRclone) {
                $sourcePath = Get-ChildItem -Path $extractPath -Name "rclone.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
                Copy-Item $sourcePath "$InstallPath\rclone.exe" -Force
                Write-Host "  ✅ Rclone actualizado" -ForegroundColor Green
            } else {
                Write-Host "  ❌ Error: No se encontró rclone.exe en el archivo descargado" -ForegroundColor Red
                if (Test-Path $backupPath) {
                    Copy-Item $backupPath "$InstallPath\rclone.exe" -Force
                    Write-Host "  🔄 Restaurada versión anterior" -ForegroundColor Yellow
                }
                return $false
            }
            
            # Reiniciar servicios
            Write-Host "Reiniciando servicios..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            foreach ($service in $services) {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc) {
                    try {
                        Start-Service -Name $service
                        Write-Host "  Iniciado: $service" -ForegroundColor Gray
                    } catch {
                        Write-Host "  ⚠️ Error iniciando $service : $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
                Start-Sleep -Seconds 10  # Espera entre servicios
            }
            
            # Limpiar archivos temporales
            Remove-Item $downloadPath -Force -ErrorAction SilentlyContinue
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
            
            return $true
        }
        
        "winfsp" {
            Write-Host "⚠️ WinFsp requiere actualización manual" -ForegroundColor Yellow
            Write-Host "  Descargar desde: https://winfsp.dev/rel/" -ForegroundColor Blue
            Write-Host "  Versión actual: $CurrentVersion" -ForegroundColor Gray
            Write-Host "  Versión disponible: $LatestVersion" -ForegroundColor Gray
            return $false
        }
        
        "nssm" {
            Write-Host "ℹ️ NSSM se actualiza raramente y la versión actual es funcional" -ForegroundColor Blue
            return $false
        }
    }
}

# Verificar versiones actuales
Write-Host "`n📋 Verificando versiones instaladas..." -ForegroundColor Yellow

$components = @{
    "rclone" = @{
        "current" = Get-CurrentVersion "rclone"
        "latest" = $null
    }
    "winfsp" = @{
        "current" = Get-CurrentVersion "winfsp"
        "latest" = Get-LatestGitHubRelease "winfsp/winfsp"
    }
    "nssm" = @{
        "current" = Get-CurrentVersion "nssm"
        "latest" = "2.24.101"  # Versión estable conocida
    }
}

# Obtener última versión de Rclone
Write-Host "Consultando última versión de Rclone..." -ForegroundColor Gray
try {
    $rcloneResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/rclone/rclone/releases/latest"
    $components["rclone"]["latest"] = $rcloneResponse.tag_name -replace '^v', ''
} catch {
    Write-Warning "No se pudo obtener la última versión de Rclone"
}

# Mostrar estado actual
Write-Host "`n📊 Estado de componentes:" -ForegroundColor Yellow
Write-Host ("="*60) -ForegroundColor Gray

foreach ($component in $components.Keys) {
    $current = $components[$component]["current"]
    $latest = $components[$component]["latest"]
    
    Write-Host "$component".PadRight(10) -NoNewline -ForegroundColor White
    
    if ($current) {
        Write-Host "Actual: $current".PadRight(20) -NoNewline -ForegroundColor Green
    } else {
        Write-Host "Actual: No instalado".PadRight(20) -NoNewline -ForegroundColor Red
    }
    
    if ($latest) {
        Write-Host "Disponible: $latest" -ForegroundColor Blue
        
        # Verificar si hay actualización disponible
        if ($current -and $latest -and $current -ne $latest) {
            Write-Host "           ⬆️ Actualización disponible" -ForegroundColor Yellow
        } elseif ($current -and $latest -and $current -eq $latest) {
            Write-Host "           ✅ Actualizado" -ForegroundColor Green
        }
    } else {
        Write-Host "Disponible: Desconocido" -ForegroundColor Gray
    }
}

# Si solo verificar, terminar aquí
if ($CheckOnly) {
    Write-Host "`n✅ Verificación completada" -ForegroundColor Green
    Read-Host "Presione Enter para salir"
    exit 0
}

# Procesar actualizaciones
$updatesAvailable = $false
$updatedComponents = @()

foreach ($component in $components.Keys) {
    $current = $components[$component]["current"]
    $latest = $components[$component]["latest"]
    
    if ($current -and $latest -and $current -ne $latest) {
        $updatesAvailable = $true
        
        if ($Force) {
            $doUpdate = $true
        } else {
            $response = Read-Host "`n¿Actualizar $component de $current a $latest? (S/N)"
            $doUpdate = $response -match '^[Ss]$'
        }
        
        if ($doUpdate) {
            $success = Update-Component -Component $component -CurrentVersion $current -LatestVersion $latest
            if ($success) {
                $updatedComponents += $component
            }
        }
    }
}

# Resumen final
Write-Host "`n=== RESUMEN DE ACTUALIZACIÓN ===" -ForegroundColor Green

if ($updatedComponents.Count -gt 0) {
    Write-Host "✅ Componentes actualizados:" -ForegroundColor Green
    foreach ($component in $updatedComponents) {
        Write-Host "  - $component" -ForegroundColor White
    }
    
    Write-Host "`n📋 Próximos pasos recomendados:" -ForegroundColor Yellow
    Write-Host "1. Verificar funcionamiento: .\test-mounts.ps1" -ForegroundColor White
    Write-Host "2. Revisar logs de servicios" -ForegroundColor White
    Write-Host "3. Probar reproducción en Plex" -ForegroundColor White
    
} elseif ($updatesAvailable) {
    Write-Host "ℹ️ Actualizaciones disponibles pero no aplicadas" -ForegroundColor Blue
} else {
    Write-Host "✅ Todos los componentes están actualizados" -ForegroundColor Green
}

# Verificar estado de servicios post-actualización
if ($updatedComponents -contains "rclone") {
    Write-Host "`n🔍 Verificando servicios después de actualización..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15  # Dar tiempo a que los servicios se estabilicen
    
    $services = @("rclone-movies", "rclone-series", "rclone-arr")
    foreach ($serviceName in $services) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $status = $service.Status
            $color = if ($status -eq "Running") { "Green" } else { "Red" }
            Write-Host "  $serviceName : $status" -ForegroundColor $color
        }
    }
}

Read-Host "`nPresione Enter para salir"