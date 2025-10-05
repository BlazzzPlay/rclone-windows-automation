# Contribuyendo a Rclone Windows Setup

¡Gracias por tu interés en contribuir! Este proyecto está abierto a contribuciones de la comunidad.

## 🚀 Formas de contribuir

### 🐛 Reportar bugs
- Usar el template de issues para bugs
- Incluir información del sistema (Windows version, logs, etc.)
- Proporcionar pasos claros para reproducir el problema

### 💡 Solicitar funcionalidades
- Usar el template de issues para feature requests
- Explicar el caso de uso y beneficios
- Considerar la compatibilidad con configuraciones existentes

### 📝 Mejorar documentación
- Corregir errores tipográficos
- Clarificar instrucciones confusas
- Agregar ejemplos de configuración
- Traducir a otros idiomas

### 🔧 Contribuir código
- Seguir las convenciones de PowerShell
- Mantener compatibilidad con Windows 10/11
- Incluir comentarios explicativos
- Probar en diferentes configuraciones

## 📋 Proceso de contribución

### 1. Fork y clone
```bash
git fork https://github.com/usuario/Rclone-Windows.git
git clone https://github.com/tu-usuario/Rclone-Windows.git
cd Rclone-Windows
```

### 2. Crear rama para tu cambio
```bash
git checkout -b feature/descripcion-del-cambio
# o
git checkout -b bugfix/descripcion-del-bug
```

### 3. Hacer cambios
- Mantener el estilo de código existente
- Agregar comentarios donde sea necesario
- Actualizar documentación si es relevante

### 4. Probar cambios
```powershell
# Probar scripts modificados
.\scripts\test-mounts.ps1

# Verificar que no se rompió funcionalidad existente
```

### 5. Commit y push
```bash
git add .
git commit -m "Descripción clara del cambio"
git push origin feature/descripcion-del-cambio
```

### 6. Crear Pull Request
- Usar template de PR
- Describir qué cambios se hicieron y por qué
- Referenciar issues relacionados

## 📏 Estándares de código

### PowerShell
```powershell
# Usar verb-noun para funciones
function Get-ServiceStatus { }

# Incluir help/comentarios
<#
.SYNOPSIS
Descripción breve de la función

.DESCRIPTION
Descripción detallada

.PARAMETER ParameterName
Descripción del parámetro

.EXAMPLE
Get-ServiceStatus -ServiceName "rclone-movies"
#>

# Manejo de errores
try {
    # código que puede fallar
} catch {
    Write-Error "Mensaje descriptivo: $($_.Exception.Message)"
}
```

### Documentación
```markdown
# Use títulos descriptivos
## Secciones bien organizadas
- Listas claras
- `Código` en bloques apropiados
```

## 🧪 Testing

### Antes de enviar PR
- [ ] Scripts ejecutan sin errores
- [ ] Funcionalidad existente no se rompe
- [ ] Documentación actualizada si es necesario
- [ ] Probado en al menos Windows 10 o 11

### Entornos de prueba
- **Mínimo**: Windows 10/11 con PowerShell 5.1+
- **Ideal**: Múltiples versiones de Windows
- **Configuraciones**: Diferentes proveedores de nube (Google Drive, OneDrive)

## 📝 Templates

### Issue Template (Bug)
```markdown
**Describe el bug**
Descripción clara del problema.

**Para reproducir**
Pasos para reproducir:
1. Ir a '...'
2. Hacer clic en '....'
3. Ver error

**Comportamiento esperado**
Qué debería pasar.

**Screenshots/Logs**
Si aplica, agregar logs de C:\rclone\logs\

**Información del sistema:**
- OS: [ej. Windows 11 22H2]
- PowerShell Version: [ej. 5.1]
- Rclone Version: [ej. 1.71.0]

**Configuración**
- Proveedor de nube: [Google Drive/OneDrive]
- Servicios configurados: [movies/series/arr]
```

### Issue Template (Feature Request)
```markdown
**¿Tu feature request está relacionado con un problema?**
Descripción clara de qué problema resuelve.

**Describe la solución que te gustaría**
Descripción clara de qué quieres que pase.

**Describe alternativas consideradas**
Otras formas de resolver el problema.

**Contexto adicional**
Cualquier otro contexto o screenshots.
```

## 🔍 Revisión de código

### Qué buscamos
- **Funcionalidad**: ¿Hace lo que dice que hace?
- **Compatibilidad**: ¿Funciona en diferentes versiones de Windows?
- **Estilo**: ¿Sigue las convenciones del proyecto?
- **Documentación**: ¿Está bien documentado?
- **Testing**: ¿Se probó adecuadamente?

### Proceso de revisión
1. Revisión automática (si hay CI/CD configurado)
2. Revisión manual por mantenedores
3. Feedback y solicitud de cambios si es necesario
4. Aprobación y merge

## 🏷️ Etiquetas de issues

- `bug` - Algo no funciona correctamente
- `enhancement` - Nueva funcionalidad o mejora
- `documentation` - Mejoras a documentación
- `good first issue` - Bueno para nuevos contribuidores
- `help wanted` - Ayuda extra bienvenida
- `question` - Pregunta sobre uso o configuración

## 🎯 Áreas donde ayuda es especialmente bienvenida

### 📚 Documentación
- Clarificar instrucciones confusas
- Agregar más ejemplos
- Crear videos tutoriales
- Traducir a otros idiomas

### 🧪 Testing
- Probar en diferentes configuraciones
- Validar en distintas versiones de Windows
- Verificar con diferentes proveedores de nube

### 🔧 Scripts
- Optimizar rendimiento
- Agregar más opciones de configuración
- Mejorar manejo de errores
- Agregar más checks de validación

### 🐛 Bug fixes
- Resolver issues reportados
- Mejorar robustez de scripts
- Manejar casos edge

## 📞 Contacto

- **Issues**: Para bugs y feature requests
- **Discussions**: Para preguntas generales y ideas
- **Pull Requests**: Para contribuciones de código

¡Gracias por ayudar a hacer este proyecto mejor para toda la comunidad!