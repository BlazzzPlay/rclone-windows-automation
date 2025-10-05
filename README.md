# Rclone Windows Setup - Plex Media Server

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue.svg)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)

Configuración automatizada para servidor Plex con almacenamiento en la nube usando Rclone en Windows.

## 🚀 Características

- ✅ **Instalación completamente automatizada** de Rclone, NSSM y WinFsp
- ✅ **Configuración optimizada** para streaming con Plex Media Server
- ✅ **Servicios Windows** configurados automáticamente con NSSM
- ✅ **Monitoreo y reportes** automáticos de caché y uso
- ✅ **Scripts de mantenimiento** y actualización
- ✅ **Documentación completa** y guías de solución de problemas

## 📋 Requisitos

### Sistema
- **Windows 10/11** (recomendado 22H2 o superior)
- **8GB RAM mínimo** (16GB+ recomendado)
- **200GB espacio libre** (500GB+ recomendado)
- **Permisos de Administrador**

### Red
- **Conexión estable a Internet** (20+ Mbps recomendado)
- **Acceso a puertos**: 32400 (Plex), 3389 (RDP opcional)

### Almacenamiento en la nube
- **Google Drive** o **OneDrive** con espacio suficiente
- **Credenciales configuradas** (Client ID, Secret, etc.)

## ⚡ Instalación Rápida (5 pasos)

### 1. Descargar repositorio
```powershell
# Opción A: Con Git
git clone https://github.com/usuario/Rclone-Windows.git C:\setup-rclone

# Opción B: Descarga manual
# Descargar ZIP desde GitHub y extraer a C:\setup-rclone
```

### 2. Verificar sistema (opcional pero recomendado)
```powershell
# Abrir PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
cd C:\setup-rclone\scripts
.\verify-system.ps1
```

### 3. Ejecutar instalación automática
```powershell
.\install-components.ps1
```

### 4. Configurar credenciales de la nube
```powershell
# Configurar remotos (Google Drive/OneDrive)
C:\rclone\rclone.exe config
```

### 5. Crear servicios Windows
```powershell
.\setup-services.ps1
```

### 6. Verificar funcionamiento
```powershell
.\test-mounts.ps1
```

## 📖 Documentación

- 📚 [**Guía Completa de Configuración**](documentation/Setup-Guide.md)
- 🔧 [**Solución de Problemas**](documentation/Troubleshooting.md)
- ⚡ [**Comandos de Referencia Rápida**](documentation/Quick-Reference.md)
- 📁 [**Índice de Archivos**](documentation/FILES-INDEX.md)

## 🛠️ Scripts Incluidos

| Script | Función |
|--------|---------|
| `verify-system.ps1` | Verificación de requisitos del sistema |
| `install-components.ps1` | Instalación automática de todos los componentes |
| `setup-services.ps1` | Configuración de servicios Windows con NSSM |
| `test-mounts.ps1` | Verificación y diagnóstico del sistema |
| `manage-services.ps1` | Gestión diaria de servicios (start/stop/status) |
| `weekly-cache-report.ps1` | Reporte automático y limpieza de caché |
| `setup-scheduled-task.ps1` | Configurar tareas programadas |
| `update-components.ps1` | Actualización automática de componentes |

## � Casos de Uso

### Streaming optimizado (Plex)
- Configuración para reproducción 4K fluida
- Caché inteligente para acceso rápido
- Límites de ancho de banda configurables

### Aplicaciones ARR
- Configuración específica para Radarr/Sonarr
- Modo de escritura optimizado
- Sincronización bidireccional

### Servidores domésticos
- Configuración de bajo consumo
- Monitoreo automático
- Mantenimiento programado

## 📊 Configuraciones Incluidas

### Por tipo de contenido:
- **Películas**: Optimizado para archivos grandes y streaming
- **Series**: Configuración balanceada para episodios
- **Descargas**: Modo de escritura para aplicaciones ARR

### Por velocidad de conexión:
- **Alta velocidad** (>100 Mbps): Configuración agresiva
- **Velocidad media** (25-100 Mbps): Configuración balanceada  
- **Velocidad baja** (<25 Mbps): Configuración conservadora

## 🤝 Contribuir

Las contribuciones son bienvenidas! Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## � Reportar Issues

Si encuentras algún problema:

1. Verifica la [documentación de troubleshooting](documentation/Troubleshooting.md)
2. Busca en issues existentes
3. Si no encuentras solución, crea un nuevo issue con:
   - Versión de Windows
   - Logs relevantes (`C:\rclone\logs\`)
   - Pasos para reproducir el problema

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## ⭐ Agradecimientos

- [Rclone](https://rclone.org/) - Herramienta principal de sincronización
- [NSSM](https://nssm.cc/) - Non-Sucking Service Manager
- [WinFsp](https://winfsp.dev/) - Sistema de archivos para Windows
- [Plex](https://www.plex.tv/) - Servidor multimedia

## � Estado del Proyecto

- ✅ **Estable**: Probado en múltiples configuraciones
- 🔄 **Activamente mantenido**: Actualizaciones regulares
- 📚 **Bien documentado**: Guías completas incluidas
- 🧪 **Probado**: Scripts de verificación incluidos

---

**⚠️ Importante**: Este proyecto no está afiliado con Rclone, Plex, Microsoft o los desarrolladores de las herramientas utilizadas. Es un proyecto de la comunidad para facilitar la configuración.