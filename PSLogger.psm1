#Requires -Version 5.0
<#
.SYNOPSIS
    Advanced PowerShell logging module with automatic rotation, compression, and flexible output options.

.DESCRIPTION
    PSLogger is a comprehensive logging solution for PowerShell scripts and modules that provides
    enterprise-grade logging capabilities. It offers automatic log rotation based on size or age,
    compression of archived logs, multiple output targets (file and console), customizable formatting,
    and support for multiple concurrent logger instances.

    Core Features:
    - Multiple log levels (INFO, WARNING, ERROR, CRITICAL, DEBUG, SUCCESS) with color-coded console output
    - Automatic log rotation by file size (KB, MB, GB) or age (days)
    - Zip compression for archived logs to save disk space
    - Concurrent logger support for complex applications
    - Retry mechanism for handling file locks
    - Pipeline support for bulk logging operations
    - Customizable timestamp formats and encoding options

    Advanced Features:
    - Enrichers: Automatically add contextual properties (machine info, process info, thread info, etc.)
    - Handlers: Multiple output destinations (file, console, Windows Event Log, custom)
    - Filters: Conditionally log based on time, user, function, or custom criteria
    - Scoped Properties: Hierarchical context tracking with automatic cleanup
    - Structured Logging: JSON output for SIEM integration and machine parsing
    - Buffered Writes: High-performance logging for high-volume scenarios

    Helper Functions:
    The module provides intuitive helper functions for common tasks:
    - New-Logger: Create logger instances with fluent configuration
    - Get-Logger: Retrieve or auto-create default logger
    - Set-DefaultLogger/Get-DefaultLogger: Manage script-wide default logger
    - Add-LogEnricher: Add context enrichers (machine, process, thread, network, environment)
    - Add-LogHandler: Add output handlers (file, console, event log, null)
    - Add-LogFilter: Add conditional filters (time, function, user)
    - Start-LogScope: Create disposable property scopes for hierarchical context

    The module is designed to be simple for basic use cases while providing advanced features
    for enterprise environments. It follows PowerShell best practices and integrates seamlessly
    with existing PowerShell workflows.

.PARAMETER LogName
    Specifies the name of the log file (without extension). Default is "Debug".
    The .log extension is automatically appended.

.PARAMETER LogPath
    Specifies the directory path where log files will be stored. Default is the user's temp directory ($env:TEMP).
    The directory is created automatically if it doesn't exist.

.PARAMETER LogLevel
    Sets the default log level for messages. Valid values: INFO, WARNING, ERROR, DEBUG, SUCCESS.
    Default is "INFO". This can be overridden per message.

.INPUTS
    System.String
    The module accepts string input for log messages via the pipeline.

.OUTPUTS
    Logger
    Initialize-Log returns a Logger object that can be used with Write-Log functions.

.EXAMPLE
    # Basic usage with default logger
    Import-Module PSLogger
    Initialize-Log -Default -LogName "MyApplication"
    Write-Log "Application started successfully"
    Write-Log "Warning: Low memory" -LogLevel "WARNING"
    Write-Log "Critical error occurred" -LogLevel "ERROR"

.EXAMPLE
    # Using module names for component identification
    Import-Module PSLogger
    
    $WebLog = Initialize-Log -LogName "WebApp" -ModuleName "WebAPI"
    $DbLog = Initialize-Log -LogName "Database" -ModuleName "DataLayer"
    
    Write-Log "API request received" -Logger $WebLog
    # Output: [2025-08-15 16:13:06][INFO][WebAPI] API request received
    
    Write-Log "Database connected" -Logger $DbLog
    # Output: [2025-08-15 16:13:06][INFO][DataLayer] Database connected

.EXAMPLE
    # Custom log format and brackets
    Import-Module PSLogger
    
    $CustomLog = Initialize-Log -LogName "Custom" `
                                -ModuleName "Engine" `
                                -LogFormat @('LEVEL', 'MODULENAME', 'TIMESTAMP') `
                                -LogBrackets "{}"
    
    Write-Log "Process started" -Logger $CustomLog
    # Output: {INFO}{Engine}{2025-08-15 16:13:06} Process started

.EXAMPLE
    # Multiple logger instances for different components
    Import-Module PSLogger
    
    $AppLog = Initialize-Log -LogName "Application" -LogPath "C:\Logs\App"
    $SecurityLog = Initialize-Log -LogName "Security" -LogPath "C:\Logs\Security" -LogLevel "WARNING"
    $DebugLog = Initialize-Log -LogName "Debug" -LogPath "C:\Logs\Debug" -WriteConsole
    
    Write-Log "User login successful" -Logger $SecurityLog
    Write-Log "Database query executed" -Logger $AppLog
    Write-Log "Variable state: $($SomeVariable)" -Logger $DebugLog -LogLevel "DEBUG"

.EXAMPLE
    # Log rotation by size with compression
    Import-Module PSLogger
    
    $RotatingLog = Initialize-Log -LogName "Production" `
                                  -LogPath "D:\Logs" `
                                  -LogRoll `
                                  -LogRotateOpt "50M" `
                                  -LogZip `
                                  -LogCountMax 10
    
    # This log will rotate when it reaches 50MB
    # Old logs will be compressed into Production-archive.zip
    # Maximum 10 rotated logs will be kept
    Write-Log "Production event logged" -Logger $RotatingLog

.EXAMPLE
    # Daily log rotation without compression
    Import-Module PSLogger
    
    $DailyLog = Initialize-Log -LogName "DailyReport" `
                               -LogPath "C:\Reports" `
                               -LogRoll `
                               -LogRotateOpt "1" `
                               -LogZip:$false
    
    # Log rotates daily, keeping uncompressed .1, .2, .3 files
    Write-Log "Daily report entry" -Logger $DailyLog

.EXAMPLE
    # Console output with file logging
    Import-Module PSLogger
    
    Initialize-Log -Default -LogName "Interactive" `
                   -WriteConsole `
                   -ConsoleInfo
    
    Write-LogInfo "This appears in both console and file with timestamp"
    Write-LogWarning "Warning shown in yellow in console"
    Write-LogError "Error shown in red in console"
    Write-LogSuccess "Success shown in green in console"

.EXAMPLE
    # Console-only mode for interactive scripts
    Import-Module PSLogger
    
    $Display = Initialize-Log -LogName "Display" `
                              -WriteConsole `
                              -ConsoleOnly
    
    # Messages only appear in console, no file is created
    Write-Log "Processing item 1 of 100..." -Logger $Display
    Write-Log "Complete!" -Logger $Display -LogLevel "SUCCESS"

.EXAMPLE
    # Pipeline support for bulk operations
    Import-Module PSLogger
    Initialize-Log -Default
    
    # Log multiple messages
    @("Starting process", "Step 1 complete", "Step 2 complete") | Write-Log
    
    # Log process names
    Get-Process | Select-Object -First 5 | ForEach-Object {
        "Process: $($_.Name) - Memory: $($_.WorkingSet64 / 1MB)MB"
    } | Write-Log -LogLevel "DEBUG"

.EXAMPLE
    # Error handling with detailed logging
    Import-Module PSLogger
    Initialize-Log -Default -LogName "ErrorHandler"
    
    Try {
        Write-LogInfo "Attempting database connection..."
        # Your code here
        Throw "Connection timeout"
    }
    Catch {
        Write-LogError "Database connection failed: $_"
        Write-LogDebug "Stack trace: $($_.ScriptStackTrace)"
        Write-LogDebug "Error position: Line $($_.InvocationInfo.ScriptLineNumber)"
    }
    Finally {
        Write-LogInfo "Cleanup completed"
    }

.EXAMPLE
    # Custom timestamp format and encoding
    Import-Module PSLogger
    
    $CustomLog = Initialize-Log -LogName "International" `
                                -DateTimeFormat "dd/MM/yyyy HH:mm:ss" `
                                -Encoding "UTF8"
    
    Write-Log "Custom formatted entry" -Logger $CustomLog
    # Output: [15/08/2025 14:30:45][INFO] Custom formatted entry

.EXAMPLE
    # Production setup with all features
    Import-Module PSLogger

    # Initialize comprehensive logging for production
    $ProdConfig = @{
        Default = $true
        LogName = "ProductionApp"
        LogPath = "E:\Logs\Application"
        LogLevel = "INFO"
        DateTimeFormat = "yyyy-MM-dd HH:mm:ss.fff"
        Encoding = "UTF8"
        LogRoll = $true
        LogRotateOpt = "100M"
        LogZip = $true
        LogCountMax = 30
        LogRetry = 5
        WriteConsole = $false
    }

    Initialize-Log @ProdConfig

    # Use throughout application
    Write-LogInfo "Application version 1.0.0 started"
    Write-LogInfo "Configuration loaded from: $ConfigPath"
    Write-LogSuccess "All services initialized"

.EXAMPLE
    # Using helper functions with enrichers and handlers
    Import-Module PSLogger

    # Create logger with fluent configuration
    $log = New-Logger -LogName "EnrichedApp" -LogPath "C:\Logs" -LogRoll -LogZip

    # Add enrichers for contextual information
    Add-LogEnricher -Logger $log -Enricher (New-MachineEnricher)
    Add-LogEnricher -Logger $log -Enricher (New-ProcessEnricher)
    Add-LogEnricher -Logger $log -Enricher (New-ThreadEnricher)

    # Add multiple output handlers
    Add-LogHandler -Logger $log -Handler (New-ConsoleHandler)
    Add-LogHandler -Logger $log -Handler (New-EventLogHandler -LogName "Application" -Source "MyApp")

    # Add filter to only log during business hours
    Add-LogFilter -Logger $log -Filter (New-TimeFilter -StartHour 8 -EndHour 17)

    # Set as default logger
    Set-DefaultLogger -Logger $log

    # All logs now include machine, process, and thread context
    Write-Log "Application started with full context"

.EXAMPLE
    # Using scoped properties for hierarchical context
    Import-Module PSLogger

    $log = New-Logger -LogName "RequestTracking"

    function Process-WebRequest {
        param($RequestId, $UserId)

        # Add request context
        Using (Start-LogScope -Logger $log -Key "RequestId" -Value $RequestId) {
            Write-Log "Request received"

            # Add user context within request scope
            Using (Start-LogScope -Logger $log -Key "UserId" -Value $UserId) {
                Write-Log "Authenticating user"
                Write-Log "Processing request"
                Write-Log "Request completed"
            }
            # UserId automatically removed after inner scope

            Write-Log "Cleaning up request resources"
        }
        # RequestId automatically removed after outer scope
    }

    Process-WebRequest -RequestId "REQ-12345" -UserId "user@example.com"

.EXAMPLE
    # Creating multiple specialized loggers
    Import-Module PSLogger

    # Error logger - only captures errors and critical events
    $errorLog = New-Logger -LogName "Errors" -LogPath "C:\Logs" -LogLevel "ERROR"
    Add-LogHandler -Logger $errorLog -Handler (New-EventLogHandler -LogName "Application" -Source "MyApp")

    # Performance logger - captures timing information
    $perfLog = New-Logger -LogName "Performance" -LogPath "C:\Logs"
    Add-LogEnricher -Logger $perfLog -Enricher (New-ProcessEnricher)

    # Audit logger - captures all user actions
    $auditLog = New-Logger -LogName "Audit" -LogPath "C:\Logs\Audit"
    Add-LogEnricher -Logger $auditLog -Enricher (New-MachineEnricher)
    $userFilter = New-UserFilter -AllowedUsers @("admin", "operator", "manager")
    Add-LogFilter -Logger $auditLog -Filter $userFilter

    # Use specialized loggers throughout application
    Write-LogError "Database connection failed" -Logger $errorLog
    Write-Log "Query executed in 250ms" -Logger $perfLog
    Write-Log "User modified configuration" -Logger $auditLog

.NOTES
    Module Name: PSLogger
    Author: Mark Newton
    Created: 08/15/2025
    Version: 2.0.0
    PowerShell Version: 5.0+

    CHANGELOG:
    2.0.0 - Major enhancement release (2025-11-05)
          - Added 24 new helper functions for intuitive logger management
          - Logger Management: New-Logger, Get-Logger, Set-DefaultLogger, Get-DefaultLogger
          - Enricher Support: Add-LogEnricher, New-MachineEnricher, New-ProcessEnricher,
            New-ThreadEnricher, New-EnvironmentEnricher, New-NetworkEnricher
          - Handler Support: Add-LogHandler, New-FileHandler, New-ConsoleHandler,
            New-EventLogHandler, New-NullHandler
          - Filter Support: Add-LogFilter, New-FunctionFilter, New-TimeFilter, New-UserFilter
          - Scoped Properties: Start-LogScope for hierarchical context tracking
          - Enhanced module documentation with comprehensive examples
          - Improved Export-ModuleMember organization with categories

    1.0.0 - Initial release (2025-08-15)
          - Core logging functionality with multiple levels
          - Log rotation by size and age
          - Zip compression support
          - Console output options
          - Multiple logger instances
          - Pipeline support
          - Retry mechanism
    
    KNOWN ISSUES:
    - Zip compression requires Windows PowerShell 5.0+ or PowerShell Core
    - File locks may occur with multiple processes writing to same log
    - Large zip archives (>2GB) may have performance impact during rotation
    
    REQUIREMENTS:
    - Windows PowerShell 5.0 or higher
    - Write permissions to log directory
    - Sufficient disk space for log storage
    
    BEST PRACTICES:
    - Initialize loggers at script start
    - Use appropriate log levels consistently
    - Implement log rotation for long-running scripts
    - Include contextual information in log messages
    - Use separate loggers for different components
    - Regular cleanup of old archived logs
    
.LINK
    https://github.com/MarkusMcNugen/PSLogger

.LINK
    https://github.com/MarkusMcNugen/PSLogger/wiki

.LINK
    https://github.com/MarkusMcNugen/PSLogger/issues

.LINK
    about_PSLogger

.COMPONENT
    Logging

.ROLE
    Administration

.FUNCTIONALITY
    Provides comprehensive logging capabilities for PowerShell scripts and modules
#>

# ================================
# ===    MODULE METADATA       ===
# ================================
$ModuleVersion = '2.0.0'
$ModuleAuthor = 'Mark Newton'
$ModuleDescription = 'Advanced PowerShell logging module with enrichers, handlers, filters, and scoped properties'

# ================================
# ===    LOGGING FUNCTIONS     ===
# ================================
#region Logging

Class Logger {
    <#
    .SYNOPSIS
    Enterprise-grade logging class with advanced features for production PowerShell scripts

    .DESCRIPTION
    Provides comprehensive logging functionality for enterprise PowerShell automation with 26+ features:

    CORE FEATURES:
    - Automatic log rotation based on size, age, or time-based patterns (daily/weekly/monthly)
    - Optional compression of rotated logs into zip archives with retention policies
    - Configurable retry logic with exponential backoff for file access conflicts
    - Simultaneous console and file output with independent formatting and color coding
    - Customizable timestamp formats and multiple encoding options (Unicode, UTF8, ASCII, etc.)
    - Log level filtering with priority hierarchy (CRITICAL > ERROR > WARNING > SUCCESS > INFO > DEBUG)

    STRUCTURED LOGGING:
    - JSON structured logging for SIEM integration and machine parsing
    - Log enrichers for automatic context injection (machine, process, thread, environment, network)
    - Correlation IDs for distributed tracing and request tracking
    - Scoped properties with automatic cleanup using IDisposable pattern

    PERFORMANCE OPTIMIZATION:
    - Lazy string formatting to avoid expensive operations for filtered messages
    - Buffered/asynchronous writes to minimize disk I/O overhead
    - Log sampling to reduce volume in high-throughput scenarios
    - Efficient memory usage with ArrayList-based buffering

    ERROR HANDLING:
    - Dedicated exception logging with full stack traces and inner exceptions
    - Automatic HResult capture for Windows-specific error codes
    - Thread-safe file writes with mutex protection

    MULTI-TARGET OUTPUT:
    - Handlers/Targets architecture for flexible output destinations
    - Built-in handlers: File, Console, EventLog, Null
    - Windows Event Log integration with automatic source registration

    ADVANCED FILTERING:
    - Custom filter chains with extensible ILogFilter interface
    - Built-in filters: Function name, time-based, user-based
    - Filter composition for complex routing logic

    VALIDATION & SAFETY:
    - Path validation for rooted paths and UNC shares
    - Disk space checking before writes
    - File name validation for cross-platform compatibility
    - Long path support (> 260 characters)

    .EXAMPLE
    # Create a basic logger with default settings
    $Logger = [Logger]::new("MyLog")
    $Logger.Write("Application started")

    .EXAMPLE
    # Create a logger with custom path and warning level
    $Logger = [Logger]::new("ApplicationLog", "C:\Logs", "WARNING")
    $Logger.Write("This is a warning message", "WARNING")

    .EXAMPLE
    # Configure log rotation by size (10MB) with compression
    $Logger = [Logger]::new()
    $Logger.LogName = "RotatingLog"
    $Logger.LogRotateOpt = "10M"  # Rotate at 10MB
    $Logger.LogZip = $True         # Compress rotated logs
    $Logger.LogCountMax = 5        # Keep max 5 rotated logs
    $Logger.Write("This message will be in a log that rotates at 10MB")

    .EXAMPLE
    # Configure time-based rotation (daily)
    $Logger = [Logger]::new("DailyLog")
    $Logger.LogRoll = $True
    $Logger.LogRotateOpt = "daily"  # Rotate daily at midnight
    $Logger.Write("This log rotates daily")

    .EXAMPLE
    # Configure time-based rotation (weekly)
    $Logger = [Logger]::new("WeeklyLog")
    $Logger.LogRoll = $True
    $Logger.LogRotateOpt = "weekly"  # Rotate every 7 days
    $Logger.Write("This log rotates weekly")

    .EXAMPLE
    # Configure time-based rotation (custom interval: every 3 days)
    $Logger = [Logger]::new("CustomLog")
    $Logger.LogRoll = $True
    $Logger.LogRotateOpt = "3d"  # Rotate every 3 days
    $Logger.Write("This log rotates every 3 days")

    .EXAMPLE
    # Use structured logging with enrichers
    $Logger = [Logger]::new("AppLog")
    $Logger.StructuredLogging = $true
    $Logger.Enrichers.Add([MachineEnricher]::new())
    $Logger.Enrichers.Add([ProcessEnricher]::new())
    $Logger.Write("User logged in")
    # Output: {"timestamp":"2025-11-05T10:30:45Z","level":"INFO","message":"User logged in","machineName":"SERVER01","userName":"admin","processId":1234,"processName":"powershell"}

    .EXAMPLE
    # Use correlation IDs for distributed tracing
    $Logger = [Logger]::new("WebLog")
    $Logger.SetCorrelationId()  # Auto-generates GUID
    $Logger.Write("Request started")
    $Logger.Write("Processing data")
    $Logger.Write("Request completed")
    $Logger.ClearCorrelationId()
    # All logs between Set and Clear include the same correlation ID

    .EXAMPLE
    # Use lazy string formatting for performance
    $Logger = [Logger]::new("PerfLog")
    $Logger.LogFilter = "WARNING"  # Only log WARNING and above
    # This string format is NEVER executed because DEBUG is filtered out
    $Logger.Write("Processing item {0} of {1}", @($i, $total), "DEBUG")

    .EXAMPLE
    # Log exceptions with full stack traces
    $Logger = [Logger]::new("ErrorLog")
    Try {
        Get-Content "C:\missing.csv"
    } Catch {
        $Logger.WriteException($_.Exception, "Failed to load customer data")
    }
    # Logs exception type, message, HResult, stack trace, and inner exceptions

    .EXAMPLE
    # Use handlers for multi-target logging
    $Logger = [Logger]::new("MultiLog")
    $Logger.AddHandler([FileHandler]::new("C:\Logs\app.log"))
    $Logger.AddHandler([ConsoleHandler]::new())
    $eventHandler = [EventLogHandler]::new("MyApplication")
    $eventHandler.MinimumLevel = "ERROR"  # Only log errors to Event Log
    $Logger.AddHandler($eventHandler)
    $Logger.Write("This goes to file, console, and Event Log (if ERROR level)")

    .EXAMPLE
    # Use buffered writes for high-performance logging
    $Logger = [Logger]::new("HighVolume")
    $Logger.BufferedWrites = $true
    $Logger.BufferSize = 1000  # Flush after 1000 messages
    1..10000 | ForEach-Object {
        $Logger.Write("Processing item $_")
    }
    $Logger.FlushBuffer()  # Force flush remaining messages

    .EXAMPLE
    # Use log sampling to reduce volume
    $Logger = [Logger]::new("SampledLog")
    $Logger.EnableSampling = $true
    $Logger.SampleRate = 100  # Log every 100th message
    1..10000 | ForEach-Object {
        $Logger.Write("High-frequency event $_")
    }
    # Only ~100 messages are actually logged

    .EXAMPLE
    # Use scoped properties with automatic cleanup
    $Logger = [Logger]::new("ScopedLog")
    $Logger.StructuredLogging = $true
    Using ($scope = $Logger.PushProperty("RequestId", "12345")) {
        $Logger.Write("Processing request")
        $Logger.Write("Querying database")
    }  # RequestId automatically removed after using block
    $Logger.Write("This message has no RequestId")

    .NOTES
    Thread Safety: The Logger class uses retry logic with delays to handle concurrent access.
                   For true multi-threaded scenarios, consider using BufferedWrites with
                   appropriate FlushIntervalSeconds settings.

    Performance: Use StructuredLogging only when needed (SIEM integration, JSON parsing).
                 Traditional text format is ~3x faster for file-only logging.

    Disk Space: Log rotation and compression are critical for long-running scripts.
                Monitor disk usage and configure appropriate LogCountMax values.
    #>

    # Required properties
    [string]$LogName
    [string]$LogPath
    [string]$LogLevel

    # Optional configuration properties
    [string]$DateTimeFormat
    [bool]$NoLogInfo
    [string]$Encoding
    [bool]$LogRoll
    [int]$LogRetry
    [bool]$WriteConsole
    [bool]$ConsoleOnly
    [bool]$ConsoleInfo
    [string]$LogRotateOpt
    [bool]$LogZip
    [int]$LogCountMax
    [string]$LogFilter
    [int]$LogRetryDelayMs

    # Structured Logging (JSON)
    [bool]$StructuredLogging = $false
    [string]$StructuredFormat = "JSON"

    # Log Enrichers
    [System.Collections.ArrayList]$Enrichers

    # Correlation IDs
    [string]$CorrelationId = $null

    # Handlers/Targets
    [System.Collections.ArrayList]$Handlers

    # Filters
    [System.Collections.ArrayList]$Filters

    # Scoped Properties
    [hashtable]$ScopedProperties

    # Event Log Integration
    [bool]$WriteToEventLog = $false
    [string]$EventLogName = 'Application'
    [string]$EventSource = 'PowerShellLogger'

    # Buffered Writes
    [bool]$BufferedWrites = $false
    [int]$BufferSize = 100
    [int]$FlushIntervalSeconds = 5

    # Log Sampling
    [bool]$EnableSampling = $false
    [int]$SampleRate = 10

    # Hidden properties
    hidden [string]$LogFile
    hidden [hashtable]$LogLevelPriority
    hidden [System.Collections.ArrayList]$WriteBuffer
    hidden [datetime]$LastFlushTime
    hidden [int]$SampleCounter

    # Default constructor
    Logger() {
        $This.InitializeDefaults()
    }

    # Constructor with basic parameters
    Logger([string]$LogName) {
        $This.InitializeDefaults()
        $This.LogName = $LogName
    }

    # Constructor with extended parameters
    Logger([string]$LogName, [string]$LogPath) {
        $This.InitializeDefaults()
        $This.LogName = $LogName
        $This.LogPath = $LogPath
    }

    # Constructor with most common parameters
    Logger([string]$LogName, [string]$LogPath, [string]$LogLevel) {
        $This.InitializeDefaults()
        $This.LogName = $LogName
        $This.LogPath = $LogPath
        $This.LogLevel = $LogLevel
    }

    # Initialize default values for all properties
    hidden [void] InitializeDefaults() {
        $This.LogName = "Debug"
        $This.LogPath = "C:\Temp"
        $This.LogLevel = "INFO"

        # Validate defaults
        $This.ValidateLogName($This.LogName) | Out-Null
        $This.DateTimeFormat = 'yyyy-MM-dd HH:mm:ss'
        $This.NoLogInfo = $False
        $This.Encoding = 'Unicode'
        $This.LogRoll = $False
        $This.LogRetry = 2
        $This.WriteConsole = $False
        $This.ConsoleOnly = $False
        $This.ConsoleInfo = $False
        $This.LogRotateOpt = "1M"
        $This.LogZip = $False
        $This.LogCountMax = 5
        $This.LogFilter = "DEBUG"  # Default to showing all messages
        $This.LogRetryDelayMs = 500  # Delay between retries

        # Initialize log level priority (lower number = higher priority)
        $This.LogLevelPriority = @{
            'CRITICAL' = 1
            'ERROR'    = 2
            'WARNING'  = 3
            'SUCCESS'  = 4
            'INFO'     = 5
            'DEBUG'    = 6
        }

        # Initialize new collections
        $This.Enrichers = New-Object System.Collections.ArrayList
        $This.Handlers = New-Object System.Collections.ArrayList
        $This.Filters = New-Object System.Collections.ArrayList
        $This.ScopedProperties = @{}
        $This.WriteBuffer = New-Object System.Collections.ArrayList
        $This.LastFlushTime = Get-Date
        $This.SampleCounter = 0

        # Set the log file path
        $This.LogFile = "$($This.LogPath)\$($This.LogName).log"
    }

    <#
    .SYNOPSIS
    Validates log file path for security and correctness

    .PARAMETER Path
    String path to validate. Must be an absolute path (not relative). Supports UNC paths.

    .EXAMPLE
    $Logger.ValidatePath("C:\Logs")  # Returns $true
    $Logger.ValidatePath("..\Logs")  # Returns $false (relative path)
    #>
    hidden [bool] ValidatePath([string]$Path) {
        Try {
            # Normalize trailing slashes for consistent handling
            $PathToValidate = $Path.TrimEnd('\', '/')

            # Check if the original path is rooted (not relative)
            # This must be checked BEFORE GetFullPath which converts relative to absolute
            If (-not [System.IO.Path]::IsPathRooted($PathToValidate)) {
                Write-Warning "Path must be absolute: $Path"
                Return $False
            }

            # Now resolve to full path (handles UNC paths, environment variables, etc.)
            $ResolvedPath = [System.IO.Path]::GetFullPath($PathToValidate)

            # UNC paths are valid if rooted (already validated above)
            # UNC paths start with \\ or are in format \\server\share

            # Check path length (Windows MAX_PATH is 260 characters)
            # Use long path prefix for paths over 260 chars
            If ($ResolvedPath.Length -ge 260) {
                If (-not $ResolvedPath.StartsWith("\\?\")) {
                    Write-Warning "Path exceeds 260 characters. Consider using shorter path or enable long path support."
                    # Still allow it, but warn
                }
            }

            Return $True
        } Catch {
            Write-Warning "Path may exceed Windows limits: $Path - $_"
            Return $true  # Allow it with warning, don't fail
        }
    }

    <#
    .SYNOPSIS
    Checks available disk space before log operations

    .PARAMETER Path
    String path to check for available disk space

    .PARAMETER RequiredBytes
    Long integer specifying minimum required free space in bytes

    .EXAMPLE
    $Logger.CheckDiskSpace("C:\Logs", 10MB)  # Returns $true if 10MB+ available
    #>
    hidden [bool] CheckDiskSpace([string]$Path, [long]$RequiredBytes) {
        Try {
            $Drive = [System.IO.Path]::GetPathRoot($Path)
            $DriveInfo = [System.IO.DriveInfo]::new($Drive)

            If ($DriveInfo.AvailableFreeSpace -lt $RequiredBytes) {
                Write-Warning "Insufficient disk space on $Drive. Required: $($RequiredBytes/1MB)MB, Available: $($DriveInfo.AvailableFreeSpace/1MB)MB"
                Return $False
            }

            Return $True
        } Catch {
            Write-Verbose "Could not check disk space: $_"
            # Don't fail on disk space check errors
            Return $True
        }
    }

    <#
    .SYNOPSIS
    Validates log name for file system compatibility

    .PARAMETER LogName
    String name to validate. Must not contain invalid file system characters.

    .EXAMPLE
    $Logger.ValidateLogName("Application")  # Returns $true
    $Logger.ValidateLogName("App:Log")  # Returns $false (colon invalid)
    #>
    hidden [bool] ValidateLogName([string]$LogName) {
        # Check for invalid file system characters
        $InvalidChars = [System.IO.Path]::GetInvalidFileNameChars()
        ForEach ($Char in $InvalidChars) {
            If ($LogName.Contains($Char)) {
                Write-Warning "Log name contains invalid character: '$Char'"
                Return $False
            }
        }

        # Warn about non-ASCII characters
        If ($LogName -match '[^\x00-\x7F]') {
            Write-Warning "Log name contains non-ASCII characters. This may cause issues on some file systems."
            # Still allow it, but warn
        }

        Return $True
    }

    <#
    .SYNOPSIS
    Updates internal LogFile path when LogName or LogPath properties change

    .EXAMPLE
    $Logger.LogPath = "D:\Logs"
    $Logger.UpdateLogFile()  # Updates LogFile to "D:\Logs\[LogName].log"
    #>
    [void] UpdateLogFile() {
        $This.LogFile = "$($This.LogPath)\$($This.LogName).log"
    }

    <#
    .SYNOPSIS
    Writes log message using lazy string formatting for performance optimization

    .DESCRIPTION
    Defers expensive string formatting operations until after log level filtering.
    Only formats the string if the message will actually be logged, avoiding
    unnecessary CPU cycles for filtered messages.

    .PARAMETER MessageTemplate
    String format template with {0}, {1}, etc. placeholders

    .PARAMETER Arguments
    Object array of arguments to insert into template

    .PARAMETER LogLevel
    String severity level (INFO, WARNING, ERROR, DEBUG, SUCCESS, CRITICAL)

    .EXAMPLE
    $Logger.Write("Processing item {0} of {1}", @($i, $total), "DEBUG")
    # If DEBUG is filtered out, the format operation is never executed
    #>
    [void] Write([string]$MessageTemplate, [object[]]$Arguments, [string]$LogLevel) {
        # Check filter FIRST (before expensive string formatting)
        If (-not $This.ShouldLog($LogLevel)) {
            Return  # Skip without formatting - HUGE performance gain!
        }

        # Now format (only if we're actually logging)
        $LogMsg = $MessageTemplate -f $Arguments
        $This.Write($LogMsg, $LogLevel)
    }

    <#
    .SYNOPSIS
    Logs exception with full stack trace and inner exception details

    .PARAMETER Exception
    System.Exception object to log

    .EXAMPLE
    Try { Get-Content "missing.csv" } Catch { $Logger.WriteException($_.Exception) }
    #>
    [void] WriteException([System.Exception]$Exception) {
        $This.WriteException($Exception, "")
    }

    <#
    .SYNOPSIS
    Logs exception with contextual message, full stack trace, and inner exception details

    .DESCRIPTION
    Captures comprehensive exception information including type, message, HResult,
    stack trace, and recursively logs inner exceptions.

    .PARAMETER Exception
    System.Exception object to log

    .PARAMETER ContextMessage
    String providing context about when/where the exception occurred

    .EXAMPLE
    Try { $data = Get-Content "C:\missing.csv" }
    Catch { $Logger.WriteException($_.Exception, "Failed to load customer data") }
    #>
    [void] WriteException([System.Exception]$Exception, [string]$ContextMessage) {
        $exceptionDetails = @"
$ContextMessage
Exception Type: $($Exception.GetType().FullName)
Message: $($Exception.Message)
HResult: $($Exception.HResult)
Stack Trace:
$($Exception.StackTrace)
"@

        # Include inner exceptions
        $inner = $Exception.InnerException
        If ($inner) {
            $exceptionDetails += "`nInner Exception: $($inner.GetType().FullName)"
            $exceptionDetails += "`nInner Message: $($inner.Message)"

            # Include inner exception stack trace
            If ($inner.StackTrace) {
                $exceptionDetails += "`nInner Stack Trace:"
                $exceptionDetails += "`n$($inner.StackTrace)"
            }
        }

        $This.Write($exceptionDetails, 'ERROR')
    }

    <#
    .SYNOPSIS
    Formats log entry as JSON for machine parsing and SIEM integration

    .DESCRIPTION
    Converts log message into structured JSON format with automatic enrichment.
    Includes timestamp (ISO 8601), level, message, machine info, and applies
    all configured enrichers and scoped properties.

    .PARAMETER LogMsg
    String message to include in JSON output

    .PARAMETER LogLevel
    String severity level to include in JSON output

    .EXAMPLE
    $json = $Logger.FormatAsJson("User logged in", "INFO")
    # Returns: {"timestamp":"2025-11-05T10:30:45Z","level":"INFO","message":"User logged in",...}
    #>
    hidden [string] FormatAsJson([string]$LogMsg, [string]$LogLevel) {
        # Build base log object (use regular hashtable for enricher compatibility)
        $logObject = @{
            timestamp = [datetime]::UtcNow.ToString('o')  # ISO 8601 format
            level = $LogLevel
            message = $LogMsg
            machineName = $env:COMPUTERNAME
            userName = $env:USERNAME
            processId = [System.Diagnostics.Process]::GetCurrentProcess().Id
        }

        # Add correlation ID if present
        If (-not [string]::IsNullOrEmpty($This.CorrelationId)) {
            $logObject['correlationId'] = $This.CorrelationId
        }

        # Add scoped properties
        ForEach ($key in $This.ScopedProperties.Keys) {
            $logObject[$key] = $This.ScopedProperties[$key]
        }

        # Apply enrichers
        ForEach ($enricher in $This.Enrichers) {
            Try {
                $enricher.Enrich($logObject)
            } Catch {
                Write-Verbose "Enricher failed: $_"
            }
        }

        # Convert to JSON (compressed for smaller file size)
        Return ($logObject | ConvertTo-Json -Compress)
    }

    <#
    .SYNOPSIS
    Sets correlation ID for distributed tracing and request tracking

    .DESCRIPTION
    Associates all subsequent log messages with the specified correlation ID
    until ClearCorrelationId() is called. Auto-generates GUID if ID is empty.

    .PARAMETER Id
    String correlation ID to set. If empty/null, auto-generates a GUID.

    .EXAMPLE
    $Logger.SetCorrelationId("REQ-12345")
    $Logger.Write("Processing request")  # Includes correlation ID
    $Logger.ClearCorrelationId()
    #>
    [void] SetCorrelationId([string]$Id) {
        If ([string]::IsNullOrEmpty($Id)) {
            # Auto-generate if not provided
            $This.CorrelationId = [Guid]::NewGuid().ToString()
        } Else {
            $This.CorrelationId = $Id
        }
    }

    <#
    .SYNOPSIS
    Auto-generates a new GUID correlation ID for distributed tracing

    .EXAMPLE
    $Logger.SetCorrelationId()  # Auto-generates GUID like "a1b2c3d4-..."
    #>
    [void] SetCorrelationId() {
        $This.CorrelationId = [Guid]::NewGuid().ToString()
    }

    <#
    .SYNOPSIS
    Removes correlation ID from subsequent log messages

    .EXAMPLE
    $Logger.ClearCorrelationId()  # Future logs won't include correlation ID
    #>
    [void] ClearCorrelationId() {
        $This.CorrelationId = $null
    }

    <#
    .SYNOPSIS
    Adds a handler to the logger's output targets collection

    .PARAMETER Handler
    LogHandler object (FileHandler, ConsoleHandler, EventLogHandler, NullHandler)

    .EXAMPLE
    $Logger.AddHandler([FileHandler]::new("C:\Logs\app.log"))
    $Logger.AddHandler([ConsoleHandler]::new())
    #>
    [void] AddHandler([LogHandler]$Handler) {
        $This.Handlers.Add($Handler) | Out-Null
    }

    <#
    .SYNOPSIS
    Removes a handler from the logger's output targets collection

    .PARAMETER HandlerName
    String name of the handler to remove

    .EXAMPLE
    $Logger.RemoveHandler("FileHandler")
    #>
    [void] RemoveHandler([string]$HandlerName) {
        $handlerToRemove = $This.Handlers | Where-Object { $_.Name -eq $HandlerName }
        If ($handlerToRemove) {
            $This.Handlers.Remove($handlerToRemove) | Out-Null
        }
    }

    <#
    .SYNOPSIS
    Adds a custom filter to the logger's filter chain

    .PARAMETER Filter
    ILogFilter object implementing ShouldFilter() method

    .EXAMPLE
    $Logger.AddFilter([FunctionFilter]::new(@("InternalHelper")))
    #>
    [void] AddFilter([ILogFilter]$Filter) {
        $This.Filters.Add($Filter) | Out-Null
    }

    <#
    .SYNOPSIS
    Removes a filter from the logger's filter chain

    .PARAMETER Filter
    ILogFilter object to remove

    .EXAMPLE
    $Logger.RemoveFilter($myFilter)
    #>
    [void] RemoveFilter([ILogFilter]$Filter) {
        $This.Filters.Remove($Filter) | Out-Null
    }

    <#
    .SYNOPSIS
    Evaluates whether log record passes all configured filters

    .PARAMETER LogRecord
    Hashtable containing log record properties (Message, Level, Timestamp, FunctionName)

    .EXAMPLE
    $passes = $Logger.PassesFilters(@{Message="Test"; Level="INFO"; Timestamp=(Get-Date); FunctionName="Main"})
    #>
    hidden [bool] PassesFilters([hashtable]$LogRecord) {
        ForEach ($filter in $This.Filters) {
            Try {
                If (-not $filter.ShouldFilter($LogRecord)) {
                    Return $false
                }
            } Catch {
                Write-Verbose "Filter failed: $_"
            }
        }
        Return $true
    }

    <#
    .SYNOPSIS
    Adds a scoped property that appears in all log messages within scope

    .DESCRIPTION
    Returns IDisposable object for automatic cleanup with Using statement.
    Property is automatically removed when Using block exits.

    .PARAMETER Key
    String property name

    .PARAMETER Value
    Property value of any type

    .EXAMPLE
    Using ($scope = $Logger.PushProperty("RequestId", "12345")) {
        $Logger.Write("Processing")  # Includes RequestId
    }  # RequestId automatically removed
    #>
    [PropertyScope] PushProperty([string]$Key, $Value) {
        $This.ScopedProperties[$Key] = $Value
        Return [PropertyScope]::new($This, $Key)
    }

    <#
    .SYNOPSIS
    Removes a scoped property from the logger

    .PARAMETER Key
    String property name to remove
    #>
    hidden [void] RemoveProperty([string]$Key) {
        $This.ScopedProperties.Remove($Key)
    }

    <#
    .SYNOPSIS
    Writes log message to Windows Event Log

    .PARAMETER LogMsg
    String message to write to Event Log

    .PARAMETER LogLevel
    String severity level. Maps to Event Log types: ERROR/CRITICAL->Error, WARNING->Warning, others->Information

    .EXAMPLE
    $Logger.WriteEventLog("Service started", "INFO")  # Writes as Information event
    #>
    hidden [void] WriteEventLog([string]$LogMsg, [string]$LogLevel) {
        If (-not $This.WriteToEventLog) { Return }

        $EventType = Switch ($LogLevel) {
            'CRITICAL' { 'Error' }
            'ERROR' { 'Error' }
            'WARNING' { 'Warning' }
            Default { 'Information' }
        }

        Try {
            # Ensure source exists (requires admin first time)
            If (-not [System.Diagnostics.EventLog]::SourceExists($This.EventSource)) {
                Try {
                    [System.Diagnostics.EventLog]::CreateEventSource($This.EventSource, $This.EventLogName)
                } Catch {
                    Write-Verbose "Could not create Event Log source (requires admin): $_"
                    Return
                }
            }

            # Write to Event Log
            Write-EventLog -LogName $This.EventLogName -Source $This.EventSource `
                -EntryType $EventType -EventId 1000 -Message $LogMsg -ErrorAction Stop
        } Catch {
            Write-Verbose "Could not write to Event Log: $_"
        }
    }

    <#
    .SYNOPSIS
    Adds message to write buffer for batch processing

    .PARAMETER Message
    String formatted message to buffer

    .EXAMPLE
    $Logger.BufferedWrite("[2025-11-05 10:30:45][INFO] Processing")
    #>
    hidden [void] BufferedWrite([string]$Message) {
        $This.WriteBuffer.Add($Message) | Out-Null

        # Flush if buffer full OR time elapsed
        $ShouldFlush = ($This.WriteBuffer.Count -ge $This.BufferSize) -or `
                       (((Get-Date) - $This.LastFlushTime).TotalSeconds -ge $This.FlushIntervalSeconds)

        If ($ShouldFlush) {
            $This.FlushBuffer()
        }
    }

    <#
    .SYNOPSIS
    Flushes all buffered messages to disk immediately

    .DESCRIPTION
    Writes all pending buffered messages to log file in a single operation.
    Should be called before script exit when BufferedWrites is enabled.

    .EXAMPLE
    $Logger.FlushBuffer()  # Write all pending messages
    #>
    [void] FlushBuffer() {
        If ($This.WriteBuffer.Count -eq 0) { Return }

        Try {
            # Write all buffered messages at once
            $allMessages = $This.WriteBuffer -join "`n"
            Add-Content -Path $This.LogFile -Value $allMessages -Encoding $This.Encoding -ErrorAction Stop

            $This.WriteBuffer.Clear()
            $This.LastFlushTime = Get-Date
        } Catch {
            Write-Warning "Failed to flush buffer: $_"
        }
    }

    <#
    .SYNOPSIS
    Closes logger and flushes any remaining buffered messages

    .DESCRIPTION
    Should be called before disposing of logger instance to ensure
    all buffered messages are written to disk.

    .EXAMPLE
    $Logger.Close()  # Flush buffer and close
    #>
    [void] Close() {
        $This.FlushBuffer()
    }

    <#
    .SYNOPSIS
    Determines if message should be sampled based on configured rate

    .DESCRIPTION
    Implements counter-based sampling. Logs every Nth message where N is SampleRate.
    Returns true to log the message, false to skip.

    .EXAMPLE
    If ($Logger.ShouldSample()) { $Logger.Write("Message") }
    #>
    hidden [bool] ShouldSample() {
        If (-not $This.EnableSampling) {
            Return $true  # Sampling disabled, log everything
        }

        $This.SampleCounter++

        # Log every Nth message
        If ($This.SampleCounter -ge $This.SampleRate) {
            $This.SampleCounter = 0
            Return $true
        }

        Return $false
    }

    <#
    .SYNOPSIS
    Determines if log should rotate based on time-based patterns

    .DESCRIPTION
    Evaluates time-based rotation patterns: daily, weekly, monthly, or custom intervals (Nd, Nw, Nmo).
    Compares log file's LastWriteTime against current time.

    .EXAMPLE
    If ($Logger.ShouldRotateByTime()) { $Logger.PerformRotation(...) }
    #>
    hidden [bool] ShouldRotateByTime() {
        $pattern = $This.LogRotateOpt.ToLower()

        Try {
            $fileInfo = Get-Item -Path $This.LogFile -ErrorAction Stop
            $lastWrite = $fileInfo.LastWriteTime
            $now = Get-Date

            Switch -Regex ($pattern) {
                '^daily$|^1d$' {
                    # Rotate if last write was on different day
                    Return $lastWrite.Date -lt $now.Date
                }
                '^weekly$|^1w$' {
                    # Rotate if more than 7 days old
                    Return ($now - $lastWrite).Days -ge 7
                }
                '^monthly$|^1mo$' {
                    # Rotate if in different month
                    Return ($lastWrite.Month -ne $now.Month) -or ($lastWrite.Year -ne $now.Year)
                }
                '^\d+d$' {
                    # Custom days (e.g., "3d" = every 3 days)
                    $days = [int]($pattern -replace 'd$', '')
                    Return ($now - $lastWrite).Days -ge $days
                }
                '^\d+w$' {
                    # Custom weeks (e.g., "2w" = every 2 weeks)
                    $weeks = [int]($pattern -replace 'w$', '')
                    Return ($now - $lastWrite).Days -ge ($weeks * 7)
                }
                '^\d+mo$' {
                    # Custom months (e.g., "3mo" = every 3 months)
                    $months = [int]($pattern -replace 'mo$', '')
                    $monthsDiff = (($now.Year - $lastWrite.Year) * 12) + ($now.Month - $lastWrite.Month)
                    Return $monthsDiff -ge $months
                }
                Default {
                    Return $false
                }
            }
            # Fallback return (should never reach here due to Switch-Default, but satisfies parser)
            Return $false
        } Catch {
            Return $false
        }
    }

    <#
    .SYNOPSIS
    Writes message to log using logger's default level

    .PARAMETER LogMsg
    String message to log

    .EXAMPLE
    $Logger.Write("Application started")  # Uses logger's default LogLevel
    #>
    [void] Write([string]$LogMsg) {
        $This.Write($LogMsg, $This.LogLevel)
    }

    <#
    .SYNOPSIS
    Checks if message should be logged based on configured filter level

    .PARAMETER LogLevel
    String log level to check against filter

    .EXAMPLE
    If ($Logger.ShouldLog("DEBUG")) { $Logger.Write("Debug info") }
    #>
    hidden [bool] ShouldLog([string]$LogLevel) {
        # Get the priority of the current log level
        $CurrentPriority = $This.LogLevelPriority[$LogLevel.ToUpper()]

        # If log level is not found, default to allowing it
        If ($null -eq $CurrentPriority) {
            $CurrentPriority = 5  # Default to INFO priority
        }

        # Get the priority of the filter level
        $FilterPriority = $This.LogLevelPriority[$This.LogFilter.ToUpper()]

        # If filter level is not found, default to DEBUG (show everything)
        If ($null -eq $FilterPriority) {
            $FilterPriority = 6  # Default to DEBUG priority (lowest)
        }

        # Return true if current message priority is equal to or higher than filter
        # Lower number = higher priority, so we check if current <= filter
        Return ($CurrentPriority -le $FilterPriority)
    }

    <#
    .SYNOPSIS
    Writes message to log with specified severity level

    .DESCRIPTION
    Main logging method that handles all formatting, filtering, rotation, buffering,
    and multi-target output. Applies all configured features including sampling,
    handlers, filters, structured logging, and Event Log integration.

    .PARAMETER LogMsg
    String message to log

    .PARAMETER LogLevel
    String severity level (INFO, WARNING, ERROR, DEBUG, SUCCESS, CRITICAL)

    .EXAMPLE
    $Logger.Write("Database connection failed", "ERROR")
    $Logger.Write("Processing completed", "SUCCESS")
    #>
    [void] Write([string]$LogMsg, [string]$LogLevel) {
        # FEATURE 11: Check sampling first
        If (-not $This.ShouldSample()) {
            Return  # Skip this message due to sampling
        }

        # Check if this message should be logged based on filter
        If (-not $This.ShouldLog($LogLevel)) {
            Return  # Skip this log message
        }

        # FEATURE 7: Apply custom filters
        $logRecord = @{
            Message = $LogMsg
            Level = $LogLevel
            Timestamp = Get-Date
            FunctionName = (Get-PSCallStack)[1].Command
        }

        If (-not $This.PassesFilters($logRecord)) {
            Return  # Filtered out by custom filter
        }

        # Update log file path if needed
        $This.UpdateLogFile()

        # Validate path before attempting to use it
        If (-not $This.ValidatePath($This.LogPath)) {
            Write-Error "Invalid log path: $($This.LogPath)"
            Return
        }

        # Check available disk space (require at least 10MB)
        If (-not $This.CheckDiskSpace($This.LogPath, 10MB)) {
            Write-Error "Insufficient disk space for logging"
            Return
        }

        # If the Log directory doesn't exist, create it
        If (!(Test-Path -Path $This.LogPath)) {
            Try {
                New-Item -ItemType Directory -Path $This.LogPath -Force | Out-Null
            } Catch {
                Write-Error "Failed to create log directory: $_"
                Return
            }
        }

        # FEATURE 3: Format as JSON if structured logging enabled
        If ($This.StructuredLogging) {
            $FormattedMsg = $This.FormatAsJson($LogMsg, $LogLevel)
        } Else {
            # Traditional format with correlation ID if present
            If (-not [string]::IsNullOrEmpty($This.CorrelationId)) {
                If ($This.NoLogInfo) {
                    $FormattedMsg = "$LogMsg"
                } Else {
                    $FormattedMsg = "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel][CID:$($This.CorrelationId)] $LogMsg"
                }
            } Else {
                If ($This.NoLogInfo) {
                    $FormattedMsg = "$LogMsg"
                } Else {
                    $FormattedMsg = "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg"
                }
            }
        }

        # Handle log file deleted mid-execution or rotation
        $LogFileExists = Test-Path -Path $This.LogFile

        # If the log file doesn't exist, create it
        If (-not $LogFileExists) {
            Try {
                $startMsg = If ($This.StructuredLogging) {
                    $This.FormatAsJson("Logging started", $LogLevel)
                } Else {
                    "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] Logging started"
                }
                Write-Output $startMsg | Out-File -FilePath $This.LogFile -Append -Encoding $This.Encoding -ErrorAction Stop
            } Catch {
                Write-Error "Failed to create log file: $_"
                Return
            }
        }
        # Check if the log needs to be rotated (size/age/time-based)
        ElseIf ($This.LogRoll -and $This.ConfirmLogRotation()) {
            # Log was rotated, create new file
            Try {
                $rotateMsg = If ($This.StructuredLogging) {
                    $This.FormatAsJson("Log rotated... Logging started", $LogLevel)
                } Else {
                    "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] Log rotated... Logging started"
                }
                Write-Output $rotateMsg | Out-File -FilePath $This.LogFile -Append -Encoding $This.Encoding -ErrorAction Stop
            } Catch {
                Write-Error "Failed to create rotated log file: $_"
                Return
            }
        }

        # FEATURE 9: Write to Event Log if enabled
        $This.WriteEventLog($LogMsg, $LogLevel)

        # FEATURE 6: If handlers are configured, use them
        If ($This.Handlers.Count -gt 0) {
            ForEach ($handler in $This.Handlers) {
                Try {
                    If ($handler.ShouldLog($LogLevel, $This.LogLevelPriority)) {
                        $handler.Emit($FormattedMsg, $LogLevel)
                    }
                } Catch {
                    Write-Verbose "Handler '$($handler.Name)' failed: $_"
                }
            }
        }

        # Write to the console
        If ($This.WriteConsole) {
            # Write timestamp and log level to the console
            If ($This.ConsoleInfo) {
                Switch ($LogLevel) {
                    'CRITICAL' { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor Magenta }
                    'ERROR'    { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor Red }
                    'WARNING'  { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor Yellow }
                    'SUCCESS'  { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor Green }
                    'DEBUG'    { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor Cyan }
                    Default    { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor White }
                }
            # Write just the log message to the console
            } Else {
                Switch ($LogLevel) {
                    'CRITICAL' { Write-Host $LogMsg -ForegroundColor Magenta }
                    'ERROR'    { Write-Host $LogMsg -ForegroundColor Red }
                    'WARNING'  { Write-Host $LogMsg -ForegroundColor Yellow }
                    'SUCCESS'  { Write-Host $LogMsg -ForegroundColor Green }
                    'DEBUG'    { Write-Host $LogMsg -ForegroundColor Cyan }
                    Default    { Write-Host $LogMsg -ForegroundColor White }
                }
            }

            # Write to the console only and return to stop the function from writing to the log
            If ($This.ConsoleOnly) {
                Return
            }
        }

        # FEATURE 10: Use buffered writes if enabled
        If ($This.BufferedWrites) {
            $This.BufferedWrite($FormattedMsg)
            Return
        }

        # Initialize variables for retrying if writing to log fails
        $Saved = $False
        $Retry = 0

        # Retry writing to the log until we have success or have hit the maximum number of retries
        Do {
            # Increment retry by 1
            $Retry++

            # Try to write to the log file
            Try {
                Write-Output $FormattedMsg | Out-File -FilePath $This.LogFile -Append -Encoding $This.Encoding -ErrorAction Stop

                # Set saved variable to true. We successfully wrote to the log file.
                $Saved = $True
            } Catch {
                If (-not $Saved -and $Retry -eq $This.LogRetry) {
                    # Write the final error to the console. We were not able to write to the log file.
                    Write-Error "Logger couldn't write to the log File $($_.Exception.Message). Tried ($Retry/$($This.LogRetry)))"
                    Write-Error "Err Line: $($_.InvocationInfo.ScriptLineNumber) Err Name: $($_.Exception.GetType().FullName) Err Msg: $($_.Exception.Message)"
                } Else {
                    # Write warning to the console and try again until we hit the maximum configured number of retries
                    Write-Warning "Logger couldn't write to the log File $($_.Exception.Message). Retrying... ($Retry/$($This.LogRetry))"
                    # Sleep for configured delay
                    Start-Sleep -Milliseconds $This.LogRetryDelayMs
                }
            }
        } Until ($Saved -or $Retry -ge $This.LogRetry)
    }

    <#
    .SYNOPSIS
    Writes INFO level message

    .PARAMETER LogMsg
    String message to log

    .EXAMPLE
    $Logger.WriteInfo("Operation completed")
    #>
    [void] WriteInfo([string]$LogMsg) {
        $This.Write($LogMsg, "INFO")
    }

    <#
    .SYNOPSIS
    Writes WARNING level message

    .PARAMETER LogMsg
    String message to log

    .EXAMPLE
    $Logger.WriteWarning("Disk space low")
    #>
    [void] WriteWarning([string]$LogMsg) {
        $This.Write($LogMsg, "WARNING")
    }

    <#
    .SYNOPSIS
    Writes ERROR level message

    .PARAMETER LogMsg
    String message to log

    .EXAMPLE
    $Logger.WriteError("Connection failed")
    #>
    [void] WriteError([string]$LogMsg) {
        $This.Write($LogMsg, "ERROR")
    }

    <#
    .SYNOPSIS
    Writes DEBUG level message

    .PARAMETER LogMsg
    String message to log

    .EXAMPLE
    $Logger.WriteDebug("Variable value: x = 42")
    #>
    [void] WriteDebug([string]$LogMsg) {
        $This.Write($LogMsg, "DEBUG")
    }

    <#
    .SYNOPSIS
    Writes CRITICAL level message

    .PARAMETER LogMsg
    String message to log

    .EXAMPLE
    $Logger.WriteCritical("System failure imminent")
    #>
    [void] WriteCritical([string]$LogMsg) {
        $This.Write($LogMsg, "CRITICAL")
    }

    <#
    .SYNOPSIS
    Writes SUCCESS level message

    .PARAMETER LogMsg
    String message to log

    .EXAMPLE
    $Logger.WriteSuccess("Deployment completed")
    #>
    [void] WriteSuccess([string]$LogMsg) {
        $This.Write($LogMsg, "SUCCESS")
    }

    <#
    .SYNOPSIS
    Changes the minimum log level filter dynamically

    .PARAMETER NewFilter
    String log level to set as new filter (CRITICAL, ERROR, WARNING, SUCCESS, INFO, DEBUG)

    .EXAMPLE
    $Logger.SetLogFilter("ERROR")  # Only log ERROR and CRITICAL from now on
    #>
    [void] SetLogFilter([string]$NewFilter) {
        $ValidLevels = @('CRITICAL', 'ERROR', 'WARNING', 'SUCCESS', 'INFO', 'DEBUG')
        If ($NewFilter.ToUpper() -in $ValidLevels) {
            $This.LogFilter = $NewFilter.ToUpper()
        } Else {
            Write-Warning "Invalid log filter level: $NewFilter. Valid levels are: $($ValidLevels -join ', ')"
        }
    }

    <#
    .SYNOPSIS
    Performs log file rotation with optional compression

    .DESCRIPTION
    Common rotation logic to avoid code duplication.
    Handles both zipped and non-zipped rotation scenarios.

    .PARAMETER LogNameLocal
    String base name of log file without extension

    .PARAMETER LogPathLocal
    String directory path containing log files

    .PARAMETER ZipPath
    String full path to zip archive for compressed rotation

    .PARAMETER TempLogPath
    String temporary directory path for zip extraction/compression operations
    #>
    hidden [bool] PerformRotation([string]$LogNameLocal, [string]$LogPathLocal, [string]$ZipPath, [string]$TempLogPath) {

        If ($This.LogZip) {
            # Zip archive does not exist yet
            If (!(Test-Path $ZipPath)) {
                # Get the list of current log files
                $LogFiles = Get-ChildItem -Path $LogPathLocal -File -Filter "*.log" -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "$LogNameLocal*" } |
                    Sort-Object BaseName

                # Roll the log files
                $LogRolled = $This.StartLogRoll($LogNameLocal, $LogPathLocal, $LogFiles)

                # Update the list of current log files after rotating
                $LogFiles = Get-ChildItem -Path $LogPathLocal -File -Filter "*.log" -ErrorAction SilentlyContinue |
                    Where-Object { ($_.Name -like "$LogNameLocal*") -and ($_.Name -match '\.\d+') } |
                    Sort-Object BaseName

                # Compress each rotated log file
                ForEach ($File in $LogFiles) {
                    Try {
                        # First file creates archive, subsequent files update it
                        If (Test-Path $ZipPath) {
                            Compress-Archive -Path "$LogPathLocal\$($File.Name)" -DestinationPath $ZipPath -Update -ErrorAction Stop
                        } Else {
                            Compress-Archive -Path "$LogPathLocal\$($File.Name)" -DestinationPath $ZipPath -ErrorAction Stop
                        }
                        Remove-Item -Path "$LogPathLocal\$($File.Name)" -Force -ErrorAction SilentlyContinue
                    } Catch {
                        Write-Warning "Failed to compress/remove log file $($File.Name): $_"
                    }
                }
                Return $True
            }
            # Zip archive already exists - extract, rotate, re-compress
            Else {
                Try {
                    # Ensure the temp folder exists
                    If (-Not (Test-Path -Path $TempLogPath)) {
                        New-Item -Path $TempLogPath -ItemType Directory -Force | Out-Null
                    }

                    # Unzip to temp folder
                    Expand-Archive -Path $ZipPath -DestinationPath $TempLogPath -Force -ErrorAction Stop

                    # Get log files from temp folder
                    $LogFiles = Get-ChildItem -Path $TempLogPath -File -Filter "*.log" -ErrorAction SilentlyContinue |
                        Where-Object { ($_.Name -like "$LogNameLocal*") -and ($_.Name -match '\.\d+') } |
                        Sort-Object BaseName

                    # Roll the log files
                    $LogRolled = $This.StartLogRoll($LogNameLocal, $LogPathLocal, $LogFiles)

                    # Compress to a temporary archive first to avoid data loss if compression fails
                    # Compress-Archive requires .zip extension, so use -temp.zip suffix
                    $TempZipPath = $ZipPath -replace '\.zip$', '-temp.zip'
                    Compress-Archive -Path "$TempLogPath\*" -DestinationPath $TempZipPath -ErrorAction Stop

                    # Only after successful compression, replace the old archive
                    Remove-Item $ZipPath -Force -ErrorAction Stop
                    Move-Item $TempZipPath -Destination $ZipPath -Force -ErrorAction Stop

                    # Clean up temp folder
                    If (Test-Path $TempLogPath) {
                        Remove-Item -Path $TempLogPath -Recurse -Force -ErrorAction SilentlyContinue
                    }

                    Return $LogRolled
                } Catch {
                    Write-Warning "Failed during zip rotation: $_"
                    # Clean up temp folder and temp zip on error
                    If (Test-Path $TempLogPath) {
                        Remove-Item -Path $TempLogPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    # Clean up temp zip file if it exists
                    $TempZipPath = $ZipPath -replace '\.zip$', '-temp.zip'
                    If (Test-Path $TempZipPath) {
                        Remove-Item -Path $TempZipPath -Force -ErrorAction SilentlyContinue
                    }
                    Return $False
                }
            }
        }
        # No zipping - just rotate on disk
        Else {
            $LogFiles = Get-ChildItem -Path $LogPathLocal -File -Filter "*.log" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "$LogNameLocal*" } |
                Sort-Object BaseName
            $LogRolled = $This.StartLogRoll($LogNameLocal, $LogPathLocal, $LogFiles)
            Return $LogRolled
        }
    }

    <#
    .SYNOPSIS
    Checks if log rotation is needed based on configured thresholds

    .DESCRIPTION
    Determines if the log needs to be rotated per the parameters values.
    Supports size-based (1M, 10M, 5G), age-based (7, 30, 365 days), and
    time-based (daily, weekly, monthly, custom intervals) rotation patterns.
    Handles both disk-based and zip-archived log rotation.

    .EXAMPLE
    $Logger = [Logger]::new("MyLog")
    $Logger.LogRotateOpt = "10M"
    $Logger.ConfirmLogRotation()  # Returns $true if log exceeds 10MB

    .EXAMPLE
    $Logger.LogRotateOpt = "daily"
    $Logger.ConfirmLogRotation()  # Returns $true if log written on different day
    #>
    [bool] ConfirmLogRotation() {

        # Use local variables to avoid modifying logger state
        $LogNameLocal = [System.IO.Path]::GetFileNameWithoutExtension($This.LogFile)
        $LogPathLocal = Split-Path -Path $This.LogFile
        $ZipPath = "$LogPathLocal\$LogNameLocal-archive.zip"
        $TempLogPath = "$([System.IO.Path]::GetTempPath())$LogNameLocal.archive"

        # Check if the LogRotateOpt matches time-based patterns (daily, weekly, monthly, Nd, Nw, Nmo)
        If ($This.LogRotateOpt -match '^(daily|weekly|monthly|\d+d|\d+w|\d+mo)$') {
            If ($This.ShouldRotateByTime()) {
                Return $This.PerformRotation($LogNameLocal, $LogPathLocal, $ZipPath, $TempLogPath)
            }
            Return $False
        }
        # Check if the LogRotateOpt matches the size pattern (e.g., 10M, 5G, 500K)
        ElseIf ($This.LogRotateOpt -match '(\d+)([GMK])') {
            $Unit = $matches[2]

            # Calculate the log size based on unit
            $RotateSize = Switch ($Unit) {
                'G' { [int]$matches[1] * 1GB }
                'M' { [int]$matches[1] * 1MB }
                'K' { [int]$matches[1] * 1KB }
                Default {
                    Write-Warning "Invalid rotation unit '$Unit'. Using default of 1MB."
                    1MB
                }
            }

            Try {
                $LogSize = (Get-Item -Path $This.LogFile -ErrorAction Stop).Length
                If ($LogSize -gt $RotateSize) {
                    Return $This.PerformRotation($LogNameLocal, $LogPathLocal, $ZipPath, $TempLogPath)
                }
            } Catch {
                Write-Warning "Could not check log file size: $_"
                Return $False
            }
        }
        # Check if LogRotateOpt matches the days pattern (e.g., 7, 30, 365)
        ElseIf ($This.LogRotateOpt -match '^\d+$') {
            $RotateDays = [int]$This.LogRotateOpt

            Try {
                # Use LastWriteTime instead of CreationTime for proper age-based rotation
                $LastWriteTime = (Get-Item -Path $This.LogFile -ErrorAction Stop).LastWriteTime
                $Age = ((Get-Date) - $LastWriteTime).Days

                If ($Age -gt $RotateDays) {
                    Return $This.PerformRotation($LogNameLocal, $LogPathLocal, $ZipPath, $TempLogPath)
                }
            } Catch {
                Write-Warning "Could not check log file age: $_"
                Return $False
            }
        }
        Else {
            Write-Error "Invalid log rotation parameter: '$($This.LogRotateOpt)'. Expected format: size (e.g. '10M', '5G') or days (e.g. '7', '30')"
            Return $False
        }

        # No rotation needed
        Return $False
    }

    <#
    .SYNOPSIS
    Performs the actual log file rotation by renaming files sequentially

    .DESCRIPTION
    Rolls the logs incrementing the number by 1 (e.g., app.log -> app.1.log, app.1.log -> app.2.log).
    Deletes logs exceeding LogCountMax. Handles both disk-based and zip-extracted rotation scenarios.

    .PARAMETER LogName
    String base name of log file without extension

    .PARAMETER LogPath
    String directory path where base log file resides

    .PARAMETER LogFiles
    Object array of FileInfo objects representing rotated log files

    .EXAMPLE
    $Logger = [Logger]::new("MyLog")
    $LogFiles = Get-ChildItem -Path $Logger.LogPath -File -Filter "*.log" | Where-Object { ($_.Name -like "$($Logger.LogName)*") -and ($_.Name -match '\.\d+') }
    $Logger.StartLogRoll($Logger.LogName, $Logger.LogPath, $LogFiles)

    .EXAMPLE
    $Logger.StartLogRoll("Application", "C:\Logs", $rotatedFiles)
    #>
    [bool] StartLogRoll([string]$LogName, [string]$LogPath, [object]$LogFiles) {

        # Validate input - check if LogFiles array is null or empty
        If ($null -eq $LogFiles -or $LogFiles.Count -eq 0) {
            Write-Verbose "No log files provided to rotate"
            # Still try to rotate the base log file
            Try {
                If (Test-Path "$LogPath\$LogName.log") {
                    Move-Item -Path "$LogPath\$LogName.log" -Destination "$LogPath\$LogName.1.log" -Force -ErrorAction Stop
                    Return $True
                }
            } Catch {
                Write-Warning "Failed to rotate base log file: $_"
            }
            Return $False
        }

        # Get the working log path from the $LogFiles object that was passed to the function.
        # This may be a temp folder for zip archived logs.
        $WorkingLogPath = $LogFiles[0].Directory

        $LogFiles = Get-ChildItem -Path $WorkingLogPath -File -Filter "*.log" -ErrorAction SilentlyContinue |
                        Where-Object { ($_.Name -like "$LogName*") -and ($_.Name -match '\.\d+') } |
                        Sort-Object BaseName

        # Rotate multiple log files if 1 or more already exists
        If ($LogFiles.Count -gt 0) {
            # Iterate over the log files starting at the highest number and decrement down to 1
            For ($i = $LogFiles.Count; $i -ge 0; $i--) {
                # Get rotating log file that we are working on
                $OperatingFile = $LogFiles | Where-Object {$_.Name -eq "$LogName.$i.log"}

                # Check if we are over the maximum allowed rotating log files
                If ($i -ge $This.LogCountMax) {
                    # Remove rotating logs that are over the maximum allowed
                    Try {
                        Remove-Item "$WorkingLogPath\$($OperatingFile.Name)" -Force -ErrorAction Stop
                    } Catch {
                        Write-Warning "Could not remove old log file $($OperatingFile.Name): $_"
                    }
                # If we have iterated down to zero, we are working with the base log file
                } ElseIf ($i -eq 0) {
                    # Set the rotating log number
                    $OperatingNumber = 1
                    # Set the name of the new rotated log name
                    $NewFileName = "$LogName.$OperatingNumber.log"
                    If ($WorkingLogPath -eq $This.LogPath) {
                        # Rotate the base log
                        Rename-Item -Path "$WorkingLogPath\$LogName.log" -NewName $NewFileName
                    } Else {
                        Move-Item -Path "$LogPath\$LogName.log" -Destination "$WorkingLogPath\$LogName.1.log"
                    }
                    # Return true since all logs have been rotated
                    Return $True
                # We are iterating through the rotated logs and renaming them as needed
                } Else {
                    # Set the operating number to be +1 of the current increment
                    $OperatingNumber = $i + 1
                    # Set the name of the new rotated log name
                    $NewFileName = "$LogName.$OperatingNumber.log"
                    # Rotate the base log
                    Rename-Item -Path "$WorkingLogPath\$LogName.$i.log" -NewName $NewFileName -Force
                }
            }
        # Rotate the base log file into its first rotating log file
        } Else {
            Move-Item -Path "$LogPath\$LogName.log" -Destination "$WorkingLogPath\$LogName.1.log"
            # Return true since base log has been rotated
            Return $True
        }

        # Return false since we didn't rotate any logs
        Return $False
    }
}

<#
.SYNOPSIS
Base interface for log enrichers that add contextual data to log entries

.DESCRIPTION
Defines the contract for enricher classes that automatically inject additional
properties into log entries. Enrichers are applied when structured logging is enabled,
adding context such as machine info, process details, environment data, etc.

.EXAMPLE
# Create custom enricher
Class CustomEnricher : IEnricher {
    [void] Enrich([hashtable]$LogEntry) {
        $LogEntry['customField'] = "custom value"
    }
}
#>
Class IEnricher {
    <#
    .SYNOPSIS
    Enriches log entry with additional properties

    .PARAMETER LogEntry
    Hashtable containing log entry properties to enrich
    #>
    [void] Enrich([hashtable]$LogEntry) {
        throw "Must override Enrich() method"
    }
}

<#
.SYNOPSIS
Enriches log entries with machine and user identification information

.DESCRIPTION
Adds machine name, username, and user domain to log entries.
Useful for identifying the source of log messages in multi-machine environments.

.EXAMPLE
$Logger.Enrichers.Add([MachineEnricher]::new())
# Adds: machineName, userName, userDomain to all log entries
#>
Class MachineEnricher : IEnricher {
    <#
    .SYNOPSIS
    Adds machine name, username, and user domain to log entry

    .PARAMETER LogEntry
    Hashtable containing log entry properties to enrich
    #>
    [void] Enrich([hashtable]$LogEntry) {
        $LogEntry['machineName'] = $env:COMPUTERNAME
        $LogEntry['userName'] = $env:USERNAME
        $LogEntry['userDomain'] = $env:USERDOMAIN
    }
}

<#
.SYNOPSIS
Enriches log entries with process identification information

.DESCRIPTION
Adds current process ID and process name to log entries.
Useful for distinguishing logs from different processes or script instances.

.EXAMPLE
$Logger.Enrichers.Add([ProcessEnricher]::new())
# Adds: processId, processName to all log entries
#>
Class ProcessEnricher : IEnricher {
    <#
    .SYNOPSIS
    Adds process ID and process name to log entry

    .PARAMETER LogEntry
    Hashtable containing log entry properties to enrich
    #>
    [void] Enrich([hashtable]$LogEntry) {
        $currentPid = [System.Diagnostics.Process]::GetCurrentProcess().Id
        $LogEntry['processId'] = $currentPid
        Try {
            $process = Get-Process -Id $currentPid -ErrorAction Stop
            $LogEntry['processName'] = $process.ProcessName
        } Catch {
            $LogEntry['processName'] = 'Unknown'
        }
    }
}

<#
.SYNOPSIS
Enriches log entries with thread identification information

.DESCRIPTION
Adds managed thread ID to log entries.
Useful for debugging multi-threaded applications and identifying thread-specific issues.

.EXAMPLE
$Logger.Enrichers.Add([ThreadEnricher]::new())
# Adds: threadId to all log entries
#>
Class ThreadEnricher : IEnricher {
    <#
    .SYNOPSIS
    Adds managed thread ID to log entry

    .PARAMETER LogEntry
    Hashtable containing log entry properties to enrich
    #>
    [void] Enrich([hashtable]$LogEntry) {
        $LogEntry['threadId'] = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    }
}

<#
.SYNOPSIS
Enriches log entries with environment and runtime information

.DESCRIPTION
Adds OS version, PowerShell version, and CLR version to log entries.
Useful for troubleshooting environment-specific issues and tracking runtime versions.

.EXAMPLE
$Logger.Enrichers.Add([EnvironmentEnricher]::new())
# Adds: osVersion, psVersion, clrVersion to all log entries
#>
Class EnvironmentEnricher : IEnricher {
    <#
    .SYNOPSIS
    Adds OS version, PowerShell version, and CLR version to log entry

    .PARAMETER LogEntry
    Hashtable containing log entry properties to enrich
    #>
    [void] Enrich([hashtable]$LogEntry) {
        $LogEntry['osVersion'] = [System.Environment]::OSVersion.VersionString
        Try {
            $psVersion = (Get-Variable -Name PSVersionTable -Scope Global -ErrorAction Stop).Value.PSVersion.ToString()
            $LogEntry['psVersion'] = $psVersion
        } Catch {
            $LogEntry['psVersion'] = 'Unknown'
        }
        $LogEntry['clrVersion'] = [System.Environment]::Version.ToString()
    }
}

<#
.SYNOPSIS
Enriches log entries with network identification information

.DESCRIPTION
Adds primary IPv4 address (excluding loopback) to log entries.
Useful for identifying the source IP in networked or distributed applications.

.EXAMPLE
$Logger.Enrichers.Add([NetworkEnricher]::new())
# Adds: ipAddress to all log entries
#>
Class NetworkEnricher : IEnricher {
    <#
    .SYNOPSIS
    Adds primary IPv4 address to log entry

    .PARAMETER LogEntry
    Hashtable containing log entry properties to enrich
    #>
    [void] Enrich([hashtable]$LogEntry) {
        Try {
            $ipAddresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
                Where-Object { $_.InterfaceAlias -notlike '*Loopback*' -and $_.IPAddress -ne '127.0.0.1' } |
                Select-Object -First 1 -ExpandProperty IPAddress
            $LogEntry['ipAddress'] = $ipAddresses
        } Catch {
            $LogEntry['ipAddress'] = 'Unknown'
        }
    }
}

<#
.SYNOPSIS
Base class for log handlers that output log messages to various destinations

.DESCRIPTION
Defines the contract for handler classes that route log messages to different targets
such as files, console, Event Log, email, etc. Handlers support minimum level filtering
to send only relevant messages to each destination.

.EXAMPLE
# Create custom handler
Class CustomHandler : LogHandler {
    CustomHandler() {
        $This.Name = "CustomHandler"
    }
    [void] Emit([string]$FormattedMessage, [string]$LogLevel) {
        # Custom output logic here
    }
}
#>
Class LogHandler {
    [string]$Name
    [string]$MinimumLevel = 'DEBUG'

    <#
    .SYNOPSIS
    Determines if message should be logged based on minimum level filter

    .PARAMETER LogLevel
    String log level to check

    .PARAMETER Priorities
    Hashtable mapping log levels to priority values
    #>
    [bool] ShouldLog([string]$LogLevel, [hashtable]$Priorities) {
        $currentPriority = $Priorities[$LogLevel]
        $minPriority = $Priorities[$This.MinimumLevel]
        Return $currentPriority -le $minPriority
    }

    <#
    .SYNOPSIS
    Outputs formatted log message to handler's target destination

    .PARAMETER FormattedMessage
    String pre-formatted log message

    .PARAMETER LogLevel
    String severity level
    #>
    [void] Emit([string]$FormattedMessage, [string]$LogLevel) {
        throw "Must override Emit() method"
    }
}

<#
.SYNOPSIS
Handler that writes log messages to a file

.DESCRIPTION
Outputs log messages to a specified file path with configurable encoding.
Supports all standard file encodings including Unicode, UTF8, ASCII.

.EXAMPLE
$fileHandler = [FileHandler]::new("C:\Logs\app.log")
$fileHandler.Encoding = "UTF8"
$Logger.AddHandler($fileHandler)
#>
Class FileHandler : LogHandler {
    [string]$FilePath
    [string]$Encoding = 'Unicode'

    <#
    .SYNOPSIS
    Creates a new FileHandler instance

    .PARAMETER FilePath
    String path to the log file
    #>
    FileHandler([string]$FilePath) {
        $This.Name = "FileHandler"
        $This.FilePath = $FilePath
    }

    <#
    .SYNOPSIS
    Writes formatted message to file

    .PARAMETER FormattedMessage
    String pre-formatted log message

    .PARAMETER LogLevel
    String severity level (unused but required by interface)
    #>
    [void] Emit([string]$FormattedMessage, [string]$LogLevel) {
        Try {
            Add-Content -Path $This.FilePath -Value $FormattedMessage -Encoding $This.Encoding -ErrorAction Stop
        } Catch {
            Write-Verbose "FileHandler failed to write: $_"
        }
    }
}

<#
.SYNOPSIS
Handler that writes color-coded log messages to console

.DESCRIPTION
Outputs log messages to console with optional color coding based on severity level.
Uses Write-Host for direct console output with ANSI color support.

.EXAMPLE
$consoleHandler = [ConsoleHandler]::new()
$consoleHandler.UseColors = $true
$consoleHandler.MinimumLevel = "WARNING"
$Logger.AddHandler($consoleHandler)
#>
Class ConsoleHandler : LogHandler {
    [bool]$UseColors = $true

    <#
    .SYNOPSIS
    Creates a new ConsoleHandler instance
    #>
    ConsoleHandler() {
        $This.Name = "ConsoleHandler"
    }

    <#
    .SYNOPSIS
    Writes formatted message to console with optional color coding

    .PARAMETER FormattedMessage
    String pre-formatted log message

    .PARAMETER LogLevel
    String severity level for color selection
    #>
    [void] Emit([string]$FormattedMessage, [string]$LogLevel) {
        If ($This.UseColors) {
            $color = Switch ($LogLevel) {
                'CRITICAL' { 'Magenta' }
                'ERROR' { 'Red' }
                'WARNING' { 'Yellow' }
                'SUCCESS' { 'Green' }
                'DEBUG' { 'Cyan' }
                Default { 'White' }
            }
            Write-Host $FormattedMessage -ForegroundColor $color
        } Else {
            Write-Host $FormattedMessage
        }
    }
}

<#
.SYNOPSIS
Handler that writes log messages to Windows Event Log

.DESCRIPTION
Outputs log messages to Windows Event Log with automatic source creation.
Maps log levels to Event Log entry types (Error, Warning, Information).
Requires administrative privileges for first-time source registration.

.EXAMPLE
$eventHandler = [EventLogHandler]::new("MyApplication")
$eventHandler.LogName = "Application"
$eventHandler.MinimumLevel = "ERROR"
$Logger.AddHandler($eventHandler)
#>
Class EventLogHandler : LogHandler {
    [string]$LogName = 'Application'
    [string]$Source

    <#
    .SYNOPSIS
    Creates a new EventLogHandler instance

    .PARAMETER Source
    String Event Log source name (must be unique per application)
    #>
    EventLogHandler([string]$Source) {
        $This.Name = "EventLogHandler"
        $This.Source = $Source
    }

    <#
    .SYNOPSIS
    Writes formatted message to Windows Event Log

    .PARAMETER FormattedMessage
    String pre-formatted log message

    .PARAMETER LogLevel
    String severity level for entry type mapping
    #>
    [void] Emit([string]$FormattedMessage, [string]$LogLevel) {
        $EntryType = Switch ($LogLevel) {
            'CRITICAL' { 'Error' }
            'ERROR' { 'Error' }
            'WARNING' { 'Warning' }
            Default { 'Information' }
        }

        Try {
            # Ensure source exists
            If (-not [System.Diagnostics.EventLog]::SourceExists($This.Source)) {
                Try {
                    [System.Diagnostics.EventLog]::CreateEventSource($This.Source, $This.LogName)
                } Catch {
                    Write-Verbose "Could not create Event Log source: $_"
                    Return
                }
            }

            Write-EventLog -LogName $This.LogName -Source $This.Source `
                -EntryType $EntryType -EventId 1000 -Message $FormattedMessage -ErrorAction Stop
        } Catch {
            Write-Verbose "EventLogHandler failed to write: $_"
        }
    }
}

<#
.SYNOPSIS
Handler that discards all log messages

.DESCRIPTION
A null handler that silently discards all log messages without output.
Useful for temporarily disabling logging without removing handler configuration.

.EXAMPLE
$nullHandler = [NullHandler]::new()
$Logger.AddHandler($nullHandler)  # Logs go nowhere
#>
Class NullHandler : LogHandler {
    <#
    .SYNOPSIS
    Creates a new NullHandler instance
    #>
    NullHandler() {
        $This.Name = "NullHandler"
    }

    <#
    .SYNOPSIS
    Discards formatted message without output

    .PARAMETER FormattedMessage
    String pre-formatted log message (ignored)

    .PARAMETER LogLevel
    String severity level (ignored)
    #>
    [void] Emit([string]$FormattedMessage, [string]$LogLevel) {
        # Do nothing - discard the log
    }
}

<#
.SYNOPSIS
Base interface for log filters that control message routing based on conditions

.DESCRIPTION
Defines the contract for filter classes that determine whether log messages
should be processed based on custom criteria such as function name, time of day,
user context, etc. Filters return true to allow the message, false to block it.

.EXAMPLE
# Create custom filter
Class CustomFilter : ILogFilter {
    [bool] ShouldFilter([hashtable]$LogRecord) {
        # Return true to allow, false to block
        Return $LogRecord.Message -notlike "*sensitive*"
    }
}
#>
Class ILogFilter {
    <#
    .SYNOPSIS
    Determines whether log record should be processed

    .PARAMETER LogRecord
    Hashtable containing log record properties (Message, Level, Timestamp, FunctionName)

    .OUTPUTS
    Boolean - true to allow message, false to block
    #>
    [bool] ShouldFilter([hashtable]$LogRecord) {
        throw "Must override ShouldFilter() method"
    }
}

<#
.SYNOPSIS
Filter that excludes log messages from specific functions

.DESCRIPTION
Blocks log messages originating from specified function names.
Useful for reducing noise from verbose internal functions while maintaining
logging for user-facing functions.

.EXAMPLE
$filter = [FunctionFilter]::new(@("Get-InternalData", "Test-Connection"))
$Logger.AddFilter($filter)
# Messages from Get-InternalData and Test-Connection are now blocked
#>
Class FunctionFilter : ILogFilter {
    [string[]]$ExcludeFunctions = @()

    <#
    .SYNOPSIS
    Creates a new FunctionFilter instance

    .PARAMETER ExcludeFunctions
    String array of function names to exclude from logging
    #>
    FunctionFilter([string[]]$ExcludeFunctions) {
        $This.ExcludeFunctions = $ExcludeFunctions
    }

    <#
    .SYNOPSIS
    Determines if log record should be processed based on function name

    .PARAMETER LogRecord
    Hashtable containing log record properties including FunctionName

    .OUTPUTS
    Boolean - true if function not in exclusion list, false otherwise
    #>
    [bool] ShouldFilter([hashtable]$LogRecord) {
        Return $LogRecord.FunctionName -notin $This.ExcludeFunctions
    }
}

<#
.SYNOPSIS
Filter that restricts logging to specific hours of the day

.DESCRIPTION
Allows log messages only during specified time window (e.g., business hours).
Uses 24-hour format. Useful for reducing log volume during off-peak hours
or focusing debugging efforts on specific time periods.

.EXAMPLE
$filter = [TimeFilter]::new(9, 17)  # Only log between 9 AM and 5 PM
$Logger.AddFilter($filter)
#>
Class TimeFilter : ILogFilter {
    [int]$StartHour = 0
    [int]$EndHour = 23

    <#
    .SYNOPSIS
    Creates a new TimeFilter instance

    .PARAMETER StartHour
    Integer hour (0-23) when logging should begin

    .PARAMETER EndHour
    Integer hour (0-23) when logging should end
    #>
    TimeFilter([int]$StartHour, [int]$EndHour) {
        $This.StartHour = $StartHour
        $This.EndHour = $EndHour
    }

    <#
    .SYNOPSIS
    Determines if log record should be processed based on current time

    .PARAMETER LogRecord
    Hashtable containing log record properties

    .OUTPUTS
    Boolean - true if current hour within allowed range, false otherwise
    #>
    [bool] ShouldFilter([hashtable]$LogRecord) {
        $Hour = (Get-Date).Hour
        Return ($Hour -ge $This.StartHour -and $Hour -le $This.EndHour)
    }
}

<#
.SYNOPSIS
Filter that restricts logging to specific users

.DESCRIPTION
Allows log messages only when running under specified user accounts.
Useful for debugging user-specific issues or limiting logging to
administrative accounts in production environments.

.EXAMPLE
$filter = [UserFilter]::new(@("admin", "debug_user"))
$Logger.AddFilter($filter)
# Only logs when script runs as admin or debug_user
#>
Class UserFilter : ILogFilter {
    [string[]]$IncludeUsers = @()

    <#
    .SYNOPSIS
    Creates a new UserFilter instance

    .PARAMETER IncludeUsers
    String array of usernames to allow logging for
    #>
    UserFilter([string[]]$IncludeUsers) {
        $This.IncludeUsers = $IncludeUsers
    }

    <#
    .SYNOPSIS
    Determines if log record should be processed based on current user

    .PARAMETER LogRecord
    Hashtable containing log record properties

    .OUTPUTS
    Boolean - true if current user in allowed list, false otherwise
    #>
    [bool] ShouldFilter([hashtable]$LogRecord) {
        Return $env:USERNAME -in $This.IncludeUsers
    }
}

<#
.SYNOPSIS
IDisposable wrapper for scoped properties with automatic cleanup

.DESCRIPTION
Implements IDisposable to enable automatic property removal when scope exits.
Used with PowerShell's Using statement for clean syntax and guaranteed cleanup.
Properties are automatically removed even if exceptions occur within the scope.

.EXAMPLE
Using ($scope = $Logger.PushProperty("RequestId", "12345")) {
    $Logger.Write("Processing request")  # Includes RequestId
    $Logger.Write("Request complete")    # Includes RequestId
}  # RequestId automatically removed here
$Logger.Write("New request")  # No RequestId
#>
Class PropertyScope : System.IDisposable {
    hidden [Logger]$Logger
    hidden [string]$Key

    <#
    .SYNOPSIS
    Creates a new PropertyScope instance

    .PARAMETER Logger
    Logger instance that owns the scoped property

    .PARAMETER Key
    String property key to remove when scope exits
    #>
    PropertyScope([Logger]$Logger, [string]$Key) {
        $This.Logger = $Logger
        $This.Key = $Key
    }

    <#
    .SYNOPSIS
    Removes scoped property when object is disposed

    .DESCRIPTION
    Called automatically when Using block exits or object is explicitly disposed.
    Ensures property cleanup even if exceptions occur.
    #>
    [void] Dispose() {
        $This.Logger.RemoveProperty($This.Key)
    }
}

#endregion


# ================================
# ===    PUBLIC FUNCTIONS      ===
# ================================
#region Public Functions

Function Initialize-Log {
    <#
    .SYNOPSIS
    Initializes a Logger instance for enterprise file and console logging operations

    .DESCRIPTION
    Creates and configures a Logger class instance with comprehensive settings for output formatting,
    rotation policies, structured logging, performance optimization, and multi-target destinations.
    The logger can be set as the script-wide default or returned for explicit use with Write-Log.

    Supports advanced features including:
    - JSON structured logging for SIEM integration
    - Buffered writes for high-performance scenarios
    - Time-based and size-based log rotation
    - Windows Event Log integration
    - Log sampling for high-volume applications
    - Custom enrichers and handlers
    - Correlation ID support for distributed tracing

    .PARAMETER LogName
    Name of the log file (without extension). The .log extension is automatically appended.
    Must not contain invalid file system characters.
    Aliases: LN
    Default: "Debug"

    .PARAMETER LogPath
    Directory path where log files will be created. Directory is created if it doesn't exist.
    Must be an absolute path (not relative). Supports UNC paths.
    Aliases: LP
    Default: "C:\Temp"

    .PARAMETER LogLevel
    Default severity level for log messages when not explicitly specified.
    Valid values: INFO, WARNING, ERROR, DEBUG, SUCCESS, CRITICAL
    Aliases: LL, LogLvl
    Default: "INFO"

    .PARAMETER DateTimeFormat
    .NET format string for timestamps in log entries.
    Example formats: 'yyyy-MM-dd HH:mm:ss', 'MM/dd/yyyy hh:mm:ss tt', 'o' (ISO 8601)
    Aliases: TF, DF, DateFormat, TimeFormat
    Default: 'yyyy-MM-dd HH:mm:ss'

    .PARAMETER NoLogInfo
    When specified, omits timestamp and log level from log entries (logs message only).
    Useful for raw data logging or when timestamps are added by external systems.
    Aliases: NLI
    Default: $false

    .PARAMETER Encoding
    Text encoding for the log file.
    Valid values: unknown, string, unicode, bigendianunicode, utf8, utf7, utf32, ascii, default, oem
    Note: Use 'utf8' for cross-platform compatibility, 'unicode' for Windows-specific scripts
    Default: 'Unicode'

    .PARAMETER LogRoll
    Enables automatic log rotation based on LogRotateOpt settings.
    When enabled, logs are rotated according to size, age, or time-based patterns.
    Aliases: LR, Roll
    Default: $false

    .PARAMETER LogRetry
    Number of retry attempts when file write operations fail (e.g., due to file locks).
    Waits LogRetryDelayMs (default 500ms) between attempts.
    Aliases: Retry
    Default: 2

    .PARAMETER WriteConsole
    Outputs log messages to console in addition to file.
    Console output uses color coding based on log level.
    Aliases: WC, Console
    Default: $false

    .PARAMETER ConsoleOnly
    Outputs to console only without writing to file.
    Requires WriteConsole to be enabled. Useful for debugging or interactive scripts.
    Aliases: CO
    Default: $false

    .PARAMETER ConsoleInfo
    Includes timestamp and log level in console output.
    Only applies when WriteConsole is enabled.
    Aliases: CI
    Default: $false

    .PARAMETER LogRotateOpt
    Rotation threshold specified as:
    - Size: Number followed by unit (K/M/G) e.g., "10M" for 10 megabytes, "5G" for 5 gigabytes
    - Age: Number of days e.g., "7" for weekly rotation, "30" for monthly
    - Time-based patterns:
      * "daily" or "1d" - Rotate daily at midnight
      * "weekly" or "1w" - Rotate every 7 days
      * "monthly" or "1mo" - Rotate monthly
      * "Nd" - Rotate every N days (e.g., "3d" = every 3 days)
      * "Nw" - Rotate every N weeks (e.g., "2w" = every 2 weeks)
      * "Nmo" - Rotate every N months (e.g., "3mo" = quarterly)
    Aliases: RotateOpt
    Default: "1M"

    .PARAMETER LogZip
    Compresses rotated log files into a zip archive to save disk space.
    Only applies when LogRoll is enabled.
    Zip files are named {LogName}-archive.zip and contain all rotated logs.
    Aliases: Zip
    Default: $false

    .PARAMETER LogCountMax
    Maximum number of rotated log files to retain.
    Older logs beyond this count are automatically deleted.
    Applies to both zipped and non-zipped rotation.
    Aliases: LF, LogFiles
    Default: 5

    .PARAMETER LogFilter
    Minimum log level filter. Only messages at this level or higher severity will be logged.
    Valid values: CRITICAL, ERROR, WARNING, SUCCESS, INFO, DEBUG
    Priority order (highest to lowest): CRITICAL > ERROR > WARNING > SUCCESS > INFO > DEBUG
    Example: Setting to "WARNING" will only log WARNING, ERROR, and CRITICAL messages
    Aliases: Filter
    Default: "DEBUG" (shows all messages)

    .PARAMETER StructuredLogging
    Enable JSON structured logging output for SIEM integration and machine parsing.
    Output format: {"timestamp":"ISO8601","level":"INFO","message":"text","machineName":"...","userName":"..."}
    Use enrichers to add additional fields automatically.
    Aliases: Struct, JSON
    Default: $false

    .PARAMETER BufferedWrites
    Enable buffered writes for high-performance logging scenarios.
    Messages are queued in memory and flushed to disk in batches.
    Reduces disk I/O overhead by up to 90% in high-volume scenarios.
    IMPORTANT: Call FlushBuffer() before script exit to ensure all messages are written.
    Aliases: Buffer, Async
    Default: $false

    .PARAMETER BufferSize
    Number of messages to buffer before automatic flush to disk.
    Also flushes every FlushIntervalSeconds (default 5 seconds).
    Higher values = better performance but more data loss risk on crash.
    Aliases: BufSize
    Default: 100

    .PARAMETER EnableSampling
    Enable log sampling to reduce volume in high-throughput scenarios.
    When enabled, only every Nth message is actually logged.
    Useful for reducing noise from high-frequency events.
    Aliases: Sample
    Default: $false

    .PARAMETER SampleRate
    When sampling is enabled, log every Nth message.
    Example: SampleRate=10 means log 1 out of every 10 messages (90% reduction).
    Aliases: SRate
    Default: 10

    .PARAMETER WriteToEventLog
    Write log entries to Windows Event Log in addition to file.
    Requires administrative privileges to create event source on first run.
    Maps log levels: CRITICAL/ERROR -> Error, WARNING -> Warning, others -> Information
    Aliases: EventLog
    Default: $false

    .PARAMETER EventSource
    Event Log source name for Windows Event Log integration.
    Must be unique per application. Created automatically if it doesn't exist (requires admin).
    Aliases: Source
    Default: "PowerShellLogger"

    .PARAMETER Default
    Sets this logger as the script-wide default logger stored in $Script:DefaultLogger.
    When specified, no logger object is returned.
    All subsequent Write-Log calls without -Logger parameter will use this default.
    Aliases: D

    .OUTPUTS
    [Logger] - Configured logger instance (unless -Default is specified)

    .EXAMPLE
    # Initialize a default log with default settings
    Initialize-Log -Default
    Write-Log "This message will go to the default log (Debug.log)"

    .EXAMPLE
    # Initialize a custom named log with rotation
    $AppLog = Initialize-Log -LogName "Application" -LogPath "C:\Logs" -LogRoll -LogRotateOpt "10M" -LogZip
    Write-Log "This message goes to Application.log (rotates at 10MB)" -Logger $AppLog

    .EXAMPLE
    # Initialize a log with structured JSON logging for SIEM
    $JsonLog = Initialize-Log -LogName "AppData" -StructuredLogging
    Write-Log "User logged in" -Logger $JsonLog
    # Output: {"timestamp":"2025-11-05T10:30:45Z","level":"INFO","message":"User logged in",...}

    .EXAMPLE
    # Initialize a high-performance log with buffered writes
    $HighPerfLog = Initialize-Log -LogName "HighVolume" -BufferedWrites -BufferSize 1000
    1..10000 | ForEach-Object {
        Write-Log "Processing item $_" -Logger $HighPerfLog
    }
    $HighPerfLog.FlushBuffer()  # Force flush before exit

    .EXAMPLE
    # Initialize a log with daily rotation
    $DailyLog = Initialize-Log -LogName "Daily" -LogRoll -LogRotateOpt "daily" -LogZip -LogCountMax 30
    Write-Log "This log rotates daily at midnight and keeps 30 days of history" -Logger $DailyLog

    .EXAMPLE
    # Initialize a log with weekly rotation
    $WeeklyLog = Initialize-Log -LogName "Weekly" -LogRoll -LogRotateOpt "weekly" -LogZip
    Write-Log "This log rotates every 7 days" -Logger $WeeklyLog

    .EXAMPLE
    # Initialize a log with monthly rotation
    $MonthlyLog = Initialize-Log -LogName "Monthly" -LogRoll -LogRotateOpt "monthly" -LogZip -LogCountMax 12
    Write-Log "This log rotates monthly and keeps 12 months of history" -Logger $MonthlyLog

    .EXAMPLE
    # Initialize a log with custom time-based rotation (every 3 days)
    $CustomLog = Initialize-Log -LogName "Custom" -LogRoll -LogRotateOpt "3d" -LogZip
    Write-Log "This log rotates every 3 days" -Logger $CustomLog

    .EXAMPLE
    # Initialize a log with Windows Event Log integration
    $EventLog = Initialize-Log -LogName "App" -WriteToEventLog -EventSource "MyApplication"
    Write-Log "This message goes to both file and Windows Event Log" -Logger $EventLog

    .EXAMPLE
    # Initialize a log with sampling (reduce volume by 90%)
    $SampledLog = Initialize-Log -LogName "HighFrequency" -EnableSampling -SampleRate 10
    1..1000 | ForEach-Object {
        Write-Log "High-frequency event $_" -Logger $SampledLog
    }
    # Only ~100 messages are actually logged

    .EXAMPLE
    # Initialize a log with console output and filtering
    $ConsoleLog = Initialize-Log -LogName "App" -WriteConsole -ConsoleInfo -LogFilter "WARNING"
    Write-Log "This DEBUG message is filtered out" -LogLevel "DEBUG" -Logger $ConsoleLog
    Write-Log "This WARNING message is shown" -LogLevel "WARNING" -Logger $ConsoleLog

    .EXAMPLE
    # Initialize multiple specialized logs
    $ErrorLog = Initialize-Log -LogName "Errors" -LogFilter "ERROR" -LogRoll -LogRotateOpt "daily"
    $AuditLog = Initialize-Log -LogName "Audit" -StructuredLogging -LogRoll -LogRotateOpt "monthly"
    $DebugLog = Initialize-Log -LogName "Debug" -WriteConsole -ConsoleInfo

    Write-Log "Application started" -Logger $AuditLog
    Write-Log "Processing data..." -Logger $DebugLog
    Write-Log "Database connection failed" -LogLevel "ERROR" -Logger $ErrorLog

    .NOTES
    Performance: BufferedWrites can improve throughput by 10x+ in high-volume scenarios,
                 but requires calling FlushBuffer() before script exit.

    Thread Safety: Use BufferedWrites with caution in multi-threaded scenarios.
                   Consider separate logger instances per thread.

    Disk Space: Enable LogZip and set appropriate LogCountMax to prevent disk exhaustion.
                Monitor disk usage for logs with high rotation frequency.

    Event Log: First-time Event Source creation requires administrative privileges.
               Subsequent runs do not require admin rights.
    #>

    Param(
        [alias ('D')][switch] $Default,
        [alias ('LN')][string] $LogName = "Debug",
        [alias ('LP')][string] $LogPath = "C:\Temp",
        [alias ('LL', 'LogLvl')][string] $LogLevel = "INFO",
        [Alias('TF', 'DF', 'DateFormat', 'TimeFormat')][string] $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',
        [alias ('NLI')][switch] $NoLogInfo,
        [ValidateSet('unknown', 'string', 'unicode', 'bigendianunicode', 'utf8', 'utf7', 'utf32', 'ascii', 'default', 'oem')][string]$Encoding = 'Unicode',
        [alias ('Retry')][int] $LogRetry = 2,
        [alias('WC', 'Console')][switch] $WriteConsole,
        [alias('CO')][switch] $ConsoleOnly,
        [alias('CI')][switch] $ConsoleInfo,
        [alias ('LR', 'Roll')][switch] $LogRoll,
        [alias ('RotateOpt')][string] $LogRotateOpt = "1M",
        [alias('Zip')][switch] $LogZip,
        [alias('LF', 'LogFiles')][int]$LogCountMax = 5,
        [alias('Filter')][ValidateSet('CRITICAL', 'ERROR', 'WARNING', 'SUCCESS', 'INFO', 'DEBUG')][string]$LogFilter = "DEBUG",
        [alias('Struct', 'JSON')][switch]$StructuredLogging,
        [alias('Buffer', 'Async')][switch]$BufferedWrites,
        [alias('BufSize')][int]$BufferSize = 100,
        [alias('Sample')][switch]$EnableSampling,
        [alias('SRate')][int]$SampleRate = 10,
        [alias('EventLog')][switch]$WriteToEventLog,
        [alias('Source')][string]$EventSource = "PowerShellLogger"
    )

    # Create a new logger instance
    $Logger = [Logger]::new()

    # Set all properties from parameters
    $Logger.LogName = $LogName
    $Logger.LogPath = $LogPath
    $Logger.LogLevel = $LogLevel
    $Logger.DateTimeFormat = $DateTimeFormat
    $Logger.NoLogInfo = $NoLogInfo
    $Logger.Encoding = $Encoding
    $Logger.LogRoll = $LogRoll
    $Logger.LogRetry = $LogRetry
    $Logger.WriteConsole = $WriteConsole
    $Logger.ConsoleOnly = $ConsoleOnly
    $Logger.ConsoleInfo = $ConsoleInfo
    $Logger.LogRotateOpt = $LogRotateOpt
    $Logger.LogZip = $LogZip
    $Logger.LogCountMax = $LogCountMax
    $Logger.LogFilter = $LogFilter

    # Set new feature properties
    $Logger.StructuredLogging = $StructuredLogging
    $Logger.BufferedWrites = $BufferedWrites
    $Logger.BufferSize = $BufferSize
    $Logger.EnableSampling = $EnableSampling
    $Logger.SampleRate = $SampleRate
    $Logger.WriteToEventLog = $WriteToEventLog
    $Logger.EventSource = $EventSource

    If ($Default) {
        $Script:DefaultLogger = $Logger
        Return
    }

    Return $Logger
}

Function Write-Log {
    <#
    .SYNOPSIS
    Writes formatted messages to configured log destinations

    .DESCRIPTION
    Outputs messages to a logger instance with specified severity level. Messages are formatted
    with timestamps and levels based on logger configuration. Supports both default and
    explicitly specified logger instances.

    Features:
    - Automatic timestamp and log level formatting
    - Color-coded console output (when enabled)
    - Multi-target output (file, console, Event Log, handlers)
    - Log level filtering
    - Correlation ID support
    - Structured JSON output (when enabled)
    - Lazy string formatting via Logger.Write(template, args, level)

    .PARAMETER LogMsg
    The message text to be logged. Can include variables and formatted strings.
    For better performance with filtered messages, use Logger.Write(template, args, level) directly.
    Aliases: LM, Msg, Message

    .PARAMETER LogLevel
    Severity level of the log message. Affects formatting, filtering, and color coding.
    Valid values: INFO, WARNING, ERROR, DEBUG, SUCCESS, CRITICAL
    Priority order (highest to lowest): CRITICAL > ERROR > WARNING > SUCCESS > INFO > DEBUG
    Aliases: LL, LogLvl, Level
    Default: "INFO"

    .PARAMETER Logger
    Logger instance to write to. If not specified, uses the script-wide default logger.
    If no default logger exists and this parameter is not provided, an error is thrown.
    Aliases: L, Log

    .EXAMPLE
    # Write to default logger with INFO level
    Write-Log "Application started successfully"

    .EXAMPLE
    # Write warning to default logger
    Write-Log "Disk space low" -LogLevel "WARNING"

    .EXAMPLE
    # Write to specific logger instance
    $ErrorLog = Initialize-Log -LogName "Errors" -LogFilter "ERROR"
    Write-Log "Database connection failed" -LogLevel "ERROR" -Logger $ErrorLog

    .EXAMPLE
    # Write formatted message with variables
    $count = 150
    $duration = 3.5
    Write-Log "Processed $count items in $duration seconds" -LogLevel "SUCCESS"

    .EXAMPLE
    # Use lazy string formatting for performance (bypasses Write-Log function)
    $Logger = Initialize-Log -LogName "Performance" -LogFilter "WARNING"
    # This expensive string format is NEVER executed because DEBUG is filtered out
    $Logger.Write("Processing item {0} of {1} with details: {2}", @($i, $total, $expensiveObject.ToString()), "DEBUG")

    .EXAMPLE
    # Write with correlation ID for distributed tracing
    $Logger = Initialize-Log -LogName "WebApp"
    $Logger.SetCorrelationId()
    Write-Log "Request received" -Logger $Logger
    Write-Log "Processing request" -Logger $Logger
    Write-Log "Request completed" -Logger $Logger
    $Logger.ClearCorrelationId()

    .EXAMPLE
    # Write different log levels with aliases
    Write-Log "Starting backup process" -Level INFO
    Write-Log "No space on backup drive" -LogLvl WARNING
    Write-Log "Backup failed - critical data loss risk" -LL CRITICAL

    .NOTES
    Performance: For high-volume logging with filtered messages, use Logger.Write(template, args, level)
                 directly instead of Write-Log to take advantage of lazy string formatting.

    Thread Safety: Write-Log is thread-safe when using file-based logging with retry logic.
                   For true multi-threaded scenarios, consider BufferedWrites or separate loggers.
    #>
    Param(
        [alias ('LM', 'Msg', 'Message')][String] $LogMsg = "",
        [alias ('LL', 'LogLvl', 'Level')][string] $LogLevel = "INFO",
        [alias ('L', 'Log')] $Logger = $Script:DefaultLogger
    )

    If (-not $Logger) {
        Write-Error "No log class has been initialized. Initialize a default log class or provide an initialized log class."
    } Else {
        # Write the log entry
        $Logger.Write($LogMsg, $LogLevel)
    }
}

Function Write-LogInfo {
    <#
    .SYNOPSIS
        Writes an INFO level message to the specified or default logger.

    .DESCRIPTION
        Write-LogInfo is a convenience function that simplifies writing informational messages
        to the log file. It automatically sets the log level to INFO, eliminating the need to
        specify the level parameter.
        
        Use this function for:
        - General application flow information
        - State changes and milestones
        - Non-critical status updates
        - Successful routine operations
        - Configuration details
        
        INFO level messages appear in white when console output is enabled.

    .PARAMETER Message
        The informational message to be logged. Supports pipeline input for bulk operations.
        Can include variables and expressions that will be evaluated before logging.
        Aliases: None

    .PARAMETER Logger
        Optional logger instance created by Initialize-Log. If not specified, uses the default
        logger. If no default logger exists and Logger parameter is not provided, throws an error.
        Aliases: None

    .INPUTS
        System.String
        Accepts string messages from the pipeline.

    .OUTPUTS
        None
        This function does not return any output.

    .EXAMPLE
        # Basic information logging
        Initialize-Log -Default
        Write-LogInfo "Application version 2.1.0 starting"
        Write-LogInfo "Configuration loaded from C:\Config\app.json"
        Write-LogInfo "Database connection established"

    .EXAMPLE
        # Pipeline input
        Initialize-Log -Default
        
        Get-Process | Select-Object -First 5 | ForEach-Object {
            "Process $($_.Name) is using $($_.WorkingSet64 / 1MB)MB memory"
        } | Write-LogInfo

    .EXAMPLE
        # Using with specific logger
        $AppLog = Initialize-Log -LogName "Application" -WriteConsole
        
        Write-LogInfo "Starting initialization sequence" -Logger $AppLog
        Write-LogInfo "Loading modules" -Logger $AppLog
        Write-LogInfo "Initialization complete" -Logger $AppLog

    .EXAMPLE
        # Logging application flow
        Initialize-Log -Default -LogName "Workflow"
        
        Write-LogInfo "Workflow started by $($env:USERNAME)"
        Write-LogInfo "Processing 1000 records"
        Write-LogInfo "Stage 1: Data validation completed"
        Write-LogInfo "Stage 2: Data transformation completed"
        Write-LogInfo "Stage 3: Data export completed"
        Write-LogInfo "Workflow finished successfully"

    .EXAMPLE
        # System information logging
        Initialize-Log -Default
        
        $os = Get-CimInstance Win32_OperatingSystem
        Write-LogInfo "Operating System: $($os.Caption)"
        Write-LogInfo "Total Memory: $([math]::Round($os.TotalVisibleMemorySize/1MB, 2))GB"
        Write-LogInfo "Free Memory: $([math]::Round($os.FreePhysicalMemory/1MB, 2))GB"
        Write-LogInfo "Last Boot: $($os.LastBootUpTime)"

    .NOTES
        - This is equivalent to calling Write-Log -LogLevel "INFO"
        - INFO level is typically used for normal, expected events
        - Avoid logging sensitive information (passwords, tokens, etc.)
        - Consider log volume when logging inside loops

    .LINK
        Write-Log

    .LINK
        Write-LogWarning

    .LINK
        Write-LogError

    .LINK
        Write-LogDebug

    .LINK
        Write-LogSuccess
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Message,
        
        [Parameter()]
        $Logger = $Script:DefaultLog
    )
    
    Process {
        Write-Log -LogMsg $Message -LogLevel "INFO" -Logger $Logger
    }
}

Function Write-LogWarning {
    <#
    .SYNOPSIS
        Writes a WARNING level message to the specified or default logger.

    .DESCRIPTION
        Write-LogWarning is a convenience function for logging warning conditions that may require
        attention but don't prevent the script from continuing. It automatically sets the log level
        to WARNING, which appears in yellow when console output is enabled.
        
        Use this function for:
        - Potentially problematic conditions
        - Deprecated feature usage
        - Missing optional configurations
        - Performance degradation
        - Approaching resource limits
        - Recoverable issues
        
        WARNING messages indicate conditions that should be reviewed but aren't critical failures.

    .PARAMETER Message
        The warning message to be logged. Should clearly describe the condition and potential impact.
        Supports pipeline input for bulk warning operations.
        Aliases: None

    .PARAMETER Logger
        Optional logger instance created by Initialize-Log. If not specified, uses the default
        logger. If no default logger exists and Logger parameter is not provided, throws an error.
        Aliases: None

    .INPUTS
        System.String
        Accepts string messages from the pipeline.

    .OUTPUTS
        None
        This function does not return any output.

    .EXAMPLE
        # Basic warning logging
        Initialize-Log -Default
        Write-LogWarning "Disk space below 10% on drive C:"
        Write-LogWarning "Configuration file not found, using defaults"
        Write-LogWarning "API rate limit approaching (450/500 requests)"

    .EXAMPLE
        # System resource warnings
        Initialize-Log -Default -WriteConsole
        
        $freeSpace = (Get-PSDrive C).Free / 1GB
        if ($freeSpace -lt 10) {
            Write-LogWarning "Low disk space: $([math]::Round($freeSpace, 2))GB remaining on C:"
        }
        
        $memory = Get-CimInstance Win32_OperatingSystem
        $percentFree = ($memory.FreePhysicalMemory / $memory.TotalVisibleMemorySize) * 100
        if ($percentFree -lt 20) {
            Write-LogWarning "Low memory: $([math]::Round($percentFree, 1))% free"
        }

    .EXAMPLE
        # Service monitoring warnings
        $ServiceLog = Initialize-Log -LogName "ServiceMonitor"
        
        Get-Service | Where-Object {
            $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic'
        } | ForEach-Object {
            "Service '$($_.DisplayName)' should be running but is stopped"
        } | Write-LogWarning -Logger $ServiceLog

    .EXAMPLE
        # Configuration validation warnings
        Initialize-Log -Default
        
        $config = @{
            MaxRetries = 100
            Timeout = 5
            CacheSize = 50000
        }
        
        if ($config.MaxRetries -gt 50) {
            Write-LogWarning "MaxRetries set to $($config.MaxRetries) - this may cause performance issues"
        }
        
        if ($config.Timeout -lt 10) {
            Write-LogWarning "Timeout of $($config.Timeout) seconds may be too low for slow networks"
        }

    .EXAMPLE
        # Deprecation warnings
        Initialize-Log -Default -LogName "Migration"
        
        Write-LogWarning "Function 'Get-OldData' is deprecated and will be removed in v3.0"
        Write-LogWarning "Please update scripts to use 'Get-Data' instead"
        Write-LogWarning "Legacy authentication method detected - consider upgrading to OAuth"

    .EXAMPLE
        # Performance warnings with metrics
        $PerfLog = Initialize-Log -LogName "Performance" -WriteConsole -ConsoleInfo
        
        $duration = Measure-Command { 
            # Some operation
            Start-Sleep -Seconds 3
        }
        
        if ($duration.TotalSeconds -gt 2) {
            Write-LogWarning "Operation took $($duration.TotalSeconds) seconds (expected < 2s)" -Logger $PerfLog
        }

    .NOTES
        - WARNING level typically indicates non-critical issues
        - Include enough context to understand and resolve the warning
        - Consider including thresholds or expected values in messages
        - Warnings should be actionable when possible
        - Yellow console color helps distinguish warnings from other messages

    .LINK
        Write-Log

    .LINK
        Write-LogInfo

    .LINK
        Write-LogError

    .LINK
        Write-LogDebug

    .LINK
        Write-LogSuccess
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Message,
        
        [Parameter()]
        $Logger = $Script:DefaultLog
    )
    
    Process {
        Write-Log -LogMsg $Message -LogLevel "WARNING" -Logger $Logger
    }
}

Function Write-LogError {
    <#
    .SYNOPSIS
        Writes an ERROR level message to the specified or default logger.

    .DESCRIPTION
        Write-LogError is a convenience function for logging error conditions and failures.
        It automatically sets the log level to ERROR, which appears in red when console output
        is enabled, making critical issues immediately visible.
        
        Use this function for:
        - Recoverable errors
        - Failed operations that can be retried
        - Non-fatal exceptions
        - Service disruptions
        - Data validation failures
        - Missing dependencies
        
        For unrecoverable, system-critical failures that require immediate intervention,
        consider using Write-LogCritical instead.

    .PARAMETER Message
        The error message to be logged. Should clearly describe what failed, why, and potential impact.
        Include error codes, exception messages, and relevant context for troubleshooting.
        Supports pipeline input for bulk error logging.
        Aliases: None

    .PARAMETER Logger
        Optional logger instance created by Initialize-Log. If not specified, uses the default
        logger. If no default logger exists and Logger parameter is not provided, throws an error.
        Aliases: None

    .INPUTS
        System.String
        Accepts string messages from the pipeline.

    .OUTPUTS
        None
        This function does not return any output.

    .EXAMPLE
        # Basic error logging
        Initialize-Log -Default
        Write-LogError "Failed to connect to database server"
        Write-LogError "Unable to read configuration file: Access denied"
        Write-LogError "Network timeout: Operation took longer than 30 seconds"

    .EXAMPLE
        # Exception handling with detailed error logging
        Initialize-Log -Default -LogName "Application"
        
        Try {
            $result = Invoke-RestMethod -Uri "https://api.example.com/data" -ErrorAction Stop
        }
        Catch {
            Write-LogError "API call failed: $_"
            Write-LogError "Exception type: $($_.Exception.GetType().FullName)"
            Write-LogError "Status code: $($_.Exception.Response.StatusCode.value__)"
            Write-LogError "Target site: $($_.TargetObject)"
        }

    .EXAMPLE
        # Structured error logging with context
        $ErrorLog = Initialize-Log -LogName "Errors" -LogPath "C:\Logs\Errors"
        
        function Test-Connection {
            param($Server)
            
            if (-not (Test-Path "\\$Server\c$")) {
                Write-LogError "Cannot access $Server - Error Code: ACCESS_DENIED (0x5)" -Logger $ErrorLog
                Write-LogError "User: $env:USERNAME, Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Logger $ErrorLog
                Write-LogError "Attempted path: \\$Server\c$" -Logger $ErrorLog
                return $false
            }
            return $true
        }

    .EXAMPLE
        # Validation errors with details
        Initialize-Log -Default
        
        $requiredFiles = @("config.json", "data.csv", "template.docx")
        
        foreach ($file in $requiredFiles) {
            if (-not (Test-Path $file)) {
                Write-LogError "Required file missing: $file"
                Write-LogError "Expected location: $(Join-Path $PWD $file)"
                Write-LogError "This will prevent the application from starting"
            }
        }

    .EXAMPLE
        # Database operation errors
        Initialize-Log -Default -WriteConsole
        
        Try {
            # Simulated database operation
            throw "Timeout expired. The timeout period elapsed prior to completion of the operation"
        }
        Catch {
            Write-LogError "Database operation failed"
            Write-LogError "Error: $_"
            Write-LogError "Connection string: Server=SQLServer01;Database=AppDB"
            Write-LogError "Query execution time before timeout: 30 seconds"
            Write-LogError "Recommended action: Check database server performance"
        }

    .EXAMPLE
        # Service failure logging
        $ServiceLog = Initialize-Log -LogName "ServiceMonitor" -LogPath "C:\Logs\Services"
        
        $criticalServices = @("W32Time", "EventLog", "Dhcp")
        foreach ($serviceName in $criticalServices) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service.Status -ne 'Running') {
                Write-LogError "Service failure: $serviceName is $($service.Status)" -Logger $ServiceLog
                Write-LogError "Attempting automatic restart..." -Logger $ServiceLog
            }
        }

    .EXAMPLE
        # File operation errors with remediation
        Initialize-Log -Default
        
        $sourceFile = "C:\Data\important.xlsx"
        $destFile = "D:\Backup\important.xlsx"
        
        Try {
            Copy-Item $sourceFile $destFile -ErrorAction Stop
        }
        Catch {
            Write-LogError "Failed to backup file: $sourceFile"
            Write-LogError "Destination: $destFile"
            Write-LogError "Error: $_"
            Write-LogError "Possible causes: Insufficient permissions, disk full, or file in use"
            Write-LogError "Suggested actions: Check disk space, verify permissions, close Excel"
        }

    .NOTES
        - ERROR level indicates problems requiring attention but not system-critical
        - For system-critical failures, use Write-LogCritical
        - Include enough detail for troubleshooting without exposing sensitive data
        - Consider logging stack traces for debugging (use DEBUG level for full traces)
        - Red console color provides immediate visual indication of problems
        - Errors should be actionable - include what went wrong and how to fix it
        - Avoid logging passwords, API keys, or other sensitive information

    .LINK
        Write-Log

    .LINK
        Write-LogCritical

    .LINK
        Write-LogWarning

    .LINK
        Write-LogInfo

    .LINK
        Write-LogDebug
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Message,
        
        [Parameter()]
        $Logger = $Script:DefaultLog
    )
    
    Process {
        Write-Log -LogMsg $Message -LogLevel "ERROR" -Logger $Logger
    }
}

Function Write-LogCritical {
    <#
    .SYNOPSIS
        Writes a CRITICAL level message to the specified or default logger.

    .DESCRIPTION
        Write-LogCritical is a convenience function for logging system-critical failures and
        catastrophic errors that require immediate intervention. It automatically sets the log
        level to CRITICAL, which appears in dark red when console output is enabled, providing
        the highest level of visual urgency.
        
        Use this function for:
        - System-critical failures
        - Unrecoverable errors requiring immediate action
        - Security breaches or violations
        - Data corruption that affects system integrity
        - Complete service failures
        - Infrastructure failures (storage, network, etc.)
        - Conditions that may cause data loss
        - Situations requiring emergency response
        
        CRITICAL messages indicate the most severe problems that threaten system stability,
        data integrity, or security. These typically require immediate administrator intervention
        and may trigger emergency response procedures.

    .PARAMETER Message
        The critical error message to be logged. Should clearly describe the catastrophic failure,
        its immediate impact, and required emergency actions. Include all relevant context for
        crisis response and recovery procedures.
        Supports pipeline input for bulk critical logging.
        Aliases: None

    .PARAMETER Logger
        Optional logger instance created by Initialize-Log. If not specified, uses the default
        logger. If no default logger exists and Logger parameter is not provided, throws an error.
        Aliases: None

    .INPUTS
        System.String
        Accepts string messages from the pipeline.

    .OUTPUTS
        None
        This function does not return any output.

    .EXAMPLE
        # Basic critical failure logging
        Initialize-Log -Default
        Write-LogCritical "SYSTEM FAILURE: Database server completely unresponsive"
        Write-LogCritical "CRITICAL: Complete data center power loss detected"
        Write-LogCritical "SECURITY BREACH: Unauthorized root access detected"

    .EXAMPLE
        # System crash with emergency procedures
        Initialize-Log -Default -LogName "SystemCritical" -WriteConsole
        
        Write-LogCritical "CRITICAL SYSTEM FAILURE DETECTED"
        Write-LogCritical "Primary database cluster has failed"
        Write-LogCritical "Automatic failover unsuccessful"
        Write-LogCritical "IMMEDIATE ACTION REQUIRED:"
        Write-LogCritical "1. Contact DBA team immediately: +1-555-EMERGENCY"
        Write-LogCritical "2. Initiate manual failover procedure DOC-001"
        Write-LogCritical "3. Notify all stakeholders via emergency channel"
        Write-LogCritical "Estimated data loss window: Last 5 minutes"

    .EXAMPLE
        # Security breach detection
        $SecurityLog = Initialize-Log -LogName "Security" -LogPath "C:\Logs\Critical"
        
        Write-LogCritical "SECURITY BREACH DETECTED" -Logger $SecurityLog
        Write-LogCritical "Multiple failed root login attempts from unknown IP" -Logger $SecurityLog
        Write-LogCritical "Suspicious file modifications in system directories" -Logger $SecurityLog
        Write-LogCritical "Potential ransomware activity detected" -Logger $SecurityLog
        Write-LogCritical "ACTIONS TAKEN:" -Logger $SecurityLog
        Write-LogCritical "- Network isolation initiated" -Logger $SecurityLog
        Write-LogCritical "- Security team notified" -Logger $SecurityLog
        Write-LogCritical "- Snapshot backup triggered" -Logger $SecurityLog
        
        # Send emergency notification
        Send-MailMessage -To "security@company.com" -Priority High `
                         -Subject "CRITICAL SECURITY BREACH" `
                         -Body "Check critical security log immediately"

    .EXAMPLE
        # Infrastructure failure with metrics
        Initialize-Log -Default -WriteConsole -ConsoleInfo
        
        $diskSpace = (Get-PSDrive C).Free / 1GB
        if ($diskSpace -lt 0.1) {
            Write-LogCritical "CRITICAL: System drive space exhausted"
            Write-LogCritical "Available space: $([math]::Round($diskSpace * 1024, 2))MB"
            Write-LogCritical "System will become unresponsive imminently"
            Write-LogCritical "All write operations will fail"
            Write-LogCritical "IMMEDIATE ACTION: Clear space or system will crash"
        }

    .EXAMPLE
        # Data corruption detection
        Initialize-Log -Default -LogName "DataIntegrity"
        
        Try {
            $checksum = Get-FileHash "C:\Critical\SystemData.db"
            $expected = "A7B9C2D4E5F6789012345678901234567890123456789012"
            
            if ($checksum.Hash -ne $expected) {
                Write-LogCritical "CRITICAL DATA CORRUPTION DETECTED"
                Write-LogCritical "File: C:\Critical\SystemData.db"
                Write-LogCritical "Expected hash: $expected"
                Write-LogCritical "Actual hash: $($checksum.Hash)"
                Write-LogCritical "Database integrity compromised - DO NOT USE"
                Write-LogCritical "Initiate recovery from backup immediately"
                
                # Prevent further damage
                Set-ItemProperty "C:\Critical\SystemData.db" -Name IsReadOnly -Value $true
            }
        }
        Catch {
            Write-LogCritical "CRITICAL: Cannot verify system data integrity"
            Write-LogCritical "Error: $_"
        }

    .EXAMPLE
        # Service failure cascade
        $CriticalLog = Initialize-Log -LogName "Critical" -LogPath "C:\Logs\Emergency"
        
        $criticalServices = @{
            "MSSQLSERVER" = "Database"
            "W3SVC" = "Web Server"
            "DNS" = "Name Resolution"
        }
        
        $failedCount = 0
        foreach ($service in $criticalServices.Keys) {
            if ((Get-Service $service -ErrorAction SilentlyContinue).Status -ne 'Running') {
                $failedCount++
                Write-LogCritical "CRITICAL: $($criticalServices[$service]) service failed" -Logger $CriticalLog
            }
        }
        
        if ($failedCount -ge 2) {
            Write-LogCritical "SYSTEM CASCADE FAILURE: $failedCount critical services down" -Logger $CriticalLog
            Write-LogCritical "System is non-functional - Emergency response required" -Logger $CriticalLog
        }

    .EXAMPLE
        # Production environment failure
        Initialize-Log -Default
        
        $productionCheck = Test-Connection "prod-server-01" -Count 1 -Quiet
        if (-not $productionCheck) {
            Write-LogCritical "PRODUCTION ENVIRONMENT OFFLINE"
            Write-LogCritical "Customer-facing services are completely unavailable"
            Write-LogCritical "Revenue impact: ~$10,000 per minute"
            Write-LogCritical "Affected users: ALL (estimated 50,000+)"
            Write-LogCritical "Escalation: Execute emergency response plan ERP-001"
            Write-LogCritical "Incident commander: John Smith (555-0100)"
            
            # Trigger emergency procedures
            & "C:\Emergency\InitiateDisasterRecovery.ps1"
        }

    .NOTES
        - CRITICAL level is reserved for the most severe, system-threatening issues
        - Should trigger immediate alerts and emergency response procedures
        - Dark red console color provides maximum visual urgency
        - Include clear action items and emergency contact information
        - Consider automatic escalation procedures for critical events
        - May warrant automatic system protective actions (isolation, shutdown, etc.)
        - Should be rare in normal operations - overuse dilutes urgency
        - Often paired with monitoring system alerts and paging

    .LINK
        Write-Log

    .LINK
        Write-LogError

    .LINK
        Write-LogWarning

    .LINK
        Write-LogInfo

    .LINK
        Write-LogDebug
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Message,
        
        [Parameter()]
        $Logger = $Script:DefaultLog
    )
    
    Process {
        Write-Log -LogMsg $Message -LogLevel "CRITICAL" -Logger $Logger
    }
}

Function Write-LogDebug {
    <#
    .SYNOPSIS
        Writes a DEBUG level message to the specified or default logger.

    .DESCRIPTION
        Write-LogDebug is a convenience function for logging detailed diagnostic information
        useful for troubleshooting and development. It automatically sets the log level to DEBUG,
        which appears in cyan when console output is enabled.
        
        Use this function for:
        - Variable values and state information
        - Execution flow tracking
        - Performance metrics
        - Detailed error context
        - Algorithm step-by-step progress
        - API request/response details
        - SQL queries and parameters
        
        DEBUG messages provide verbose information typically only needed during development
        or when diagnosing issues. Consider using a separate debug log file to avoid cluttering
        production logs.

    .PARAMETER Message
        The debug message to be logged. Should include detailed technical information,
        variable states, and execution context useful for troubleshooting.
        Supports pipeline input for bulk debug operations.
        Aliases: None

    .PARAMETER Logger
        Optional logger instance created by Initialize-Log. If not specified, uses the default
        logger. If no default logger exists and Logger parameter is not provided, throws an error.
        Aliases: None

    .INPUTS
        System.String
        Accepts string messages from the pipeline.

    .OUTPUTS
        None
        This function does not return any output.

    .EXAMPLE
        # Basic debug logging
        Initialize-Log -Default -LogLevel "DEBUG"
        
        $userData = @{Name="John"; ID=123; Role="Admin"}
        Write-LogDebug "User data loaded: $($userData | ConvertTo-Json -Compress)"
        Write-LogDebug "Cache hit ratio: 85.3%"
        Write-LogDebug "Memory usage: $([System.GC]::GetTotalMemory($false) / 1MB)MB"

    .EXAMPLE
        # Function execution tracing
        Initialize-Log -Default
        
        function Process-Data {
            param($InputData)
            
            Write-LogDebug "Entering Process-Data function"
            Write-LogDebug "Input parameter type: $($InputData.GetType().Name)"
            Write-LogDebug "Input parameter count: $($InputData.Count)"
            
            # Processing logic here
            
            Write-LogDebug "Process-Data completed in $($timer.ElapsedMilliseconds)ms"
            Write-LogDebug "Exiting Process-Data function"
        }

    .EXAMPLE
        # Variable state debugging
        $DebugLog = Initialize-Log -LogName "Debug" -WriteConsole -ConsoleInfo
        
        $config = Get-Content "config.json" | ConvertFrom-Json
        Write-LogDebug "Configuration loaded:" -Logger $DebugLog
        Write-LogDebug "  Server: $($config.Server)" -Logger $DebugLog
        Write-LogDebug "  Port: $($config.Port)" -Logger $DebugLog
        Write-LogDebug "  Timeout: $($config.Timeout)" -Logger $DebugLog
        Write-LogDebug "  RetryCount: $($config.RetryCount)" -Logger $DebugLog

    .EXAMPLE
        # Loop iteration debugging
        Initialize-Log -Default
        
        $items = Get-ChildItem -Path "C:\Data" -File
        Write-LogDebug "Found $($items.Count) files to process"
        
        foreach ($item in $items) {
            Write-LogDebug "Processing file: $($item.Name)"
            Write-LogDebug "  Size: $($item.Length) bytes"
            Write-LogDebug "  Modified: $($item.LastWriteTime)"
            Write-LogDebug "  Attributes: $($item.Attributes)"
            
            # Process file
            
            Write-LogDebug "  Result: Success"
        }

    .EXAMPLE
        # API debugging with request/response
        Initialize-Log -Default -LogName "API"
        
        $headers = @{
            "Authorization" = "Bearer [REDACTED]"
            "Content-Type" = "application/json"
        }
        
        Write-LogDebug "API Request:"
        Write-LogDebug "  Method: POST"
        Write-LogDebug "  URL: https://api.example.com/users"
        Write-LogDebug "  Headers: $($headers.Keys -join ', ')"
        
        $response = Invoke-RestMethod -Uri "https://api.example.com/users" -Method Post
        
        Write-LogDebug "API Response:"
        Write-LogDebug "  Status: 200 OK"
        Write-LogDebug "  Body: $($response | ConvertTo-Json -Depth 2 -Compress)"
        Write-LogDebug "  Time: 243ms"

    .EXAMPLE
        # Performance debugging
        Initialize-Log -Default
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        Write-LogDebug "Starting data import process"
        # Import operation
        Write-LogDebug "Import completed: $($stopwatch.ElapsedMilliseconds)ms"
        
        $stopwatch.Restart()
        Write-LogDebug "Starting data validation"
        # Validation operation
        Write-LogDebug "Validation completed: $($stopwatch.ElapsedMilliseconds)ms"
        
        $stopwatch.Restart()
        Write-LogDebug "Starting data transformation"
        # Transform operation
        Write-LogDebug "Transformation completed: $($stopwatch.ElapsedMilliseconds)ms"

    .EXAMPLE
        # SQL query debugging
        $DbLog = Initialize-Log -LogName "Database" -LogPath "C:\Logs\Debug"
        
        $query = @"
        SELECT u.Name, u.Email, r.RoleName
        FROM Users u
        JOIN Roles r ON u.RoleId = r.Id
        WHERE u.Active = @Active
        "@
        
        Write-LogDebug "Executing SQL query:" -Logger $DbLog
        Write-LogDebug $query -Logger $DbLog
        Write-LogDebug "Parameters: @Active = 1" -Logger $DbLog
        Write-LogDebug "Connection: Server=SQL01;Database=AppDB" -Logger $DbLog
        Write-LogDebug "Query returned 42 rows in 156ms" -Logger $DbLog

    .NOTES
        - DEBUG level is typically disabled in production environments
        - Can generate large log files if not managed properly
        - Consider using conditional debug logging based on a flag
        - Sanitize sensitive information (passwords, tokens) before logging
        - Cyan console color helps distinguish debug output
        - Use structured data formats (JSON) for complex objects
        - Include timestamps for performance analysis

    .LINK
        Write-Log

    .LINK
        Write-LogInfo

    .LINK
        Write-LogWarning

    .LINK
        Write-LogError

    .LINK
        Write-LogSuccess
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Message,
        
        [Parameter()]
        $Logger = $Script:DefaultLog
    )
    
    Process {
        Write-Log -LogMsg $Message -LogLevel "DEBUG" -Logger $Logger
    }
}

Function Write-LogSuccess {
    <#
    .SYNOPSIS
        Writes a SUCCESS level message to the specified or default logger.

    .DESCRIPTION
        Write-LogSuccess is a convenience function for logging successful operations and positive
        outcomes. It automatically sets the log level to SUCCESS, which appears in green when
        console output is enabled, providing clear visual confirmation of successful operations.
        
        Use this function for:
        - Successful operation completions
        - Achieved milestones
        - Passed validations
        - Successful authentications
        - Completed transactions
        - Backup confirmations
        - Deployment successes
        
        SUCCESS messages help track positive outcomes and provide confirmation that critical
        operations completed as expected. They're particularly useful for audit trails and
        operational reporting.

    .PARAMETER Message
        The success message to be logged. Should clearly indicate what succeeded and any
        relevant metrics or identifiers for tracking.
        Supports pipeline input for bulk success logging.
        Aliases: None

    .PARAMETER Logger
        Optional logger instance created by Initialize-Log. If not specified, uses the default
        logger. If no default logger exists and Logger parameter is not provided, throws an error.
        Aliases: None

    .INPUTS
        System.String
        Accepts string messages from the pipeline.

    .OUTPUTS
        None
        This function does not return any output.

    .EXAMPLE
        # Basic success logging
        Initialize-Log -Default
        Write-LogSuccess "Database backup completed successfully"
        Write-LogSuccess "All systems operational"
        Write-LogSuccess "User authentication successful"

    .EXAMPLE
        # Operation completion with metrics
        Initialize-Log -Default -WriteConsole
        
        $startTime = Get-Date
        # Perform operation
        Start-Sleep -Seconds 2
        $duration = (Get-Date) - $startTime
        
        Write-LogSuccess "Data import completed: 1000 records in $($duration.TotalSeconds) seconds"
        Write-LogSuccess "Performance: $([math]::Round(1000/$duration.TotalSeconds, 2)) records/second"

    .EXAMPLE
        # Batch processing success tracking
        $ProcessLog = Initialize-Log -LogName "BatchProcess" -WriteConsole -ConsoleInfo
        
        $files = Get-ChildItem -Path "C:\Import" -Filter "*.csv"
        $processed = 0
        
        foreach ($file in $files) {
            # Process file
            $processed++
            Write-LogSuccess "Processed: $($file.Name) ($processed/$($files.Count))" -Logger $ProcessLog
        }
        
        Write-LogSuccess "Batch complete: All $processed files processed successfully" -Logger $ProcessLog

    .EXAMPLE
        # Validation success messages
        Initialize-Log -Default
        
        function Test-Configuration {
            param($Config)
            
            if (Test-Path $Config.LogPath) {
                Write-LogSuccess "✓ Log path exists and is accessible"
            }
            
            if (Test-Connection $Config.Server -Count 1 -Quiet) {
                Write-LogSuccess "✓ Server $($Config.Server) is reachable"
            }
            
            if ($Config.Version -eq "2.0") {
                Write-LogSuccess "✓ Configuration version is compatible"
            }
            
            Write-LogSuccess "Configuration validation passed all checks"
        }

    .EXAMPLE
        # Deployment success tracking
        Initialize-Log -Default -LogName "Deployment"
        
        Write-LogSuccess "Deployment started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-LogSuccess "Package uploaded to server: PROD-WEB-01"
        Write-LogSuccess "Previous version backed up to: /backup/app_v1.9.0.zip"
        Write-LogSuccess "New version extracted: v2.0.0"
        Write-LogSuccess "Database migration completed: 5 scripts executed"
        Write-LogSuccess "Service restarted successfully"
        Write-LogSuccess "Health check passed: All endpoints responding"
        Write-LogSuccess "Deployment completed successfully in 4 minutes 32 seconds"

    .EXAMPLE
        # Transaction success with details
        $TransactionLog = Initialize-Log -LogName "Transactions" -LogPath "C:\Logs\Audit"
        
        $transactionId = [guid]::NewGuid().ToString()
        Write-LogSuccess "Transaction initiated: $transactionId" -Logger $TransactionLog
        Write-LogSuccess "Payment processed: $100.00 USD" -Logger $TransactionLog
        Write-LogSuccess "Order confirmed: ORD-2025-08-15-001" -Logger $TransactionLog
        Write-LogSuccess "Email notification sent to: customer@example.com" -Logger $TransactionLog
        Write-LogSuccess "Transaction $transactionId completed successfully" -Logger $TransactionLog

    .EXAMPLE
        # Backup success with statistics
        Initialize-Log -Default
        
        $backupStart = Get-Date
        $sourceSize = (Get-ChildItem "C:\Data" -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
        
        # Perform backup
        Write-LogSuccess "Backup completed successfully"
        Write-LogSuccess "Source size: $([math]::Round($sourceSize, 2))GB"
        Write-LogSuccess "Files backed up: 1,234"
        Write-LogSuccess "Compression ratio: 65%"
        Write-LogSuccess "Final backup size: $([math]::Round($sourceSize * 0.35, 2))GB"
        Write-LogSuccess "Time taken: $((Get-Date) - $backupStart)"
        Write-LogSuccess "Backup verified: Checksum match confirmed"

    .NOTES
        - SUCCESS level helps identify positive outcomes in logs
        - Green console color provides immediate visual confirmation
        - Include relevant metrics and identifiers for tracking
        - Useful for audit trails and compliance reporting
        - Consider logging both start and completion of operations
        - Success messages should be clear and unambiguous

    .LINK
        Write-Log

    .LINK
        Write-LogInfo

    .LINK
        Write-LogWarning

    .LINK
        Write-LogError

    .LINK
        Write-LogDebug
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Message,
        
        [Parameter()]
        $Logger = $Script:DefaultLog
    )
    
    Process {
        Write-Log -LogMsg $Message -LogLevel "SUCCESS" -Logger $Logger
    }
}

Function Get-LoggerInfo {
    <#
    .SYNOPSIS
        Retrieves configuration and status information about a logger instance.

    .DESCRIPTION
        Get-LoggerInfo returns detailed information about a logger's configuration, including
        file paths, rotation settings, output options, and current status. This is useful for
        verifying logger configuration, troubleshooting issues, and runtime inspection of
        logging settings.
        
        The function returns a custom object with all logger properties in an easy-to-read
        format, which can be displayed in a table, exported to CSV, or used for documentation.
        
        Information returned includes:
        - Log file name and full path
        - Current log level setting
        - Rotation configuration
        - Console output settings
        - Encoding and formatting options
        - Retry and compression settings

    .PARAMETER Logger
        Optional logger instance to inspect. If not specified, uses the default logger set by
        Initialize-Log -Default. If no default logger exists and Logger parameter is not
        provided, throws an error.
        Aliases: None

    .INPUTS
        None
        This function does not accept pipeline input.

    .OUTPUTS
        PSCustomObject
        Returns a custom object containing all logger configuration properties.

    .EXAMPLE
        # Get information about the default logger
        Initialize-Log -Default -LogName "Application"
        Get-LoggerInfo
        
        # Output:
        # LogName        : Application
        # LogPath        : C:\Temp
        # LogFile        : C:\Temp\Application.log
        # LogLevel       : INFO
        # DateTimeFormat : yyyy-MM-dd HH:mm:ss
        # ...

    .EXAMPLE
        # Get information about a specific logger
        $AppLog = Initialize-Log -LogName "MyApp" -LogPath "D:\Logs" -LogRoll -LogRotateOpt "10M"
        Get-LoggerInfo -Logger $AppLog
        
        # Shows configuration including rotation settings

    .EXAMPLE
        # Export logger configuration to CSV
        Initialize-Log -Default -LogName "Production" -LogRoll -LogZip
        Get-LoggerInfo | Export-Csv -Path "logger-config.csv" -NoTypeInformation
        
        # Creates a CSV file with all logger settings for documentation

    .EXAMPLE
        # Display logger info in formatted table
        $Log1 = Initialize-Log -LogName "App" -WriteConsole
        $Log2 = Initialize-Log -LogName "Error" -LogLevel "ERROR"
        
        @($Log1, $Log2) | ForEach-Object {
            Get-LoggerInfo -Logger $_
        } | Format-Table LogName, LogPath, LogLevel, WriteToConsole

    .EXAMPLE
        # Verify logger configuration in script
        Initialize-Log -Default -LogName "Service" -LogRoll -LogRotateOpt "1"
        
        $info = Get-LoggerInfo
        if ($info.LogRotation -eq $true -and $info.LogRotateOption -eq "1") {
            Write-Host "Daily rotation is configured correctly"
        }
        
        if ($info.LogZip -eq $true) {
            Write-Host "Log compression is enabled"
        }

    .EXAMPLE
        # Troubleshooting logger issues
        $TestLog = Initialize-Log -LogName "Test" -LogPath "C:\InvalidPath\?"
        $info = Get-LoggerInfo -Logger $TestLog
        
        # Check if path exists
        if (-not (Test-Path $info.LogPath)) {
            Write-Warning "Log path does not exist: $($info.LogPath)"
        }
        
        # Verify file accessibility
        try {
            [System.IO.File]::OpenWrite($info.LogFile).Close()
            Write-Host "Log file is writable"
        } catch {
            Write-Error "Cannot write to log file: $_"
        }

    .EXAMPLE
        # Document multiple logger configurations
        $loggers = @{
            Application = Initialize-Log -LogName "App" -LogPath "C:\Logs\App"
            Security = Initialize-Log -LogName "Security" -LogPath "C:\Logs\Security" -LogLevel "WARNING"
            Debug = Initialize-Log -LogName "Debug" -WriteConsole -ConsoleOnly
        }
        
        $documentation = foreach ($name in $loggers.Keys) {
            $info = Get-LoggerInfo -Logger $loggers[$name]
            [PSCustomObject]@{
                Purpose = $name
                Configuration = $info
                Status = if (Test-Path $info.LogPath) { "Ready" } else { "Invalid" }
            }
        }
        
        $documentation | ConvertTo-Json -Depth 3 | Out-File "logger-documentation.json"

    .NOTES
        - Useful for runtime inspection of logger configuration
        - Can be used to validate logger setup before operations
        - Helps with troubleshooting logging issues
        - Output can be exported for documentation purposes
        - All properties are read-only snapshots of current configuration

    .LINK
        Initialize-Log

    .LINK
        Test-Logger

    .LINK
        Write-Log
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
        $Logger = $Script:DefaultLog
    )
    
    If (-not $Logger) {
        Write-Error "No logger specified and no default logger is initialized."
        Return
    }
    
    [PSCustomObject]@{
        LogName = $Logger.LogName
        LogPath = $Logger.LogPath
        LogFile = $Logger.LogFile
        LogLevel = $Logger.LogLevel
        DateTimeFormat = $Logger.DateTimeFormat
        Encoding = $Logger.Encoding
        LogRotation = $Logger.LogRoll
        LogRotateOption = $Logger.LogRotateOpt
        LogZip = $Logger.LogZip
        MaxLogFiles = $Logger.LogCountMax
        WriteToConsole = $Logger.WriteConsole
        ConsoleOnly = $Logger.ConsoleOnly
        RetryCount = $Logger.LogRetry
        ModuleName = $Logger.ModuleName
        LogFormat = $Logger.LogFormat -join ', '
        LogBrackets = $Logger.LogBrackets
    }
}

Function Test-Logger {
    <#
    .SYNOPSIS
        Tests logger functionality and verifies write access to the log file.

    .DESCRIPTION
        Test-Logger validates that a logger instance is properly configured and can successfully
        write to its designated log file. It performs a test write operation and reports success
        or failure, making it useful for pre-flight checks before starting critical operations.
        
        The function tests:
        - Logger initialization status
        - Directory existence and permissions
        - File write capabilities
        - Rotation mechanism (if enabled)
        - Retry mechanism functionality
        
        This is particularly useful in:
        - Script initialization phases
        - CI/CD pipelines
        - Configuration validation
        - Troubleshooting logging issues
        - Health checks

    .PARAMETER Logger
        Optional logger instance to test. If not specified, uses the default logger set by
        Initialize-Log -Default. If no default logger exists and Logger parameter is not
        provided, returns $false with an error.
        Aliases: None

    .PARAMETER TestMessage
        Custom message to use for the test write operation. If not specified, uses a default
        message with timestamp. The message will be written at DEBUG level.
        Default: "Logger test message - {current timestamp}"
        Aliases: None

    .INPUTS
        None
        This function does not accept pipeline input.

    .OUTPUTS
        System.Boolean
        Returns $true if the logger test succeeds, $false if it fails.

    .EXAMPLE
        # Test the default logger
        Initialize-Log -Default -LogName "Application"
        
        if (Test-Logger) {
            Write-Host "Logger is working correctly" -ForegroundColor Green
        } else {
            Write-Host "Logger test failed" -ForegroundColor Red
            exit 1
        }

    .EXAMPLE
        # Test a specific logger with custom message
        $AppLog = Initialize-Log -LogName "TestLog" -LogPath "C:\Logs"
        
        if (Test-Logger -Logger $AppLog -TestMessage "Initialization test") {
            Write-LogInfo "Logger verified and ready" -Logger $AppLog
        } else {
            Write-Error "Cannot initialize logging system"
        }

    .EXAMPLE
        # Test multiple loggers in a script
        $loggers = @{
            Main = Initialize-Log -LogName "Main" -LogPath "C:\Logs"
            Error = Initialize-Log -LogName "Errors" -LogPath "C:\Logs\Errors"
            Audit = Initialize-Log -LogName "Audit" -LogPath "C:\Logs\Audit"
        }
        
        $failed = @()
        foreach ($name in $loggers.Keys) {
            if (-not (Test-Logger -Logger $loggers[$name])) {
                $failed += $name
            }
        }
        
        if ($failed.Count -gt 0) {
            Write-Error "Following loggers failed: $($failed -join ', ')"
        }

    .EXAMPLE
        # Pre-flight check in production script
        Initialize-Log -Default -LogName "Production" -LogPath "E:\Logs" -LogRoll
        
        # Verify logger before starting critical operations
        if (-not (Test-Logger)) {
            Send-MailMessage -To "admin@company.com" `
                            -Subject "Production Script Failed to Start" `
                            -Body "Logger initialization failed on $env:COMPUTERNAME"
            throw "Cannot initialize logging system"
        }
        
        Write-LogInfo "Production script started successfully"

    .EXAMPLE
        # Test logger with verbose output for troubleshooting
        $VerbosePreference = "Continue"
        $TestLog = Initialize-Log -LogName "Debug" -LogPath "C:\Temp\Logs"
        
        if (Test-Logger -Logger $TestLog) {
            Write-Verbose "Test write successful"
            Write-Verbose "Log file: $($TestLog.LogFile)"
            Write-Verbose "Can proceed with operations"
        } else {
            Write-Verbose "Test failed - checking permissions"
            $acl = Get-Acl -Path (Split-Path $TestLog.LogFile)
            Write-Verbose "Current permissions: $($acl.Access | Out-String)"
        }

    .EXAMPLE
        # Automated testing in CI/CD pipeline
        BeforeAll {
            $script:Logger = Initialize-Log -LogName "UnitTest" -LogPath $TestDrive
        }
        
        Describe "Logger Functionality" {
            It "Should successfully write to log file" {
                Test-Logger -Logger $script:Logger | Should -Be $true
            }
            
            It "Should create log file if it doesn't exist" {
                $script:Logger.LogFile | Should -Exist
            }
        }

    .EXAMPLE
        # Health check function using Test-Logger
        function Test-LoggingHealth {
            $results = @()
            
            # Test default logger
            Initialize-Log -Default -LogName "HealthCheck"
            $results += [PSCustomObject]@{
                Logger = "Default"
                Status = if (Test-Logger) { "Healthy" } else { "Failed" }
                Timestamp = Get-Date
            }
            
            # Test application logger
            $appLog = Initialize-Log -LogName "Application" -LogPath "C:\Logs"
            $results += [PSCustomObject]@{
                Logger = "Application"
                Status = if (Test-Logger -Logger $appLog) { "Healthy" } else { "Failed" }
                Timestamp = Get-Date
            }
            
            return $results
        }
        
        Test-LoggingHealth | Format-Table -AutoSize

    .NOTES
        - Returns boolean for easy integration in conditional logic
        - Test message is written at DEBUG level to minimize log pollution
        - Useful for pre-flight checks before critical operations
        - Can help diagnose permission and path issues
        - Consider running tests periodically in long-running scripts
        - Verbose output available for detailed troubleshooting

    .LINK
        Initialize-Log

    .LINK
        Get-LoggerInfo

    .LINK
        Write-Log
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
        [Parameter()]
        $Logger = $Script:DefaultLog,
        
        [Parameter()]
        [string]$TestMessage = "Logger test message - $(Get-Date)"
    )
    
    If (-not $Logger) {
        Write-Error "No logger specified and no default logger is initialized."
        Return $false
    }
    
    Try {
        $Logger.Write($TestMessage, "DEBUG")
        Write-Verbose "Logger test successful. Log file: $($Logger.LogFile)"
        Return $true
    }
    Catch {
        Write-Error "Logger test failed: $_"
        Return $false
    }
}

Function New-Logger {
    <#
    .SYNOPSIS
        Creates a new Logger instance with specified configuration settings.

    .DESCRIPTION
        New-Logger is a wrapper around Initialize-Log that provides a more intuitive function name
        for creating logger instances. It returns a configured Logger object that can be used with
        Write-Log and related functions.

        This function is ideal for scenarios where you need multiple logger instances or want to
        explicitly manage logger objects without setting a script-wide default.

    .PARAMETER LogName
        Name of the log file (without extension). The .log extension is automatically appended.
        Default: "Debug"

    .PARAMETER LogPath
        Directory path where log files will be created. Directory is created if it doesn't exist.
        Default: "C:\Temp"

    .PARAMETER LogLevel
        Default logging level. Valid values: INFO, WARNING, ERROR, DEBUG, SUCCESS, CRITICAL
        Default: "INFO"

    .PARAMETER LogRoll
        Enable automatic log rotation based on size or age.
        Default: $false

    .PARAMETER LogRotateOpt
        Rotation threshold. Format: "10M" (10MB), "100M", "1G" (size-based) or "7" (days-based).
        Default: "1M"

    .PARAMETER LogZip
        Enable compression of rotated logs into zip archives.
        Default: $false

    .PARAMETER LogCountMax
        Maximum number of rotated log files to keep. Oldest logs are deleted when exceeded.
        Default: 5

    .PARAMETER WriteConsole
        Enable output to console in addition to file logging.
        Default: $false

    .PARAMETER ConsoleOnly
        Output only to console, do not create log files.
        Default: $false

    .PARAMETER ModuleName
        Module or component name to include in log entries for identification.
        Default: $null

    .INPUTS
        None

    .OUTPUTS
        Logger
        Returns a configured Logger instance.

    .EXAMPLE
        # Create a simple logger
        $log = New-Logger -LogName "Application" -LogPath "C:\Logs"
        Write-Log "Application started" -Logger $log

    .EXAMPLE
        # Create logger with rotation and compression
        $log = New-Logger -LogName "Production" -LogPath "D:\Logs" -LogRoll -LogRotateOpt "50M" -LogZip -LogCountMax 10
        Write-Log "Production event" -Logger $log

    .EXAMPLE
        # Create console-only logger for interactive scripts
        $log = New-Logger -LogName "Interactive" -WriteConsole -ConsoleOnly
        Write-Log "This appears only in console" -Logger $log

    .EXAMPLE
        # Create multiple loggers for different components
        $webLog = New-Logger -LogName "WebAPI" -LogPath "C:\Logs" -ModuleName "WebAPI"
        $dbLog = New-Logger -LogName "Database" -LogPath "C:\Logs" -ModuleName "DataLayer"

        Write-Log "API request received" -Logger $webLog
        Write-Log "Database query executed" -Logger $dbLog

    .NOTES
        This is a convenience wrapper around Initialize-Log with a more intuitive name.
        Use Set-DefaultLogger if you want to set a logger as the script-wide default.

    .LINK
        Initialize-Log

    .LINK
        Set-DefaultLogger

    .LINK
        Get-Logger
    #>
    [CmdletBinding()]
    [OutputType([Logger])]
    Param(
        [Parameter()]
        [string]$LogName = "Debug",

        [Parameter()]
        [string]$LogPath = "C:\Temp",

        [Parameter()]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG", "SUCCESS", "CRITICAL")]
        [string]$LogLevel = "INFO",

        [Parameter()]
        [switch]$LogRoll,

        [Parameter()]
        [string]$LogRotateOpt = "1M",

        [Parameter()]
        [switch]$LogZip,

        [Parameter()]
        [int]$LogCountMax = 5,

        [Parameter()]
        [switch]$WriteConsole,

        [Parameter()]
        [switch]$ConsoleOnly,

        [Parameter()]
        [string]$ModuleName
    )

    # Build parameter hashtable
    $params = @{
        LogName = $LogName
        LogPath = $LogPath
        LogLevel = $LogLevel
        LogRoll = $LogRoll
        LogRotateOpt = $LogRotateOpt
        LogZip = $LogZip
        LogCountMax = $LogCountMax
        WriteConsole = $WriteConsole
        ConsoleOnly = $ConsoleOnly
    }

    If ($ModuleName) {
        $params.ModuleName = $ModuleName
    }

    # Call Initialize-Log with parameters (do not set as default)
    Return Initialize-Log @params
}

Function Get-Logger {
    <#
    .SYNOPSIS
        Retrieves the default logger or creates one if none exists.

    .DESCRIPTION
        Get-Logger provides a safe way to retrieve the current default logger instance. If no default
        logger has been initialized, it creates a new one with default settings and sets it as the
        default. This ensures that logging functions always have a logger to work with.

        This is particularly useful in modules or scripts where you want to ensure a logger exists
        without explicitly checking every time.

    .PARAMETER EnsureExists
        If specified, creates a default logger if one doesn't exist. If not specified and no default
        logger exists, returns $null.
        Default: $true

    .INPUTS
        None

    .OUTPUTS
        Logger
        Returns the default Logger instance, or $null if none exists and EnsureExists is $false.

    .EXAMPLE
        # Get or create default logger
        $log = Get-Logger
        Write-Log "Application started" -Logger $log

    .EXAMPLE
        # Check if default logger exists without creating one
        $log = Get-Logger -EnsureExists:$false
        if ($log) {
            Write-Log "Using existing logger"
        } else {
            Write-Host "No logger initialized"
        }

    .EXAMPLE
        # Use in a function that needs logging
        function Do-Something {
            $log = Get-Logger
            Write-Log "Doing something..." -Logger $log
            # ... function logic ...
            Write-Log "Done!" -Logger $log
        }

    .NOTES
        If EnsureExists is $true (default) and no logger exists, creates a logger with:
        - LogName: "Debug"
        - LogPath: "C:\Temp"
        - LogLevel: "INFO"

    .LINK
        Set-DefaultLogger

    .LINK
        New-Logger

    .LINK
        Initialize-Log
    #>
    [CmdletBinding()]
    [OutputType([Logger])]
    Param(
        [Parameter()]
        [bool]$EnsureExists = $true
    )

    If ($Script:DefaultLog) {
        Return $Script:DefaultLog
    }

    If ($EnsureExists) {
        Write-Verbose "No default logger exists, creating one with default settings"
        $Script:DefaultLog = Initialize-Log -Default
        Return $Script:DefaultLog
    }

    Return $null
}

Function Set-DefaultLogger {
    <#
    .SYNOPSIS
        Sets a logger instance as the script-wide default logger.

    .DESCRIPTION
        Set-DefaultLogger configures a Logger instance as the default logger for the current script
        or module scope. Once set, all Write-Log* functions will use this logger by default unless
        a different logger is explicitly specified.

        This is useful when you create a logger with specific settings and want to use it throughout
        your script without passing it to every logging call.

    .PARAMETER Logger
        The Logger instance to set as default. Must be a valid Logger object created by Initialize-Log
        or New-Logger.

    .INPUTS
        Logger
        Accepts a Logger instance via the pipeline.

    .OUTPUTS
        None

    .EXAMPLE
        # Create a logger and set it as default
        $log = New-Logger -LogName "Application" -LogPath "C:\Logs" -LogRoll
        Set-DefaultLogger -Logger $log

        # Now all Write-Log calls use this logger by default
        Write-Log "Application started"
        Write-LogInfo "Processing data"

    .EXAMPLE
        # Pipeline usage
        New-Logger -LogName "Production" -LogPath "D:\Logs" -LogRoll -LogZip | Set-DefaultLogger
        Write-Log "Production script started"

    .EXAMPLE
        # Switch default logger during script execution
        $normalLog = New-Logger -LogName "Normal" -LogPath "C:\Logs"
        $debugLog = New-Logger -LogName "Debug" -LogPath "C:\Logs" -LogLevel "DEBUG" -WriteConsole

        Set-DefaultLogger -Logger $normalLog
        Write-Log "Normal operation"

        # Switch to debug mode
        Set-DefaultLogger -Logger $debugLog
        Write-LogDebug "Debug information"

    .NOTES
        The default logger is stored in $Script:DefaultLog and persists for the script scope.
        Module functions can use Get-Logger to retrieve the default logger.

    .LINK
        Get-DefaultLogger

    .LINK
        Get-Logger

    .LINK
        New-Logger
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Logger]$Logger
    )

    Process {
        $Script:DefaultLog = $Logger
        Write-Verbose "Default logger set to: $($Logger.LogName) at $($Logger.LogPath)"
    }
}

Function Get-DefaultLogger {
    <#
    .SYNOPSIS
        Returns the current default logger instance.

    .DESCRIPTION
        Get-DefaultLogger retrieves the logger that has been set as the script-wide default using
        Initialize-Log -Default or Set-DefaultLogger. If no default logger has been configured,
        returns $null.

        This function is useful for checking whether a default logger exists before using logging
        functions, or for retrieving the default logger to inspect its configuration.

    .INPUTS
        None

    .OUTPUTS
        Logger
        Returns the default Logger instance, or $null if no default logger is set.

    .EXAMPLE
        # Check if default logger exists
        $log = Get-DefaultLogger
        if ($log) {
            Write-Host "Default logger: $($log.LogName) at $($log.LogPath)"
        } else {
            Write-Host "No default logger configured"
        }

    .EXAMPLE
        # Get default logger info
        $log = Get-DefaultLogger
        if ($log) {
            Get-LoggerInfo -Logger $log | Format-List
        }

    .EXAMPLE
        # Verify default logger before script execution
        if (-not (Get-DefaultLogger)) {
            Write-Error "No default logger configured. Initialize with Initialize-Log -Default"
            exit 1
        }

        Write-Log "Script starting..."

    .NOTES
        Returns $null if no default logger has been set.
        Use Get-Logger -EnsureExists to automatically create a default logger if none exists.

    .LINK
        Set-DefaultLogger

    .LINK
        Get-Logger

    .LINK
        Initialize-Log
    #>
    [CmdletBinding()]
    [OutputType([Logger])]
    Param()

    Return $Script:DefaultLog
}

Function Add-LogEnricher {
    <#
    .SYNOPSIS
        Adds a context enricher to a logger for automatic property injection.

    .DESCRIPTION
        Add-LogEnricher attaches an enricher object to a logger instance. Enrichers automatically add
        contextual properties to log entries, such as machine name, process ID, thread ID, environment
        variables, or network information.

        Multiple enrichers can be added to a single logger, and each enricher's Enrich() method is
        called for every log entry to inject its properties.

    .PARAMETER Logger
        The Logger instance to add the enricher to. If not specified, uses the default logger.

    .PARAMETER Enricher
        The enricher object to add. Must implement the IEnricher interface with an Enrich() method.
        Can be created using New-*Enricher functions (New-MachineEnricher, New-ProcessEnricher, etc.)
        or custom enrichers inheriting from IEnricher.

    .INPUTS
        Logger
        Accepts a Logger instance via the pipeline.

    .OUTPUTS
        None

    .EXAMPLE
        # Add machine enricher to default logger
        Initialize-Log -Default -LogName "Application"
        $machineEnricher = New-MachineEnricher
        Add-LogEnricher -Enricher $machineEnricher

        Write-Log "Application started"
        # Log includes: MachineName, OSVersion, Domain

    .EXAMPLE
        # Add multiple enrichers to a logger
        $log = New-Logger -LogName "Production" -LogPath "D:\Logs"

        Add-LogEnricher -Logger $log -Enricher (New-MachineEnricher)
        Add-LogEnricher -Logger $log -Enricher (New-ProcessEnricher)
        Add-LogEnricher -Logger $log -Enricher (New-ThreadEnricher)

        Write-Log "Enriched log entry" -Logger $log

    .EXAMPLE
        # Pipeline usage to add enricher
        $log = New-Logger -LogName "App"
        $log | Add-LogEnricher -Enricher (New-NetworkEnricher)
        Write-Log "Network information included" -Logger $log

    .EXAMPLE
        # Create custom enricher
        class CustomEnricher : IEnricher {
            [hashtable] Enrich() {
                return @{
                    AppVersion = "1.0.0"
                    BuildDate = "2025-11-05"
                    Environment = "Production"
                }
            }
        }

        $log = New-Logger -LogName "Custom"
        Add-LogEnricher -Logger $log -Enricher ([CustomEnricher]::new())
        Write-Log "Custom properties included"

    .NOTES
        Enrichers are called for every log entry, so avoid expensive operations in Enrich() method.
        Common enrichers: MachineEnricher, ProcessEnricher, ThreadEnricher, EnvironmentEnricher, NetworkEnricher

    .LINK
        New-MachineEnricher

    .LINK
        New-ProcessEnricher

    .LINK
        New-ThreadEnricher

    .LINK
        Remove-LogEnricher
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [Logger]$Logger = $Script:DefaultLog,

        [Parameter(Mandatory)]
        [IEnricher]$Enricher
    )

    Process {
        If (-not $Logger) {
            Write-Error "No logger specified and no default logger is initialized."
            Return
        }

        $Logger.AddEnricher($Enricher)
        Write-Verbose "Enricher added to logger: $($Enricher.GetType().Name)"
    }
}

Function Add-LogHandler {
    <#
    .SYNOPSIS
        Adds a log handler to a logger for custom output destinations.

    .DESCRIPTION
        Add-LogHandler attaches a handler object to a logger instance. Handlers define where and how
        log messages are written. Multiple handlers can be added to support writing to multiple
        destinations simultaneously (e.g., file, console, Windows Event Log, database, API).

        The Logger class supports FileHandler, ConsoleHandler, EventLogHandler, and custom handlers.

    .PARAMETER Logger
        The Logger instance to add the handler to. If not specified, uses the default logger.

    .PARAMETER Handler
        The handler object to add. Must inherit from LogHandler base class. Can be created using
        New-*Handler functions (New-FileHandler, New-ConsoleHandler, etc.) or custom handlers.

    .INPUTS
        Logger
        Accepts a Logger instance via the pipeline.

    .OUTPUTS
        None

    .EXAMPLE
        # Add console handler to logger
        $log = New-Logger -LogName "Application"
        $consoleHandler = New-ConsoleHandler
        Add-LogHandler -Logger $log -Handler $consoleHandler

        Write-Log "Appears in both file and console" -Logger $log

    .EXAMPLE
        # Add Windows Event Log handler
        $log = New-Logger -LogName "Production"
        $eventHandler = New-EventLogHandler -LogName "Application" -Source "MyApp"
        Add-LogHandler -Logger $log -Handler $eventHandler

        Write-LogError "Error logged to file and Windows Event Log" -Logger $log

    .EXAMPLE
        # Multiple handlers for different destinations
        $log = New-Logger -LogName "MultiTarget"

        Add-LogHandler -Logger $log -Handler (New-FileHandler -Path "C:\Logs\app.log")
        Add-LogHandler -Logger $log -Handler (New-ConsoleHandler)
        Add-LogHandler -Logger $log -Handler (New-EventLogHandler -LogName "Application" -Source "App")

        Write-Log "Written to file, console, and event log" -Logger $log

    .EXAMPLE
        # Pipeline usage
        $log = New-Logger -LogName "Pipeline"
        $log | Add-LogHandler -Handler (New-ConsoleHandler)
        Write-Log "Handler added via pipeline" -Logger $log

    .NOTES
        Handlers are invoked in the order they are added.
        Use NullHandler to disable output without removing logger functionality.

    .LINK
        New-FileHandler

    .LINK
        New-ConsoleHandler

    .LINK
        New-EventLogHandler

    .LINK
        Remove-LogHandler
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [Logger]$Logger = $Script:DefaultLog,

        [Parameter(Mandatory)]
        [LogHandler]$Handler
    )

    Process {
        If (-not $Logger) {
            Write-Error "No logger specified and no default logger is initialized."
            Return
        }

        $Logger.AddHandler($Handler)
        Write-Verbose "Handler added to logger: $($Handler.GetType().Name)"
    }
}

Function Add-LogFilter {
    <#
    .SYNOPSIS
        Adds a filter to a logger to conditionally include or exclude log entries.

    .DESCRIPTION
        Add-LogFilter attaches a filter object to a logger instance. Filters implement logic to
        determine whether a log entry should be written based on various conditions (time of day,
        calling function, user, custom properties, etc.).

        Multiple filters can be added to a logger, and ALL filters must return $true for a log
        entry to be written (AND logic).

    .PARAMETER Logger
        The Logger instance to add the filter to. If not specified, uses the default logger.

    .PARAMETER Filter
        The filter object to add. Must implement the ILogFilter interface with a ShouldLog() method.
        Can be created using New-*Filter functions or custom filters inheriting from ILogFilter.

    .INPUTS
        Logger
        Accepts a Logger instance via the pipeline.

    .OUTPUTS
        None

    .EXAMPLE
        # Only log during business hours
        $log = New-Logger -LogName "BusinessHours"
        $timeFilter = New-TimeFilter -StartHour 8 -EndHour 17
        Add-LogFilter -Logger $log -Filter $timeFilter

        Write-Log "Only logged between 8 AM and 5 PM" -Logger $log

    .EXAMPLE
        # Filter logs from specific function
        $log = New-Logger -LogName "Filtered"
        $funcFilter = New-FunctionFilter -AllowedFunctions @("Main", "ProcessData")
        Add-LogFilter -Logger $log -Filter $funcFilter

        # Only logs from Main or ProcessData functions will be written

    .EXAMPLE
        # Combine multiple filters
        $log = New-Logger -LogName "Restricted"

        Add-LogFilter -Logger $log -Filter (New-TimeFilter -StartHour 8 -EndHour 17)
        Add-LogFilter -Logger $log -Filter (New-UserFilter -AllowedUsers @("admin", "operator"))

        # Logs only written during business hours AND by admin/operator users

    .EXAMPLE
        # Custom filter for high-priority logs only
        class PriorityFilter : ILogFilter {
            [bool] ShouldLog([string]$Message, [string]$Level, [hashtable]$Properties) {
                return $Level -in @("ERROR", "CRITICAL", "WARNING")
            }
        }

        $log = New-Logger -LogName "HighPriority"
        Add-LogFilter -Logger $log -Filter ([PriorityFilter]::new())

        Write-LogInfo "Not logged (INFO filtered out)" -Logger $log
        Write-LogError "Logged (ERROR allowed)" -Logger $log

    .NOTES
        All filters must return $true for a log entry to be written (AND logic).
        Filters are evaluated before handlers, so filtered messages are never written.

    .LINK
        New-FunctionFilter

    .LINK
        New-TimeFilter

    .LINK
        New-UserFilter

    .LINK
        Remove-LogFilter
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        [Logger]$Logger = $Script:DefaultLog,

        [Parameter(Mandatory)]
        [ILogFilter]$Filter
    )

    Process {
        If (-not $Logger) {
            Write-Error "No logger specified and no default logger is initialized."
            Return
        }

        $Logger.AddFilter($Filter)
        Write-Verbose "Filter added to logger: $($Filter.GetType().Name)"
    }
}

Function New-FileHandler {
    <#
    .SYNOPSIS
        Creates a new FileHandler for writing logs to a file.

    .DESCRIPTION
        New-FileHandler creates a LogHandler that writes log entries to a specified file path.
        This handler can be added to a logger using Add-LogHandler to enable file-based logging
        with custom file locations separate from the logger's default log file.

    .PARAMETER Path
        The full path to the log file where entries will be written.

    .PARAMETER Encoding
        The file encoding to use. Valid values: Unicode, UTF7, UTF8, UTF32, ASCII, BigEndianUnicode, Default, OEM
        Default: "Unicode"

    .INPUTS
        None

    .OUTPUTS
        FileHandler
        Returns a configured FileHandler instance.

    .EXAMPLE
        # Create file handler and add to logger
        $log = New-Logger -LogName "Application"
        $fileHandler = New-FileHandler -Path "C:\Logs\custom.log"
        Add-LogHandler -Logger $log -Handler $fileHandler

    .EXAMPLE
        # Multiple file handlers for different log levels
        $log = New-Logger -LogName "MultiFile"

        $errorHandler = New-FileHandler -Path "C:\Logs\errors.log"
        $infoHandler = New-FileHandler -Path "C:\Logs\info.log"

        Add-LogHandler -Logger $log -Handler $errorHandler
        Add-LogHandler -Logger $log -Handler $infoHandler

    .NOTES
        FileHandler inherits from LogHandler base class.
        The directory is created automatically if it doesn't exist.

    .LINK
        Add-LogHandler

    .LINK
        New-ConsoleHandler

    .LINK
        New-EventLogHandler
    #>
    [CmdletBinding()]
    [OutputType([FileHandler])]
    Param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [ValidateSet("Unicode", "UTF7", "UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", "OEM")]
        [string]$Encoding = "Unicode"
    )

    Return [FileHandler]::new($Path, $Encoding)
}

Function New-ConsoleHandler {
    <#
    .SYNOPSIS
        Creates a new ConsoleHandler for writing logs to the console.

    .DESCRIPTION
        New-ConsoleHandler creates a LogHandler that writes log entries to the PowerShell console
        with color-coded output based on log level. This handler can be added to a logger using
        Add-LogHandler to enable console output.

    .PARAMETER UseColor
        Enable color-coded console output based on log level.
        Default: $true

    .INPUTS
        None

    .OUTPUTS
        ConsoleHandler
        Returns a configured ConsoleHandler instance.

    .EXAMPLE
        # Create console handler and add to logger
        $log = New-Logger -LogName "Application"
        $consoleHandler = New-ConsoleHandler
        Add-LogHandler -Logger $log -Handler $consoleHandler

        Write-LogError "Appears in red in console" -Logger $log

    .EXAMPLE
        # Console handler without colors
        $log = New-Logger -LogName "Plain"
        $consoleHandler = New-ConsoleHandler -UseColor:$false
        Add-LogHandler -Logger $log -Handler $consoleHandler

    .NOTES
        ConsoleHandler inherits from LogHandler base class.
        Color mappings: ERROR/CRITICAL=Red, WARNING=Yellow, SUCCESS=Green, INFO=White, DEBUG=Gray

    .LINK
        Add-LogHandler

    .LINK
        New-FileHandler

    .LINK
        New-EventLogHandler
    #>
    [CmdletBinding()]
    [OutputType([ConsoleHandler])]
    Param(
        [Parameter()]
        [bool]$UseColor = $true
    )

    Return [ConsoleHandler]::new($UseColor)
}

Function New-EventLogHandler {
    <#
    .SYNOPSIS
        Creates a new EventLogHandler for writing logs to Windows Event Log.

    .DESCRIPTION
        New-EventLogHandler creates a LogHandler that writes log entries to the Windows Event Log.
        This handler enables integration with Windows logging infrastructure for centralized log
        management and monitoring.

    .PARAMETER LogName
        The Windows Event Log to write to (Application, System, Security, or custom log name).
        Default: "Application"

    .PARAMETER Source
        The event source name that identifies the application in the event log.
        The source must be registered with Windows before use.

    .INPUTS
        None

    .OUTPUTS
        EventLogHandler
        Returns a configured EventLogHandler instance.

    .EXAMPLE
        # Create event log handler
        $log = New-Logger -LogName "Application"
        $eventHandler = New-EventLogHandler -LogName "Application" -Source "MyApplication"
        Add-LogHandler -Logger $log -Handler $eventHandler

        Write-LogError "Error written to Windows Event Log" -Logger $log

    .EXAMPLE
        # Custom event log
        $log = New-Logger -LogName "CustomApp"
        $eventHandler = New-EventLogHandler -LogName "CustomAppLog" -Source "CustomApp"
        Add-LogHandler -Logger $log -Handler $eventHandler

    .NOTES
        EventLogHandler inherits from LogHandler base class.
        The event source must be registered before use: New-EventLog -LogName "Application" -Source "MyApp"
        Requires elevated permissions to create new event sources.

    .LINK
        Add-LogHandler

    .LINK
        New-FileHandler

    .LINK
        New-ConsoleHandler
    #>
    [CmdletBinding()]
    [OutputType([EventLogHandler])]
    Param(
        [Parameter()]
        [string]$LogName = "Application",

        [Parameter(Mandatory)]
        [string]$Source
    )

    Return [EventLogHandler]::new($LogName, $Source)
}

Function New-NullHandler {
    <#
    .SYNOPSIS
        Creates a new NullHandler that discards all log entries.

    .DESCRIPTION
        New-NullHandler creates a LogHandler that silently discards all log entries without writing
        them anywhere. This is useful for temporarily disabling logging without removing logger calls
        from code, or for testing scenarios where log output is not needed.

    .INPUTS
        None

    .OUTPUTS
        NullHandler
        Returns a configured NullHandler instance.

    .EXAMPLE
        # Disable logging temporarily
        $log = New-Logger -LogName "Test"
        $nullHandler = New-NullHandler
        Add-LogHandler -Logger $log -Handler $nullHandler

        Write-Log "This message is discarded" -Logger $log

    .EXAMPLE
        # Testing scenario
        function Test-Function {
            $log = New-Logger -LogName "Test"
            Add-LogHandler -Logger $log -Handler (New-NullHandler)

            # Function code with logging calls
            Write-Log "Test message (not written)" -Logger $log
        }

    .NOTES
        NullHandler inherits from LogHandler base class.
        Useful for testing and temporarily disabling logging.

    .LINK
        Add-LogHandler

    .LINK
        New-FileHandler

    .LINK
        New-ConsoleHandler
    #>
    [CmdletBinding()]
    [OutputType([NullHandler])]
    Param()

    Return [NullHandler]::new()
}

Function New-MachineEnricher {
    <#
    .SYNOPSIS
        Creates an enricher that adds machine/computer information to log entries.

    .DESCRIPTION
        New-MachineEnricher creates an IEnricher that automatically adds computer-related properties
        to every log entry, including machine name, OS version, domain membership, and IP address.

        Properties added:
        - MachineName: Computer name
        - OSVersion: Operating system version
        - Domain: Active Directory domain (if domain-joined)
        - IPAddress: Primary IP address

    .INPUTS
        None

    .OUTPUTS
        MachineEnricher
        Returns a configured MachineEnricher instance.

    .EXAMPLE
        # Add machine enricher to logger
        $log = New-Logger -LogName "Application"
        $machineEnricher = New-MachineEnricher
        Add-LogEnricher -Logger $log -Enricher $machineEnricher

        Write-Log "Log includes machine info" -Logger $log

    .EXAMPLE
        # Combine with other enrichers
        $log = New-Logger -LogName "FullContext"

        Add-LogEnricher -Logger $log -Enricher (New-MachineEnricher)
        Add-LogEnricher -Logger $log -Enricher (New-ProcessEnricher)
        Add-LogEnricher -Logger $log -Enricher (New-ThreadEnricher)

        Write-Log "Comprehensive context logging" -Logger $log

    .NOTES
        MachineEnricher implements IEnricher interface.
        Properties are cached per log entry for performance.

    .LINK
        Add-LogEnricher

    .LINK
        New-ProcessEnricher

    .LINK
        New-ThreadEnricher
    #>
    [CmdletBinding()]
    [OutputType([MachineEnricher])]
    Param()

    Return [MachineEnricher]::new()
}

Function New-ProcessEnricher {
    <#
    .SYNOPSIS
        Creates an enricher that adds process information to log entries.

    .DESCRIPTION
        New-ProcessEnricher creates an IEnricher that automatically adds process-related properties
        to every log entry, including process ID, name, start time, and memory usage.

        Properties added:
        - ProcessId: Current process ID (PID)
        - ProcessName: Process executable name
        - ProcessStartTime: Process start timestamp
        - ProcessMemory: Working set memory in MB

    .INPUTS
        None

    .OUTPUTS
        ProcessEnricher
        Returns a configured ProcessEnricher instance.

    .EXAMPLE
        # Add process enricher to logger
        $log = New-Logger -LogName "Application"
        $processEnricher = New-ProcessEnricher
        Add-LogEnricher -Logger $log -Enricher $processEnricher

        Write-Log "Log includes process info" -Logger $log

    .EXAMPLE
        # Useful for multi-process applications
        $log = New-Logger -LogName "MultiProcess"
        Add-LogEnricher -Logger $log -Enricher (New-ProcessEnricher)

        # Each process instance logs with its own PID
        Write-Log "Process-specific logging" -Logger $log

    .NOTES
        ProcessEnricher implements IEnricher interface.
        Useful for debugging multi-process applications.

    .LINK
        Add-LogEnricher

    .LINK
        New-MachineEnricher

    .LINK
        New-ThreadEnricher
    #>
    [CmdletBinding()]
    [OutputType([ProcessEnricher])]
    Param()

    Return [ProcessEnricher]::new()
}

Function New-ThreadEnricher {
    <#
    .SYNOPSIS
        Creates an enricher that adds thread information to log entries.

    .DESCRIPTION
        New-ThreadEnricher creates an IEnricher that automatically adds thread-related properties
        to every log entry, including thread ID and managed thread status. This is particularly
        useful for debugging multi-threaded applications and runspaces.

        Properties added:
        - ThreadId: Current managed thread ID
        - ThreadName: Thread name (if set)
        - IsThreadPoolThread: Whether thread is from thread pool

    .INPUTS
        None

    .OUTPUTS
        ThreadEnricher
        Returns a configured ThreadEnricher instance.

    .EXAMPLE
        # Add thread enricher to logger
        $log = New-Logger -LogName "MultiThreaded"
        $threadEnricher = New-ThreadEnricher
        Add-LogEnricher -Logger $log -Enricher $threadEnricher

        Write-Log "Log includes thread info" -Logger $log

    .EXAMPLE
        # Useful for runspace debugging
        $log = New-Logger -LogName "Runspaces"
        Add-LogEnricher -Logger $log -Enricher (New-ThreadEnricher)

        $runspaces = 1..5 | ForEach-Object {
            $rs = [runspacefactory]::CreateRunspace()
            $rs.Open()
            # Runspace code that logs with thread ID
            $rs
        }

    .NOTES
        ThreadEnricher implements IEnricher interface.
        Essential for debugging parallel and multi-threaded code.

    .LINK
        Add-LogEnricher

    .LINK
        New-ProcessEnricher

    .LINK
        New-MachineEnricher
    #>
    [CmdletBinding()]
    [OutputType([ThreadEnricher])]
    Param()

    Return [ThreadEnricher]::new()
}

Function New-EnvironmentEnricher {
    <#
    .SYNOPSIS
        Creates an enricher that adds environment variables to log entries.

    .DESCRIPTION
        New-EnvironmentEnricher creates an IEnricher that automatically adds specified environment
        variables to every log entry. This is useful for capturing deployment environment, user
        context, or custom variables set by deployment scripts.

    .PARAMETER Variables
        Array of environment variable names to include in log entries. Only specified variables
        are added to avoid cluttering logs with hundreds of environment variables.

    .INPUTS
        None

    .OUTPUTS
        EnvironmentEnricher
        Returns a configured EnvironmentEnricher instance.

    .EXAMPLE
        # Add specific environment variables to logs
        $log = New-Logger -LogName "Application"
        $envEnricher = New-EnvironmentEnricher -Variables @("COMPUTERNAME", "USERNAME", "DEPLOYMENT_ENV")
        Add-LogEnricher -Logger $log -Enricher $envEnricher

        Write-Log "Log includes environment context" -Logger $log

    .EXAMPLE
        # Capture deployment environment
        $log = New-Logger -LogName "Deployment"
        $envEnricher = New-EnvironmentEnricher -Variables @("CI", "BUILD_NUMBER", "GIT_BRANCH")
        Add-LogEnricher -Logger $log -Enricher $envEnricher

    .NOTES
        EnvironmentEnricher implements IEnricher interface.
        Only specified variables are included to avoid log bloat.

    .LINK
        Add-LogEnricher

    .LINK
        New-MachineEnricher

    .LINK
        New-ProcessEnricher
    #>
    [CmdletBinding()]
    [OutputType([EnvironmentEnricher])]
    Param(
        [Parameter(Mandatory)]
        [string[]]$Variables
    )

    Return [EnvironmentEnricher]::new($Variables)
}

Function New-NetworkEnricher {
    <#
    .SYNOPSIS
        Creates an enricher that adds network information to log entries.

    .DESCRIPTION
        New-NetworkEnricher creates an IEnricher that automatically adds network-related properties
        to every log entry, including IP addresses, network adapters, and connectivity status.

        Properties added:
        - PrimaryIP: Primary IPv4 address
        - NetworkAdapters: Active network adapter count
        - DefaultGateway: Default gateway address
        - DNSServers: Configured DNS servers

    .INPUTS
        None

    .OUTPUTS
        NetworkEnricher
        Returns a configured NetworkEnricher instance.

    .EXAMPLE
        # Add network enricher to logger
        $log = New-Logger -LogName "NetworkApp"
        $networkEnricher = New-NetworkEnricher
        Add-LogEnricher -Logger $log -Enricher $networkEnricher

        Write-Log "Log includes network info" -Logger $log

    .EXAMPLE
        # Useful for distributed applications
        $log = New-Logger -LogName "Distributed"
        Add-LogEnricher -Logger $log -Enricher (New-NetworkEnricher)
        Add-LogEnricher -Logger $log -Enricher (New-MachineEnricher)

        Write-Log "Full network and machine context" -Logger $log

    .NOTES
        NetworkEnricher implements IEnricher interface.
        Network information is captured at log time, not enricher creation time.

    .LINK
        Add-LogEnricher

    .LINK
        New-MachineEnricher

    .LINK
        New-ProcessEnricher
    #>
    [CmdletBinding()]
    [OutputType([NetworkEnricher])]
    Param()

    Return [NetworkEnricher]::new()
}

Function New-FunctionFilter {
    <#
    .SYNOPSIS
        Creates a filter that only logs messages from specified functions.

    .DESCRIPTION
        New-FunctionFilter creates an ILogFilter that restricts logging to messages originating
        from specific functions. This is useful for focusing logs on particular code paths or
        debugging specific functions without modifying code.

    .PARAMETER AllowedFunctions
        Array of function names that are allowed to log. Only messages from these functions
        will be written to the log. Function names are case-insensitive.

    .INPUTS
        None

    .OUTPUTS
        FunctionFilter
        Returns a configured FunctionFilter instance.

    .EXAMPLE
        # Only log from specific functions
        $log = New-Logger -LogName "Filtered"
        $funcFilter = New-FunctionFilter -AllowedFunctions @("Initialize-Application", "Process-Data")
        Add-LogFilter -Logger $log -Filter $funcFilter

        # Only logs from Initialize-Application and Process-Data will be written

    .EXAMPLE
        # Debug specific code path
        $log = New-Logger -LogName "Debug"
        $funcFilter = New-FunctionFilter -AllowedFunctions @("Troublesome-Function")
        Add-LogFilter -Logger $log -Filter $funcFilter

        # Focus logging on problematic function

    .NOTES
        FunctionFilter implements ILogFilter interface.
        Function names are matched case-insensitively.

    .LINK
        Add-LogFilter

    .LINK
        New-TimeFilter

    .LINK
        New-UserFilter
    #>
    [CmdletBinding()]
    [OutputType([FunctionFilter])]
    Param(
        [Parameter(Mandatory)]
        [string[]]$AllowedFunctions
    )

    Return [FunctionFilter]::new($AllowedFunctions)
}

Function New-TimeFilter {
    <#
    .SYNOPSIS
        Creates a filter that only logs messages during specified hours.

    .DESCRIPTION
        New-TimeFilter creates an ILogFilter that restricts logging to specific hours of the day.
        This is useful for reducing log volume during off-hours or focusing on business hours activity.

    .PARAMETER StartHour
        Starting hour (0-23) for logging window. Logs are only written during this time range.

    .PARAMETER EndHour
        Ending hour (0-23) for logging window. Logs are only written during this time range.

    .INPUTS
        None

    .OUTPUTS
        TimeFilter
        Returns a configured TimeFilter instance.

    .EXAMPLE
        # Only log during business hours
        $log = New-Logger -LogName "BusinessHours"
        $timeFilter = New-TimeFilter -StartHour 8 -EndHour 17
        Add-LogFilter -Logger $log -Filter $timeFilter

        # Logs only written between 8 AM and 5 PM

    .EXAMPLE
        # Log only during overnight batch processing
        $log = New-Logger -LogName "BatchProcessing"
        $timeFilter = New-TimeFilter -StartHour 22 -EndHour 6
        Add-LogFilter -Logger $log -Filter $timeFilter

        # Logs written from 10 PM to 6 AM

    .NOTES
        TimeFilter implements ILogFilter interface.
        Uses 24-hour clock (0-23).
        Can span midnight (e.g., StartHour=22, EndHour=6).

    .LINK
        Add-LogFilter

    .LINK
        New-FunctionFilter

    .LINK
        New-UserFilter
    #>
    [CmdletBinding()]
    [OutputType([TimeFilter])]
    Param(
        [Parameter(Mandatory)]
        [ValidateRange(0, 23)]
        [int]$StartHour,

        [Parameter(Mandatory)]
        [ValidateRange(0, 23)]
        [int]$EndHour
    )

    Return [TimeFilter]::new($StartHour, $EndHour)
}

Function New-UserFilter {
    <#
    .SYNOPSIS
        Creates a filter that only logs messages from specified users.

    .DESCRIPTION
        New-UserFilter creates an ILogFilter that restricts logging to messages from specific
        user accounts. This is useful for multi-user environments where you want to focus on
        specific user activity or exclude service accounts from logs.

    .PARAMETER AllowedUsers
        Array of usernames that are allowed to log. Only messages from these users will be
        written to the log. Usernames are case-insensitive.

    .INPUTS
        None

    .OUTPUTS
        UserFilter
        Returns a configured UserFilter instance.

    .EXAMPLE
        # Only log from specific users
        $log = New-Logger -LogName "UserSpecific"
        $userFilter = New-UserFilter -AllowedUsers @("admin", "operator")
        Add-LogFilter -Logger $log -Filter $userFilter

        # Only logs from admin and operator users

    .EXAMPLE
        # Exclude service account activity
        $log = New-Logger -LogName "InteractiveOnly"
        $userFilter = New-UserFilter -AllowedUsers @("user1", "user2", "user3")
        Add-LogFilter -Logger $log -Filter $userFilter

        # Service account logs excluded

    .NOTES
        UserFilter implements ILogFilter interface.
        Usernames are matched case-insensitively.

    .LINK
        Add-LogFilter

    .LINK
        New-FunctionFilter

    .LINK
        New-TimeFilter
    #>
    [CmdletBinding()]
    [OutputType([UserFilter])]
    Param(
        [Parameter(Mandatory)]
        [string[]]$AllowedUsers
    )

    Return [UserFilter]::new($AllowedUsers)
}

Function Start-LogScope {
    <#
    .SYNOPSIS
        Creates a disposable scope that adds temporary properties to log entries.

    .DESCRIPTION
        Start-LogScope creates a PropertyScope object that adds a key-value pair to all log entries
        within a code block. When the scope is disposed (via Using statement or explicit Dispose()),
        the property is automatically removed. This enables hierarchical context tracking without
        manually adding/removing properties.

        Best used with PowerShell's Using statement for automatic cleanup, or explicitly call
        Dispose() in a Finally block.

    .PARAMETER Logger
        The Logger instance to add the scoped property to. If not specified, uses the default logger.

    .PARAMETER Key
        The property key name to add to log entries within this scope.

    .PARAMETER Value
        The property value to add to log entries within this scope.

    .INPUTS
        Logger
        Accepts a Logger instance via the pipeline.

    .OUTPUTS
        PropertyScope
        Returns a PropertyScope instance that implements IDisposable.

    .EXAMPLE
        # Using PowerShell 5.0+ Using statement
        $log = New-Logger -LogName "Scoped"

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

    .EXAMPLE
        # Manual disposal in Try-Finally
        $log = New-Logger -LogName "Manual"
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

    .EXAMPLE
        # Nested scopes for hierarchical context
        $log = New-Logger -LogName "Hierarchical"

        Using (Start-LogScope -Logger $log -Key "JobId" -Value "JOB-001") {
            Write-Log "Job started" -Logger $log

            foreach ($task in $tasks) {
                Using (Start-LogScope -Logger $log -Key "TaskId" -Value $task.Id) {
                    Write-Log "Task processing" -Logger $log
                    # Includes JobId and TaskId
                }
            }

            Write-Log "Job complete" -Logger $log
        }

    .EXAMPLE
        # Web request context tracking
        $log = New-Logger -LogName "WebAPI"

        function Process-Request {
            param($requestId, $userId)

            Using (Start-LogScope -Key "RequestId" -Value $requestId) {
                Using (Start-LogScope -Key "UserId" -Value $userId) {
                    Write-Log "Request received"
                    # ... process request ...
                    Write-Log "Request complete"
                }
            }
        }

    .NOTES
        PropertyScope implements IDisposable for automatic cleanup.
        Requires PowerShell 5.0+ for Using statement support.
        Properties are automatically removed when scope exits.

    .LINK
        Initialize-Log

    .LINK
        Write-Log

    .LINK
        Add-LogEnricher
    #>
    [CmdletBinding()]
    [OutputType([PropertyScope])]
    Param(
        [Parameter(ValueFromPipeline)]
        [Logger]$Logger = $Script:DefaultLog,

        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [object]$Value
    )

    Process {
        If (-not $Logger) {
            Write-Error "No logger specified and no default logger is initialized."
            Return $null
        }

        Return [PropertyScope]::new($Logger, $Key, $Value)
    }
}

#endregion

# ================================
# ===    MODULE EXPORT         ===
# ================================
#region Module Export

# Export public functions
Export-ModuleMember -Function @(
    # Core logger initialization and management
    'Initialize-Log',
    'New-Logger',
    'Get-Logger',
    'Set-DefaultLogger',
    'Get-DefaultLogger',

    # Primary logging functions
    'Write-Log',
    'Write-LogInfo',
    'Write-LogWarning',
    'Write-LogError',
    'Write-LogCritical',
    'Write-LogDebug',
    'Write-LogSuccess',

    # Logger information and testing
    'Get-LoggerInfo',
    'Test-Logger',

    # Enricher management
    'Add-LogEnricher',
    'New-MachineEnricher',
    'New-ProcessEnricher',
    'New-ThreadEnricher',
    'New-EnvironmentEnricher',
    'New-NetworkEnricher',

    # Handler management
    'Add-LogHandler',
    'New-FileHandler',
    'New-ConsoleHandler',
    'New-EventLogHandler',
    'New-NullHandler',

    # Filter management
    'Add-LogFilter',
    'New-FunctionFilter',
    'New-TimeFilter',
    'New-UserFilter',

    # Scoped properties
    'Start-LogScope'
)

# Note: The Logger class is automatically available when the module is imported in PowerShell 5.0+
# Users can create instances directly: $logger = [Logger]::new()
# No explicit export needed for classes, but we're not exporting any variables
Export-ModuleMember -Variable @()

#endregion