# PSLogger PowerShell Module

A comprehensive PowerShell logging module with automatic log rotation, compression, and flexible output options.

## Features

- **Multiple Log Levels**: INFO, WARNING, ERROR, CRITICAL, DEBUG, SUCCESS with color-coded console output
- **Automatic Log Rotation**: Based on file size or age
- **Log Compression**: Automatic zip archiving of rotated logs
- **Flexible Output**: Write to file, console, or both
- **Retry Mechanism**: Automatic retry on file write failures
- **Multiple Loggers**: Support for concurrent logger instances
- **Default Logger**: Set a default logger for simplified usage
- **Pipeline Support**: Process multiple messages through the pipeline
- **Customizable Format**: Configure timestamp format and encoding

## Installation

### Manual Installation
1. Download the module files
2. Copy to your PowerShell modules directory:
   ```powershell
   # Check module paths
   $env:PSModulePath -split ';'
   
   # Copy to user modules directory (example)
   Copy-Item -Path ".\PSLogger" -Destination "$HOME\Documents\PowerShell\Modules\" -Recurse
   ```
3. Import the module:
   ```powershell
   Import-Module PSLogger
   ```

## Quick Start

### Basic Usage with Default Logger

```powershell
# Import the module
Import-Module PSLogger

# Initialize a default logger
Initialize-Log -Default -LogName "MyApplication"

# Write messages to the log (will go to %TEMP%\MyApplication.log)
Write-Log "Application started"
Write-Log "Warning message" -LogLevel "WARNING"
Write-Log "Error occurred" -LogLevel "ERROR"

# Use convenience functions
Write-LogInfo "Information message"
Write-LogWarning "Warning message"
Write-LogError "Error message"
Write-LogCritical "Critical system failure"
Write-LogDebug "Debug information"
Write-LogSuccess "Operation completed"
```

### Multiple Logger Instances

```powershell
# Create multiple loggers for different purposes
$AppLog = Initialize-Log -LogName "Application" -LogPath "C:\Logs\App"
$ErrorLog = Initialize-Log -LogName "Errors" -LogPath "C:\Logs\Errors" -LogLevel "ERROR"
$DebugLog = Initialize-Log -LogName "Debug" -LogPath "C:\Logs\Debug" -WriteConsole

# Write to specific logs
Write-Log "App started" -Logger $AppLog
Write-Log "Critical error" -LogLevel "ERROR" -Logger $ErrorLog
Write-Log "Debug info" -LogLevel "DEBUG" -Logger $DebugLog
```

## Advanced Features

### Log Rotation by Size

```powershell
# Rotate when log reaches 10MB, keep 5 rotated files
$RotatingLog = Initialize-Log -LogName "Rotating" `
                              -LogRoll `
                              -LogRotateOpt "10M" `
                              -LogCountMax 5

Write-Log "This log will rotate at 10MB" -Logger $RotatingLog
```

### Log Rotation by Age

```powershell
# Rotate daily, archive to zip
$DailyLog = Initialize-Log -LogName "Daily" `
                           -LogRoll `
                           -LogRotateOpt "1" `
                           -LogZip

Write-Log "This log rotates daily and archives to zip" -Logger $DailyLog
```

### Console Output Options

```powershell
# Write to both console and file with timestamps
$ConsoleLog = Initialize-Log -LogName "Console" `
                             -WriteConsole `
                             -ConsoleInfo

# Write to console only (no file)
$ConsoleOnly = Initialize-Log -LogName "Display" `
                              -WriteConsole `
                              -ConsoleOnly

Write-Log "Visible in console and file" -Logger $ConsoleLog
Write-Log "Only in console" -Logger $ConsoleOnly
```

### Custom Formatting

```powershell
# Custom timestamp format
$CustomLog = Initialize-Log -LogName "Custom" `
                            -DateTimeFormat "MM/dd/yyyy HH:mm:ss"

# No timestamp/level in log entries
$CleanLog = Initialize-Log -LogName "Clean" `
                           -NoLogInfo

# UTF8 encoding
$Utf8Log = Initialize-Log -LogName "UTF8" `
                          -Encoding "utf8"
```

### Pipeline Support

```powershell
# Process multiple messages
@("Message 1", "Message 2", "Message 3") | Write-Log

# Process with specific log level
Get-Process | Select-Object -First 5 | ForEach-Object {
    $_.Name
} | Write-Log -LogLevel "DEBUG"
```

## Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| LogName | Name of the log file (without extension) | "Debug" |
| LogPath | Directory path for log files | User's temp directory ($env:TEMP) |
| LogLevel | Default log level | "INFO" |
| DateTimeFormat | Timestamp format string | "yyyy-MM-dd HH:mm:ss" |
| NoLogInfo | Omit timestamp and level from log entries | False |
| Encoding | Text encoding for log file | "Unicode" |
| LogRoll | Enable automatic log rotation | False |
| LogRotateOpt | Rotation trigger (size: "10M", "5G", "500K" or days: "7", "30") | "1M" |
| LogZip | Archive rotated logs to zip | True |
| LogCountMax | Maximum number of rotated log files | 5 |
| LogRetry | Number of write retry attempts | 2 |
| WriteConsole | Output to console | False |
| ConsoleOnly | Output to console only (no file) | False |
| ConsoleInfo | Include timestamp/level in console output | False |

## Log Levels

The module supports six log levels with color-coded console output:

| Level | Console Color | Usage |
|-------|---------------|-------|
| INFO | White | General information |
| WARNING | Yellow | Warning conditions |
| ERROR | Red | Error conditions |
| CRITICAL | Dark Red | System-critical failures |
| DEBUG | Cyan | Debug information |
| SUCCESS | Green | Successful operations |

## Utility Functions

### Get Logger Information

```powershell
# Get configuration details of a logger
Get-LoggerInfo
Get-LoggerInfo -Logger $AppLog
```

### Test Logger

```powershell
# Test if logger can write to its log file
Test-Logger
Test-Logger -Logger $AppLog -TestMessage "Custom test"
```

## Examples

### Production Logging Setup

```powershell
# Initialize production logger with all features
Initialize-Log -Default `
               -LogName "Production" `
               -LogPath "D:\Logs\Application" `  # Explicitly set path for production
               -LogLevel "INFO" `
               -LogRoll `
               -LogRotateOpt "100M" `
               -LogZip `
               -LogCountMax 10 `
               -Encoding "utf8"

# Log application events
Write-LogInfo "Application started at $(Get-Date)"
Write-LogSuccess "Database connection established"
Write-LogWarning "Memory usage above 80%"
Write-LogError "Failed to process request"
```

### Development/Debug Setup

```powershell
# Initialize debug logger with console output
$Debug = Initialize-Log -LogName "Debug" `
                        -LogPath "$PSScriptRoot\Logs" `
                        -WriteConsole `
                        -ConsoleInfo `
                        -LogLevel "DEBUG"

# Detailed debugging
Write-Log "Starting process..." -Logger $Debug
Write-Log "Variable X = $($SomeVariable)" -LogLevel "DEBUG" -Logger $Debug
Write-Log "Process completed" -LogLevel "SUCCESS" -Logger $Debug
```

### Error Handling with Logging

```powershell
Initialize-Log -Default -LogName "Script"

Try {
    Write-LogInfo "Attempting operation..."
    # Your code here
    Throw "Simulated error"
}
Catch {
    Write-LogError "Operation failed: $_"
    Write-LogDebug "Stack trace: $($_.ScriptStackTrace)"
}
Finally {
    Write-LogInfo "Cleanup completed"
}
```

## Best Practices

1. **Initialize Early**: Set up logging at the beginning of your script
2. **Use Default Logger**: For simple scripts, use the default logger to avoid passing logger objects
3. **Appropriate Log Levels**: Use the correct log level for each message
4. **Include Context**: Add relevant information to log messages (timestamps, user, machine, etc.)
5. **Handle Errors**: Always log errors with full exception details
6. **Clean Up Old Logs**: Use rotation features to manage disk space
7. **Test Configuration**: Use Test-Logger to verify setup before production use

## Troubleshooting

### Common Issues

1. **Access Denied**: Ensure write permissions to log directory
2. **Path Not Found**: Logger creates directories automatically, but verify parent path exists
3. **Encoding Issues**: Use appropriate encoding for your environment
4. **Rotation Not Working**: Check LogRoll is enabled and LogRotateOpt is valid

### Debug Mode

```powershell
# Enable verbose output for troubleshooting
$VerbosePreference = "Continue"
Initialize-Log -Default -LogName "Test"
Test-Logger
```

## Requirements

- PowerShell 5.0 or higher
- Windows operating system (for compression features)
- Write permissions to log directory

## License

Copyright (c) 2025 Mark Newton. All rights reserved.

## Author

**Mark Newton**  
Created: August 15, 2025  
Version: 1.0.0

## Contributing

Contributions are welcome! Please submit issues and pull requests on the project repository.

## Changelog

### Version 1.0.0 (2025-08-15)
- Initial release
- Core logging functionality
- Six log levels (INFO, WARNING, ERROR, CRITICAL, DEBUG, SUCCESS)
- Log rotation and compression
- Multiple logger support
- Console output options
- Convenience functions for each log level
