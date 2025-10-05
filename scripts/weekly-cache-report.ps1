# Script de reporte semanal de caché Rclone
# Para ejecutar automáticamente vía Programador de tareas

param(
    [string]$CachePath = "C:\rclone\cache",
    [string]$LogPath = "C:\rclone\logs",
    [string]$ConfigPath = "C:\rclone\rclone.conf",
    [string]$RclonePath = "C:\rclone\rclone.exe",
    [int]$MaxCacheSizeGB = 100,
    [int]$RetentionDays = 30
)

$reportFile = "$LogPath\cache-report-$(Get-Date -Format 'yyyy-MM-dd').txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "=== Reporte Semanal de Caché Rclone ===" -ForegroundColor Green
Write-Host "Fecha: $timestamp" -ForegroundColor Gray
Write-Host "Archivo de reporte: $reportFile" -ForegroundColor Gray

# Función para convertir bytes a unidades legibles
function Format-FileSize {
    param([long]$Size)
    
    if ($Size -ge 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
    elseif ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    elseif ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    elseif ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    else { return "$Size bytes" }
}

# Función para obtener información del caché
function Get-CacheInfo {
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        return @{
            "Exists" = $false
            "TotalSize" = 0
            "FileCount" = 0
            "FolderCount" = 0
            "OldestFile" = $null
            "NewestFile" = $null
        }
    }
    
    try {
        $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
        $folders = Get-ChildItem -Path $Path -Recurse -Directory -ErrorAction SilentlyContinue
        
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
        $fileCount = $files.Count
        $folderCount = $folders.Count
        
        $oldestFile = $files | Sort-Object LastWriteTime | Select-Object -First 1
        $newestFile = $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        return @{
            "Exists" = $true
            "TotalSize" = $totalSize
            "FileCount" = $fileCount  
            "FolderCount" = $folderCount
            "OldestFile" = $oldestFile
            "NewestFile" = $newestFile
            "Files" = $files
        }
    } catch {
        Write-Warning "Error analizando caché en $Path : $($_.Exception.Message)"
        return @{
            "Exists" = $false
            "TotalSize" = 0
            "FileCount" = 0
            "FolderCount" = 0
            "OldestFile" = $null
            "NewestFile" = $null
        }
    }
}

# Función para generar reporte
function New-CacheReport {
    $report = @()
    
    $report += "="*60
    $report += "REPORTE SEMANAL DE CACHE RCLONE"
    $report += "="*60
    $report += "Fecha de generacion: $timestamp"
    $report += "Servidor: $env:COMPUTERNAME"
    $report += "Usuario: $env:USERNAME"
    $report += ""
    
    # Informacion del sistema
    $report += "INFORMACION DEL SISTEMA"
    $report += "-"*30
    
    $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
    $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
    $usagePercent = [math]::Round(($usedSpaceGB / $totalSpaceGB) * 100, 1)
    
    $report += "Espacio total en disco C: $(Format-FileSize $disk.Size)"
    $report += "Espacio libre en disco C: $(Format-FileSize $disk.FreeSpace) ($freeSpaceGB GB)"
    $report += "Uso del disco: $usagePercent%"
    $report += ""
    
    # Análisis del caché principal
    $report += "ANALISIS DEL CACHE PRINCIPAL"
    $report += "-"*35
    
    $cacheInfo = Get-CacheInfo -Path $CachePath
    
    if ($cacheInfo.Exists) {
        $cacheSizeGB = [math]::Round($cacheInfo.TotalSize / 1GB, 2)
        $cacheUsagePercent = [math]::Round(($cacheSizeGB / $MaxCacheSizeGB) * 100, 1)
        
        $report += "Ubicacion: $CachePath"
        $report += "Tamano total: $(Format-FileSize $cacheInfo.TotalSize) ($cacheSizeGB GB)"
        $report += "Uso del limite: $cacheUsagePercent% de $MaxCacheSizeGB GB"
        $report += "Archivos en cache: $($cacheInfo.FileCount)"
        $report += "Carpetas: $($cacheInfo.FolderCount)"
        
        if ($cacheInfo.OldestFile) {
            $report += "Archivo mas antiguo: $($cacheInfo.OldestFile.Name) ($(Get-Date $cacheInfo.OldestFile.LastWriteTime -Format 'yyyy-MM-dd HH:mm'))"
        }
        
        if ($cacheInfo.NewestFile) {
            $report += "Archivo mas reciente: $($cacheInfo.NewestFile.Name) ($(Get-Date $cacheInfo.NewestFile.LastWriteTime -Format 'yyyy-MM-dd HH:mm'))"
        }
        
        # Alertas
        if ($cacheUsagePercent -gt 90) {
            $report += ""
            $report += "ALERTA: Cache casi lleno ($cacheUsagePercent%)"
        } elseif ($cacheUsagePercent -gt 75) {
            $report += ""
            $report += "ADVERTENCIA: Cache alto ($cacheUsagePercent%)"
        }
    } else {
        $report += "ERROR: Directorio de cache no encontrado: $CachePath"
    }
    
    $report += ""
    
    # Análisis por subcarpetas (vfs, vfsMeta)
    $report += "ANÁLISIS POR SUBCARPETAS"
    $report += "-"*28
    
    $subfolders = @("vfs", "vfsMeta")
    foreach ($subfolder in $subfolders) {
        $subPath = Join-Path $CachePath $subfolder
        $subInfo = Get-CacheInfo -Path $subPath
        
        if ($subInfo.Exists) {
            $report += "$subfolder/: $(Format-FileSize $subInfo.TotalSize) ($($subInfo.FileCount) archivos)"
        } else {
            $report += "$subfolder/: No existe o vacío"
        }
    }
    
    $report += ""
    
    # Estado de servicios
    $report += "ESTADO DE SERVICIOS"
    $report += "-"*22
    
    $services = @("rclone-movies", "rclone-series", "rclone-arr")
    foreach ($serviceName in $services) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $status = $service.Status
            $startType = (Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'").StartMode
            $report += "$serviceName : $status ($startType)"
        } else {
            $report += "$serviceName : No encontrado"
        }
    }
    
    $report += ""
    
    # Análisis de logs recientes
    $report += "ANÁLISIS DE LOGS (ÚLTIMOS 7 DÍAS)"
    $report += "-"*38
    
    $logFiles = Get-ChildItem -Path $LogPath -Filter "*.log" -ErrorAction SilentlyContinue
    $cutoffDate = (Get-Date).AddDays(-7)
    
    foreach ($logFile in $logFiles) {
        if ($logFile.LastWriteTime -gt $cutoffDate) {
            $logSize = Format-FileSize $logFile.Length
            $report += "$($logFile.Name): $logSize (actualizado: $(Get-Date $logFile.LastWriteTime -Format 'yyyy-MM-dd HH:mm'))"
            
            # Buscar errores recientes en el log
            try {
                $recentErrors = Get-Content $logFile.FullName | Where-Object { 
                    $_ -match "ERROR|FATAL|Failed|Error" 
                } | Select-Object -Last 3
                
                if ($recentErrors) {
                    $report += "  ⚠️ Errores recientes encontrados:"
                    foreach ($errLine in $recentErrors) {
                        $report += "    $errLine"
                    }
                }
            } catch {
                $report += "  ❌ No se pudo analizar el archivo de log"
            }
        }
    }
    
    $report += ""
    
    # Limpieza automática
    $report += "LIMPIEZA AUTOMÁTICA"
    $report += "-"*20
    
    $cleanupActions = @()
    
    # Limpiar logs antiguos
    $oldLogs = Get-ChildItem -Path $LogPath -Filter "*.log.*" -ErrorAction SilentlyContinue | 
               Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }
    
    if ($oldLogs) {
        $totalCleaned = ($oldLogs | Measure-Object -Property Length -Sum).Sum
        $cleanupActions += "Logs antiguos eliminados: $($oldLogs.Count) archivos ($(Format-FileSize $totalCleaned))"
        
        foreach ($log in $oldLogs) {
            try {
                Remove-Item $log.FullName -Force
            } catch {
                $cleanupActions += "Error eliminando $($log.Name): $($_.Exception.Message)"
            }
        }
    } else {
        $cleanupActions += "No hay logs antiguos para eliminar"
    }
    
    # Limpiar reportes antiguos
    $oldReports = Get-ChildItem -Path $LogPath -Filter "cache-report-*.txt" -ErrorAction SilentlyContinue | 
                  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }
    
    if ($oldReports) {
        $cleanupActions += "Reportes antiguos eliminados: $($oldReports.Count) archivos"
        $oldReports | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    foreach ($action in $cleanupActions) {
        $report += $action
    }
    
    $report += ""
    
    # Recomendaciones
    $report += "RECOMENDACIONES"
    $report += "-"*16
    
    if ($cacheInfo.Exists) {
        $cacheSizeGB = [math]::Round($cacheInfo.TotalSize / 1GB, 2)
        $cacheUsagePercent = [math]::Round(($cacheSizeGB / $MaxCacheSizeGB) * 100, 1)
        
        if ($cacheUsagePercent -gt 90) {
            $report += "🔴 URGENTE: Aumentar límite de caché o limpiar manualmente"
            $report += "   Comando: rclone cleanup ucmovie: --config=$ConfigPath"
        } elseif ($cacheUsagePercent -gt 75) {
            $report += "🟡 MONITOR: Vigilar crecimiento del caché"
        } else {
            $report += "🟢 OK: Uso de caché dentro de límites normales"
        }
    }
    
    if ($freeSpaceGB -lt 50) {
        $report += "🔴 URGENTE: Poco espacio libre en disco ($freeSpaceGB GB)"
    } elseif ($freeSpaceGB -lt 100) {
        $report += "🟡 ADVERTENCIA: Espacio en disco bajo ($freeSpaceGB GB)"
    }
    
    $stoppedServices = $services | ForEach-Object { 
        $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne "Running") { $_ }
    }
    
    if ($stoppedServices) {
        $report += "🔧 ACCIÓN: Revisar servicios detenidos: $($stoppedServices -join ', ')"
    }
    
    $report += ""
    $report += "Próximo reporte: $(Get-Date (Get-Date).AddDays(7) -Format 'yyyy-MM-dd')"
    $report += "="*60
    
    return $report
}

# Generar y guardar reporte
Write-Host "Generando reporte..." -ForegroundColor Yellow

$reportContent = New-CacheReport
$reportContent | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "✅ Reporte generado: $reportFile" -ForegroundColor Green

# Mostrar resumen en consola
Write-Host "`n📊 RESUMEN EJECUTIVO:" -ForegroundColor Cyan

$cacheInfo = Get-CacheInfo -Path $CachePath
if ($cacheInfo.Exists) {
    $cacheSizeGB = [math]::Round($cacheInfo.TotalSize / 1GB, 2)
    $cacheUsagePercent = [math]::Round(($cacheSizeGB / $MaxCacheSizeGB) * 100, 1)
    
    Write-Host "Caché: $(Format-FileSize $cacheInfo.TotalSize) ($cacheUsagePercent% del límite)" -ForegroundColor White
    Write-Host "Archivos: $($cacheInfo.FileCount)" -ForegroundColor White
}

$disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
Write-Host "Espacio libre: $freeSpaceGB GB" -ForegroundColor White

# Verificar servicios
$runningServices = 0
$totalServices = 0
@("rclone-movies", "rclone-series", "rclone-arr") | ForEach-Object {
    $service = Get-Service -Name $_ -ErrorAction SilentlyContinue
    if ($service) {
        $totalServices++
        if ($service.Status -eq "Running") {
            $runningServices++
        }
    }
}
Write-Host "Servicios: $runningServices/$totalServices activos" -ForegroundColor White

# Abrir reporte si se ejecuta interactivamente
if ([Environment]::UserInteractive) {
    $openReport = Read-Host "`n¿Abrir reporte completo? (S/N)"
    if ($openReport -match '^[Ss]$') {
        Start-Process notepad.exe $reportFile
    }
}

Write-Host "`n✅ Reporte semanal completado" -ForegroundColor Green