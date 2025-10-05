# ⚡ Comandos de Referencia Rápida

## 🚀 Instalación Inicial

```powershell
# Ejecutar como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
cd C:\path\to\Rclone-Windows\scripts

# Instalación completa
.\install-components.ps1
# Configurar credenciales: C:\rclone\rclone.exe config
.\setup-services.ps1
.\test-mounts.ps1
```

## 🎮 Gestión Diaria de Servicios

```powershell
# Ver estado de todos los servicios
.\manage-services.ps1 -Action status

# Iniciar todos los servicios
.\manage-services.ps1 -Action start

# Detener todos los servicios
.\manage-services.ps1 -Action stop

# Reiniciar todos los servicios
.\manage-services.ps1 -Action restart

# Gestionar servicio específico
.\manage-services.ps1 -Action restart -Service movies
.\manage-services.ps1 -Action status -Service downloads
```

## 📋 Comandos Windows Útiles

```powershell
# Ver estado de servicios Rclone
Get-Service rclone-*

# Iniciar servicio específico
Start-Service rclone-movies

# Detener servicio específico
Stop-Service rclone-movies -Force

# Ver dependencias de servicios
Get-Service rclone-movies | Select-Object -ExpandProperty DependentServices
Get-Service rclone-movies | Select-Object -ExpandProperty ServicesDependedOn
```

## 📄 Logs y Diagnóstico

```powershell
# Ver logs en tiempo real
Get-Content C:\rclone\logs\rclone-movies.log -Wait

# Ver últimas 50 líneas del log
Get-Content C:\rclone\logs\rclone-movies.log -Tail 50

# Buscar errores en logs
Select-String -Path "C:\rclone\logs\*.log" -Pattern "ERROR|FATAL|Failed"

# Ver logs del sistema relacionados con servicios
Get-EventLog -LogName System -Source "Service Control Manager" -Newest 10

# Ejecutar diagnóstico completo
.\test-mounts.ps1

# Generar reporte de caché
.\weekly-cache-report.ps1
```

## 🔧 Comandos Rclone Directos

```powershell
# Verificar configuración
C:\rclone\rclone.exe config show

# Listar remotos configurados
C:\rclone\rclone.exe listremotes --config=C:\rclone\rclone.conf

# Probar conectividad a remoto
C:\rclone\rclone.exe lsd movies: --config=C:\rclone\rclone.conf

# Ver información de cuota/espacio
C:\rclone\rclone.exe about movies: --config=C:\rclone\rclone.conf

# Verificar archivos específicos
C:\rclone\rclone.exe ls movies: --config=C:\rclone\rclone.conf

# Montaje manual temporal (para pruebas)
C:\rclone\rclone.exe mount movies: C:\temp\test --config=C:\rclone\rclone.conf --vfs-cache-mode minimal --read-only
```

## 🛠️ Mantenimiento y Limpieza

```powershell
# Limpiar caché manualmente
Remove-Item C:\rclone\cache\vfs\* -Recurse -Force

# Limpiar logs antiguos (>30 días)
Get-ChildItem C:\rclone\logs\*.log.* | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force

# Verificar espacio en disco
Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"} | Select-Object Size,FreeSpace,@{Name="FreePercent";Expression={[math]::Round(($_.FreeSpace/$_.Size)*100,2)}}

# Ver uso de caché actual
Get-ChildItem C:\rclone\cache -Recurse | Measure-Object -Property Length -Sum

# Verificar archivos de configuración
Test-Path C:\rclone\rclone.conf
Get-Acl C:\rclone\rclone.conf | Select-Object -ExpandProperty Access
```

## 🔄 Actualizaciones

```powershell
# Verificar versiones disponibles
.\update-components.ps1 -CheckOnly

# Actualizar componentes automáticamente
.\update-components.ps1

# Verificar versión actual de Rclone
C:\rclone\rclone.exe version

# Verificar versión de WinFsp
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object {$_.DisplayName -like "*WinFsp*"}
```

## 💾 Backup y Restauración

```powershell
# Respaldar configuración (SIN credenciales)
C:\rclone\rclone.exe config show --obscure > C:\temp\rclone-config-backup.txt

# Respaldar configuración completa (CON credenciales - CUIDADO)
Copy-Item C:\rclone\rclone.conf C:\secure-backup\rclone.conf.backup

# Listar servicios para backup de configuración
Get-Service rclone-* | Select-Object Name,Status,StartType

# Exportar configuración de servicios NSSM
C:\rclone\bin\nssm.exe export rclone-movies C:\temp\rclone-movies-service.reg
```

## 🌐 Red y Conectividad

```powershell
# Verificar conectividad a Google Drive
Test-NetConnection -ComputerName drive.google.com -Port 443

# Ver uso de ancho de banda (requiere herramientas adicionales)
# Ejemplo con netstat para conexiones activas:
netstat -b | findstr rclone

# Verificar DNS
nslookup drive.google.com
nslookup api.onedrive.com

# Probar latencia
ping drive.google.com
```

## 🚨 Emergencia / Solución de Problemas

```powershell
# Detener TODOS los servicios de Rclone
Get-Service rclone-* | Stop-Service -Force

# Eliminar puntos de montaje problemáticos
Remove-Item C:\mnt\movies -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\mnt\series -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\mnt\downloads -Recurse -Force -ErrorAction SilentlyContinue

# Reiniciar WinFsp si hay problemas de montaje
Restart-Service WinFsp.Launcher

# Verificar procesos de Rclone que puedan estar colgados
Get-Process | Where-Object {$_.ProcessName -like "*rclone*"}

# Terminar procesos de Rclone si es necesario
Get-Process | Where-Object {$_.ProcessName -like "*rclone*"} | Stop-Process -Force

# Reiniciar servicios después de resolver problemas
Start-Service rclone-movies
Start-Sleep 15
Start-Service rclone-series  
Start-Sleep 15
Start-Service rclone-downloads
```

## 📊 Monitoreo en Tiempo Real

```powershell
# Monitor de servicios en tiempo real (cada 5 segundos)
while ($true) { 
    Clear-Host
    Get-Service rclone-* | Format-Table -AutoSize
    Start-Sleep 5 
}

# Monitor de puntos de montaje
while ($true) {
    Clear-Host
    Write-Host "=== Montajes Activos ===" -ForegroundColor Green
    Get-ChildItem C:\mnt -ErrorAction SilentlyContinue | ForEach-Object {
        $count = (Get-ChildItem $_.FullName -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "$($_.Name): $count elementos" -ForegroundColor Blue
    }
    Start-Sleep 10
}

# Monitor básico de rendimiento
while ($true) {
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
    $memory = Get-Counter '\Memory\Available MBytes' | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
    Write-Host "CPU: $([math]::Round($cpu,1))% | RAM libre: $([math]::Round($memory,0)) MB" -ForegroundColor Cyan
    Start-Sleep 5
}
```

## 🔑 Comandos de Configuración NSSM

```powershell
# Ver configuración completa de un servicio
C:\rclone\bin\nssm.exe dump rclone-movies

# Editar parámetros específicos
C:\rclone\bin\nssm.exe set rclone-movies AppParameters "nuevos parámetros aquí"

# Cambiar modo de inicio
C:\rclone\bin\nssm.exe set rclone-movies Start SERVICE_AUTO_START

# Ver configuración específica
C:\rclone\bin\nssm.exe get rclone-movies AppParameters
C:\rclone\bin\nssm.exe get rclone-movies AppStdout
```

Estos comandos cubren el 95% de las operaciones diarias y situaciones de emergencia.