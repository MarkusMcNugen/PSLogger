# PSLogger Helper Functions Reference

Comprehensive documentation for PSLogger module helper and convenience functions. These functions provide an intuitive interface for creating, configuring, and managing sophisticated logging infrastructure in PowerShell scripts.

## Table of Contents

- [Core Logger Management](#core-logger-management)
  - [New-Logger](#new-logger)
  - [Get-Logger](#get-logger)
  - [Set-DefaultLogger](#set-defaultlogger)
  - [Get-DefaultLogger](#get-defaultlogger)
- [Handler Management](#handler-management)
  - [Add-LogHandler](#add-loghandler)
  - [New-FileHandler](#new-filehandler)
  - [New-ConsoleHandler](#new-consolehandler)
  - [New-EventLogHandler](#new-eventloghandler)
  - [New-NullHandler](#new-nullhandler)
- [Enricher Management](#enricher-management)
  - [Add-LogEnricher](#add-logenricher)
  - [New-MachineEnricher](#new-machineenricher)
  - [New-ProcessEnricher](#new-processenricher)
  - [New-ThreadEnricher](#new-threadenricher)
  - [New-EnvironmentEnricher](#new-environmentenricher)
  - [New-NetworkEnricher](#new-networkenricher)
- [Filter Management](#filter-management)
  - [Add-LogFilter](#add-logfilter)
  - [New-FunctionFilter](#new-functionfilter)
  - [New-TimeFilter](#new-timefilter)
  - [New-UserFilter](#new-userfilter)
- [Scoped Properties](#scoped-properties)
  - [Start-LogScope](#start-logscope)

---

# Core Logger Management

## New-Logger

### Synopsis
Creates a new Logger instance with specified configuration settings.

### Syntax
```powershell
New-Logger [-LogName <String>] [-LogPath <String>] [-LogLevel <String>]
    [-LogRoll] [-LogRotateOpt <String>] [-LogZip] [-LogCountMax <Int32>]
    [-WriteConsole] [-ConsoleOnly] [-ModuleName <String>]
```

### Description
New-Logger is a wrapper around Initialize-Log that provides a more intuitive function name for creating logger instances. It returns a configured Logger object that can be used with Write-Log and related functions.

This function is ideal for scenarios where you need multiple logger instances or want to explicitly manage logger objects without setting a script-wide default.

### Parameters

#### -LogName
- **Type**: String
- **Required**: No
- **Default**: "Debug"
- **Description**: Name of the log file (without extension). The .log extension is automatically appended.

#### -LogPath
- **Type**: String
- **Required**: No
- **Default**: "C:\Temp"
- **Description**: Directory path where log files will be created. Directory is created if it doesn't exist.

#### -LogLevel
- **Type**: String
- **Required**: No
- **Default**: "INFO"
- **Valid Values**: INFO, WARNING, ERROR, DEBUG, SUCCESS, CRITICAL
- **Description**: Default logging level for the logger.

#### -LogRoll
- **Type**: Switch
- **Required**: No
- **Default**: $false
- **Description**: Enable automatic log rotation based on size or age.

#### -LogRotateOpt
- **Type**: String
- **Required**: No
- **Default**: "1M"
- **Description**: Rotation threshold. Format: "10M" (10MB), "100M", "1G" (size-based) or "7" (days-based).

#### -LogZip
- **Type**: Switch
- **Required**: No
- **Default**: $false
- **Description**: Enable compression of rotated logs into zip archives.

#### -LogCountMax
- **Type**: Int32
- **Required**: No
- **Default**: 5
- **Description**: Maximum number of rotated log files to keep. Oldest logs are deleted when exceeded.

#### -WriteConsole
- **Type**: Switch
- **Required**: No
- **Default**: $false
- **Description**: Enable output to console in addition to file logging.

#### -ConsoleOnly
- **Type**: Switch
- **Required**: No
- **Default**: $false
- **Description**: Output only to console, do not create log files.

#### -ModuleName
- **Type**: String
- **Required**: No
- **Default**: $null
- **Description**: Module or component name to include in log entries for identification.

### Examples

#### Example 1: Create a Simple Logger
```powershell
# Create a basic logger for an application
$log = New-Logger -LogName "Application" -LogPath "C:\Logs"
Write-Log "Application started" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Application started
```

**Explanation:** Creates a logger named "Application" that writes to C:\Logs\Application.log with default settings.

#### Example 2: Logger with Rotation and Compression
```powershell
# Create production logger with rotation and compression
$log = New-Logger -LogName "Production" -LogPath "D:\Logs" `
    -LogRoll -LogRotateOpt "50M" -LogZip -LogCountMax 10

Write-Log "Production service started" -Logger $log
```

**Explanation:** Creates a logger that rotates when the log file reaches 50MB, compresses rotated logs, and keeps the last 10 rotated archives.

#### Example 3: Console-Only Logger for Interactive Scripts
```powershell
# Interactive debugging logger
$log = New-Logger -LogName "Interactive" -WriteConsole -ConsoleOnly
Write-Log "This appears only in console" -Logger $log
Write-LogDebug "Debug information" -Logger $log
```

**Explanation:** Creates a logger that outputs only to the console without creating any log files. Useful for interactive scripts and debugging.

#### Example 4: Multiple Loggers for Different Components
```powershell
# Create separate loggers for different application layers
$webLog = New-Logger -LogName "WebAPI" -LogPath "C:\Logs" -ModuleName "WebAPI"
$dbLog = New-Logger -LogName "Database" -LogPath "C:\Logs" -ModuleName "DataLayer"
$authLog = New-Logger -LogName "Authentication" -LogPath "C:\Logs" -ModuleName "Auth"

Write-Log "API request received: GET /users" -Logger $webLog
Write-Log "Database query executed: SELECT * FROM Users" -Logger $dbLog
Write-Log "User authentication successful: user@example.com" -Logger $authLog
```

**Explanation:** Creates separate logger instances for different application components, allowing independent configuration and log file separation.

### Notes
- This is a convenience wrapper around Initialize-Log with a more intuitive name.
- Use Set-DefaultLogger if you want to set a logger as the script-wide default.
- The logger instance must be passed to Write-Log unless set as default.

### Related Functions
- [Set-DefaultLogger](#set-defaultlogger)
- [Get-Logger](#get-logger)
- [Get-DefaultLogger](#get-defaultlogger)

---

## Get-Logger

### Synopsis
Retrieves the default logger or creates one if none exists.

### Syntax
```powershell
Get-Logger [-EnsureExists <Boolean>]
```

### Description
Get-Logger provides a safe way to retrieve the current default logger instance. If no default logger has been initialized, it creates a new one with default settings and sets it as the default. This ensures that logging functions always have a logger to work with.

This is particularly useful in modules or scripts where you want to ensure a logger exists without explicitly checking every time.

### Parameters

#### -EnsureExists
- **Type**: Boolean
- **Required**: No
- **Default**: $true
- **Description**: If $true, creates a default logger if one doesn't exist. If $false and no default logger exists, returns $null.

### Examples

#### Example 1: Get or Create Default Logger
```powershell
# Ensures a logger exists before using it
$log = Get-Logger
Write-Log "Application started" -Logger $log
```

**Explanation:** Retrieves the default logger if one exists, or creates a new default logger with standard settings (LogName: "Debug", LogPath: "C:\Temp").

#### Example 2: Check for Logger Without Creating One
```powershell
# Check if default logger exists without auto-creating
$log = Get-Logger -EnsureExists:$false
if ($log) {
    Write-Log "Using existing logger" -Logger $log
} else {
    Write-Host "No logger initialized - configure one first"
}
```

**Explanation:** Checks for an existing default logger without creating one automatically, allowing conditional logic based on logger existence.

#### Example 3: Use in Function that Needs Logging
```powershell
function Process-Data {
    param($Data)

    # Ensure logger exists
    $log = Get-Logger

    Write-Log "Processing data batch: $($Data.Count) items" -Logger $log

    foreach ($item in $Data) {
        Write-LogDebug "Processing item: $($item.Id)" -Logger $log
        # ... processing logic ...
    }

    Write-Log "Data processing complete" -Logger $log
}
```

**Explanation:** Function automatically retrieves or creates a logger, ensuring logging is always available without explicit initialization in every function call.

### Notes
- If EnsureExists is $true (default) and no logger exists, creates a logger with LogName: "Debug", LogPath: "C:\Temp", LogLevel: "INFO"
- Returns $null if EnsureExists is $false and no default logger is set
- Useful for library functions that need optional logging

### Related Functions
- [Set-DefaultLogger](#set-defaultlogger)
- [New-Logger](#new-logger)
- [Get-DefaultLogger](#get-defaultlogger)

---

## Set-DefaultLogger

### Synopsis
Sets a logger instance as the script-wide default logger.

### Syntax
```powershell
Set-DefaultLogger -Logger <Logger>
```

### Description
Set-DefaultLogger configures a Logger instance as the default logger for the current script or module scope. Once set, all Write-Log* functions will use this logger by default unless a different logger is explicitly specified.

This is useful when you create a logger with specific settings and want to use it throughout your script without passing it to every logging call.

### Parameters

#### -Logger
- **Type**: Logger
- **Required**: Yes
- **Pipeline**: Accepts Logger instances via pipeline
- **Description**: The Logger instance to set as default. Must be a valid Logger object created by Initialize-Log or New-Logger.

### Examples

#### Example 1: Create and Set Default Logger
```powershell
# Create a logger and set it as default
$log = New-Logger -LogName "Application" -LogPath "C:\Logs" -LogRoll
Set-DefaultLogger -Logger $log

# Now all Write-Log calls use this logger by default
Write-Log "Application started"
Write-LogInfo "Processing data"
Write-LogError "An error occurred"
```

**Explanation:** After setting the default logger, all logging functions can be called without the -Logger parameter.

#### Example 2: Pipeline Usage
```powershell
# Create and set default logger in one line
New-Logger -LogName "Production" -LogPath "D:\Logs" -LogRoll -LogZip | Set-DefaultLogger

Write-Log "Production script started"
Write-LogInfo "Configuration loaded"
```

**Explanation:** Uses pipeline to create a logger and immediately set it as default in a single command chain.

#### Example 3: Switch Default Logger During Execution
```powershell
# Create two loggers with different configurations
$normalLog = New-Logger -LogName "Normal" -LogPath "C:\Logs"
$debugLog = New-Logger -LogName "Debug" -LogPath "C:\Logs" -LogLevel "DEBUG" -WriteConsole

# Start with normal logging
Set-DefaultLogger -Logger $normalLog
Write-Log "Normal operation mode"

# Switch to debug mode for troubleshooting
Set-DefaultLogger -Logger $debugLog
Write-LogDebug "Debug information: Variable state = $state"
Write-LogDebug "Debug information: Stack trace available"

# Switch back to normal mode
Set-DefaultLogger -Logger $normalLog
Write-Log "Resumed normal operation"
```

**Explanation:** Demonstrates switching between different logger configurations during script execution, useful for dynamic log level changes or conditional verbose output.

#### Example 4: Module Initialization Pattern
```powershell
# Module initialization script
$script:ModuleLogger = New-Logger -LogName "MyModule" -LogPath "$PSScriptRoot\Logs" `
    -LogRoll -LogRotateOpt "10M" -LogCountMax 5
Set-DefaultLogger -Logger $script:ModuleLogger

# Module functions automatically use this logger
function Get-ModuleData {
    Write-Log "Retrieving module data"
    # ... function logic ...
}

function Set-ModuleConfig {
    Write-Log "Updating module configuration"
    # ... function logic ...
}
```

**Explanation:** Common pattern for module-wide logging where all module functions share a single logger configuration.

### Notes
- The default logger is stored in $Script:DefaultLog and persists for the script scope
- Module functions can use Get-Logger to retrieve the default logger
- Only one logger can be the default at a time

### Related Functions
- [Get-DefaultLogger](#get-defaultlogger)
- [Get-Logger](#get-logger)
- [New-Logger](#new-logger)

---

## Get-DefaultLogger

### Synopsis
Returns the current default logger instance.

### Syntax
```powershell
Get-DefaultLogger
```

### Description
Get-DefaultLogger retrieves the logger that has been set as the script-wide default using Initialize-Log -Default or Set-DefaultLogger. If no default logger has been configured, returns $null.

This function is useful for checking whether a default logger exists before using logging functions, or for retrieving the default logger to inspect its configuration.

### Examples

#### Example 1: Check if Default Logger Exists
```powershell
# Verify default logger configuration
$log = Get-DefaultLogger
if ($log) {
    Write-Host "Default logger: $($log.LogName) at $($log.LogPath)"
} else {
    Write-Host "No default logger configured"
}
```

**Output:**
```
Default logger: Application at C:\Logs
```

**Explanation:** Retrieves and displays information about the default logger, or notifies if none is configured.

#### Example 2: Inspect Logger Configuration
```powershell
# Get detailed logger information
$log = Get-DefaultLogger
if ($log) {
    Write-Host "Logger Configuration:"
    Write-Host "  Name: $($log.LogName)"
    Write-Host "  Path: $($log.LogPath)"
    Write-Host "  Level: $($log.LogLevel)"
    Write-Host "  Rotation: $($log.LogRoll)"
    Write-Host "  Compression: $($log.LogZip)"
}
```

**Output:**
```
Logger Configuration:
  Name: Production
  Path: D:\Logs
  Level: INFO
  Rotation: True
  Compression: True
```

**Explanation:** Inspects the default logger's configuration properties for debugging or reporting purposes.

#### Example 3: Verify Logger Before Script Execution
```powershell
# Ensure logger is initialized before continuing
if (-not (Get-DefaultLogger)) {
    Write-Error "No default logger configured. Initialize with Initialize-Log -Default"
    exit 1
}

Write-Log "Script starting - logger verified"
# ... script logic ...
```

**Explanation:** Validates that a default logger exists before proceeding with script execution, preventing logging failures.

#### Example 4: Conditional Logger Creation
```powershell
# Use existing logger or create new one
$log = Get-DefaultLogger
if (-not $log) {
    Write-Verbose "No default logger found, creating one"
    $log = New-Logger -LogName "AutoCreated" -LogPath "C:\Temp"
    Set-DefaultLogger -Logger $log
}

Write-Log "Logging initialized" -Logger $log
```

**Explanation:** Implements lazy logger initialization - creates logger only if one doesn't already exist.

### Notes
- Returns $null if no default logger has been set
- Use Get-Logger -EnsureExists to automatically create a default logger if none exists
- Does not modify or create any logger instances

### Related Functions
- [Set-DefaultLogger](#set-defaultlogger)
- [Get-Logger](#get-logger)
- [New-Logger](#new-logger)

---

# Handler Management

## Add-LogHandler

### Synopsis
Adds a log handler to a logger for custom output destinations.

### Syntax
```powershell
Add-LogHandler [-Logger <Logger>] -Handler <LogHandler>
```

### Description
Add-LogHandler attaches a handler object to a logger instance. Handlers define where and how log messages are written. Multiple handlers can be added to support writing to multiple destinations simultaneously (e.g., file, console, Windows Event Log, database, API).

The Logger class supports FileHandler, ConsoleHandler, EventLogHandler, and custom handlers.

### Parameters

#### -Logger
- **Type**: Logger
- **Required**: No
- **Default**: $Script:DefaultLog
- **Pipeline**: Accepts Logger instances via pipeline
- **Description**: The Logger instance to add the handler to. If not specified, uses the default logger.

#### -Handler
- **Type**: LogHandler
- **Required**: Yes
- **Description**: The handler object to add. Must inherit from LogHandler base class. Can be created using New-*Handler functions or custom handlers.

### Examples

#### Example 1: Add Console Handler to File Logger
```powershell
# Create file logger and add console output
$log = New-Logger -LogName "Application" -LogPath "C:\Logs"
$consoleHandler = New-ConsoleHandler
Add-LogHandler -Logger $log -Handler $consoleHandler

Write-Log "Appears in both file and console" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Appears in both file and console
```
(Written to both C:\Logs\Application.log and console)

**Explanation:** Adds console output to a file-based logger, enabling dual output destinations.

#### Example 2: Add Windows Event Log Handler
```powershell
# Log to both file and Windows Event Log
$log = New-Logger -LogName "Production" -LogPath "D:\Logs"
$eventHandler = New-EventLogHandler -LogName "Application" -Source "MyApp"
Add-LogHandler -Logger $log -Handler $eventHandler

Write-LogError "Critical error occurred" -Logger $log
```

**Explanation:** Errors are written to both the log file and Windows Event Log for centralized monitoring.

#### Example 3: Multiple Handlers for Different Destinations
```powershell
# Create comprehensive logging with multiple outputs
$log = New-Logger -LogName "MultiTarget" -LogPath "C:\Logs"

Add-LogHandler -Logger $log -Handler (New-FileHandler -Path "C:\Logs\app.log")
Add-LogHandler -Logger $log -Handler (New-ConsoleHandler)
Add-LogHandler -Logger $log -Handler (New-EventLogHandler -LogName "Application" -Source "App")

Write-Log "Written to file, console, and event log" -Logger $log
```

**Explanation:** Single log entry is written to three different destinations simultaneously.

#### Example 4: Pipeline Usage
```powershell
# Add handler via pipeline
$log = New-Logger -LogName "Pipeline" -LogPath "C:\Logs"
$log | Add-LogHandler -Handler (New-ConsoleHandler)

Write-Log "Handler added via pipeline" -Logger $log
```

**Explanation:** Uses pipeline to add handler in a fluent style.

#### Example 5: Separate Handlers for Different Log Levels
```powershell
# Create custom handler configuration
$log = New-Logger -LogName "LevelBased" -LogPath "C:\Logs"

# Main log file gets everything
Add-LogHandler -Logger $log -Handler (New-FileHandler -Path "C:\Logs\all.log")

# Error log file gets only errors (would need custom handler with level filtering)
# Console gets everything for interactive monitoring
Add-LogHandler -Logger $log -Handler (New-ConsoleHandler)

Write-LogInfo "Informational message"
Write-LogError "Error message"
```

**Explanation:** Demonstrates adding multiple handlers with different purposes (comprehensive file log + console monitoring).

### Notes
- Handlers are invoked in the order they are added
- Each handler processes every log entry independently
- Use NullHandler to disable output without removing logger functionality
- Custom handlers can be created by inheriting from LogHandler base class

### Related Functions
- [New-FileHandler](#new-filehandler)
- [New-ConsoleHandler](#new-consolehandler)
- [New-EventLogHandler](#new-eventloghandler)
- [New-NullHandler](#new-nullhandler)

---

## New-FileHandler

### Synopsis
Creates a new FileHandler for writing logs to a file.

### Syntax
```powershell
New-FileHandler -Path <String> [-Encoding <String>]
```

### Description
New-FileHandler creates a LogHandler that writes log entries to a specified file path. This handler can be added to a logger using Add-LogHandler to enable file-based logging with custom file locations separate from the logger's default log file.

### Parameters

#### -Path
- **Type**: String
- **Required**: Yes
- **Description**: The full path to the log file where entries will be written.

#### -Encoding
- **Type**: String
- **Required**: No
- **Default**: "Unicode"
- **Valid Values**: Unicode, UTF7, UTF8, UTF32, ASCII, BigEndianUnicode, Default, OEM
- **Description**: The file encoding to use for writing log entries.

### Examples

#### Example 1: Create File Handler
```powershell
# Create logger with custom file handler
$log = New-Logger -LogName "Application" -LogPath "C:\Logs"
$fileHandler = New-FileHandler -Path "C:\Logs\custom.log"
Add-LogHandler -Logger $log -Handler $fileHandler

Write-Log "Written to custom.log" -Logger $log
```

**Explanation:** Creates a file handler that writes to a specific log file separate from the logger's default file.

#### Example 2: Multiple File Handlers for Log Separation
```powershell
# Separate error logs from info logs
$log = New-Logger -LogName "MultiFile" -LogPath "C:\Logs"

$errorHandler = New-FileHandler -Path "C:\Logs\errors.log"
$infoHandler = New-FileHandler -Path "C:\Logs\info.log"

Add-LogHandler -Logger $log -Handler $errorHandler
Add-LogHandler -Logger $log -Handler $infoHandler

Write-LogError "Error message"  # Written to both files
Write-LogInfo "Info message"    # Written to both files
```

**Explanation:** Creates multiple file handlers writing to different files (note: both handlers write all messages; use filters to restrict by level).

#### Example 3: UTF-8 Encoded Log File
```powershell
# Create UTF-8 encoded log for international characters
$log = New-Logger -LogName "International" -LogPath "C:\Logs"
$utf8Handler = New-FileHandler -Path "C:\Logs\international.log" -Encoding "UTF8"
Add-LogHandler -Logger $log -Handler $utf8Handler

Write-Log "Application started - Demarre - Iniciado - Gestartet" -Logger $log
```

**Explanation:** Uses UTF-8 encoding to properly handle international characters in log files.

### Notes
- FileHandler inherits from LogHandler base class
- The directory is created automatically if it doesn't exist
- File is opened for append (does not overwrite existing content)
- Thread-safe file writes with proper locking

### Related Functions
- [Add-LogHandler](#add-loghandler)
- [New-ConsoleHandler](#new-consolehandler)
- [New-EventLogHandler](#new-eventloghandler)

---

## New-ConsoleHandler

### Synopsis
Creates a new ConsoleHandler for writing logs to the console.

### Syntax
```powershell
New-ConsoleHandler [-UseColor <Boolean>]
```

### Description
New-ConsoleHandler creates a LogHandler that writes log entries to the PowerShell console with color-coded output based on log level. This handler can be added to a logger using Add-LogHandler to enable console output.

### Parameters

#### -UseColor
- **Type**: Boolean
- **Required**: No
- **Default**: $true
- **Description**: Enable color-coded console output based on log level.

### Examples

#### Example 1: Create Color-Coded Console Handler
```powershell
# Add console output with colors
$log = New-Logger -LogName "Application" -LogPath "C:\Logs"
$consoleHandler = New-ConsoleHandler
Add-LogHandler -Logger $log -Handler $consoleHandler

Write-LogError "Appears in red in console" -Logger $log
Write-LogWarning "Appears in yellow in console" -Logger $log
Write-LogSuccess "Appears in green in console" -Logger $log
Write-LogInfo "Appears in white in console" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [ERROR] Appears in red in console         (Red text)
[2025-11-05 10:30:46] [WARNING] Appears in yellow in console    (Yellow text)
[2025-11-05 10:30:47] [SUCCESS] Appears in green in console     (Green text)
[2025-11-05 10:30:48] [INFO] Appears in white in console        (White text)
```

**Explanation:** Console output is color-coded based on log level for easy visual identification.

#### Example 2: Console Handler Without Colors
```powershell
# Plain text console output for piping or redirection
$log = New-Logger -LogName "Plain" -LogPath "C:\Logs"
$consoleHandler = New-ConsoleHandler -UseColor:$false
Add-LogHandler -Logger $log -Handler $consoleHandler

Write-Log "Plain text output" -Logger $log
```

**Explanation:** Disables color output, useful for log redirection or environments that don't support ANSI colors.

#### Example 3: Interactive Debugging Logger
```powershell
# Console-only logger for interactive scripts
$log = New-Logger -LogName "Debug" -LogPath "C:\Logs"
$log | Add-LogHandler -Handler (New-ConsoleHandler)

Write-LogDebug "Debug information visible in console" -Logger $log
Write-LogInfo "Progress information" -Logger $log
```

**Explanation:** Adds console output to see real-time logging during script execution.

### Notes
- ConsoleHandler inherits from LogHandler base class
- Color mappings:
  - ERROR/CRITICAL: Red
  - WARNING: Yellow
  - SUCCESS: Green
  - INFO: White
  - DEBUG: Gray
- Colors can be disabled for compatibility with log parsers or redirected output

### Related Functions
- [Add-LogHandler](#add-loghandler)
- [New-FileHandler](#new-filehandler)
- [New-EventLogHandler](#new-eventloghandler)

---

## New-EventLogHandler

### Synopsis
Creates a new EventLogHandler for writing logs to Windows Event Log.

### Syntax
```powershell
New-EventLogHandler [-LogName <String>] -Source <String>
```

### Description
New-EventLogHandler creates a LogHandler that writes log entries to the Windows Event Log. This handler enables integration with Windows logging infrastructure for centralized log management and monitoring.

### Parameters

#### -LogName
- **Type**: String
- **Required**: No
- **Default**: "Application"
- **Description**: The Windows Event Log to write to (Application, System, Security, or custom log name).

#### -Source
- **Type**: String
- **Required**: Yes
- **Description**: The event source name that identifies the application in the event log. The source must be registered with Windows before use.

### Examples

#### Example 1: Write to Application Event Log
```powershell
# Register event source (run as administrator once)
New-EventLog -LogName "Application" -Source "MyApplication"

# Create logger with event log handler
$log = New-Logger -LogName "Application" -LogPath "C:\Logs"
$eventHandler = New-EventLogHandler -LogName "Application" -Source "MyApplication"
Add-LogHandler -Logger $log -Handler $eventHandler

Write-LogError "Error written to Windows Event Log" -Logger $log
```

**Explanation:** Writes log entries to both file and Windows Application Event Log for centralized monitoring.

#### Example 2: Custom Event Log
```powershell
# Create custom event log (run as administrator once)
New-EventLog -LogName "CustomAppLog" -Source "CustomApp"

# Use custom event log
$log = New-Logger -LogName "CustomApp" -LogPath "C:\Logs"
$eventHandler = New-EventLogHandler -LogName "CustomAppLog" -Source "CustomApp"
Add-LogHandler -Logger $log -Handler $eventHandler

Write-Log "Application started" -Logger $log
```

**Explanation:** Creates and uses a custom Windows Event Log for application-specific events.

#### Example 3: Enterprise Monitoring Integration
```powershell
# Setup for SCOM/enterprise monitoring
New-EventLog -LogName "Application" -Source "EnterpriseApp"

$log = New-Logger -LogName "Production" -LogPath "D:\Logs"
$eventHandler = New-EventLogHandler -LogName "Application" -Source "EnterpriseApp"
Add-LogHandler -Logger $log -Handler $eventHandler

Write-LogCritical "Critical system failure detected" -Logger $log
Write-LogError "Database connection lost" -Logger $log
```

**Explanation:** Integrates application logging with enterprise monitoring tools that watch Windows Event Log.

### Notes
- EventLogHandler inherits from LogHandler base class
- The event source must be registered before use: `New-EventLog -LogName "Application" -Source "MyApp"`
- Requires elevated permissions to create new event sources
- Event log entries include log level, timestamp, and message
- Integration point for SCOM, Splunk, and other monitoring tools

### Related Functions
- [Add-LogHandler](#add-loghandler)
- [New-FileHandler](#new-filehandler)
- [New-ConsoleHandler](#new-consolehandler)

---

## New-NullHandler

### Synopsis
Creates a new NullHandler that discards all log entries.

### Syntax
```powershell
New-NullHandler
```

### Description
New-NullHandler creates a LogHandler that silently discards all log entries without writing them anywhere. This is useful for temporarily disabling logging without removing logger calls from code, or for testing scenarios where log output is not needed.

### Examples

#### Example 1: Disable Logging Temporarily
```powershell
# Temporarily disable all logging
$log = New-Logger -LogName "Test" -LogPath "C:\Logs"
$nullHandler = New-NullHandler
Add-LogHandler -Logger $log -Handler $nullHandler

Write-Log "This message is discarded" -Logger $log
Write-LogError "This error is also discarded" -Logger $log
```

**Explanation:** All log messages are silently discarded, useful for temporarily disabling logging without code changes.

#### Example 2: Testing Scenario
```powershell
# Function testing without log file creation
function Test-Function {
    $log = New-Logger -LogName "Test" -LogPath "C:\Logs"
    Add-LogHandler -Logger $log -Handler (New-NullHandler)

    # Function code with logging calls
    Write-Log "Test message (not written)" -Logger $log
    Write-LogDebug "Debug info (not written)" -Logger $log

    # Actual test logic
    return $true
}

# Test function without creating log files
$result = Test-Function
```

**Explanation:** Allows unit testing of functions with logging calls without creating actual log files.

#### Example 3: Conditional Logging Based on Environment
```powershell
# Disable logging in test environment
$log = New-Logger -LogName "Application" -LogPath "C:\Logs"

if ($env:ENVIRONMENT -eq "Test") {
    Add-LogHandler -Logger $log -Handler (New-NullHandler)
} else {
    Add-LogHandler -Logger $log -Handler (New-FileHandler -Path "C:\Logs\app.log")
    Add-LogHandler -Logger $log -Handler (New-ConsoleHandler)
}

Write-Log "Environment: $($env:ENVIRONMENT)" -Logger $log
```

**Explanation:** Dynamically enables or disables logging based on environment configuration.

### Notes
- NullHandler inherits from LogHandler base class
- Useful for testing and temporarily disabling logging
- No performance overhead beyond the logger's internal processing
- All log entries are silently discarded with no I/O operations

### Related Functions
- [Add-LogHandler](#add-loghandler)
- [New-FileHandler](#new-filehandler)
- [New-ConsoleHandler](#new-consolehandler)

---

# Enricher Management

## Add-LogEnricher

### Synopsis
Adds a context enricher to a logger for automatic property injection.

### Syntax
```powershell
Add-LogEnricher [-Logger <Logger>] -Enricher <IEnricher>
```

### Description
Add-LogEnricher attaches an enricher object to a logger instance. Enrichers automatically add contextual properties to log entries, such as machine name, process ID, thread ID, environment variables, or network information.

Multiple enrichers can be added to a single logger, and each enricher's Enrich() method is called for every log entry to inject its properties.

### Parameters

#### -Logger
- **Type**: Logger
- **Required**: No
- **Default**: $Script:DefaultLog
- **Pipeline**: Accepts Logger instances via pipeline
- **Description**: The Logger instance to add the enricher to. If not specified, uses the default logger.

#### -Enricher
- **Type**: IEnricher
- **Required**: Yes
- **Description**: The enricher object to add. Must implement the IEnricher interface with an Enrich() method. Can be created using New-*Enricher functions or custom enrichers inheriting from IEnricher.

### Examples

#### Example 1: Add Machine Enricher
```powershell
# Add machine context to all log entries
Initialize-Log -Default -LogName "Application"
$machineEnricher = New-MachineEnricher
Add-LogEnricher -Enricher $machineEnricher

Write-Log "Application started"
```

**Output (log file):**
```
[2025-11-05 10:30:45] [INFO] Application started | MachineName=DESKTOP-ABC123 | OSVersion=Microsoft Windows 11 Pro | Domain=WORKGROUP | IPAddress=192.168.1.100
```

**Explanation:** Every log entry now includes machine name, OS version, domain, and IP address automatically.

#### Example 2: Add Multiple Enrichers
```powershell
# Add comprehensive context information
$log = New-Logger -LogName "Production" -LogPath "D:\Logs"

Add-LogEnricher -Logger $log -Enricher (New-MachineEnricher)
Add-LogEnricher -Logger $log -Enricher (New-ProcessEnricher)
Add-LogEnricher -Logger $log -Enricher (New-ThreadEnricher)

Write-Log "Enriched log entry" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Enriched log entry | MachineName=SERVER01 | OSVersion=Windows Server 2022 | ProcessId=4567 | ProcessName=powershell | ThreadId=12
```

**Explanation:** Multiple enrichers combine to add comprehensive context to every log entry.

#### Example 3: Pipeline Usage
```powershell
# Add enricher via pipeline
$log = New-Logger -LogName "App" -LogPath "C:\Logs"
$log | Add-LogEnricher -Enricher (New-NetworkEnricher)

Write-Log "Network information included" -Logger $log
```

**Explanation:** Uses pipeline for fluent enricher configuration.

#### Example 4: Create Custom Enricher
```powershell
# Define custom enricher for application-specific properties
class AppVersionEnricher : IEnricher {
    [hashtable] Enrich() {
        return @{
            AppVersion = "1.0.0"
            BuildDate = "2025-11-05"
            Environment = $env:DEPLOYMENT_ENV
        }
    }
}

$log = New-Logger -LogName "Custom" -LogPath "C:\Logs"
Add-LogEnricher -Logger $log -Enricher ([AppVersionEnricher]::new())

Write-Log "Application initialized"
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Application initialized | AppVersion=1.0.0 | BuildDate=2025-11-05 | Environment=Production
```

**Explanation:** Custom enrichers can add application-specific context to log entries.

### Notes
- Enrichers are called for every log entry, so avoid expensive operations in Enrich() method
- Multiple enrichers are executed in the order they are added
- Enricher properties are appended to log entries in key=value format
- Common enrichers: MachineEnricher, ProcessEnricher, ThreadEnricher, EnvironmentEnricher, NetworkEnricher

### Related Functions
- [New-MachineEnricher](#new-machineenricher)
- [New-ProcessEnricher](#new-processenricher)
- [New-ThreadEnricher](#new-threadenricher)
- [New-EnvironmentEnricher](#new-environmentenricher)
- [New-NetworkEnricher](#new-networkenricher)

---

## New-MachineEnricher

### Synopsis
Creates an enricher that adds machine/computer information to log entries.

### Syntax
```powershell
New-MachineEnricher
```

### Description
New-MachineEnricher creates an IEnricher that automatically adds computer-related properties to every log entry, including machine name, OS version, domain membership, and IP address.

Properties added:
- **MachineName**: Computer name
- **OSVersion**: Operating system version
- **Domain**: Active Directory domain (if domain-joined)
- **IPAddress**: Primary IP address

### Examples

#### Example 1: Add Machine Context to Logs
```powershell
# Create logger with machine enricher
$log = New-Logger -LogName "Application" -LogPath "C:\Logs"
$machineEnricher = New-MachineEnricher
Add-LogEnricher -Logger $log -Enricher $machineEnricher

Write-Log "Log includes machine info" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Log includes machine info | MachineName=LAPTOP-XYZ789 | OSVersion=Windows 11 Pro | Domain=CONTOSO | IPAddress=10.0.1.50
```

**Explanation:** Every log entry automatically includes comprehensive machine information.

#### Example 2: Combine with Other Enrichers
```powershell
# Full context logging for troubleshooting
$log = New-Logger -LogName "FullContext" -LogPath "C:\Logs"

Add-LogEnricher -Logger $log -Enricher (New-MachineEnricher)
Add-LogEnricher -Logger $log -Enricher (New-ProcessEnricher)
Add-LogEnricher -Logger $log -Enricher (New-ThreadEnricher)

Write-Log "Comprehensive context logging" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Comprehensive context logging | MachineName=SERVER01 | OSVersion=Windows Server 2022 | Domain=CORP | IPAddress=192.168.10.5 | ProcessId=2345 | ProcessName=powershell | ThreadId=8
```

**Explanation:** Combines machine, process, and thread information for complete diagnostic context.

#### Example 3: Distributed Application Logging
```powershell
# Track which server processed each request
$log = New-Logger -LogName "WebAPI" -LogPath "C:\Logs"
Add-LogEnricher -Logger $log -Enricher (New-MachineEnricher)

Write-Log "API request processed: GET /api/users" -Logger $log
```

**Explanation:** Useful in distributed applications to identify which server handled each request.

### Notes
- MachineEnricher implements IEnricher interface
- Properties are cached per log entry for performance
- Useful for distributed systems and multi-server environments
- IP address is the primary network adapter's IPv4 address

### Related Functions
- [Add-LogEnricher](#add-logenricher)
- [New-ProcessEnricher](#new-processenricher)
- [New-ThreadEnricher](#new-threadenricher)
- [New-NetworkEnricher](#new-networkenricher)

---

## New-ProcessEnricher

### Synopsis
Creates an enricher that adds process information to log entries.

### Syntax
```powershell
New-ProcessEnricher
```

### Description
New-ProcessEnricher creates an IEnricher that automatically adds process-related properties to every log entry, including process ID, name, start time, and memory usage.

Properties added:
- **ProcessId**: Current process ID (PID)
- **ProcessName**: Process executable name
- **ProcessStartTime**: Process start timestamp
- **ProcessMemory**: Working set memory in MB

### Examples

#### Example 1: Add Process Context
```powershell
# Track process information in logs
$log = New-Logger -LogName "Application" -LogPath "C:\Logs"
$processEnricher = New-ProcessEnricher
Add-LogEnricher -Logger $log -Enricher $processEnricher

Write-Log "Log includes process info" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Log includes process info | ProcessId=4567 | ProcessName=powershell | ProcessStartTime=2025-11-05T09:15:23 | ProcessMemory=125.5
```

**Explanation:** Every log entry includes process diagnostics, useful for troubleshooting memory leaks or performance issues.

#### Example 2: Multi-Process Application Tracking
```powershell
# Distinguish logs from different process instances
$log = New-Logger -LogName "MultiProcess" -LogPath "C:\Logs"
Add-LogEnricher -Logger $log -Enricher (New-ProcessEnricher)

# Each process instance logs with its own PID
Write-Log "Process-specific logging" -Logger $log
```

**Explanation:** When multiple process instances write to the same log file, process ID distinguishes entries.

#### Example 3: Performance Monitoring
```powershell
# Monitor memory usage over time
$log = New-Logger -LogName "Performance" -LogPath "C:\Logs"
Add-LogEnricher -Logger $log -Enricher (New-ProcessEnricher)

Write-Log "Starting data processing"
# ... process large dataset ...
Write-Log "Data processing complete"
```

**Output:**
```
[2025-11-05 10:30:00] [INFO] Starting data processing | ProcessMemory=98.2
[2025-11-05 10:35:00] [INFO] Data processing complete | ProcessMemory=425.7
```

**Explanation:** Track memory consumption changes throughout script execution.

### Notes
- ProcessEnricher implements IEnricher interface
- Useful for debugging multi-process applications
- Process memory is working set in megabytes
- Process start time helps identify long-running processes

### Related Functions
- [Add-LogEnricher](#add-logenricher)
- [New-MachineEnricher](#new-machineenricher)
- [New-ThreadEnricher](#new-threadenricher)

---

## New-ThreadEnricher

### Synopsis
Creates an enricher that adds thread information to log entries.

### Syntax
```powershell
New-ThreadEnricher
```

### Description
New-ThreadEnricher creates an IEnricher that automatically adds thread-related properties to every log entry, including thread ID and managed thread status. This is particularly useful for debugging multi-threaded applications and runspaces.

Properties added:
- **ThreadId**: Current managed thread ID
- **ThreadName**: Thread name (if set)
- **IsThreadPoolThread**: Whether thread is from thread pool

### Examples

#### Example 1: Multi-Threaded Application Logging
```powershell
# Track thread activity
$log = New-Logger -LogName "MultiThreaded" -LogPath "C:\Logs"
$threadEnricher = New-ThreadEnricher
Add-LogEnricher -Logger $log -Enricher $threadEnricher

Write-Log "Log includes thread info" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Log includes thread info | ThreadId=12 | IsThreadPoolThread=False
```

**Explanation:** Thread ID helps trace execution through multi-threaded code.

#### Example 2: Runspace Debugging
```powershell
# Debug parallel runspaces
$log = New-Logger -LogName "Runspaces" -LogPath "C:\Logs"
Add-LogEnricher -Logger $log -Enricher (New-ThreadEnricher)

$runspaces = 1..5 | ForEach-Object {
    $rs = [runspacefactory]::CreateRunspace()
    $rs.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript({
        param($logger)
        Write-Log "Runspace executing" -Logger $logger
    }).AddArgument($log)
    [PSCustomObject]@{
        PowerShell = $ps
        Handle = $ps.BeginInvoke()
    }
}
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Runspace executing | ThreadId=15 | IsThreadPoolThread=True
[2025-11-05 10:30:45] [INFO] Runspace executing | ThreadId=16 | IsThreadPoolThread=True
[2025-11-05 10:30:45] [INFO] Runspace executing | ThreadId=17 | IsThreadPoolThread=True
```

**Explanation:** Each runspace logs with its own thread ID, helping debug parallel execution.

#### Example 3: Thread Pool Analysis
```powershell
# Analyze thread pool usage
$log = New-Logger -LogName "ThreadPool" -LogPath "C:\Logs"
Add-LogEnricher -Logger $log -Enricher (New-ThreadEnricher)

1..10 | ForEach-Object -Parallel {
    Write-Log "Parallel task $_"
} -ThrottleLimit 5
```

**Explanation:** Identifies which tasks run on thread pool threads vs. dedicated threads.

### Notes
- ThreadEnricher implements IEnricher interface
- Essential for debugging parallel and multi-threaded code
- Thread ID is the managed thread identifier, not the OS thread ID
- IsThreadPoolThread indicates if thread is from .NET thread pool

### Related Functions
- [Add-LogEnricher](#add-logenricher)
- [New-ProcessEnricher](#new-processenricher)
- [New-MachineEnricher](#new-machineenricher)

---

## New-EnvironmentEnricher

### Synopsis
Creates an enricher that adds environment variables to log entries.

### Syntax
```powershell
New-EnvironmentEnricher -Variables <String[]>
```

### Description
New-EnvironmentEnricher creates an IEnricher that automatically adds specified environment variables to every log entry. This is useful for capturing deployment environment, user context, or custom variables set by deployment scripts.

### Parameters

#### -Variables
- **Type**: String[]
- **Required**: Yes
- **Description**: Array of environment variable names to include in log entries. Only specified variables are added to avoid cluttering logs with hundreds of environment variables.

### Examples

#### Example 1: Capture Common Environment Variables
```powershell
# Add basic environment context
$log = New-Logger -LogName "Application" -LogPath "C:\Logs"
$envEnricher = New-EnvironmentEnricher -Variables @("COMPUTERNAME", "USERNAME", "USERDOMAIN")
Add-LogEnricher -Logger $log -Enricher $envEnricher

Write-Log "Log includes environment context" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Log includes environment context | COMPUTERNAME=DESKTOP-ABC123 | USERNAME=jdoe | USERDOMAIN=CORP
```

**Explanation:** Captures user and computer context from environment variables.

#### Example 2: CI/CD Deployment Context
```powershell
# Capture build and deployment information
$log = New-Logger -LogName "Deployment" -LogPath "C:\Logs"
$envEnricher = New-EnvironmentEnricher -Variables @("CI", "BUILD_NUMBER", "GIT_BRANCH", "GIT_COMMIT", "DEPLOYMENT_ENV")
Add-LogEnricher -Logger $log -Enricher $envEnricher

Write-Log "Deployment started"
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Deployment started | CI=true | BUILD_NUMBER=1234 | GIT_BRANCH=main | GIT_COMMIT=a1b2c3d | DEPLOYMENT_ENV=Production
```

**Explanation:** Logs include complete build and deployment context from CI/CD pipeline.

#### Example 3: Custom Application Variables
```powershell
# Track custom application configuration
$env:APP_CONFIG_FILE = "C:\Config\production.json"
$env:APP_LOG_LEVEL = "INFO"
$env:APP_FEATURE_FLAGS = "EnableCache,EnableMetrics"

$log = New-Logger -LogName "AppConfig" -LogPath "C:\Logs"
$envEnricher = New-EnvironmentEnricher -Variables @("APP_CONFIG_FILE", "APP_LOG_LEVEL", "APP_FEATURE_FLAGS")
Add-LogEnricher -Logger $log -Enricher $envEnricher

Write-Log "Application configuration loaded"
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Application configuration loaded | APP_CONFIG_FILE=C:\Config\production.json | APP_LOG_LEVEL=INFO | APP_FEATURE_FLAGS=EnableCache,EnableMetrics
```

**Explanation:** Captures custom application configuration from environment variables.

### Notes
- EnvironmentEnricher implements IEnricher interface
- Only specified variables are included to avoid log bloat
- Non-existent environment variables are omitted from logs
- Variable values are captured at log time, not enricher creation time

### Related Functions
- [Add-LogEnricher](#add-logenricher)
- [New-MachineEnricher](#new-machineenricher)
- [New-ProcessEnricher](#new-processenricher)

---

## New-NetworkEnricher

### Synopsis
Creates an enricher that adds network information to log entries.

### Syntax
```powershell
New-NetworkEnricher
```

### Description
New-NetworkEnricher creates an IEnricher that automatically adds network-related properties to every log entry, including IP addresses, network adapters, and connectivity status.

Properties added:
- **PrimaryIP**: Primary IPv4 address
- **NetworkAdapters**: Active network adapter count
- **DefaultGateway**: Default gateway address
- **DNSServers**: Configured DNS servers

### Examples

#### Example 1: Add Network Context
```powershell
# Include network information in logs
$log = New-Logger -LogName "NetworkApp" -LogPath "C:\Logs"
$networkEnricher = New-NetworkEnricher
Add-LogEnricher -Logger $log -Enricher $networkEnricher

Write-Log "Log includes network info" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Log includes network info | PrimaryIP=192.168.1.100 | NetworkAdapters=2 | DefaultGateway=192.168.1.1 | DNSServers=8.8.8.8,8.8.4.4
```

**Explanation:** Every log entry includes comprehensive network configuration.

#### Example 2: Distributed Application Tracking
```powershell
# Track network context across distributed systems
$log = New-Logger -LogName "Distributed" -LogPath "C:\Logs"
Add-LogEnricher -Logger $log -Enricher (New-NetworkEnricher)
Add-LogEnricher -Logger $log -Enricher (New-MachineEnricher)

Write-Log "Service request processed" -Logger $log
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Service request processed | MachineName=API-SERVER-01 | Domain=CORP | PrimaryIP=10.0.2.15 | NetworkAdapters=3 | DefaultGateway=10.0.2.1
```

**Explanation:** Combines machine and network context for distributed system troubleshooting.

#### Example 3: Network Diagnostics
```powershell
# Log network configuration during troubleshooting
$log = New-Logger -LogName "NetworkDiag" -LogPath "C:\Logs"
Add-LogEnricher -Logger $log -Enricher (New-NetworkEnricher)

Write-Log "Starting network diagnostics"
# ... network tests ...
Write-Log "Network diagnostics complete"
```

**Explanation:** Network configuration is logged automatically for troubleshooting connectivity issues.

### Notes
- NetworkEnricher implements IEnricher interface
- Network information is captured at log time, not enricher creation time
- Useful for distributed applications and network-dependent services
- Handles multiple network adapters by selecting primary adapter

### Related Functions
- [Add-LogEnricher](#add-logenricher)
- [New-MachineEnricher](#new-machineenricher)
- [New-ProcessEnricher](#new-processenricher)

---

# Filter Management

## Add-LogFilter

### Synopsis
Adds a filter to a logger to conditionally include or exclude log entries.

### Syntax
```powershell
Add-LogFilter [-Logger <Logger>] -Filter <ILogFilter>
```

### Description
Add-LogFilter attaches a filter object to a logger instance. Filters implement logic to determine whether a log entry should be written based on various conditions (time of day, calling function, user, custom properties, etc.).

Multiple filters can be added to a logger, and ALL filters must return $true for a log entry to be written (AND logic).

### Parameters

#### -Logger
- **Type**: Logger
- **Required**: No
- **Default**: $Script:DefaultLog
- **Pipeline**: Accepts Logger instances via pipeline
- **Description**: The Logger instance to add the filter to. If not specified, uses the default logger.

#### -Filter
- **Type**: ILogFilter
- **Required**: Yes
- **Description**: The filter object to add. Must implement the ILogFilter interface with a ShouldLog() method. Can be created using New-*Filter functions or custom filters inheriting from ILogFilter.

### Examples

#### Example 1: Time-Based Filtering
```powershell
# Only log during business hours
$log = New-Logger -LogName "BusinessHours" -LogPath "C:\Logs"
$timeFilter = New-TimeFilter -StartHour 8 -EndHour 17
Add-LogFilter -Logger $log -Filter $timeFilter

Write-Log "Only logged between 8 AM and 5 PM" -Logger $log
```

**Explanation:** Log entries are only written during specified hours, reducing log volume during off-hours.

#### Example 2: Function-Based Filtering
```powershell
# Filter logs from specific functions
$log = New-Logger -LogName "Filtered" -LogPath "C:\Logs"
$funcFilter = New-FunctionFilter -AllowedFunctions @("Initialize-Application", "Process-Data")
Add-LogFilter -Logger $log -Filter $funcFilter

# Only logs from Initialize-Application and Process-Data will be written
```

**Explanation:** Restricts logging to specific functions, useful for focused debugging.

#### Example 3: Combine Multiple Filters
```powershell
# Logs only written during business hours AND by specific users
$log = New-Logger -LogName "Restricted" -LogPath "C:\Logs"

Add-LogFilter -Logger $log -Filter (New-TimeFilter -StartHour 8 -EndHour 17)
Add-LogFilter -Logger $log -Filter (New-UserFilter -AllowedUsers @("admin", "operator"))

Write-Log "Only logged if all filters pass"
```

**Explanation:** Multiple filters create AND logic - all must return $true for log entry to be written.

#### Example 4: Custom Filter for Priority Logs
```powershell
# Only log high-priority messages
class PriorityFilter : ILogFilter {
    [bool] ShouldLog([string]$Message, [string]$Level, [hashtable]$Properties) {
        return $Level -in @("ERROR", "CRITICAL", "WARNING")
    }
}

$log = New-Logger -LogName "HighPriority" -LogPath "C:\Logs"
Add-LogFilter -Logger $log -Filter ([PriorityFilter]::new())

Write-LogInfo "Not logged (INFO filtered out)" -Logger $log
Write-LogError "Logged (ERROR allowed)" -Logger $log
```

**Explanation:** Custom filter allows only ERROR, CRITICAL, and WARNING level messages.

### Notes
- All filters must return $true for a log entry to be written (AND logic)
- Filters are evaluated before handlers, so filtered messages are never written
- Filters can inspect message, level, and custom properties
- Use filters to reduce log volume or focus on specific scenarios

### Related Functions
- [New-FunctionFilter](#new-functionfilter)
- [New-TimeFilter](#new-timefilter)
- [New-UserFilter](#new-userfilter)

---

## New-FunctionFilter

### Synopsis
Creates a filter that only logs messages from specified functions.

### Syntax
```powershell
New-FunctionFilter -AllowedFunctions <String[]>
```

### Description
New-FunctionFilter creates an ILogFilter that restricts logging to messages originating from specific functions. This is useful for focusing logs on particular code paths or debugging specific functions without modifying code.

### Parameters

#### -AllowedFunctions
- **Type**: String[]
- **Required**: Yes
- **Description**: Array of function names that are allowed to log. Only messages from these functions will be written to the log. Function names are case-insensitive.

### Examples

#### Example 1: Focus on Specific Functions
```powershell
# Only log from specific functions
$log = New-Logger -LogName "Filtered" -LogPath "C:\Logs"
$funcFilter = New-FunctionFilter -AllowedFunctions @("Initialize-Application", "Process-Data", "Send-Report")
Add-LogFilter -Logger $log -Filter $funcFilter

# Only logs from these three functions will be written
```

**Explanation:** Restricts logging to specific functions, ignoring all others.

#### Example 2: Debug Specific Code Path
```powershell
# Focus logging on problematic function
$log = New-Logger -LogName "Debug" -LogPath "C:\Logs" -LogLevel "DEBUG"
$funcFilter = New-FunctionFilter -AllowedFunctions @("Troublesome-Function")
Add-LogFilter -Logger $log -Filter $funcFilter

function Troublesome-Function {
    Write-LogDebug "Entering function"
    # ... problematic code ...
    Write-LogDebug "Exiting function"
}

function Other-Function {
    Write-LogDebug "This will not be logged"
}
```

**Explanation:** Debug logging focuses only on the specific function being troubleshot.

#### Example 3: Module Function Filtering
```powershell
# Log only public module functions
$log = New-Logger -LogName "PublicAPI" -LogPath "C:\Logs"
$funcFilter = New-FunctionFilter -AllowedFunctions @(
    "Get-UserData",
    "Set-UserData",
    "Remove-UserData",
    "New-UserData"
)
Add-LogFilter -Logger $log -Filter $funcFilter
```

**Explanation:** Filters logs to show only public API function calls, excluding internal helper functions.

### Notes
- FunctionFilter implements ILogFilter interface
- Function names are matched case-insensitively
- Uses PowerShell call stack to determine calling function
- Useful for focused debugging and API call logging

### Related Functions
- [Add-LogFilter](#add-logfilter)
- [New-TimeFilter](#new-timefilter)
- [New-UserFilter](#new-userfilter)

---

## New-TimeFilter

### Synopsis
Creates a filter that only logs messages during specified hours.

### Syntax
```powershell
New-TimeFilter -StartHour <Int32> -EndHour <Int32>
```

### Description
New-TimeFilter creates an ILogFilter that restricts logging to specific hours of the day. This is useful for reducing log volume during off-hours or focusing on business hours activity.

### Parameters

#### -StartHour
- **Type**: Int32
- **Required**: Yes
- **Valid Range**: 0-23
- **Description**: Starting hour (0-23) for logging window. Logs are only written during this time range.

#### -EndHour
- **Type**: Int32
- **Required**: Yes
- **Valid Range**: 0-23
- **Description**: Ending hour (0-23) for logging window. Logs are only written during this time range.

### Examples

#### Example 1: Business Hours Logging
```powershell
# Only log during business hours (8 AM to 5 PM)
$log = New-Logger -LogName "BusinessHours" -LogPath "C:\Logs"
$timeFilter = New-TimeFilter -StartHour 8 -EndHour 17
Add-LogFilter -Logger $log -Filter $timeFilter

Write-Log "Logged only between 8 AM and 5 PM" -Logger $log
```

**Explanation:** Reduces log volume by only writing entries during business hours.

#### Example 2: Overnight Batch Processing
```powershell
# Log only during overnight batch window (10 PM to 6 AM)
$log = New-Logger -LogName "BatchProcessing" -LogPath "C:\Logs"
$timeFilter = New-TimeFilter -StartHour 22 -EndHour 6
Add-LogFilter -Logger $log -Filter $timeFilter

Write-Log "Batch process activity" -Logger $log
```

**Explanation:** Time filter spans midnight (22:00 to 06:00), logging only during batch window.

#### Example 3: After-Hours Monitoring
```powershell
# Alert on activity outside business hours
$log = New-Logger -LogName "AfterHours" -LogPath "C:\Logs"
$timeFilter = New-TimeFilter -StartHour 18 -EndHour 7
Add-LogFilter -Logger $log -Filter $timeFilter

Write-LogWarning "Activity detected outside business hours"
```

**Explanation:** Logs only after-hours activity for security monitoring.

### Notes
- TimeFilter implements ILogFilter interface
- Uses 24-hour clock (0-23)
- Can span midnight (e.g., StartHour=22, EndHour=6)
- Time comparison uses current local time

### Related Functions
- [Add-LogFilter](#add-logfilter)
- [New-FunctionFilter](#new-functionfilter)
- [New-UserFilter](#new-userfilter)

---

## New-UserFilter

### Synopsis
Creates a filter that only logs messages from specified users.

### Syntax
```powershell
New-UserFilter -AllowedUsers <String[]>
```

### Description
New-UserFilter creates an ILogFilter that restricts logging to messages from specific user accounts. This is useful for multi-user environments where you want to focus on specific user activity or exclude service accounts from logs.

### Parameters

#### -AllowedUsers
- **Type**: String[]
- **Required**: Yes
- **Description**: Array of usernames that are allowed to log. Only messages from these users will be written to the log. Usernames are case-insensitive.

### Examples

#### Example 1: Admin and Operator Logging Only
```powershell
# Only log from specific users
$log = New-Logger -LogName "UserSpecific" -LogPath "C:\Logs"
$userFilter = New-UserFilter -AllowedUsers @("admin", "operator", "supervisor")
Add-LogFilter -Logger $log -Filter $userFilter

Write-Log "Only logged if current user is admin, operator, or supervisor"
```

**Explanation:** Filters logs to only include entries from specified user accounts.

#### Example 2: Exclude Service Account Activity
```powershell
# Log only interactive user activity
$log = New-Logger -LogName "InteractiveOnly" -LogPath "C:\Logs"
$userFilter = New-UserFilter -AllowedUsers @("user1", "user2", "user3")
Add-LogFilter -Logger $log -Filter $userFilter

Write-Log "Service account activity excluded"
```

**Explanation:** Excludes automated service account activity from logs.

#### Example 3: VIP User Monitoring
```powershell
# Track specific user activity
$log = New-Logger -LogName "VIPUsers" -LogPath "C:\Logs"
$userFilter = New-UserFilter -AllowedUsers @("ceo", "cfo", "cto")
Add-LogFilter -Logger $log -Filter $userFilter

Write-Log "VIP user action logged"
```

**Explanation:** Focuses logging on specific high-priority users for compliance or monitoring.

### Notes
- UserFilter implements ILogFilter interface
- Usernames are matched case-insensitively
- Uses current Windows identity ($env:USERNAME)
- Useful for multi-user systems and user activity tracking

### Related Functions
- [Add-LogFilter](#add-logfilter)
- [New-FunctionFilter](#new-functionfilter)
- [New-TimeFilter](#new-timefilter)

---

# Scoped Properties

## Start-LogScope

### Synopsis
Creates a disposable scope that adds temporary properties to log entries.

### Syntax
```powershell
Start-LogScope [-Logger <Logger>] -Key <String> -Value <Object>
```

### Description
Start-LogScope creates a PropertyScope object that adds a key-value pair to all log entries within a code block. When the scope is disposed (via Using statement or explicit Dispose()), the property is automatically removed. This enables hierarchical context tracking without manually adding/removing properties.

Best used with PowerShell's Using statement for automatic cleanup, or explicitly call Dispose() in a Finally block.

### Parameters

#### -Logger
- **Type**: Logger
- **Required**: No
- **Default**: $Script:DefaultLog
- **Pipeline**: Accepts Logger instances via pipeline
- **Description**: The Logger instance to add the scoped property to. If not specified, uses the default logger.

#### -Key
- **Type**: String
- **Required**: Yes
- **Description**: The property key name to add to log entries within this scope.

#### -Value
- **Type**: Object
- **Required**: Yes
- **Description**: The property value to add to log entries within this scope.

### Examples

#### Example 1: Using PowerShell Using Statement
```powershell
# Automatic scope cleanup with Using statement
$log = New-Logger -LogName "Scoped" -LogPath "C:\Logs"

Using (Start-LogScope -Logger $log -Key "RequestId" -Value "REQ-12345") {
    Write-Log "Processing request" -Logger $log
    # Log includes RequestId=REQ-12345

    Using (Start-LogScope -Logger $log -Key "UserId" -Value "user123") {
        Write-Log "User action" -Logger $log
        # Log includes RequestId=REQ-12345 and UserId=user123
    }

    Write-Log "Request complete" -Logger $log
    # Log includes RequestId=REQ-12345 only
}
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Processing request | RequestId=REQ-12345
[2025-11-05 10:30:46] [INFO] User action | RequestId=REQ-12345 | UserId=user123
[2025-11-05 10:30:47] [INFO] Request complete | RequestId=REQ-12345
```

**Explanation:** Scoped properties are automatically added and removed based on scope nesting.

#### Example 2: Manual Disposal in Try-Finally
```powershell
# Manual scope management
$log = New-Logger -LogName "Manual" -LogPath "C:\Logs"
$scope = $null

Try {
    $scope = Start-LogScope -Logger $log -Key "Operation" -Value "BatchProcess"
    Write-Log "Starting batch process" -Logger $log
    # ... processing ...
    Write-Log "Batch complete" -Logger $log
}
Finally {
    if ($scope) { $scope.Dispose() }
}
```

**Explanation:** Manual disposal ensures scope is cleaned up even if exceptions occur.

#### Example 3: Nested Scopes for Hierarchical Context
```powershell
# Track job and task hierarchy
$log = New-Logger -LogName "Hierarchical" -LogPath "C:\Logs"

Using (Start-LogScope -Logger $log -Key "JobId" -Value "JOB-001") {
    Write-Log "Job started" -Logger $log

    foreach ($task in $tasks) {
        Using (Start-LogScope -Logger $log -Key "TaskId" -Value $task.Id) {
            Write-Log "Task processing: $($task.Name)" -Logger $log
            # Includes JobId and TaskId
        }
    }

    Write-Log "Job complete" -Logger $log
}
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Job started | JobId=JOB-001
[2025-11-05 10:30:46] [INFO] Task processing: Data Import | JobId=JOB-001 | TaskId=TASK-A
[2025-11-05 10:30:47] [INFO] Task processing: Data Transform | JobId=JOB-001 | TaskId=TASK-B
[2025-11-05 10:30:48] [INFO] Job complete | JobId=JOB-001
```

**Explanation:** Hierarchical scopes enable tracking of job→task relationships in logs.

#### Example 4: Web Request Context Tracking
```powershell
# Track web API request context
$log = New-Logger -LogName "WebAPI" -LogPath "C:\Logs"

function Process-Request {
    param($requestId, $userId, $endpoint)

    Using (Start-LogScope -Logger $log -Key "RequestId" -Value $requestId) {
        Using (Start-LogScope -Logger $log -Key "UserId" -Value $userId) {
            Using (Start-LogScope -Logger $log -Key "Endpoint" -Value $endpoint) {
                Write-Log "Request received"
                # ... process request ...
                Write-Log "Request complete"
            }
        }
    }
}

Process-Request -requestId "REQ-789" -userId "user@example.com" -endpoint "/api/users"
```

**Output:**
```
[2025-11-05 10:30:45] [INFO] Request received | RequestId=REQ-789 | UserId=user@example.com | Endpoint=/api/users
[2025-11-05 10:30:46] [INFO] Request complete | RequestId=REQ-789 | UserId=user@example.com | Endpoint=/api/users
```

**Explanation:** All logs within request processing automatically include request context.

#### Example 5: Database Transaction Tracking
```powershell
# Track database operations
$log = New-Logger -LogName "Database" -LogPath "C:\Logs"

function Invoke-DatabaseTransaction {
    param($transactionId, $operations)

    Using (Start-LogScope -Logger $log -Key "TransactionId" -Value $transactionId) {
        Write-Log "Transaction started"

        foreach ($op in $operations) {
            Using (Start-LogScope -Logger $log -Key "OperationType" -Value $op.Type) {
                Write-Log "Executing: $($op.Query)"
            }
        }

        Write-Log "Transaction committed"
    }
}
```

**Explanation:** Scoped properties provide transaction context without passing parameters through every function.

### Notes
- PropertyScope implements IDisposable for automatic cleanup
- Requires PowerShell 5.0+ for Using statement support
- Properties are automatically removed when scope exits
- Scopes can be nested for hierarchical context
- Ideal for request tracking, transaction logging, and context correlation

### Related Functions
- [New-Logger](#new-logger)
- [Write-Log](./WRITE_FUNCTIONS.md#write-log)
- [Add-LogEnricher](#add-logenricher)

---

## Summary

This document covers **20 helper functions** in the PSLogger module:

### Core Logger Management (4 functions)
- New-Logger
- Get-Logger
- Set-DefaultLogger
- Get-DefaultLogger

### Handler Management (5 functions)
- Add-LogHandler
- New-FileHandler
- New-ConsoleHandler
- New-EventLogHandler
- New-NullHandler

### Enricher Management (6 functions)
- Add-LogEnricher
- New-MachineEnricher
- New-ProcessEnricher
- New-ThreadEnricher
- New-EnvironmentEnricher
- New-NetworkEnricher

### Filter Management (4 functions)
- Add-LogFilter
- New-FunctionFilter
- New-TimeFilter
- New-UserFilter

### Scoped Properties (1 function)
- Start-LogScope

All functions have been documented with comprehensive examples, parameter descriptions, and usage notes.
