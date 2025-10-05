# Guía de Seguridad

## 🔒 Información Sensible

### ⚠️ NUNCA compartir estos archivos:

- `C:\rclone\rclone.conf` - Contiene tokens de autenticación OAuth
- Logs con información de depuración que puedan incluir tokens
- Archivos de respaldo que contengan credenciales

### ✅ Archivos seguros para compartir:

- Todos los scripts y documentación de este repositorio
- Logs sin información de autenticación
- Configuraciones de ejemplo (templates)

## 🔐 Mejores Prácticas de Seguridad

### Protección de credenciales:

1. **Permisos de archivo**:
   ```powershell
   # Solo Administradores y usuario del servicio deben acceder
   icacls C:\rclone\rclone.conf /inheritance:d
   icacls C:\rclone\rclone.conf /grant:r "Administradores:(F)"
   icacls C:\rclone\rclone.conf /grant:r "SYSTEM:(F)"
   ```

2. **Backup seguro**:
   ```powershell
   # Respaldar configuración sin credenciales (para documentación)
   C:\rclone\rclone.exe config show --obscure > config-backup-safe.txt
   
   # Backup completo (mantener en lugar seguro)
   Copy-Item C:\rclone\rclone.conf "\\servidor-backup\rclone\rclone.conf.$(Get-Date -Format 'yyyy-MM-dd')"
   ```

3. **Rotación de tokens**:
   - Rotar credenciales OAuth periódicamente
   - Monitorear uso de API en consolas de desarrollador
   - Revocar acceso de aplicaciones no utilizadas

### Configuración de firewall:

```powershell
# Solo permitir tráfico necesario
# Puerto 32400 para Plex (si se accede remotamente)
New-NetFirewallRule -DisplayName "Plex Media Server" -Direction Inbound -Protocol TCP -LocalPort 32400 -Action Allow

# Puerto 3389 para RDP (si se requiere acceso remoto)
# Configurar solo si es necesario y con autenticación fuerte
```

### Monitoreo de seguridad:

1. **Revisar logs regularmente**:
   ```powershell
   # Buscar intentos de acceso no autorizados
   Get-EventLog -LogName Security -InstanceId 4625 -Newest 50
   
   # Revisar errores de autenticación en Rclone
   Select-String -Path "C:\rclone\logs\*.log" -Pattern "401|403|authentication"
   ```

2. **Monitorear uso de API**:
   - Revisar métricas en Google Cloud Console
   - Verificar patrones de uso inusuales
   - Configurar alertas de cuota si están disponibles

### Actualizaciones de seguridad:

- Mantener Windows actualizado
- Actualizar Rclone regularmente usando `update-components.ps1`
- Revisar advisories de seguridad de componentes utilizados

## 🚨 En caso de compromiso

### Si sospechas que las credenciales fueron comprometidas:

1. **Acción inmediata**:
   ```powershell
   # Detener todos los servicios
   Get-Service rclone-* | Stop-Service -Force
   ```

2. **Revocar acceso**:
   - Ir a Google Cloud Console o Azure AD
   - Revocar tokens de la aplicación
   - Cambiar credenciales OAuth

3. **Reconfigurar**:
   ```powershell
   # Eliminar configuración comprometida
   Remove-Item C:\rclone\rclone.conf -Force
   
   # Reconfigurar desde cero
   C:\rclone\rclone.exe config
   ```

4. **Verificar integridad**:
   - Revisar logs de acceso en el proveedor de nube
   - Verificar que no se hayan modificado archivos
   - Comprobar patrones de tráfico inusuales

### Reportar vulnerabilidades:

Si encuentras una vulnerabilidad de seguridad en este proyecto:

1. **NO** abras un issue público
2. Envía un email a los mantenedores (ver CONTRIBUTING.md)
3. Incluye detalles técnicos y pasos para reproducir
4. Permite tiempo razonable para corrección antes de divulgación

## 📋 Checklist de Seguridad

### Durante la instalación:
- [ ] Ejecutar solo con permisos de Administrador necesarios
- [ ] Verificar integridad de archivos descargados
- [ ] Configurar permisos restrictivos en `C:\rclone\`
- [ ] Usar credenciales OAuth específicas para esta aplicación

### Configuración operativa:
- [ ] Servicios ejecutándose con usuario de menor privilegio posible
- [ ] Logs configurados sin información sensible
- [ ] Firewall configurado apropiadamente
- [ ] Backup de configuración en lugar seguro

### Mantenimiento:
- [ ] Revisión periódica de logs de seguridad
- [ ] Actualización de componentes
- [ ] Rotación de credenciales según política
- [ ] Monitoreo de uso de recursos en proveedor de nube

Esta guía debe actualizarse conforme evolucionan las mejores prácticas de seguridad.