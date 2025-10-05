# Configuraciones de Ejemplo para Diferentes Casos de Uso

## 🎬 Configuración para Plex Streaming (Producción)

### Para contenido 4K y alta calidad:
```bash
rclone mount ucmovie:plex-all C:\mnt\movies \
  --config=C:\rclone\rclone.conf \
  --cache-dir=C:\rclone\cache \
  --vfs-cache-mode full \
  --vfs-cache-max-size 200G \
  --vfs-cache-max-age 168h \
  --vfs-read-ahead 1G \
  --buffer-size 512M \
  --vfs-read-chunk-size 256M \
  --vfs-read-chunk-size-limit 4G \
  --bwlimit 10M \
  --poll-interval 30m \
  --allow-other \
  --dir-cache-time 2h \
  --vfs-cache-poll-interval 5m \
  --log-file=C:\rclone\logs\rclone-movies.log \
  --log-level INFO
```

### Para contenido HD estándar:
```bash
rclone mount ucserie:plex-all C:\mnt\series \
  --config=C:\rclone\rclone.conf \
  --cache-dir=C:\rclone\cache \
  --vfs-cache-mode full \
  --vfs-cache-max-size 100G \
  --vfs-cache-max-age 720h \
  --vfs-read-ahead 512M \
  --buffer-size 256M \
  --vfs-read-chunk-size 128M \
  --vfs-read-chunk-size-limit 2G \
  --bwlimit 6M \
  --poll-interval 15m \
  --allow-other \
  --dir-cache-time 1h \
  --vfs-cache-poll-interval 1m \
  --log-file=C:\rclone\logs\rclone-series.log \
  --log-level INFO
```

## 📥 Configuración para ARR Applications

### Radarr/Sonarr (descarga activa):
```bash
rclone mount ucarr:plex-all C:\mnt\arr \
  --config=C:\rclone\rclone.conf \
  --cache-dir=C:\rclone\cache \
  --vfs-cache-mode writes \
  --vfs-write-back 5s \
  --transfers 8 \
  --checkers 16 \
  --poll-interval 5m \
  --allow-other \
  --dir-cache-time 10m \
  --fast-list \
  --buffer-size 64M \
  --bwlimit 15M \
  --log-file=C:\rclone\logs\rclone-arr.log \
  --log-level INFO
```

## 🔄 Configuración para Sincronización Bi-direccional

### Para uso con qBittorrent:
```bash
rclone mount ucarr:downloads C:\mnt\downloads \
  --config=C:\rclone\rclone.conf \
  --vfs-cache-mode full \
  --vfs-write-back 10s \
  --transfers 4 \
  --checkers 8 \
  --upload-cutoff 100M \
  --chunk-size 32M \
  --bwlimit-file 20M \
  --poll-interval 2m \
  --allow-other \
  --log-file=C:\rclone\logs\rclone-downloads.log \
  --log-level INFO
```

## 🌐 Configuración por Tipo de Conexión

### Conexión rápida (>100 Mbps):
```bash
--vfs-cache-mode full \
--vfs-cache-max-size 150G \
--vfs-read-ahead 1G \
--buffer-size 512M \
--bwlimit 20M \
--transfers 8 \
--checkers 16
```

### Conexión media (25-100 Mbps):
```bash
--vfs-cache-mode full \
--vfs-cache-max-size 100G \
--vfs-read-ahead 512M \
--buffer-size 256M \
--bwlimit 6M \
--transfers 4 \
--checkers 8
```

### Conexión lenta (<25 Mbps):
```bash
--vfs-cache-mode writes \
--vfs-cache-max-size 50G \
--vfs-read-ahead 256M \
--buffer-size 128M \
--bwlimit 3M \
--transfers 2 \
--checkers 4 \
--tpslimit 2
```

## 💾 Configuración por Espacio Disponible

### Servidor con >500GB libres:
```bash
--vfs-cache-mode full \
--vfs-cache-max-size 200G \
--vfs-cache-max-age 168h
```

### Servidor con 200-500GB libres:
```bash
--vfs-cache-mode full \
--vfs-cache-max-size 100G \
--vfs-cache-max-age 720h
```

### Servidor con <200GB libres:
```bash
--vfs-cache-mode writes \
--vfs-cache-max-size 50G \
--vfs-cache-max-age 24h
```

## 🎯 Configuraciones Especializadas

### Solo lectura (máximo rendimiento):
```bash
rclone mount ucmovie:plex-all C:\mnt\movies \
  --config=C:\rclone\rclone.conf \
  --read-only \
  --vfs-cache-mode full \
  --vfs-cache-max-size 150G \
  --vfs-read-ahead 1G \
  --buffer-size 1G \
  --bwlimit 50M \
  --fast-list \
  --no-modtime \
  --no-checksum \
  --poll-interval 60m
```

### Primer escaneo de Plex (temporal):
```bash
rclone mount ucmovie:plex-all C:\mnt\movies \
  --config=C:\rclone\rclone.conf \
  --vfs-cache-mode minimal \
  --fast-list \
  --dir-cache-time 720h \
  --poll-interval 0 \
  --tpslimit 2 \
  --bwlimit 4M \
  --transfers 2 \
  --checkers 4 \
  --no-traverse
```

### Depuración (máximo logging):
```bash
rclone mount ucmovie:plex-all C:\mnt\movies \
  --config=C:\rclone\rclone.conf \
  --vfs-cache-mode writes \
  --log-level DEBUG \
  --log-file=C:\rclone\logs\debug.log \
  --stats 30s \
  --stats-log-level INFO \
  --progress
```

## 📊 Parámetros por Proveedor de Nube

### Google Drive:
```bash
# En rclone.conf
[ucmovie]
type = drive
disable_http2 = true
pacer_min_sleep = 100ms
pacer_burst = 100

# Parámetros de montaje adicionales
--drive-chunk-size 32M \
--drive-acknowledge-abuse
```

### OneDrive Business:
```bash
# En rclone.conf
[ucmovie]
type = onedrive
chunk_size = 10M
upload_cutoff = 10M

# Parámetros de montaje adicionales
--onedrive-chunk-size 10M
```

### Dropbox:
```bash
# En rclone.conf
[ucmovie]
type = dropbox
chunk_size = 48M

# Parámetros de montaje adicionales
--dropbox-chunk-size 48M \
--dropbox-impersonate user@domain.com
```

## 🔧 Plantillas para NSSM

### Servicio básico de streaming:
```powershell
$serviceName = "rclone-movies"
$appPath = "C:\rclone\rclone.exe"
$appParams = "mount ucmovie:plex-all C:\mnt\movies --config=C:\rclone\rclone.conf --cache-dir=C:\rclone\cache --vfs-cache-mode full --vfs-cache-max-size 100G --vfs-cache-max-age 720h --vfs-read-ahead 512M --buffer-size 256M --vfs-read-chunk-size 128M --vfs-read-chunk-size-limit 2G --bwlimit 6M --poll-interval 15m --allow-other --dir-cache-time 1h --vfs-cache-poll-interval 1m --log-file=C:\rclone\logs\rclone-movies.log --log-level INFO"

# Crear servicio
& C:\rclone\bin\nssm.exe install $serviceName $appPath $appParams
& C:\rclone\bin\nssm.exe set $serviceName AppStdout "C:\rclone\logs\$serviceName.log"
& C:\rclone\bin\nssm.exe set $serviceName AppStderr "C:\rclone\logs\$serviceName.log"
& C:\rclone\bin\nssm.exe set $serviceName Start SERVICE_AUTO_START
```

## 📝 Configuraciones de Ejemplo en rclone.conf

### Google Drive optimizado:
```ini
[ucmovie]
type = drive
client_id = tu_client_id
client_secret = tu_client_secret
scope = drive
token = {"access_token":"token","token_type":"Bearer","refresh_token":"refresh","expiry":"2025-12-31T23:59:59Z"}
team_drive = tu_team_drive_id
disable_http2 = true
pacer_min_sleep = 100ms
pacer_burst = 100
server_side_across_configs = false
```

### OneDrive Business optimizado:
```ini
[ucserie]
type = onedrive
client_id = tu_client_id
client_secret = tu_client_secret
token = {"access_token":"token","token_type":"Bearer","refresh_token":"refresh","expiry":"2025-12-31T23:59:59Z"}
drive_id = tu_drive_id
drive_type = business
chunk_size = 10M
upload_cutoff = 10M
```

Estos ejemplos cubren la mayoría de casos de uso comunes. Ajusta los parámetros según tu hardware, conexión y necesidades específicas.