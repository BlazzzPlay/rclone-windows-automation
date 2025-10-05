# 📁 Estructura de Archivos - Rclone Windows Setup

```
Rclone-Windows/
├── README.md                          # 🚀 Guía de instalación rápida
├── documentation/
│   ├── Setup-Guide.md                 # 📖 Documentación técnica completa
│   ├── Troubleshooting.md             # 🔧 Solución de problemas comunes
│   ├── Quick-Reference.md             # ⚡ Comandos de referencia rápida
│   └── FILES-INDEX.md                 # 📋 Este archivo - índice completo
├── scripts/                           # 🔨 Scripts de automatización
│   ├── install-components.ps1         # 📦 Instalación automática inicial
│   ├── setup-services.ps1            # ⚙️ Configuración de servicios NSSM
│   ├── test-mounts.ps1               # 🧪 Pruebas y verificación
│   ├── manage-services.ps1           # 🎮 Gestión de servicios (start/stop/status)
│   ├── weekly-cache-report.ps1       # 📊 Reporte automático de caché
│   ├── setup-scheduled-task.ps1      # ⏰ Configurar tareas programadas
│   └── update-components.ps1         # 🔄 Actualizar Rclone y componentes
├── config/
│   └── rclone.conf.template          # 🔑 Plantilla de configuración
└── templates/
    └── example-configurations.md     # 📝 Ejemplos de configuración avanzada
```

## 📝 Descripción de Archivos

### 📚 Documentación

| Archivo | Propósito | Audiencia |
|---------|-----------|-----------|
| `README.md` | Guía de instalación rápida en 5 pasos | Usuarios nuevos |
| `Setup-Guide.md` | Documentación técnica completa | Administradores |
| `Troubleshooting.md` | Solución de problemas comunes | Soporte técnico |
| `Quick-Reference.md` | Comandos de referencia rápida | Usuarios diarios |
| `FILES-INDEX.md` | Índice y organización de archivos | Desarrolladores |

### 🔨 Scripts de PowerShell

#### Scripts Principales (orden de ejecución):

1. **`install-components.ps1`**
   - 🎯 **Propósito**: Instalación inicial de todos los componentes
   - 📦 **Descarga**: Rclone, NSSM, WinFsp
   - 📁 **Crea**: Estructura de carpetas y permisos
   - ⚡ **Ejecución**: Una vez al configurar el sistema

2. **`setup-services.ps1`** 
   - 🎯 **Propósito**: Crear servicios Windows con NSSM
   - ⚙️ **Configura**: 3 servicios (movies, series, arr)
   - 🔧 **Parámetros**: Optimizados para cada tipo de contenido
   - ⚡ **Ejecución**: Después de configurar rclone.conf

3. **`test-mounts.ps1`**
   - 🎯 **Propósito**: Verificar que todo funciona correctamente
   - 🧪 **Prueba**: Conectividad, montajes, servicios
   - 📊 **Reporta**: Estado detallado y recomendaciones
   - ⚡ **Ejecución**: Después de setup, cuando hay problemas

#### Scripts de Gestión:

4. **`manage-services.ps1`**
   - 🎯 **Propósito**: Controlar servicios día a día
   - 🎮 **Acciones**: start, stop, restart, status, logs
   - 📋 **Filtra**: Por servicio individual o todos
   - ⚡ **Ejecución**: Diaria según necesidad

5. **`weekly-cache-report.ps1`**
   - 🎯 **Propósito**: Monitoreo automático y limpieza
   - 📊 **Genera**: Reporte detallado de uso de caché
   - 🧹 **Limpia**: Logs antiguos y archivos temporales
   - ⚡ **Ejecución**: Automática los domingos

#### Scripts de Mantenimiento:

6. **`setup-scheduled-task.ps1`**
   - 🎯 **Propósito**: Automatizar el reporte semanal
   - ⏰ **Programa**: Tarea que corre domingos 2:00 AM
   - 🔧 **Configura**: Como servicio de sistema
   - ⚡ **Ejecución**: Una vez para automatizar

7. **`update-components.ps1`**
   - 🎯 **Propósito**: Mantener componentes actualizados
   - 🔄 **Actualiza**: Rclone automáticamente
   - ✅ **Verifica**: Versiones disponibles vs instaladas
   - ⚡ **Ejecución**: Mensual o cuando haya actualizaciones

### 🔧 Archivos de Configuración

| Archivo | Descripción | Editar |
|---------|-------------|--------|
| `rclone.conf.template` | Plantilla con ejemplos de Google Drive/OneDrive | ❌ No (es plantilla) |
| `C:\rclone\rclone.conf` | Configuración real con credenciales | ✅ Sí (después de install) |

### 📝 Templates y Ejemplos

| Archivo | Contenido |
|---------|-----------|
| `example-configurations.md` | Configuraciones para diferentes casos de uso |

## 🚀 Flujo de Trabajo Típico

### Instalación inicial:
```powershell
# 1. Descargar repositorio
git clone https://github.com/usuario/Rclone-Windows.git

# 2. Ejecutar como Administrador
cd Rclone-Windows\scripts
.\install-components.ps1

# 3. Configurar credenciales
C:\rclone\rclone.exe config

# 4. Crear servicios
.\setup-services.ps1

# 5. Verificar funcionamiento
.\test-mounts.ps1
```

### Gestión diaria:
```powershell
# Ver estado
.\manage-services.ps1 -Action status

# Reiniciar si hay problemas
.\manage-services.ps1 -Action restart -Service movies

# Ver logs en tiempo real
.\manage-services.ps1 -Action logs -Service movies
```

### Mantenimiento:
```powershell
# Configurar reportes automáticos (una vez)
.\setup-scheduled-task.ps1

# Verificar actualizaciones (mensual)
.\update-components.ps1 -CheckOnly

# Actualizar componentes
.\update-components.ps1
```

## 📊 Archivos Generados Durante el Uso

### Estructura en `C:\rclone\`:
```
C:\rclone\
├── rclone.exe                    # Ejecutable principal
├── rclone.conf                   # Configuración con credenciales
├── bin\
│   └── nssm.exe                  # Service manager
├── cache\                        # Caché VFS (automático)
│   ├── vfs\                      # Archivos en caché
│   └── vfsMeta\                  # Metadatos
└── logs\                         # Logs de funcionamiento
    ├── rclone-movies.log         # Log del servicio películas
    ├── rclone-series.log         # Log del servicio series
    ├── rclone-arr.log            # Log del servicio ARR
    └── cache-report-YYYY-MM-DD.txt  # Reportes semanales
```

### Puntos de montaje en `C:\mnt\`:
```
C:\mnt\                           # Creado automáticamente por Rclone
├── movies\                       # Montaje películas (ucmovie:)
├── series\                       # Montaje series (ucserie:)
└── arr\                          # Montaje ARR apps (ucarr:)
```

## 🔒 Archivos Sensibles

⚠️ **NUNCA compartir estos archivos**:
- `C:\rclone\rclone.conf` - Contiene tokens de autenticación
- Logs pueden contener información sensible

✅ **Seguros para compartir**:
- Todos los archivos del repositorio (sin credenciales reales)
- Reportes de caché (sin información de autenticación)

## 💡 Consejos de Uso

### Para administradores:
- **Backup**: `rclone.conf` debe respaldarse regularmente
- **Permisos**: Solo Administradores y usuario del servicio deben acceder a `C:\rclone\`
- **Monitoreo**: Revisar logs semanalmente o configurar alertas

### Para desarrollo:
- **Modular**: Cada script tiene una función específica
- **Reutilizable**: Templates permiten diferentes configuraciones
- **Documentado**: Cada función tiene comentarios explicativos

### Para troubleshooting:
- **Logs centralizados**: Todo en `C:\rclone\logs\`
- **Scripts de diagnóstico**: `test-mounts.ps1` para verificación completa
- **Información del sistema**: Incluida en reportes automáticos

Esta organización permite mantener un sistema ordenado, automatizado y fácil de mantener.