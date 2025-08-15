#Requires -Version 5.0
<#
.SYNOPSIS
    Advanced PowerShell logging module with automatic rotation, compression, and flexible output options.

.DESCRIPTION
    PSLogger is a comprehensive logging solution for PowerShell scripts and modules that provides 
    enterprise-grade logging capabilities. It offers automatic log rotation based on size or age, 
    compression of archived logs, multiple output targets (file and console), customizable formatting, 
    and support for multiple concurrent logger instances.
    
    Key Features:
    - Multiple log levels (INFO, WARNING, ERROR, CRITICAL, DEBUG, SUCCESS) with color-coded console output
    - Automatic log rotation by file size (KB, MB, GB) or age (days)
    - Zip compression for archived logs to save disk space
    - Concurrent logger support for complex applications
    - Retry mechanism for handling file locks
    - Pipeline support for bulk logging operations
    - Customizable timestamp formats and encoding options
    
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

.NOTES
    Module Name: PSLogger
    Author: Mark Newton
    Created: 08/15/2025
    Version: 1.0.0
    PowerShell Version: 5.0+
    
    CHANGELOG:
    1.0.0 - Initial release
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
$ModuleVersion = '1.0.0'
$ModuleAuthor = 'Mark Newton'
$ModuleDescription = 'Advanced PowerShell logging module with rotation and archiving'

# ================================
# ===    LOGGING CLASS         ===
# ================================
#region Logger Class

Class Logger {
    <#
    .DESCRIPTION
    Class that handles logging operations with multiple options including file rotation, encoding options, and console output

    .EXAMPLE
    # Create a new logger with default settings
    $Logger = [Logger]::new("MyLog")
    $Logger.Write("Hello World!")

    # Create a logger with custom settings
    $Logger = [Logger]::new("ApplicationLog", "C:\Logs", "WARNING")
    $Logger.Write("This is a warning message")
    
    # Create a logger with log rotation settings
    $Logger = [Logger]::new()
    $Logger.LogName = "RotatingLog"
    $Logger.LogRotateOpt = "10M"
    $Logger.LogZip = $True
    $Logger.Write("This message will be in a log that rotates at 10MB")
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

    # Hidden properties
    hidden [string]$LogFile

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
        $This.LogPath = $env:TEMP
        $This.LogLevel = "INFO"
        $This.DateTimeFormat = 'yyyy-MM-dd HH:mm:ss'
        $This.NoLogInfo = $False
        $This.Encoding = 'Unicode'
        $This.LogRoll = $False
        $This.LogRetry = 2
        $This.WriteConsole = $False
        $This.ConsoleOnly = $False
        $This.ConsoleInfo = $False
        $This.LogRotateOpt = "1M"
        $This.LogZip = $True
        $This.LogCountMax = 5
        
        # Set the log file path
        $This.LogFile = "$($This.LogPath)\$($This.LogName).log"
    }

    # Update LogFile property when LogName or LogPath changes
    [void] UpdateLogFile() {
        $This.LogFile = "$($This.LogPath)\$($This.LogName).log"
    }

    # Main method to write to the log
    [void] Write([string]$LogMsg) {
        $This.Write($LogMsg, $This.LogLevel)
    }

    # Overload to specify log level
    [void] Write([string]$LogMsg, [string]$LogLevel) {
        # Update log file path if needed
        $This.UpdateLogFile()
        
        # If the Log directory doesn't exist, create it
        If (!(Test-Path -Path $This.LogPath)) {
            New-Item -ItemType "Directory" -Path $This.LogPath > $Null
        }

        # If the log file doesn't exist, create it
        If (!(Test-Path -Path $This.LogFile)) {
            Write-Output "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] Logging started" | 
                Out-File -FilePath $This.LogFile -Append -Encoding $This.Encoding
        # Else check if the log needs to be rotated. If rotated, create a new log file.
        } Else {
            If ($This.LogRoll -and ($This.ConfirmLogRotation() -eq $True)) {
                Write-Output "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] Log rotated... Logging started" | 
                    Out-File -FilePath $This.LogFile -Append -Encoding $This.Encoding
            }
        }

        # Write to the console
        If ($This.WriteConsole) {
            # Write timestamp and log level to the console
            If ($This.ConsoleInfo) {
                Switch ($LogLevel) {
                    'CRITICAL' { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor DarkRed }
                    'ERROR'    { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor Red }
                    'WARNING'  { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor Yellow }
                    'SUCCESS'  { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor Green }
                    'DEBUG'    { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor Cyan }
                    Default    { Write-Host "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" -ForegroundColor White }
                }
            # Write just the log message to the console
            } Else {
                Switch ($LogLevel) {
                    'CRITICAL' { Write-Host $LogMsg -ForegroundColor DarkRed }
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

        # Initialize variables for retrying if writing to log fails
        $Saved = $False
        $Retry = 0
        
        # Retry writing to the log until we have success or have hit the maximum number of retries
        Do {
            # Increment retry by 1
            $Retry++
            
            # Try to write to the log file
            Try {
                # Write to the log without log info (timestamp and log level)
                If ($This.NoLogInfo) {
                    Write-Output "$LogMsg" | Out-File -FilePath $This.LogFile -Append -Encoding $This.Encoding -ErrorAction Stop
                # Write to the log with log info (timestamp and log level)
                } Else {
                    Write-Output "[$([datetime]::Now.ToString($This.DateTimeFormat))][$LogLevel] $LogMsg" | 
                        Out-File -FilePath $This.LogFile -Append -Encoding $This.Encoding -ErrorAction Stop
                }
                
                # Set saved variable to true. We successfully wrote to the log file.
                $Saved = $True
            } Catch {
                If ($Saved -eq $False -and $Retry -eq $This.LogRetry) {
                    # Write the final error to the console. We were not able to write to the log file.
                    Write-Error "Logger couldn't write to the log File $($_.Exception.Message). Tried ($Retry/$($This.LogRetry)))"
                    Write-Error "Err Line: $($_.InvocationInfo.ScriptLineNumber) Err Name: $($_.Exception.GetType().FullName) Err Msg: $($_.Exception.Message)"
                } Else {
                    # Write warning to the console and try again until we hit the maximum configured number of retries
                    Write-Warning "Logger couldn't write to the log File $($_.Exception.Message). Retrying... ($Retry/$($This.LogRetry))"
                    # Sleep for half a second
                    Start-Sleep -Milliseconds 500
                }
            }
        } Until ($Saved -eq $True -or $Retry -ge $This.LogRetry)
    }

    # Convenience methods for different log levels
    [void] WriteInfo([string]$LogMsg) {
        $This.Write($LogMsg, "INFO")
    }

    [void] WriteWarning([string]$LogMsg) {
        $This.Write($LogMsg, "WARNING")
    }

    [void] WriteError([string]$LogMsg) {
        $This.Write($LogMsg, "ERROR")
    }

    [void] WriteCritical([string]$LogMsg) {
        $This.Write($LogMsg, "CRITICAL")
    }

    [void] WriteDebug([string]$LogMsg) {
        $This.Write($LogMsg, "DEBUG")
    }

    [void] WriteSuccess([string]$LogMsg) {
        $This.Write($LogMsg, "SUCCESS")
    }

    # Method to check if log rotation is needed
    [bool] ConfirmLogRotation() {
        <#
        .DESCRIPTION
        Determines if the log needs to be rotated per the parameters values. It supports rotating log files on disk and stored in a zip archive.
        
        .EXAMPLE
        $Logger = [Logger]::new("MyLog")
        $Logger.LogRotateOpt = "10M"
        $Logger.ConfirmLogRotation()
        #>
        
        # Initialize default return variable. If returned $True, will write a log rotate line to a new log file.
        $LogRolled = $False

        # Get the log name without the file extension
        $This.LogName = "$([System.IO.Path]::GetFileNameWithoutExtension($This.LogFile))"

        # Get the base path to the log file
        $This.LogPath = Split-Path -Path $This.LogFile

        # Initialize the zip archive path
        $ZipPath = "$($This.LogPath)\$($This.LogName)-archive.zip"

        # Initialize the TempLogPath variable to null.
        $TempLogPath = $Null

        # If the zip already exists, we set TempLogPath to a generated user temp folder path
        # This will be used to extract the zip archive before rotating logs
        If (Test-Path $ZipPath) {
            $TempLogPath = "$([System.IO.Path]::GetTempPath())$($This.LogName).archive"
        } 

        # Check If the LogRotateOpt matches the size pattern (e.g., 10M, 5G, 500K)
        If ($This.LogRotateOpt -match '(\d+)([GMK])') {
            $Unit = $matches[2]

            # Calculate the log size and compare it to the LogRotateOpt size
            If ($Unit -eq 'G') {
                # Calculate size with GB
                $RotateSize = [int]$matches[1] * 1GB 
            } ElseIf ($Unit -eq 'M') {
                # Calculate size with MB
                $RotateSize = [int]$matches[1] * 1MB 
            } ElseIf ($Unit -eq 'K') {
                # Calculate size with KB
                $RotateSize = [int]$matches[1] * 1KB 
            } Else {
                Write-Warning "Incorrect log rotation parameter provided. Using default of 1MB."
                $RotateSize = 1 * 1MB
            }

            $LogSize = ((Get-Item -Path $This.LogFile).Length)

            If ($LogSize -gt $RotateSize) {
                If ($This.LogZip) {
                    # Zip archive does not exist yet. Rotate existing logs and put them all inside of a zip archive
                    If (!(Test-Path $ZipPath)) {
                        # Get the list of current log files
                        $LogFiles = Get-ChildItem -Path $This.LogPath -File -Filter "*.log" | 
                            Where-Object { ($_.Name -like "$($This.LogName)*") } | 
                            Sort-Object BaseName
                            
                        # Roll the log files
                        $LogRolled = $This.StartLogRoll($This.LogName, $This.LogPath, $LogFiles)
                        
                        # Update the list of current log files after rotating
                        $LogFiles = Get-ChildItem -Path $This.LogPath -File -Filter "*.log" | 
                            Where-Object { ($_.Name -like "$($This.LogName)*") -and ($_.Name -match '\.\d+') } | 
                            Sort-Object BaseName
                            
                        # Iterate over each log file and compress it into the archive and then delete it off the disk
                        ForEach ($File in $LogFiles) {
                            Compress-Archive -Path "$($This.LogPath)\$($File.Name)" -DestinationPath $ZipPath -Update
                            Remove-Item -Path "$($This.LogPath)\$($File.Name)"
                        }
                        Return $True
                    # Zip archive already exists. Lets extract and rotate some logs
                    } Else {
                        # Ensure the temp folder exists
                        If (-Not (Test-Path -Path $TempLogPath)) {
                            New-Item -Path $TempLogPath -ItemType Directory | Out-Null
                        }

                        # Unzip the File to the temp folder
                        Expand-Archive -Path $ZipPath -DestinationPath $TempLogPath -Force

                        # Get the LogFiles from the temp folder
                        $LogFiles = Get-ChildItem -Path $TempLogPath -File -Filter "*.log" | 
                            Where-Object { ($_.Name -like "$($This.LogName)*") -and ($_.Name -match '\.\d+') } | 
                            Sort-Object BaseName
                        
                        # Roll the log files
                        $LogRolled = $This.StartLogRoll($This.LogName, $This.LogPath, $LogFiles)

                        # Compress and overwrite the old log files inside the existing archive
                        Compress-Archive -Path "$TempLogPath\*" -DestinationPath $ZipPath -Update

                        # Remove the Files we extracted, we no longer need them
                        If (Test-Path $TempLogPath) {
                            Remove-Item -Path $TempLogPath -Recurse -Force
                        }

                        # Return True or False
                        Return $LogRolled
                    }
                # Logs are not zipped, just roll em over
                } Else {
                    $LogFiles = Get-ChildItem -Path $This.LogPath -File -Filter "*.log" | 
                        Where-Object { ($_.Name -like "$($This.LogName)*") } | 
                        Sort-Object BaseName
                    $LogRolled = $This.StartLogRoll($This.LogName, $This.LogPath, $LogFiles)
                    Return $LogRolled
                }
            }
        # Check if LogRotateOpt matches the days pattern (e.g., 7, 30, 365)
        } ElseIf ($This.LogRotateOpt -match '^\d+$') {
            # Convert the string digit into an integer
            $RotateDays = [int]$This.LogRotateOpt

            # Get the file's last write time
            $CreationTime = (Get-Item $This.LogFile).CreationTime

            # Calculate the age of the file in days
            $Age = ((Get-Date) - $CreationTime).Days

            # If the age of the file is older than the configured number of days to rotate the log
            If ($Age -gt $RotateDays) {
                If ($This.LogZip) {
                    # Zip archive does not exist yet. Rotate existing logs and put them all inside of a zip archive
                    If (!(Test-Path $ZipPath)) {
                        # Get the list of current log files
                        $LogFiles = Get-ChildItem -Path $This.LogPath -File -Filter "*.log" | 
                            Where-Object { ($_.Name -like "$($This.LogName)*") } | 
                            Sort-Object BaseName
                            
                        # Roll the log files
                        $LogRolled = $This.StartLogRoll($This.LogName, $This.LogPath, $LogFiles)
                        
                        # Update the list of current log files after rotating
                        $LogFiles = Get-ChildItem -Path $This.LogPath -File -Filter "*.log" | 
                            Where-Object { ($_.Name -like "$($This.LogName)*") -and ($_.Name -match '\.\d+') } | 
                            Sort-Object BaseName
                            
                        # Iterate over each log file and compress it into the archive and then delete it off the disk
                        ForEach ($File in $LogFiles) {
                            Compress-Archive -Path "$($This.LogPath)\$($File.Name)" -DestinationPath $ZipPath -Update
                            Remove-Item -Path "$($This.LogPath)\$($File.Name)"
                        }
                        Return $True
                    # Zip archive already exists. Lets extract and rotate some logs
                    } Else {
                        # Ensure the temp folder exists
                        If (-Not (Test-Path -Path $TempLogPath)) {
                            New-Item -Path $TempLogPath -ItemType Directory | Out-Null
                        }

                        # Unzip the File to the temp folder
                        Expand-Archive -Path $ZipPath -DestinationPath $TempLogPath -Force

                        # Get the LogFiles from the temp folder
                        $LogFiles = Get-ChildItem -Path $TempLogPath -File -Filter "*.log" | 
                            Where-Object { ($_.Name -like "$($This.LogName)*") } | 
                            Sort-Object BaseName
                        
                        # Roll the log files
                        $LogRolled = $This.StartLogRoll($This.LogName, $This.LogPath, $LogFiles)

                        # Compress and overwrite the old log files inside the existing archive
                        Compress-Archive -Path "$TempLogPath\*" -DestinationPath $ZipPath -Update -Force

                        # Remove the Files we extracted, we no longer need them
                        If (Test-Path $TempLogPath) {
                            Remove-Item -Path $TempLogPath -Recurse -Force
                        }

                        # Return True or False
                        Return $LogRolled
                    }
                # No zip archiving. Just roll us some logs on the disk.
                } Else {
                    $LogFiles = Get-ChildItem -Path $This.LogPath -File -Filter "*.log" | 
                        Where-Object { ($_.Name -like "$($This.LogName)*") } | 
                        Sort-Object BaseName
                    $LogRolled = $This.StartLogRoll($This.LogName, $This.LogPath, $LogFiles)
                    Return $LogRolled
                }
            }
        } Else {
            Write-Error "Incorrect log rotation parameter provided. Logs will not be rotated!"
        }
        
        # Return false by default if no rotation was triggered
        Return $False
    }

    # Method to perform log rotation
    [bool] StartLogRoll([string]$LogName, [string]$LogPath, [object]$LogFiles) {
        <#
        .DESCRIPTION
        Rolls the logs incrementing the number by 1 and deleting any older logs over the allowed maximum count of log files
        
        .EXAMPLE
        $Logger = [Logger]::new("MyLog")
        $LogFiles = Get-ChildItem -Path $Logger.LogPath -File -Filter "*.log" | Where-Object { ($_.Name -like "$($Logger.LogName)*") -and ($_.Name -match '\.\d+') }
        $Logger.StartLogRoll($Logger.LogName, $Logger.LogPath, $LogFiles)
        #>

        # Get the working log path from the $LogFiles object that was passed to the function. 
        # This may be a temp folder for zip archived logs.
        $WorkingLogPath = $LogFiles[0].Directory

        $LogFiles = Get-ChildItem -Path $WorkingLogPath -File -Filter "*.log" | 
                        Where-Object { ($_.Name -like "$($This.LogName)*") -and ($_.Name -match '\.\d+') } | 
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
                    Remove-Item "$WorkingLogPath\$($OperatingFile.Name)" -Force -ErrorAction Stop
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

#endregion

# ================================
# ===    PUBLIC FUNCTIONS      ===
# ================================
#region Public Functions

Function Initialize-Log {
    <#
    .SYNOPSIS
        Initializes a logger instance for use with the Write-Log function.

    .DESCRIPTION
        Initialize-Log creates and configures a Logger class instance with specified settings for 
        file output, console display, rotation policies, and formatting options. The logger can be 
        set as the default for the session or returned for explicit use with Write-Log.
        
        This function provides extensive customization options including:
        - Automatic log file rotation based on size or age
        - Compression of rotated logs into zip archives
        - Simultaneous console and file output
        - Customizable timestamp formats
        - Multiple text encoding options
        - Retry logic for file access conflicts
        
        The function creates the log directory if it doesn't exist and validates all parameters
        before creating the logger instance.

    .PARAMETER Default
        Sets this logger as the default logger for the session. When set, Write-Log can be called 
        without specifying a logger parameter. Only one default logger can exist at a time.

    .PARAMETER LogName
        Name of the log file that will be written to. The .log extension is automatically appended.
        Avoid special characters that are invalid in filenames.
        Default: "Debug"

    .PARAMETER LogPath
        Full path to the directory where log files will be stored. Directory is created if it doesn't exist.
        Ensure the account running the script has write permissions to this location.
        Default: User's temp directory ($env:TEMP)

    .PARAMETER LogLevel
        The default log level to be used if a log level is not specified in Write-Log.
        This sets the default severity but doesn't filter messages.
        Valid values: INFO, WARNING, ERROR, CRITICAL, DEBUG, SUCCESS
        Default: "INFO"

    .PARAMETER DateTimeFormat
        .NET format string for timestamps in log entries. Common formats:
        - "yyyy-MM-dd HH:mm:ss" - Standard format (default)
        - "yyyy-MM-dd HH:mm:ss.fff" - Include milliseconds
        - "MM/dd/yyyy hh:mm:ss tt" - US format with AM/PM
        - "dd/MM/yyyy HH:mm:ss" - European format
        Default: "yyyy-MM-dd HH:mm:ss"

    .PARAMETER NoLogInfo
        When specified, disables the timestamp and log level prefix in log entries.
        Useful for creating clean output files or when logging pre-formatted data.
        Default: False

    .PARAMETER Encoding
        Text encoding for the log file. Important for international characters.
        Valid values: unknown, string, unicode, bigendianunicode, utf8, utf7, utf32, ascii, default, oem
        Default: "Unicode"

    .PARAMETER LogRoll
        Enables automatic log rotation based on the criteria specified in LogRotateOpt.
        When enabled, logs are automatically rotated when size or age limits are reached.
        Default: False

    .PARAMETER LogRetry
        Number of times to retry writing to the log file if it's locked or inaccessible.
        Each retry waits 500ms before attempting again. Useful in multi-process scenarios.
        Range: 1-10
        Default: 2

    .PARAMETER WriteConsole
        Outputs log messages to the console in addition to the log file.
        Messages are color-coded by level (ERROR=Red, WARNING=Yellow, SUCCESS=Green, DEBUG=Cyan).
        Default: False

    .PARAMETER ConsoleOnly
        When used with WriteConsole, outputs only to console without creating a log file.
        Useful for interactive scripts or when file logging isn't needed.
        Default: False

    .PARAMETER ConsoleInfo
        When used with WriteConsole, includes timestamp and log level in console output.
        Without this switch, only the message text is displayed in the console.
        Default: False

    .PARAMETER LogRotateOpt
        Specifies when logs should be rotated. Two formats supported:
        - Size-based: Number followed by unit (K=Kilobytes, M=Megabytes, G=Gigabytes)
          Examples: "100K", "50M", "1G"
        - Time-based: Number of days as integer
          Examples: "1" (daily), "7" (weekly), "30" (monthly)
        Default: "1M"

    .PARAMETER LogZip
        When log rotation is enabled, archives rotated logs into a zip file.
        Zip file is named <LogName>-archive.zip and stored in the same directory.
        Significantly reduces disk space usage for archived logs.
        Default: True

    .PARAMETER LogCountMax
        Maximum number of rotated log files to retain (either in zip or on disk).
        Older logs beyond this count are permanently deleted during rotation.
        Range: 1-100
        Default: 5

    .OUTPUTS
        [Logger]
        Returns an initialized Logger class instance unless -Default is specified.

    .EXAMPLE
        # Initialize a default logger with basic settings
        Initialize-Log -Default
        Write-Log "This message will go to C:\Temp\Debug.log"
    
    .EXAMPLE
        # Initialize a named logger with custom path
        $AppLog = Initialize-Log -LogName "MyApplication" -LogPath "D:\Logs"
        Write-Log "Application started" -Logger $AppLog
    
    .EXAMPLE
        # Initialize with console output and timestamps
        Initialize-Log -Default -LogName "Verbose" -WriteConsole -ConsoleInfo
        Write-Log "This appears in both console and file with timestamps"
    
    .EXAMPLE
        # Initialize with size-based rotation and compression
        $ProdLog = Initialize-Log -LogName "Production" `
                                  -LogPath "E:\Logs" `
                                  -LogRoll `
                                  -LogRotateOpt "100M" `
                                  -LogZip `
                                  -LogCountMax 20
        
        # Logs rotate at 100MB, compressed to Production-archive.zip, keeping 20 versions
        Write-Log "Production message" -Logger $ProdLog
    
    .EXAMPLE
        # Initialize with daily rotation
        $DailyLog = Initialize-Log -LogName "DailyReport" `
                                   -LogRoll `
                                   -LogRotateOpt "1"
        
        # Log rotates every day
        Write-Log "Daily entry" -Logger $DailyLog
    
    .EXAMPLE
        # Console-only mode for interactive feedback
        $Console = Initialize-Log -LogName "Progress" `
                                  -WriteConsole `
                                  -ConsoleOnly
        
        # No file created, only console output
        Write-Log "Processing..." -Logger $Console
    
    .EXAMPLE
        # Custom timestamp format and UTF8 encoding
        $IntlLog = Initialize-Log -LogName "International" `
                                  -DateTimeFormat "dd.MM.yyyy HH:mm:ss" `
                                  -Encoding "utf8"
        
        Write-Log "Ü, ö, ä, ß characters supported" -Logger $IntlLog
    
    .EXAMPLE
        # Production configuration with splatting
        $LogConfig = @{
            LogName = "WebService"
            LogPath = "D:\IIS\Logs"
            LogLevel = "INFO"
            DateTimeFormat = "yyyy-MM-dd HH:mm:ss.fff"
            Encoding = "utf8"
            LogRoll = $true
            LogRotateOpt = "500M"
            LogZip = $true
            LogCountMax = 30
            LogRetry = 5
        }
        
        $WebLog = Initialize-Log @LogConfig
        Write-Log "Web service initialized" -Logger $WebLog
    
    .NOTES
        - The function creates log directories automatically if they don't exist
        - Only one default logger can exist at a time in a session
        - Logger objects can be stored in variables for use throughout scripts
        - Consider performance impact when using console output for high-volume logging
        - Zip compression requires Windows PowerShell 5.0+ or PowerShell Core
    
    .LINK
        Write-Log
    
    .LINK
        Write-LogInfo
    
    .LINK
        Get-LoggerInfo
    
    .LINK
        Test-Logger
    #>

    [CmdletBinding()]
    [OutputType([Logger])]
    Param(
        [Parameter()]
        [alias ('D')]
        [switch] $Default,

        [Parameter()]
        [alias ('LN')]
        [string] $LogName = "Debug",

        [Parameter()]
        [alias ('LP')]
        [string] $LogPath = $env:TEMP,

        [Parameter()]
        [alias ('LL', 'LogLvl')]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'CRITICAL', 'DEBUG', 'SUCCESS')]
        [string] $LogLevel = "INFO",

        [Parameter()]
        [Alias('TF', 'DF', 'DateFormat', 'TimeFormat')]
        [string] $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',

        [Parameter()]
        [alias ('NLI')]
        [switch] $NoLogInfo,

        [Parameter()]
        [ValidateSet('unknown', 'string', 'unicode', 'bigendianunicode', 'utf8', 'utf7', 'utf32', 'ascii', 'default', 'oem')]
        [string]$Encoding = 'Unicode',

        [Parameter()]
        [alias ('Retry')]
        [ValidateRange(1, 10)]
        [int] $LogRetry = 2,

        [Parameter()]
        [alias('WC', 'Console')]
        [switch] $WriteConsole,

        [Parameter()]
        [alias('CO')]
        [switch] $ConsoleOnly,

        [Parameter()]
        [alias('CI')]
        [switch] $ConsoleInfo,

        [Parameter()]
        [alias ('LR', 'Roll')]
        [switch] $LogRoll,

        [Parameter()]
        [alias ('RotateOpt')]
        [string] $LogRotateOpt = "1M",

        [Parameter()]
        [alias('Zip')]
        [switch] $LogZip,

        [Parameter()]
        [alias('LF', 'LogFiles')]
        [ValidateRange(1, 100)]
        [int]$LogCountMax = 5
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

    If ($Default) {
        $Script:DefaultLog = $Logger
        Write-Verbose "Default logger initialized: $($Logger.LogName) at $($Logger.LogPath)"
        Return
    }

    Return $Logger
}

Function Write-Log {
    <#
    .SYNOPSIS
        Writes a message to a log file with specified severity level and optional console output.

    .DESCRIPTION
        Write-Log is the primary function for writing messages to log files created by Initialize-Log.
        It supports multiple severity levels, pipeline input, and can write to both file and console
        simultaneously based on logger configuration.
        
        The function handles:
        - Automatic timestamp formatting based on logger settings
        - Color-coded console output for different severity levels
        - Retry logic for file access conflicts
        - Log rotation triggers when size/age limits are reached
        - Pipeline processing for bulk message logging
        
        Messages are formatted as: [timestamp][level] message
        Unless NoLogInfo is set on the logger, in which case only the message is written.

    .PARAMETER LogMsg
        The message text to be written to the log. Supports string input from pipeline.
        Can include variables and expressions that will be evaluated.
        Maximum recommended length is 8KB per message for optimal performance.
        Aliases: LM, Msg, Message

    .PARAMETER LogLevel
        Severity level of the log message. Determines color coding in console output.
        Valid values:
        - INFO: General informational messages (White in console)
        - WARNING: Warning conditions that may need attention (Yellow in console)
        - ERROR: Error conditions requiring intervention (Red in console)
        - CRITICAL: System-critical failures requiring immediate action (Dark Red in console)
        - DEBUG: Detailed diagnostic information (Cyan in console)
        - SUCCESS: Successful operation confirmations (Green in console)
        Default: "INFO"
        Aliases: LL, LogLvl, Level

    .PARAMETER Logger
        Logger instance created by Initialize-Log. If not specified, uses the default logger
        set by Initialize-Log -Default. If no default exists and Logger is not provided,
        the function will throw an error.
        Aliases: L, Log

    .INPUTS
        System.String
        Accepts string messages from the pipeline for bulk logging operations.

    .OUTPUTS
        None
        This function does not return any output.

    .EXAMPLE
        # Basic logging with default logger
        Initialize-Log -Default
        Write-Log "Application started"
        Write-Log "Processing completed"
        
        # Output in log file:
        # [2025-08-15 10:30:00][INFO] Application started
        # [2025-08-15 10:30:01][INFO] Processing completed

    .EXAMPLE
        # Using different severity levels
        Initialize-Log -Default -WriteConsole
        
        Write-Log "Normal operation" -LogLevel "INFO"
        Write-Log "Low disk space" -LogLevel "WARNING"
        Write-Log "Database connection failed" -LogLevel "ERROR"
        Write-Log "Variable X = 42" -LogLevel "DEBUG"
        Write-Log "Upload completed" -LogLevel "SUCCESS"
        
        # Each message appears in different colors in console

    .EXAMPLE
        # Using specific logger instances
        $AppLog = Initialize-Log -LogName "Application"
        $ErrorLog = Initialize-Log -LogName "Errors" -LogLevel "ERROR"
        
        Write-Log "App started" -Logger $AppLog
        Write-Log "Critical failure" -Logger $ErrorLog -LogLevel "ERROR"

    .EXAMPLE
        # Pipeline input for bulk logging
        Initialize-Log -Default
        
        # Log multiple messages
        @("Step 1", "Step 2", "Step 3") | Write-Log
        
        # Log with specific level
        Get-Service | Where-Object Status -eq "Stopped" | ForEach-Object {
            "Service $($_.Name) is stopped"
        } | Write-Log -LogLevel "WARNING"

    .EXAMPLE
        # Logging with variable expansion
        $userName = $env:USERNAME
        $computerName = $env:COMPUTERNAME
        $processCount = (Get-Process).Count
        
        Write-Log "User $userName logged into $computerName"
        Write-Log "System is running $processCount processes" -LogLevel "INFO"

    .EXAMPLE
        # Error handling with detailed logging
        Initialize-Log -Default -LogName "ErrorHandler"
        
        Try {
            Write-Log "Attempting file operation..." -LogLevel "INFO"
            $content = Get-Content "C:\NonExistent.txt" -ErrorAction Stop
        }
        Catch {
            Write-Log "Failed to read file: $_" -LogLevel "ERROR"
            Write-Log "Error type: $($_.Exception.GetType().Name)" -LogLevel "DEBUG"
            Write-Log "Script line: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel "DEBUG"
        }

    .EXAMPLE
        # Performance logging with timestamps
        $logger = Initialize-Log -LogName "Performance" -DateTimeFormat "yyyy-MM-dd HH:mm:ss.fff"
        
        Write-Log "Operation started" -Logger $logger
        # Perform operation
        Start-Sleep -Milliseconds 500
        Write-Log "Operation completed" -Logger $logger
        
        # Timestamps include milliseconds for precise timing

    .EXAMPLE
        # Structured logging for parsing
        Initialize-Log -Default -NoLogInfo
        
        $logData = @{
            Timestamp = Get-Date -Format "o"
            User = $env:USERNAME
            Action = "FileUpload"
            Result = "Success"
            Duration = 1.543
        }
        
        Write-Log ($logData | ConvertTo-Json -Compress)
        
        # Creates clean JSON entries without log prefixes

    .NOTES
        - If no logger is available, the function will throw an error
        - Large messages (>8KB) may impact performance
        - Console output may slow down high-volume logging
        - File locks from other processes will trigger retry mechanism
        - Log rotation happens automatically based on logger configuration

    .LINK
        Initialize-Log

    .LINK
        Write-LogInfo

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
        [alias ('LM', 'Msg', 'Message')]
        [String] $LogMsg,

        [Parameter()]
        [alias ('LL', 'LogLvl', 'Level')]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'CRITICAL', 'DEBUG', 'SUCCESS')]
        [string] $LogLevel = "INFO",

        [Parameter()]
        [alias ('L', 'Log')] 
        $Logger = $Script:DefaultLog
    )

    Process {
        If (-not $Logger) {
            Write-Error "No log class has been initialized. Initialize a default log class or provide an initialized log class."
            Return
        } 
        
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

#endregion

# ================================
# ===    MODULE EXPORT         ===
# ================================
#region Module Export

# Export public functions
Export-ModuleMember -Function @(
    'Initialize-Log',
    'Write-Log',
    'Write-LogInfo',
    'Write-LogWarning',
    'Write-LogError',
    'Write-LogCritical',
    'Write-LogDebug',
    'Write-LogSuccess',
    'Get-LoggerInfo',
    'Test-Logger'
)

# Note: The Logger class is automatically available when the module is imported in PowerShell 5.0+
# Users can create instances directly: $logger = [Logger]::new()
# No explicit export needed for classes, but we're not exporting any variables
Export-ModuleMember -Variable @()

#endregion
