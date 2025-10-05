# Solución de Problemas - Rclone Windows

Esta guía cubre los problemas más comunes y sus soluciones.

## 🚨 Problemas de montaje

### ❌ "mountpoint path already exists"

**Síntoma**: El servicio no inicia y aparece este error en los logs.

**Causa**: La carpeta de montaje ya existe o WinFsp está en estado inconsistente.

**Solución**:
```powershell
# 1. Detener todos los servicios
.\manage-services.ps1 -Action stop

# 2. Eliminar carpetas de montaje manualmente
Remove-Item C:\mnt\movies -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\mnt\series -Recurse -Force -ErrorAction SilentlyContinue  
Remove-Item C:\mnt\arr -Recurse -Force -ErrorAction SilentlyContinue

# 3. Reiniciar WinFsp (opcional)
Restart-Service -Name WinFsp.Launcher

# 4. Iniciar servicios nuevamente
.\manage-services.ps1 -Action start
```

### ❌ Servicio en estado "Paused"

**Síntoma**: El servicio aparece como "Paused" en lugar de "Running" o "Stopped".

**Causa**: Fallo al iniciar múltiples montajes simultáneos.

**Solución**:
```powershell
# Iniciar servicios secuencialmente con espera
Start-Service rclone-movies
Start-Sleep -Seconds 15
Start-Service rclone-series  
Start-Sleep -Seconds 15
Start-Service rclone-arr
```

### ❌ Montaje lento o no responde

**Síntoma**: Los archivos tardan mucho en cargar o Plex no puede reproducir.

**Posibles causas y soluciones**:

1. **Límite de ancho de banda muy bajo**:
   ```powershell
   # Aumentar bwlimit en la configuración del servicio
   # Ejemplo: cambiar --bwlimit 2M por --bwlimit 6M
   ```

2. **Caché VFS deshabilitado**:
   ```powershell
   # Verificar que usa --vfs-cache-mode full para streaming
   # Ver configuración actual: .\manage-services.ps1 -Action status
   ```

3. **API rate limiting**:
   ```powershell
   # Aumentar pacer_min_sleep en rclone.conf
   # Ejemplo: pacer_min_sleep = 200ms
   ```

## 🔐 Problemas de autenticación

### ❌ "Failed to get token"

**Síntoma**: Error de autenticación al acceder a Google Drive/OneDrive.

**Solución**:
```powershell
# Reconfigurar credenciales
C:\rclone\rclone.exe config

# Seleccionar el remoto existente y "Edit existing remote"
# Seguir proceso de autorización nuevamente
```

### ❌ "Token expired"

**Síntoma**: Funcionaba antes pero ahora da errores de token.

**Solución**:
```powershell
# Rclone renueva tokens automáticamente, pero si persiste:
C:\rclone\rclone.exe config reconnect ucmovie:
C:\rclone\rclone.exe config reconnect ucserie:
C:\rclone\rclone.exe config reconnect ucarr:
```

## 💾 Problemas de espacio y caché

### ⚠️ Caché lleno

**Síntoma**: Logs muestran "cache full" o rendimiento degradado.

**Solución**:
```powershell
# Ver uso actual del caché
.\weekly-cache-report.ps1

# Limpiar caché manualmente
Remove-Item C:\rclone\cache\vfs\* -Recurse -Force

# Ajustar límite de caché (editar servicios)
# Cambiar --vfs-cache-max-size 100G por valor mayor
```

### ⚠️ Disco lleno

**Síntoma**: Sistema lento, errores de escritura.

**Solución**:
```powershell
# Verificar espacio disponible
Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}

# Limpiar logs antiguos
Remove-Item C:\rclone\logs\*.log.* -Force

# Reducir tamaño de caché
# Editar configuración de servicios con --vfs-cache-max-size 50G
```

## 🌐 Problemas de conectividad

### ❌ "No internet connection"

**Síntoma**: Error de red al intentar conectar con la nube.

**Solución**:
```powershell
# Verificar conectividad básica
Test-NetConnection -ComputerName google.com -Port 443

# Probar DNS
nslookup drive.google.com

# Verificar proxy/firewall empresarial
C:\rclone\rclone.exe config show
# Añadir configuración de proxy si es necesario
```

### ❌ "Too many requests"

**Síntoma**: Errores 429 o rate limiting de Google Drive.

**Solución**:
```powershell
# Reducir concurrencia en rclone.conf:
# pacer_min_sleep = 500ms
# pacer_burst = 50

# O añadir límites globales al montaje:
# --tpslimit 2 --transfers 4
```

## ⚙️ Problemas de servicios Windows

### ❌ Servicio no se instala

**Síntoma**: NSSM falla al crear el servicio.

**Solución**:
```powershell
# Verificar permisos de administrador
whoami /groups | findstr "S-1-5-32-544"

# Verificar que NSSM es la versión correcta
C:\rclone\bin\nssm.exe --version
# Debe ser 2.24-101 o superior para Windows 10/11

# Reinstalar servicio manualmente
C:\rclone\bin\nssm.exe remove rclone-movies confirm
C:\rclone\bin\nssm.exe install rclone-movies C:\rclone\rclone.exe
```

### ❌ "Service failed to start"

**Síntoma**: El servicio se crea pero no inicia.

**Solución**:
```powershell
# Ver detalles del error
Get-EventLog -LogName System -Source "Service Control Manager" -Newest 5

# Verificar permisos del archivo ejecutable
icacls C:\rclone\rclone.exe

# Probar comando manualmente
C:\rclone\rclone.exe mount ucmovie:plex-all C:\test-mount --config=C:\rclone\rclone.conf --vfs-cache-mode minimal
```

## 🎬 Problemas específicos de Plex

### ❌ Plex no ve el contenido

**Síntoma**: Las bibliotecas aparecen vacías en Plex.

**Solución**:
```powershell
# Verificar que los montajes son accesibles
Get-ChildItem C:\mnt\movies
Get-ChildItem C:\mnt\series

# Verificar permisos para el usuario de Plex
# Plex corre como LocalService por defecto

# Forzar escaneo en Plex
# Ir a Settings > Libraries > Scan Library Files
```

### ❌ Reproducción entrecortada

**Síntoma**: Video se pausa o buffering constante.

**Solución**:
1. **Optimizar parámetros de caché**:
   ```
   --vfs-read-ahead 1G --buffer-size 512M
   ```

2. **Aumentar límite de ancho de banda**:
   ```
   --bwlimit 10M  # O sin límite para pruebas
   ```

3. **Habilitar transcoding en Plex** para streams problemáticos

## 📋 Diagnóstico sistemático

### Script de diagnóstico completo:
```powershell
# Ejecutar diagnóstico automatizado
.\test-mounts.ps1

# Ver estado detallado
.\manage-services.ps1 -Action status

# Generar reporte completo
.\weekly-cache-report.ps1
```

### Información útil para soporte:

```powershell
# Información del sistema
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory

# Versión de Rclone
C:\rclone\rclone.exe --version

# Estado de WinFsp
Get-Service WinFsp.Launcher

# Últimos errores del sistema
Get-EventLog -LogName System -EntryType Error -Newest 10
```

## 📞 Escalación

Si ninguna solución funciona:

1. **Recopilar logs**:
   ```powershell
   # Comprimir logs para envío
   Compress-Archive -Path C:\rclone\logs\* -DestinationPath C:\temp\rclone-logs.zip
   ```

2. **Información del sistema**:
   ```powershell
   # Exportar configuración (SIN credenciales)
   C:\rclone\rclone.exe config show --obscure
   ```

3. **Reinicio completo** como último recurso:
   ```powershell
   .\manage-services.ps1 -Action stop
   Restart-Computer
   ```

Con esta información, cualquier administrador puede diagnosticar y resolver los problemas más comunes.