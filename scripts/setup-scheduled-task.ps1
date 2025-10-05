# Template para crear tarea programada del reporte semanal
# Ejecutar este script como Administrador para crear la tarea automáticamente

param(
    [string]$TaskName = "Rclone-Weekly-Cache-Report",
    [string]$ScriptPath = "C:\rclone\weekly-cache-report.ps1",
    [string]$LogPath = "C:\rclone\logs"
)

Write-Host "=== Configuración de Tarea Programada ===" -ForegroundColor Green

# Verificar que el script existe
if (!(Test-Path $ScriptPath)) {
    Write-Error "Script no encontrado: $ScriptPath"
    Write-Host "Copie weekly-cache-report.ps1 a la ubicación correcta" -ForegroundColor Yellow
    exit 1
}

# Verificar permisos de administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script requiere permisos de Administrador."
    exit 1
}

try {
    # Eliminar tarea existente si existe
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Eliminando tarea existente..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Crear nueva tarea programada
    Write-Host "Creando tarea programada: $TaskName" -ForegroundColor Cyan

    # Configurar acción (ejecutar PowerShell con el script)
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

    # Configurar trigger (todos los domingos a las 2:00 AM)
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "2:00AM"

    # Configurar settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

    # Configurar principal (ejecutar como SYSTEM)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Registrar la tarea
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Reporte semanal automático del caché de Rclone - Generado automáticamente"

    Write-Host "✅ Tarea programada creada exitosamente" -ForegroundColor Green
    Write-Host "Configuración:" -ForegroundColor Yellow
    Write-Host "  Nombre: $TaskName" -ForegroundColor White
    Write-Host "  Frecuencia: Todos los domingos a las 2:00 AM" -ForegroundColor White
    Write-Host "  Script: $ScriptPath" -ForegroundColor White
    Write-Host "  Usuario: SYSTEM" -ForegroundColor White

    # Mostrar la tarea creada
    $createdTask = Get-ScheduledTask -TaskName $TaskName
    Write-Host "`nDetalles de la tarea:" -ForegroundColor Yellow
    Write-Host "  Estado: $($createdTask.State)" -ForegroundColor White
    Write-Host "  Próxima ejecución: $((Get-ScheduledTask -TaskName $TaskName | Get-ScheduledTaskInfo).NextRunTime)" -ForegroundColor White

    # Preguntar si ejecutar una prueba
    $runTest = Read-Host "`n¿Ejecutar una prueba ahora? (S/N)"
    if ($runTest -match '^[Ss]$') {
        Write-Host "Ejecutando prueba..." -ForegroundColor Cyan
        Start-ScheduledTask -TaskName $TaskName
        
        # Esperar un momento y verificar resultado
        Start-Sleep -Seconds 5
        $taskInfo = Get-ScheduledTask -TaskName $TaskName | Get-ScheduledTaskInfo
        Write-Host "Última ejecución: $($taskInfo.LastRunTime)" -ForegroundColor White
        Write-Host "Resultado: $($taskInfo.LastTaskResult)" -ForegroundColor White
        
        if ($taskInfo.LastTaskResult -eq 0) {
            Write-Host "✅ Prueba exitosa" -ForegroundColor Green
        } else {
            Write-Host "❌ Error en la prueba (código: $($taskInfo.LastTaskResult))" -ForegroundColor Red
        }
    }

} catch {
    Write-Error "Error creando la tarea programada: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nComandos útiles:" -ForegroundColor Yellow
Write-Host "  Ver tarea: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
Write-Host "  Ejecutar manualmente: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
Write-Host "  Eliminar tarea: Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
Write-Host "  Ver historial: Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=200,201}" -ForegroundColor Cyan

Read-Host "`nPresione Enter para salir"