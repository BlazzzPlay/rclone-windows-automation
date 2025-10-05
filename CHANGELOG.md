# Changelog

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Versionado Semántico](https://semver.org/lang/es/).

## [Unreleased]

### Próximas funcionalidades
- Soporte para más proveedores de nube (Dropbox, Amazon S3)
- Interfaz web para gestión de servicios
- Configuración automática de Plex
- Soporte para múltiples usuarios

## [1.0.0] - 2025-10-05

### Agregado
- Instalación automática completa de Rclone, NSSM y WinFsp
- Scripts de configuración de servicios Windows optimizados
- Sistema de verificación y diagnóstico automático
- Gestión simplificada de servicios (start/stop/restart/status)
- Reporte automático semanal de caché con limpieza
- Configuración automática de tareas programadas
- Sistema de actualización automática de componentes
- Documentación completa y guías de troubleshooting
- Configuraciones optimizadas para diferentes casos de uso
- Soporte para Google Drive y OneDrive
- Configuraciones específicas para Plex streaming
- Configuraciones optimizadas para aplicaciones ARR
- Templates de configuración para diferentes proveedores
- Sistema de logs centralizado
- Comandos de referencia rápida

### Características técnicas
- Soporte completo para Windows 10/11
- Configuración automática de permisos de seguridad
- Montajes optimizados con VFS caching
- Gestión inteligente de ancho de banda
- Monitoreo automático de espacio en disco
- Rotación automática de logs
- Configuración de servicios con dependencias
- Manejo robusto de errores y recuperación

### Documentación
- Guía de instalación rápida (5 pasos)
- Documentación técnica completa
- Guía de solución de problemas
- Comandos de referencia rápida
- Ejemplos de configuración avanzada
- Índice completo de archivos
- Guía de contribución para la comunidad

### Scripts incluidos
- `install-components.ps1` - Instalación automática inicial
- `setup-services.ps1` - Configuración de servicios NSSM
- `test-mounts.ps1` - Verificación y diagnóstico del sistema
- `manage-services.ps1` - Gestión diaria de servicios
- `weekly-cache-report.ps1` - Reporte automático de caché
- `setup-scheduled-task.ps1` - Configuración de tareas programadas
- `update-components.ps1` - Actualización de componentes

### Configuraciones soportadas
- Streaming optimizado para Plex (4K y HD)
- Descarga activa para aplicaciones ARR (Radarr/Sonarr)
- Configuraciones por velocidad de conexión
- Configuraciones por espacio disponible en disco
- Soporte para diferentes proveedores de almacenamiento

## [0.9.0] - 2025-10-04

### Agregado
- Versión beta inicial
- Scripts básicos de configuración
- Documentación preliminar

---

## Tipos de cambios

- `Agregado` para nuevas funcionalidades
- `Cambiado` para cambios en funcionalidades existentes
- `Obsoleto` para funcionalidades que serán removidas pronto
- `Removido` para funcionalidades removidas
- `Arreglado` para cualquier corrección de bugs
- `Seguridad` en caso de vulnerabilidades