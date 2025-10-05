# Script de pruebas para montajes Rclone
# Ejecutar después de configurar servicios

param(
    [string]$ConfigPath = "C:\rclone\rclone.conf",
    [string]$RclonePath = "C:\rclone\rclone.exe"
)

Write-Host "=== Pruebas de Montajes Rclone ===" -ForegroundColor Green
Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray

# Verificar archivos necesarios
if (!(Test-Path $RclonePath)) {
    Write-Error "Rclone no encontrado en: $RclonePath"
    exit 1
}

if (!(Test-Path $ConfigPath)) {
    Write-Error "Archivo de configuración no encontrado en: $ConfigPath"
    exit 1
}

# Función para probar conectividad de remotos
function Test-Remote {
    param($RemoteName)
    
    Write-Host "`nProbando remoto: $RemoteName" -ForegroundColor Cyan
    
    try {
        # Probar listado básico
        $result = & $RclonePath lsd "$RemoteName" --config="$ConfigPath" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Conectividad exitosa" -ForegroundColor Green
            Write-Host "  📁 Directorios encontrados: $($result.Count)" -ForegroundColor Blue
            
            # Mostrar primeros directorios
            if ($result.Count -gt 0) {
                Write-Host "  Primeras carpetas:" -ForegroundColor Gray
                $result | Select-Object -First 3 | ForEach-Object {
                    Write-Host "    - $_" -ForegroundColor Gray
                }
            }
            
            return $true
        } else {
            Write-Host "  ❌ Error de conexión" -ForegroundColor Red
            Write-Host "  Error: $result" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  ❌ Excepción: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Función para probar montaje temporal
function Test-Mount {
    param($RemoteName, $TestMountPoint)
    
    Write-Host "`nPrueba de montaje temporal: $RemoteName" -ForegroundColor Cyan
    
    # Crear punto de montaje temporal
    if (!(Test-Path $TestMountPoint)) {
        New-Item -ItemType Directory -Path $TestMountPoint -Force | Out-Null
    }
    
    # Comando de montaje con timeout
    $mountCmd = "mount `"$RemoteName`" `"$TestMountPoint`" --config=`"$ConfigPath`" --vfs-cache-mode minimal --read-only"
    
    Write-Host "  Comando: rclone $mountCmd" -ForegroundColor Gray
    
    # Iniciar proceso de montaje en background
    $process = Start-Process -FilePath $RclonePath -ArgumentList $mountCmd.Split(' ') -PassThru
    
    # Esperar un momento para que se establezca el montaje
    Start-Sleep -Seconds 10
    
    # Verificar si el montaje fue exitoso
    if (Test-Path $TestMountPoint) {
        try {
            $items = Get-ChildItem $TestMountPoint -ErrorAction Stop
            Write-Host "  ✅ Montaje exitoso - $($items.Count) elementos" -ForegroundColor Green
            
            # Mostrar algunos elementos
            if ($items.Count -gt 0) {
                Write-Host "  Contenido:" -ForegroundColor Gray
                $items | Select-Object -First 3 | ForEach-Object {
                    Write-Host "    - $($_.Name)" -ForegroundColor Gray
                }
            }
            
            $success = $true
        } catch {
            Write-Host "  ❌ Error accediendo al montaje: $($_.Exception.Message)" -ForegroundColor Red
            $success = $false
        }
    } else {
        Write-Host "  ❌ Punto de montaje no accesible" -ForegroundColor Red
        $success = $false
    }
    
    # Limpiar proceso y montaje
    if (!$process.HasExited) {
        Write-Host "  Terminando proceso de montaje..." -ForegroundColor Yellow
        $process.Kill()
    }
    
    # Limpiar directorio de prueba
    Start-Sleep -Seconds 2
    if (Test-Path $TestMountPoint) {
        Remove-Item $TestMountPoint -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    return $success
}

# Verificar configuración básica
Write-Host "`n1. Verificando configuración básica..." -ForegroundColor Yellow

# Listar remotos configurados
Write-Host "Remotos configurados:" -ForegroundColor Cyan
try {
    $remotes = & $RclonePath listremotes --config="$ConfigPath"
    if ($remotes) {
        foreach ($remote in $remotes) {
            Write-Host "  📡 $remote" -ForegroundColor Blue
        }
    } else {
        Write-Host "  ❌ No se encontraron remotos configurados" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ❌ Error listando remotos: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verificar version de Rclone
$version = & $RclonePath version --check=false
Write-Host "`nVersión de Rclone:" -ForegroundColor Cyan
Write-Host "  $($version[0])" -ForegroundColor Blue

# Probar conectividad de cada remoto
Write-Host "`n2. Probando conectividad de remotos..." -ForegroundColor Yellow

$remoteTests = @()
$expectedRemotes = @("movies:", "series:", "downloads:")

foreach ($remote in $expectedRemotes) {
    if ($remotes -contains $remote) {
        $result = Test-Remote -RemoteName $remote
        $remoteTests += @{
            "Remote" = $remote
            "Success" = $result
        }
    } else {
        Write-Host "`n❌ Remoto esperado no encontrado: $remote" -ForegroundColor Red
        $remoteTests += @{
            "Remote" = $remote  
            "Success" = $false
        }
    }
}

# Probar montajes temporales
Write-Host "`n3. Probando montajes temporales..." -ForegroundColor Yellow

$mountTests = @()
$testBasePath = "C:\temp\rclone-test"

foreach ($test in $remoteTests) {
    if ($test.Success) {
        $remote = $test.Remote
        $testMountPoint = "$testBasePath\$($remote.Replace(':', ''))"
        
        Write-Host "Preparando directorio de prueba: $testMountPoint" -ForegroundColor Gray
        if (!(Test-Path (Split-Path $testMountPoint))) {
            New-Item -ItemType Directory -Path (Split-Path $testMountPoint) -Force | Out-Null
        }
        
        $mountResult = Test-Mount -RemoteName $remote -TestMountPoint $testMountPoint
        $mountTests += @{
            "Remote" = $remote
            "Success" = $mountResult
        }
    } else {
        $mountTests += @{
            "Remote" = $test.Remote
            "Success" = $false
        }
    }
}

# Verificar estado de servicios
Write-Host "`n4. Verificando servicios NSSM..." -ForegroundColor Yellow

$services = @("rclone-movies", "rclone-series", "rclone-downloads")
$serviceStatus = @()

foreach ($serviceName in $services) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        Write-Host "  📋 $serviceName - Estado: $($service.Status)" -ForegroundColor $(if($service.Status -eq 'Running'){'Green'}else{'Yellow'})
        $serviceStatus += @{
            "Service" = $serviceName
            "Status" = $service.Status
            "Exists" = $true
        }
    } else {
        Write-Host "  ❌ $serviceName - No existe" -ForegroundColor Red
        $serviceStatus += @{
            "Service" = $serviceName
            "Status" = "NotFound"
            "Exists" = $false
        }
    }
}

# Verificar puntos de montaje activos
Write-Host "`n5. Verificando puntos de montaje activos..." -ForegroundColor Yellow

$mountPoints = @("C:\mnt\movies", "C:\mnt\series", "C:\mnt\downloads")
$activeMounts = @()

foreach ($mountPoint in $mountPoints) {
    if (Test-Path $mountPoint) {
        try {
            $items = Get-ChildItem $mountPoint -ErrorAction Stop | Measure-Object
            Write-Host "  ✅ $mountPoint - Montado ($($items.Count) elementos)" -ForegroundColor Green
            $activeMounts += @{
                "MountPoint" = $mountPoint
                "Active" = $true
                "ItemCount" = $items.Count
            }
        } catch {
            Write-Host "  ⚠️  $mountPoint - Existe pero no accesible" -ForegroundColor Yellow
            $activeMounts += @{
                "MountPoint" = $mountPoint
                "Active" = $false
                "ItemCount" = 0
            }
        }
    } else {
        Write-Host "  ➖ $mountPoint - No existe (normal si servicios no están corriendo)" -ForegroundColor Gray
        $activeMounts += @{
            "MountPoint" = $mountPoint
            "Active" = $false
            "ItemCount" = 0
        }
    }
}

# Generar reporte final
Write-Host "`n=== REPORTE FINAL ===" -ForegroundColor Green

Write-Host "`n📊 Resumen de pruebas:" -ForegroundColor Yellow

# Conectividad
Write-Host "`n🌐 Conectividad de remotos:" -ForegroundColor Cyan
foreach ($test in $remoteTests) {
    $status = if($test.Success){"✅ Exitoso"}else{"❌ Fallido"}
    Write-Host "  $($test.Remote) - $status" -ForegroundColor $(if($test.Success){'Green'}else{'Red'})
}

# Montajes de prueba
Write-Host "`n🔧 Pruebas de montaje:" -ForegroundColor Cyan
foreach ($test in $mountTests) {
    $status = if($test.Success){"✅ Exitoso"}else{"❌ Fallido"}
    Write-Host "  $($test.Remote) - $status" -ForegroundColor $(if($test.Success){'Green'}else{'Red'})
}

# Servicios
Write-Host "`n⚙️  Estado de servicios:" -ForegroundColor Cyan
foreach ($status in $serviceStatus) {
    if ($status.Exists) {
        $color = switch($status.Status) {
            "Running" { "Green" }
            "Stopped" { "Yellow" }
            default { "Red" }
        }
        Write-Host "  $($status.Service) - $($status.Status)" -ForegroundColor $color
    } else {
        Write-Host "  $($status.Service) - No configurado" -ForegroundColor Red
    }
}

# Montajes activos
Write-Host "`n📁 Montajes activos:" -ForegroundColor Cyan
foreach ($mount in $activeMounts) {
    if ($mount.Active) {
        Write-Host "  $($mount.MountPoint) - ✅ Activo ($($mount.ItemCount) elementos)" -ForegroundColor Green
    } else {
        Write-Host "  $($mount.MountPoint) - ➖ Inactivo" -ForegroundColor Gray
    }
}

# Recomendaciones
Write-Host "`n💡 Recomendaciones:" -ForegroundColor Yellow

$allRemotesOk = ($remoteTests | Where-Object { -not $_.Success }).Count -eq 0
$allMountsOk = ($mountTests | Where-Object { -not $_.Success }).Count -eq 0
$allServicesRunning = ($serviceStatus | Where-Object { $_.Status -ne "Running" -and $_.Exists }).Count -eq 0

if ($allRemotesOk -and $allMountsOk) {
    Write-Host "  ✅ Configuración básica correcta" -ForegroundColor Green
    
    if (-not $allServicesRunning) {
        Write-Host "  🔧 Iniciar servicios: Start-Service rclone-movies" -ForegroundColor Blue
    }
    
    Write-Host "  📖 Configurar bibliotecas de Plex apuntando a C:\mnt\" -ForegroundColor Blue
} else {
    Write-Host "  🔧 Revisar configuración de rclone.conf" -ForegroundColor Red
    Write-Host "  📋 Verificar credenciales de Google Drive/OneDrive" -ForegroundColor Red
    Write-Host "  🌐 Comprobar conectividad a internet" -ForegroundColor Red
}

# Limpiar archivos temporales
if (Test-Path $testBasePath) {
    Remove-Item $testBasePath -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`n✅ Pruebas completadas" -ForegroundColor Green
Read-Host "Presione Enter para salir"