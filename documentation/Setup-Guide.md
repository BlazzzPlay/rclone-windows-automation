# 🏠 Servidor Windows - Configuración Plex + Rclone

## 📝 **Resumen del sistema**

- **Nombre del equipo**: `Windows-Plex-Server` (ejemplo)
- **SO**: Windows 10/11 (recomendado 22H2 o superior)
- **Rol**: Servidor multimedia (Plex) + Almacenamiento en la nube
- **Hardware mínimo**: 8 GB RAM / 200 GB SSD disponible
- **Hardware recomendado**: 16+ GB RAM / 500+ GB SSD disponible

---

## 🔧 **Componentes instalados**

| Componente | Versión | Enlace | Estado |
|-----------|--------|--------|--------|
| Rclone | v1.71.0 | [rclone.org](https://rclone.org/downloads/) | ✅ Instalado |
| WinFsp | v2.0+ | [winfsp.dev](https://winfsp.dev/rel/) | ✅ Instalado |
| NSSM | v2.24-101+ | [nssm.cc](https://nssm.cc/download) | ✅ Instalado |
| Plex Media Server | Última estable | [plex.tv](https://www.plex.tv/media-server-downloads/) | ✅ Instalado |

> ⚠️ **Nota importante**: NSSM debe ser **2.24-101 o superior** para Windows 10/11 (según la documentación oficial).

---

## 🗂️ **Estructura de carpetas**

```
C:\rclone\
├── rclone.exe                 ← Ejecutable principal
├── rclone.conf               ← Configuración de remotos
├── cache\                    ← Caché VFS de Rclone
│   ├── vfs\                  ← Archivos en caché
│   └── vfsMeta\              ← Metadatos de caché
└── logs\                     ← Archivos de log
    ├── rclone-movies.log
    ├── rclone-series.log
    ├── rclone-arr.log
    └── cache-report-*.txt

C:\mnt\                       ← Puntos de montaje (NO crear manualmente)
├── movies\                   ← Se crea automáticamente por Rclone
├── series\                   ← Se crea automáticamente por Rclone
└── arr\                      ← Se crea automáticamente por Rclone
```

> 🔴 **CRÍTICO**: Las carpetas bajo `C:\mnt\` **NO deben existir** antes del montaje. Rclone las crea automáticamente.

---

## ⚙️ **Configuración de Rclone**

### Remotos configurados:
- **`movies:`** → Películas (Google Drive/OneDrive)
- **`series:`** → Series (Google Drive/OneDrive)
- **`downloads:`** → Descargas/aplicaciones (Radarr, Sonarr, qBittorrent)

### Archivo de configuración:
- **Ruta**: `C:\rclone\rclone.conf`
- **Permisos**: Solo accesible por el usuario del servicio y Administradores
- **Backup**: Se recomienda respaldar regularmente

---

## 🖥️ **Servicios NSSM**

| Servicio | Descripción | Comando AppParameters | Modo de inicio |
|---------|-------------|----------------------|----------------|
| `rclone-movies` | Montaje de películas | `mount movies: C:\mnt\movies --config=C:\rclone\rclone.conf [parámetros]` | Automático |
| `rclone-series` | Montaje de series | `mount series: C:\mnt\series --config=C:\rclone\rclone.conf [parámetros]` | Automático |
| `rclone-downloads` | Montaje para descargas/ARR | `mount downloads: C:\mnt\downloads --config=C:\rclone\rclone.conf [parámetros]` | Automático |

### Configuración adicional NSSM:
- **AppStdout**: `C:\rclone\logs\[servicio].log`
- **AppStderr**: `C:\rclone\logs\[servicio].log`
- **AppStdoutCreationDisposition**: 4 (append)
- **AppStderrCreationDisposition**: 4 (append)

---

## 🎬 **Parámetros de Rclone por uso**

### 🎭 Películas/Series (producción optimizada):
```bash
--vfs-cache-mode full 
--vfs-cache-max-size 100G 
--vfs-cache-max-age 720h 
--vfs-read-ahead 512M 
--buffer-size 256M 
--vfs-read-chunk-size 128M 
--vfs-read-chunk-size-limit 2G 
--bwlimit 6M 
--poll-interval 15m 
--allow-other 
--dir-cache-time 1h 
--vfs-cache-poll-interval 1m
```

### 📥 ARR (escritura optimizada):
```bash
--vfs-cache-mode writes 
--vfs-write-back 5s 
--transfers 8 
--checkers 16 
--poll-interval 5m 
--allow-other 
--dir-cache-time 10m 
--fast-list
```

### 🔍 Temporal (primer escaneo de Plex):
```bash
--fast-list 
--dir-cache-time 720h 
--poll-interval 0 
--tpslimit 2 
--bwlimit 4M 
--vfs-cache-mode minimal 
--allow-other
```

---

## 📅 **Mantenimiento automático**

### Informe semanal de caché:
- **Script**: `C:\rclone\weekly-cache-report.ps1`
- **Programación**: Domingo 2:00 AM vía Programador de tareas de Windows
- **Función**: Genera reporte de uso de caché y limpia archivos antiguos

### Rotación de logs:
- **Frecuencia**: Semanal
- **Retención**: 30 días
- **Ubicación**: `C:\rclone\logs\`

---

## 🚨 **Solución de problemas comunes**

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| `mountpoint path already exists` | Carpeta de montaje ya existe o WinFsp en estado inconsistente | 1. Eliminar carpeta manualmente<br>2. Reiniciar servicio WinFsp<br>3. Si persiste: reiniciar equipo |
| Servicio en estado "Paused" | Fallo al iniciar múltiples montajes simultáneos | Iniciar servicios secuencialmente con 15s de espera entre cada uno |
| Alto tráfico en primer escaneo | Plex lee metadatos de todos los archivos | Usar configuración temporal con `--tpslimit 2` |
| Caché lleno | VFS alcanzó límite de 100GB | Ejecutar limpieza manual o esperar limpieza automática |
| Montaje lento | Parámetros no optimizados | Verificar configuración según tipo de uso |

### Comandos útiles de diagnóstico:
```powershell
# Verificar estado de servicios
Get-Service rclone-*

# Ver logs en tiempo real
Get-Content C:\rclone\logs\rclone-movies.log -Wait

# Verificar montajes activos
rclone listremotes --config=C:\rclone\rclone.conf

# Estado de caché
rclone about ucmovie: --config=C:\rclone\rclone.conf
```

---

## 🔐 **Seguridad y permisos**

### Archivos sensibles:
- `rclone.conf`: Contiene tokens de autenticación
- Solo accesible por: Usuario del servicio y grupo `Administradores`

### Firewall:
- **Puerto RDP**: 3389 (acceso remoto - opcional)
- **Puerto Plex**: 32400 (servidor multimedia)
- **Rclone**: No requiere puertos adicionales

---

## 📊 **Monitoreo**

### Métricas clave:
- **Uso de caché**: Máximo 100GB
- **Ancho de banda**: Limitado a 6MB/s para streaming
- **Uptime de servicios**: >99%
- **Espacio disponible**: >200GB libres en SSD

### Alertas:
- Caché >90% utilizado
- Servicios caídos >5 minutos
- Espacio en disco <100GB

---

## 📎 **Enlaces útiles**

- [📖 Documentación oficial de Rclone](https://rclone.org/)
- [🔧 Guía de WinFsp](https://winfsp.dev/rel/)
- [⚙️ NSSM – Non-Sucking Service Manager](https://nssm.cc/)
- [🎬 Plex Media Server](https://www.plex.tv/)
- [💾 Repositorio de configuración](file:///c:/web/VSc/Rclone-Windows/)

---

## 📝 **Historial de cambios**

| Fecha | Cambio | Versión |
|-------|--------|---------|
| 2025-10-05 | Versión inicial del repositorio | 1.0 |

---

## 🆘 **Soporte y contribuciones**

- **Repositorio**: [GitHub](https://github.com/usuario/Rclone-Windows)
- **Issues**: Para reportar problemas o solicitar funcionalidades
- **Contribuciones**: Pull requests bienvenidos

---

## 🗂️ **Archivos del repositorio**

### Estructura completa generada:
```
Rclone-Windows/
├── README.md                     # Guía de instalación rápida
├── documentation/
│   ├── Notion-Setup-Completo.md  # Esta documentación
│   ├── Troubleshooting.md        # Solución de problemas
│   └── FILES-INDEX.md            # Índice de archivos
├── scripts/                      # Scripts de PowerShell
│   ├── install-components.ps1    # Instalación automática
│   ├── setup-services.ps1       # Configurar servicios NSSM
│   ├── test-mounts.ps1          # Verificar funcionamiento
│   ├── manage-services.ps1      # Gestión diaria
│   ├── weekly-cache-report.ps1  # Reporte automático
│   ├── setup-scheduled-task.ps1 # Tareas programadas
│   └── update-components.ps1    # Actualizar componentes
├── config/
│   └── rclone.conf.template     # Plantilla de configuración
└── templates/
    └── example-configurations.md # Ejemplos avanzados
```

### 🚀 **Instalación en 5 comandos**:
```powershell
# 1. Clonar/descargar repositorio
# 2. .\install-components.ps1
# 3. rclone config (configurar credenciales)
# 4. .\setup-services.ps1
# 5. .\test-mounts.ps1
```

### 📁 **Archivos clave generados**:
- **Scripts automatizados**: Instalación, configuración y mantenimiento
- **Documentación técnica**: Guías completas y solución de problemas
- **Templates**: Configuraciones predefinidas para diferentes casos
- **Herramientas de diagnóstico**: Verificación y reportes automáticos

Todos los archivos están optimizados para servidores Windows con Plex Media Server y almacenamiento en la nube.