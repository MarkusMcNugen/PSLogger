# PSLogger PowerShell Module

A comprehensive PowerShell logging module with automatic log rotation, compression, and flexible output options.

## Features

- **Multiple Log Levels**: INFO, WARNING, ERROR, CRITICAL, DEBUG, SUCCESS with color-coded console output
- **Automatic Log Rotation**: Based on file size or age
- **Log Compression**: Automatic zip archiving of rotated logs
- **Flexible Output**: Write to file, console, or both
- **Retry Mechanism**: Automatic retry on file write failures
- **Multiple Loggers**: Support for concurrent logger instances
- **Default Logger Protection**: Force parameter required to overwrite existing default logger
- **Pipeline Support**: Process multiple messages through the pipeline
- **Customizable Format**: Configure timestamp format, encoding, and log prefix elements
- **Module/Component Names**: Identify log sources in multi-component applications
- **Flexible Log Formatting**: Customize order of timestamp, level, and module name
- **Custom Brackets**: Define custom bracket characters for log elements

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

# Attempting to create another default logger without Force will fail
Initialize-Log -Default -LogName "AnotherApp"
# ERROR: A default logger has already been initialized. Use -Force parameter to overwrite...

# Use Force to overwrite the default logger
Initialize-Log -Default -LogName "AnotherApp" -Force
# WARNING: Overwriting existing default logger 'MyApplication' with new logger 'AnotherApp'

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

### Module Names for Component Identification

```powershell
# Create loggers with module names
$ApiLog = Initialize-Log -LogName "API" -ModuleName "WebAPI" -LogPath "C:\Logs"
$DbLog = Initialize-Log -LogName "Database" -ModuleName "DataAccess" -LogPath "C:\Logs"
$AuthLog = Initialize-Log -LogName "Security" -ModuleName "Authentication" -LogPath "C:\Logs"

# Logs include module names for easy identification
Write-Log "Request received" -Logger $ApiLog
# Output: [2025-08-15 16:13:06][INFO][WebAPI] Request received

Write-Log "Query executed" -Logger $DbLog
# Output: [2025-08-15 16:13:06][INFO][DataAccess] Query executed

Write-Log "User authenticated" -Logger $AuthLog
# Output: [2025-08-15 16:13:06][INFO][Authentication] User authenticated
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

# Custom log format order
$OrderedLog = Initialize-Log -LogName "Ordered" `
                             -LogFormat @('LEVEL', 'TIMESTAMP', 'MODULENAME') `
                             -ModuleName "Core"
# Output: [INFO][2025-08-15 16:13:06][Core] Message

# Minimal format with only level
$MinimalLog = Initialize-Log -LogName "Minimal" `
                             -LogFormat @('LEVEL')
# Output: [INFO] Message

# Custom brackets
$BraceLog = Initialize-Log -LogName "Braces" `
                           -LogBrackets "{}" `
                           -ModuleName "Engine"
# Output: {2025-08-15 16:13:06}{INFO}{Engine} Message

$ParenLog = Initialize-Log -LogName "Parens" `
                           -LogBrackets "()"
# Output: (2025-08-15 16:13:06)(INFO) Message

$PipeLog = Initialize-Log -LogName "Pipes" `
                          -LogBrackets "||"
# Output: |2025-08-15 16:13:06||INFO| Message
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
| ModuleName | Module/component name to include in logs | $null |
| LogFormat | Array defining order of log elements | @('TIMESTAMP', 'LEVEL', 'MODULENAME') |
| LogBrackets | Bracket characters for log elements (2 chars) | "[]" |
| Force | Required to overwrite existing default logger | False |

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

### Test Default Logger

```powershell
# Check if a default logger exists
if (Test-DefaultLogger) {
    Write-Log "Default logger is available"
} else {
    Initialize-Log -Default -LogName "MyApp"
    Write-Log "Default logger created"
}

# Prevent duplicate initialization
if (-not (Test-DefaultLogger)) {
    Initialize-Log -Default -LogName "Application"
}
```

## Examples

### Production Logging Setup

```powershell
# Initialize production logger with all features
Initialize-Log -Default `
               -LogName "Production" `
               -LogPath "D:\Logs\Application" `  # Explicitly set path for production
               -ModuleName "MainApp" `
               -LogLevel "INFO" `
               -LogRoll `
               -LogRotateOpt "100M" `
               -LogZip `
               -LogCountMax 10 `
               -Encoding "utf8"

# Log application events with module identification
Write-LogInfo "Application started at $(Get-Date)"
# Output: [2025-08-15 16:13:06][INFO][MainApp] Application started at ...

Write-LogSuccess "Database connection established"
# Output: [2025-08-15 16:13:06][SUCCESS][MainApp] Database connection established

Write-LogWarning "Memory usage above 80%"
# Output: [2025-08-15 16:13:06][WARNING][MainApp] Memory usage above 80%

Write-LogError "Failed to process request"
# Output: [2025-08-15 16:13:06][ERROR][MainApp] Failed to process request
```

### Development/Debug Setup

```powershell
# Initialize debug logger with console output
$Debug = Initialize-Log -LogName "Debug" `
                        -LogPath "$PSScriptRoot\Logs" `
                        -ModuleName "DevEnvironment" `
                        -WriteConsole `
                        -ConsoleInfo `
                        -LogLevel "DEBUG"

# Detailed debugging with module identification
Write-Log "Starting process..." -Logger $Debug
# Console and file: [2025-08-15 16:13:06][INFO][DevEnvironment] Starting process...

Write-Log "Variable X = $($SomeVariable)" -LogLevel "DEBUG" -Logger $Debug
# Console and file: [2025-08-15 16:13:06][DEBUG][DevEnvironment] Variable X = ...

Write-Log "Process completed" -LogLevel "SUCCESS" -Logger $Debug
# Console and file: [2025-08-15 16:13:06][SUCCESS][DevEnvironment] Process completed
```

### Multi-Component Application

```powershell
# Initialize different loggers for application components
$WebLogger = Initialize-Log -LogName "Web" `
                            -ModuleName "WebServer" `
                            -LogPath "C:\Logs\Web" `
                            -LogFormat @('TIMESTAMP', 'LEVEL', 'MODULENAME')

$ApiLogger = Initialize-Log -LogName "API" `
                            -ModuleName "RestAPI" `
                            -LogPath "C:\Logs\API" `
                            -LogFormat @('TIMESTAMP', 'LEVEL', 'MODULENAME')

$DbLogger = Initialize-Log -LogName "Database" `
                           -ModuleName "DataLayer" `
                           -LogPath "C:\Logs\DB" `
                           -LogFormat @('LEVEL', 'MODULENAME', 'TIMESTAMP') `
                           -LogBrackets "{}"

# Each component logs with its own identifier
Write-Log "HTTP request received" -Logger $WebLogger
# Output: [2025-08-15 16:13:06][INFO][WebServer] HTTP request received

Write-Log "API endpoint called: /users" -Logger $ApiLogger
# Output: [2025-08-15 16:13:06][INFO][RestAPI] API endpoint called: /users

Write-Log "Executing stored procedure" -Logger $DbLogger
# Output: {INFO}{DataLayer}{2025-08-15 16:13:06} Executing stored procedure
```

### Error Handling with Logging

```powershell
# Check if default logger exists before initializing
if (-not (Test-DefaultLogger)) {
    Initialize-Log -Default -LogName "Script"
}

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

### Safe Default Logger Replacement

```powershell
# Pattern 1: Check before overwriting
if (Test-DefaultLogger) {
    Write-Warning "Default logger already exists"
    # Must use Force to overwrite
    Initialize-Log -Default -LogName "NewLogger" -Force
} else {
    Initialize-Log -Default -LogName "NewLogger"
}

# Pattern 2: Always use Force in initialization scripts
function Initialize-ApplicationLogging {
    param([string]$AppName)
    
    # Force ensures this always works, even if called multiple times
    Initialize-Log -Default -LogName $AppName -ModuleName "Core" -Force
}

# Pattern 3: Interactive confirmation
if (Test-DefaultLogger) {
    $current = Get-LoggerInfo
    Write-Host "Current logger: $($current.LogName)"
    $response = Read-Host "Replace with new logger? (Y/N)"
    
    if ($response -eq 'Y') {
        Initialize-Log -Default -LogName "NewLogger" -Force
    }
}
```

## Best Practices

1. **Initialize Early**: Set up logging at the beginning of your script
2. **Check Before Initializing**: Use Test-DefaultLogger to avoid initialization errors
3. **Use Force Wisely**: Only use -Force when intentionally replacing the default logger
4. **Use Default Logger**: For simple scripts, use the default logger to avoid passing logger objects
5. **Appropriate Log Levels**: Use the correct log level for each message
6. **Include Context**: Add relevant information to log messages (timestamps, user, machine, etc.)
7. **Handle Errors**: Always log errors with full exception details
8. **Clean Up Old Logs**: Use rotation features to manage disk space
9. **Test Configuration**: Use Test-Logger to verify setup before production use
10. **Module Names**: Use ModuleName parameter for multi-component applications

## Troubleshooting

### Common Issues

1. **Default Logger Already Exists Error**
   - **Error**: "A default logger has already been initialized"
   - **Solution**: Use `-Force` parameter to overwrite: `Initialize-Log -Default -LogName "New" -Force`
   - **Prevention**: Check with `Test-DefaultLogger` before initializing

2. **Access Denied**: Ensure write permissions to log directory

3. **Path Not Found**: Logger creates directories automatically, but verify parent path exists

4. **Encoding Issues**: Use appropriate encoding for your environment

5. **Rotation Not Working**: Check LogRoll is enabled and LogRotateOpt is valid

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
- Log rotation by size and age
- Zip compression for archived logs
- Multiple logger support
- Console output options
- Convenience functions for each log level
- Module name support for component identification
- Customizable log format order (TIMESTAMP, LEVEL, MODULENAME)
- Configurable bracket characters for log elements
- Default log path changed to user temp directory
- Force parameter required to overwrite default logger

- Test-DefaultLogger function to check for existing default logger

