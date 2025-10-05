# ================================================================
# RCLONE WINDOWS AUTOMATION - VERIFICACION DEL SISTEMA
# ================================================================
# Descripcion: Verifica que el sistema cumpla con los requisitos
# Autor: Comunidad Rclone Windows
# Version: 1.0
# Fecha: Octubre 2024
# ================================================================

param(
    [switch]$Detailed = $false
)

# Inicializar arrays para resultados
$checks = @()
$warnings = @()
$systemErrors = @()

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "RCLONE WINDOWS - VERIFICACION DEL SISTEMA" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray

# Verificar version de Windows
Write-Host "`n[OS] Verificando sistema operativo..." -ForegroundColor Yellow

$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$osVersion = [System.Environment]::OSVersion.Version

if ($osInfo.Caption -like "*Windows 10*" -or $osInfo.Caption -like "*Windows 11*") {
    if ($osVersion.Build -ge 22000) {
        $checks += "✅ Windows 11 detectado (Build: $($osVersion.Build))"
    } elseif ($osVersion.Build -ge 19041) {
        $checks += "✅ Windows 10 versión soportada (Build: $($osVersion.Build))"
    } else {
        $systemErrors += "❌ Windows 10 build no soportado: $($osVersion.Build). Requerido: 19041+"
    }
} else {
    $systemErrors += "❌ Windows version no soportada. Requerido: Windows 10/11"
}

# Verificar arquitectura
Write-Host "[ARCH] Verificando arquitectura..." -ForegroundColor Yellow

$arch = $env:PROCESSOR_ARCHITECTURE
if ($arch -eq "AMD64") {
    $checks += "✅ Arquitectura x64 compatible"
} else {
    $systemErrors += "❌ Arquitectura no soportada: $arch. Requerido: x64"
}

# Verificar permisos de administrador
Write-Host "[ADMIN] Verificando permisos..." -ForegroundColor Yellow

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    $checks += "✅ Ejecutandose con permisos de Administrador"
} else {
    $systemErrors += "❌ Se requieren permisos de Administrador para la instalación"
}

# Verificar version de PowerShell
Write-Host "[PS] Verificando PowerShell..." -ForegroundColor Yellow

$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5 -and $psVersion.Minor -ge 1) {
    $checks += "✅ PowerShell $($psVersion.ToString()) compatible"
} else {
    $systemErrors += "❌ PowerShell version no soportada: $($psVersion.ToString()). Requerido: 5.1+"
}

# Verificar conectividad a Internet
Write-Host "[NET] Verificando conectividad..." -ForegroundColor Yellow

try {
    $response = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -WarningAction SilentlyContinue
    if ($response.TcpTestSucceeded) {
        $checks += "✅ Conectividad a Internet disponible"
    } else {
        $warnings += "⚠️ Problemas de conectividad detectados"
    }
} catch {
    $warnings += "⚠️ No se pudo verificar conectividad a Internet"
}

# Verificar memoria RAM
Write-Host "[RAM] Verificando memoria..." -ForegroundColor Yellow

$memory = Get-CimInstance -ClassName Win32_ComputerSystem
$memoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)

if ($memoryGB -ge 16) {
    $checks += "✅ RAM abundante: $memoryGB GB"
} elseif ($memoryGB -ge 8) {
    $checks += "✅ RAM suficiente: $memoryGB GB"
} else {
    $systemErrors += "❌ RAM insuficiente: $memoryGB GB (mínimo: 8 GB)"
}

# Verificar espacio en disco
Write-Host "[DISK] Verificando espacio en disco..." -ForegroundColor Yellow

try {
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    
    if ($freeSpaceGB -ge 500) {
        $checks += "✅ Espacio abundante: $freeSpaceGB GB libres"
    } elseif ($freeSpaceGB -ge 200) {
        $checks += "✅ Espacio suficiente: $freeSpaceGB GB libres"
    } else {
        $systemErrors += "❌ Espacio insuficiente: $freeSpaceGB GB (mínimo: 200 GB)"
    }
} catch {
    $warnings += "⚠️ No se pudo verificar espacio en disco"
}

# Verificar servicios de Windows requeridos
Write-Host "[SVC] Verificando servicios..." -ForegroundColor Yellow

$requiredServices = @("Winmgmt", "EventLog", "Schedule")
foreach ($serviceName in $requiredServices) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        $checks += "✅ Servicio $serviceName ejecutándose"
    } else {
        $warnings += "⚠️ Servicio $serviceName no disponible"
    }
}

# Verificar si WinFsp ya está instalado
Write-Host "[WINFSP] Verificando WinFsp..." -ForegroundColor Yellow

$winfsp = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*WinFsp*" }
if ($winfsp) {
    $checks += "✅ WinFsp ya instalado: $($winfsp.DisplayVersion)"
} else {
    $warnings += "⚠️ WinFsp no instalado (se instalará automáticamente)"
}

# Verificar si Rclone ya está instalado
Write-Host "[RCLONE] Verificando Rclone..." -ForegroundColor Yellow

$rcloneExists = Test-Path "C:\Program Files\Rclone\rclone.exe"
if ($rcloneExists) {
    try {
        $rcloneVersion = & "C:\Program Files\Rclone\rclone.exe" version --check=false 2>$null | Select-String "rclone v" | ForEach-Object { $_.ToString().Split(' ')[1] }
        $checks += "✅ Rclone ya instalado: $rcloneVersion"
    } catch {
        $warnings += "⚠️ Rclone instalado pero no se pudo verificar versión"
    }
} else {
    $warnings += "⚠️ Rclone no instalado (se instalará automáticamente)"
}

# Verificar puertos en uso
Write-Host "[PUERTOS] Verificando puertos..." -ForegroundColor Yellow

$portsToCheck = @(32400)  # Plex
foreach ($portNumber in $portsToCheck) {
    $portInUse = Get-NetTCPConnection -LocalPort $portNumber -ErrorAction SilentlyContinue
    if ($portInUse) {
        $processId = $portInUse[0].OwningProcess
        $processName = (Get-Process -Id $processId -ErrorAction SilentlyContinue).ProcessName
        if ($processName -eq "Plex Media Server") {
            $checks += "✅ Puerto $portNumber en uso por Plex (correcto)"
        } else {
            $warnings += "⚠️ Puerto $portNumber en uso por: $processName"
        }
    } else {
        Write-Host "  Puerto $portNumber disponible" -ForegroundColor Gray
    }
}

# Mostrar resumen
$separator = "=" * 60
Write-Host "`n$separator" -ForegroundColor Gray
Write-Host "[RESUMEN] RESUMEN DE VERIFICACION" -ForegroundColor Green
Write-Host "$separator" -ForegroundColor Gray

if ($checks.Count -gt 0) {
    Write-Host "`n[OK] VERIFICACIONES EXITOSAS:" -ForegroundColor Green
    foreach ($check in $checks) {
        Write-Host "  $check" -ForegroundColor Green
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n[ADVERTENCIA] ADVERTENCIAS:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  $warning" -ForegroundColor Yellow
    }
}

if ($systemErrors.Count -gt 0) {
    Write-Host "`n[ERROR] ERRORES CRITICOS:" -ForegroundColor Red
    foreach ($errorMsg in $systemErrors) {
        Write-Host "  $errorMsg" -ForegroundColor Red
    }
}

if ($systemErrors.Count -eq 0) {
    Write-Host "`n[EXITO] ✅ SISTEMA LISTO PARA INSTALACION" -ForegroundColor Green
    Write-Host "Puede proceder con install-components.ps1" -ForegroundColor Gray
} else {
    Write-Host "`n[FALLO] ❌ SISTEMA NO PREPARADO" -ForegroundColor Red
    Write-Host "Corrija los errores antes de continuar" -ForegroundColor Gray
}

# Separador final
Write-Host "`n$separator" -ForegroundColor Gray

# Retornar código de salida apropiado
if ($systemErrors.Count -gt 0) {
    exit 1
} else {
    exit 0
}