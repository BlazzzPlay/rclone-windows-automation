# Script para configurar servicios NSSM para Rclone
# Ejecutar como Administrador después de instalar componentes

param(
    [string]$RclonePath = "C:\rclone\rclone.exe",
    [string]$ConfigPath = "C:\rclone\rclone.conf",
    [string]$NssmPath = "C:\rclone\bin\nssm.exe",
    [string]$LogPath = "C:\rclone\logs"
)

Write-Host "=== Configuración de Servicios NSSM para Rclone ===" -ForegroundColor Green
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray

# Verificar permisos de administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

# Verificar archivos necesarios
$requiredFiles = @{
    "Rclone" = $RclonePath
    "NSSM" = $NssmPath
    "Config" = $ConfigPath
}

foreach ($component in $requiredFiles.Keys) {
    if (!(Test-Path $requiredFiles[$component])) {
        Write-Error "$component no encontrado en: $($requiredFiles[$component])"
        Write-Host "Ejecute primero install-components.ps1" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ $component encontrado: $($requiredFiles[$component])" -ForegroundColor Green
}

# Configuración de servicios
$services = @{
    "rclone-movies" = @{
        "Description" = "Rclone Mount - Películas (movies)"
        "Remote" = "movies:"
        "MountPoint" = "C:\mnt\movies"
        "Parameters" = "--vfs-cache-mode full --vfs-cache-max-size 100G --vfs-cache-max-age 720h --vfs-read-ahead 512M --buffer-size 256M --vfs-read-chunk-size 128M --vfs-read-chunk-size-limit 2G --bwlimit 6M --poll-interval 15m --allow-other --dir-cache-time 1h --vfs-cache-poll-interval 1m"
    }
    "rclone-series" = @{
        "Description" = "Rclone Mount - Series (series)"
        "Remote" = "series:"
        "MountPoint" = "C:\mnt\series"
        "Parameters" = "--vfs-cache-mode full --vfs-cache-max-size 100G --vfs-cache-max-age 720h --vfs-read-ahead 512M --buffer-size 256M --vfs-read-chunk-size 128M --vfs-read-chunk-size-limit 2G --bwlimit 6M --poll-interval 15m --allow-other --dir-cache-time 1h --vfs-cache-poll-interval 1m"
    }
    "rclone-downloads" = @{
        "Description" = "Rclone Mount - Downloads/ARR (downloads)"
        "Remote" = "downloads:"
        "MountPoint" = "C:\mnt\downloads"
        "Parameters" = "--vfs-cache-mode writes --vfs-write-back 5s --transfers 8 --checkers 16 --poll-interval 5m --allow-other --dir-cache-time 10m --fast-list"
    }
}

function Remove-ExistingService {
    param($ServiceName)
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "Deteniendo servicio existente: $ServiceName" -ForegroundColor Yellow
        if ($service.Status -eq 'Running') {
            Stop-Service -Name $ServiceName -Force
        }
        
        Write-Host "Eliminando servicio existente: $ServiceName" -ForegroundColor Yellow
        & $NssmPath remove $ServiceName confirm
        
        Start-Sleep -Seconds 2
    }
}

function New-RcloneService {
    param($ServiceName, $Config)
    
    Write-Host "`nConfigurando servicio: $ServiceName" -ForegroundColor Cyan
    Write-Host "  Descripción: $($Config.Description)" -ForegroundColor Gray
    
    # Eliminar servicio existente si existe
    Remove-ExistingService -ServiceName $ServiceName
    
    # Construir comando completo
    $fullCommand = "mount $($Config.Remote) $($Config.MountPoint) --config=`"$ConfigPath`" --cache-dir=`"C:\rclone\cache`" --log-file=`"$LogPath\$ServiceName.log`" --log-level INFO $($Config.Parameters)"
    
    Write-Host "  Comando: $fullCommand" -ForegroundColor Gray
    
    # Crear servicio con NSSM
    & $NssmPath install $ServiceName $RclonePath
    & $NssmPath set $ServiceName AppParameters $fullCommand
    & $NssmPath set $ServiceName Description $Config.Description
    & $NssmPath set $ServiceName Start SERVICE_AUTO_START
    & $NssmPath set $ServiceName AppStdout "$LogPath\$ServiceName.log"
    & $NssmPath set $ServiceName AppStderr "$LogPath\$ServiceName.log" 
    & $NssmPath set $ServiceName AppStdoutCreationDisposition 4
    & $NssmPath set $ServiceName AppStderrCreationDisposition 4
    & $NssmPath set $ServiceName AppRotateFiles 1
    & $NssmPath set $ServiceName AppRotateOnline 1
    & $NssmPath set $ServiceName AppRotateSeconds 86400
    & $NssmPath set $ServiceName AppRotateBytes 10485760
    
    # Configurar reinicio automático
    & $NssmPath set $ServiceName AppExit Default Restart
    & $NssmPath set $ServiceName AppRestartDelay 5000
    
    Write-Host "  ✅ Servicio $ServiceName creado correctamente" -ForegroundColor Green
}

# Verificar que las carpetas de montaje NO existen
Write-Host "`nVerificando puntos de montaje..." -ForegroundColor Yellow
foreach ($serviceName in $services.Keys) {
    $mountPoint = $services[$serviceName].MountPoint
    if (Test-Path $mountPoint) {
        Write-Warning "¡ADVERTENCIA! Punto de montaje ya existe: $mountPoint"
        Write-Host "Rclone debe crear estas carpetas automáticamente." -ForegroundColor Red
        Write-Host "¿Eliminar carpeta existente? (S/N): " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
        if ($response -match '^[Ss]$') {
            Remove-Item $mountPoint -Recurse -Force
            Write-Host "  ✅ Carpeta eliminada: $mountPoint" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Mantenga la carpeta (puede causar errores)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✅ Punto de montaje listo: $mountPoint" -ForegroundColor Green
    }
}

# Crear servicios
Write-Host "`nCreando servicios NSSM..." -ForegroundColor Yellow
foreach ($serviceName in $services.Keys) {
    New-RcloneService -ServiceName $serviceName -Config $services[$serviceName]
}

# Configurar dependencias entre servicios
Write-Host "`nConfigurando dependencias de servicios..." -ForegroundColor Yellow
$dependencyOrder = @("rclone-movies", "rclone-series", "rclone-arr")

for ($i = 1; $i -lt $dependencyOrder.Count; $i++) {
    $currentService = $dependencyOrder[$i]
    $previousService = $dependencyOrder[$i-1]
    
    # El servicio actual depende del anterior (inicio secuencial)
    & $NssmPath set $currentService DependOnService $previousService
    Write-Host "  ✅ $currentService depende de $previousService" -ForegroundColor Green
}

Write-Host "`n=== SERVICIOS CONFIGURADOS ===" -ForegroundColor Green

# Mostrar resumen
Write-Host "`nServicios creados:" -ForegroundColor Yellow
foreach ($serviceName in $services.Keys) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "  ✅ $serviceName - Estado: $($service.Status)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $serviceName - No encontrado" -ForegroundColor Red
    }
}

Write-Host "`nComandos útiles:" -ForegroundColor Yellow
Write-Host "  Iniciar todos: " -NoNewline -ForegroundColor White
Write-Host "Start-Service rclone-movies" -ForegroundColor Cyan
Write-Host "  Ver estado: " -NoNewline -ForegroundColor White  
Write-Host "Get-Service rclone-*" -ForegroundColor Cyan
Write-Host "  Ver logs: " -NoNewline -ForegroundColor White
Write-Host "Get-Content $LogPath\rclone-movies.log -Wait" -ForegroundColor Cyan

Write-Host "`nPróximos pasos:" -ForegroundColor Yellow
Write-Host "1. Verificar configuración con test-mounts.ps1" -ForegroundColor White
Write-Host "2. Iniciar servicios manualmente para pruebas" -ForegroundColor White
Write-Host "3. Configurar Plex para usar los puntos de montaje" -ForegroundColor White

$startNow = Read-Host "`n¿Iniciar servicios ahora? (S/N)"
if ($startNow -match '^[Ss]$') {
    Write-Host "`nIniciando servicios secuencialmente..." -ForegroundColor Yellow
    foreach ($serviceName in $dependencyOrder) {
        Write-Host "Iniciando $serviceName..." -ForegroundColor Cyan
        Start-Service -Name $serviceName
        Start-Sleep -Seconds 15 # Espera entre inicios
        
        $service = Get-Service -Name $serviceName
        Write-Host "  Estado: $($service.Status)" -ForegroundColor $(if($service.Status -eq 'Running'){'Green'}else{'Red'})
    }
    
    Write-Host "`nVerificando montajes..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    foreach ($serviceName in $services.Keys) {
        $mountPoint = $services[$serviceName].MountPoint
        if (Test-Path $mountPoint) {
            $items = Get-ChildItem $mountPoint -ErrorAction SilentlyContinue | Measure-Object
            Write-Host "  ✅ $mountPoint montado ($($items.Count) elementos)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $mountPoint no montado" -ForegroundColor Red
        }
    }
}

Read-Host "`nPresione Enter para salir"