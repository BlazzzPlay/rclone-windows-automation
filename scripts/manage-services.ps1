# Script de gestión de servicios Rclone
# Utilidades para iniciar, detener y gestionar servicios

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "status", "logs", "install", "uninstall")]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "movies", "series", "downloads")]
    [string]$Service = "all"
)

$services = @{
    "movies" = "rclone-movies"
    "series" = "rclone-series" 
    "downloads" = "rclone-downloads"
}

Write-Host "=== Gestión de Servicios Rclone ===" -ForegroundColor Green
Write-Host "Acción: $Action | Servicio: $Service" -ForegroundColor Gray
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray

function Get-ServiceList {
    param($ServiceFilter)
    
    if ($ServiceFilter -eq "all") {
        return $services.Values
    } else {
        return @($services[$ServiceFilter])
    }
}

function Show-ServiceStatus {
    param($ServiceNames)
    
    Write-Host "`n📊 Estado de servicios:" -ForegroundColor Yellow
    Write-Host ("="*50) -ForegroundColor Gray
    
    foreach ($serviceName in $ServiceNames) {
        if (!$serviceName) { continue }
        
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $color = switch($service.Status) {
                "Running" { "Green" }
                "Stopped" { "Red" }
                "Paused" { "Yellow" }
                default { "Gray" }
            }
            
            $startType = (Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'").StartMode
            Write-Host "  $serviceName" -ForegroundColor White -NoNewline
            Write-Host " - $($service.Status)" -ForegroundColor $color -NoNewline
            Write-Host " ($startType)" -ForegroundColor Gray
            
            # Verificar punto de montaje si está corriendo
            if ($service.Status -eq "Running") {
                $mountPoint = switch($serviceName) {
                    "rclone-movies" { "C:\mnt\movies" }
                    "rclone-series" { "C:\mnt\series" }
                    "rclone-downloads" { "C:\mnt\downloads" }
                }
                
                if ($mountPoint -and (Test-Path $mountPoint)) {
                    try {
                        $itemCount = (Get-ChildItem $mountPoint -ErrorAction Stop | Measure-Object).Count
                        Write-Host "    📁 Montado: $itemCount elementos en $mountPoint" -ForegroundColor Blue
                    } catch {
                        Write-Host "    ⚠️ Montaje no accesible: $mountPoint" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "    ❌ Punto de montaje no encontrado: $mountPoint" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "  $serviceName - No encontrado" -ForegroundColor Red
        }
    }
}

function Start-Services {
    param($ServiceNames)
    
    Write-Host "`n🚀 Iniciando servicios..." -ForegroundColor Green
    
    foreach ($serviceName in $ServiceNames) {
        if (!$serviceName) { continue }
        
        Write-Host "Iniciando $serviceName..." -ForegroundColor Cyan
        
        try {
            Start-Service -Name $serviceName -ErrorAction Stop
            Write-Host "  ✅ $serviceName iniciado" -ForegroundColor Green
            
            # Esperar un momento para que se establezca el montaje
            Start-Sleep -Seconds 10
            
            # Verificar montaje
            $mountPoint = switch($serviceName) {
                "rclone-movies" { "C:\mnt\movies" }
                "rclone-series" { "C:\mnt\series" }
                "rclone-arr" { "C:\mnt\arr" }
            }
            
            if ($mountPoint -and (Test-Path $mountPoint)) {
                Write-Host "  📁 Montaje verificado: $mountPoint" -ForegroundColor Blue
            } else {
                Write-Host "  ⚠️ Montaje no detectado aún (normal si recién inició)" -ForegroundColor Yellow
            }
            
        } catch {
            Write-Host "  ❌ Error iniciando $serviceName : $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Espera entre servicios para evitar conflictos
        if ($ServiceNames.Count -gt 1) {
            Start-Sleep -Seconds 5
        }
    }
}

function Stop-Services {
    param($ServiceNames)
    
    Write-Host "`n🛑 Deteniendo servicios..." -ForegroundColor Red
    
    # Detener en orden inverso
    $reversedServices = $ServiceNames | Sort-Object -Descending
    
    foreach ($serviceName in $reversedServices) {
        if (!$serviceName) { continue }
        
        Write-Host "Deteniendo $serviceName..." -ForegroundColor Yellow
        
        try {
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
            Write-Host "  ✅ $serviceName detenido" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Error deteniendo $serviceName : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Verificar que los puntos de montaje se desmontaron
    Write-Host "`nVerificando desmontaje..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    $mountPoints = @("C:\mnt\movies", "C:\mnt\series", "C:\mnt\arr")
    foreach ($mountPoint in $mountPoints) {
        if (Test-Path $mountPoint) {
            Write-Host "  ⚠️ Punto de montaje aún existe: $mountPoint" -ForegroundColor Yellow
        } else {
            Write-Host "  ✅ Desmontado: $mountPoint" -ForegroundColor Green
        }
    }
}

function Show-ServiceLogs {
    param($ServiceNames)
    
    Write-Host "`n📄 Logs de servicios:" -ForegroundColor Yellow
    
    foreach ($serviceName in $ServiceNames) {
        if (!$serviceName) { continue }
        
        $logFile = "C:\rclone\logs\$serviceName.log"
        
        Write-Host "`n--- Log de $serviceName ---" -ForegroundColor Cyan
        
        if (Test-Path $logFile) {
            $logSize = (Get-Item $logFile).Length / 1MB
            Write-Host "Archivo: $logFile ($('{0:N2}' -f $logSize) MB)" -ForegroundColor Gray
            
            # Mostrar últimas 20 líneas
            Write-Host "Últimas entradas:" -ForegroundColor White
            try {
                $lastLines = Get-Content $logFile -Tail 20 -ErrorAction Stop
                foreach ($line in $lastLines) {
                    if ($line -match "ERROR|FATAL|Failed") {
                        Write-Host "  $line" -ForegroundColor Red
                    } elseif ($line -match "WARN") {
                        Write-Host "  $line" -ForegroundColor Yellow
                    } elseif ($line -match "INFO.*mounted") {
                        Write-Host "  $line" -ForegroundColor Green
                    } else {
                        Write-Host "  $line" -ForegroundColor Gray
                    }
                }
            } catch {
                Write-Host "  Error leyendo log: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  Log no encontrado: $logFile" -ForegroundColor Red
        }
    }
    
    Write-Host "`nComandos para ver logs en tiempo real:" -ForegroundColor Yellow
    foreach ($serviceName in $ServiceNames) {
        if (!$serviceName) { continue }
        Write-Host "  $serviceName : Get-Content C:\rclone\logs\$serviceName.log -Wait" -ForegroundColor Cyan
    }
}

# Procesar acción solicitada
$serviceList = Get-ServiceList -ServiceFilter $Service

switch ($Action) {
    "status" {
        Show-ServiceStatus -ServiceNames $serviceList
    }
    
    "start" {
        Start-Services -ServiceNames $serviceList
        Start-Sleep -Seconds 5
        Show-ServiceStatus -ServiceNames $serviceList
    }
    
    "stop" {
        Stop-Services -ServiceNames $serviceList
        Start-Sleep -Seconds 3
        Show-ServiceStatus -ServiceNames $serviceList
    }
    
    "restart" {
        Write-Host "`n🔄 Reiniciando servicios..." -ForegroundColor Blue
        Stop-Services -ServiceNames $serviceList
        Start-Sleep -Seconds 10
        Start-Services -ServiceNames $serviceList
        Start-Sleep -Seconds 5
        Show-ServiceStatus -ServiceNames $serviceList
    }
    
    "logs" {
        Show-ServiceLogs -ServiceNames $serviceList
    }
    
    "install" {
        Write-Host "`nPara instalar servicios, ejecute: setup-services.ps1" -ForegroundColor Yellow
    }
    
    "uninstall" {
        Write-Host "`n⚠️ Desinstalando servicios..." -ForegroundColor Red
        
        $confirm = Read-Host "¿Está seguro? Esto eliminará todos los servicios configurados (S/N)"
        if ($confirm -match '^[Ss]$') {
            foreach ($serviceName in $serviceList) {
                if (!$serviceName) { continue }
                
                # Detener servicio
                $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                if ($service -and $service.Status -eq "Running") {
                    Stop-Service -Name $serviceName -Force
                }
                
                # Eliminar con NSSM
                $nssmPath = "C:\rclone\bin\nssm.exe"
                if (Test-Path $nssmPath) {
                    & $nssmPath remove $serviceName confirm
                    Write-Host "  ✅ $serviceName eliminado" -ForegroundColor Green
                } else {
                    Write-Host "  ❌ NSSM no encontrado para eliminar $serviceName" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Operación cancelada" -ForegroundColor Yellow
        }
    }
}

# Mostrar comandos útiles
if ($Action -ne "logs") {
    Write-Host "`n💡 Comandos útiles:" -ForegroundColor Yellow
    Write-Host "  Ver estado: .\manage-services.ps1 -Action status" -ForegroundColor Cyan
    Write-Host "  Iniciar todo: .\manage-services.ps1 -Action start" -ForegroundColor Cyan
    Write-Host "  Detener todo: .\manage-services.ps1 -Action stop" -ForegroundColor Cyan
    Write-Host "  Ver logs: .\manage-services.ps1 -Action logs -Service movies" -ForegroundColor Cyan
    Write-Host "  Reiniciar ARR: .\manage-services.ps1 -Action restart -Service arr" -ForegroundColor Cyan
}

if ([Environment]::UserInteractive) {
    Read-Host "`nPresione Enter para salir"
}