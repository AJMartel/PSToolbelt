﻿function Add-ToLog {
    [cmdletBinding(DefaultParameterSetName = "Message")]
    Param
    (
        [parameter(Mandatory = $true,ParameterSetName = "Message",Position = 0,ValueFromPipeline = $true)]
        [String]
        $Message,
        [parameter(Mandatory = $false,ParameterSetName = "Message",Position = 1)]
        [object]
        $Object,
        [parameter(Mandatory = $false,ParameterSetName = "Message")]
        [parameter(ParameterSetName = "ShowLog")]
        [ValidateSet("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
        [String]
        $ForegroundColor,
        [parameter(Mandatory = $false,ParameterSetName = "Message")]
        [parameter(ParameterSetName = "ShowLog")]
        [ValidateSet("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
        [String]
        $BackgroundColor,
        [parameter(Mandatory = $false,ParameterSetName = "Message")]
        [ValidateSet("INFO","WARNING","ERROR","VERBOSE","DEBUG")]
        [String]
        $MessageType = "INFO",
        [parameter(Mandatory = $false,ParameterSetName = "Message")]
        [switch]
        $WriteToEventLog,
        [parameter(Mandatory = $false,ParameterSetName = "LogOut")]
        [ValidateScript( {if ($_ -like "*.txt" -or $_ -like "*.log") {
                    $true
                }
                else {
                    throw "Incorrect file type! Only txt or log files can be used here"
                }})]
        [String]
        $SaveLogToPath,
        [parameter(Mandatory = $false,ParameterSetName = "LogOut")]
        [ValidateScript( {if ($_ -like "*.csv") {
                    $true
                }
                else {
                    throw "Incorrect file type! Only CSV files can be used here"
                }})]
        [String]
        $SaveCSVToPath,
        [parameter(Mandatory = $false,ParameterSetName = "RefreshCache")]
        [switch]
        $RefreshLogCache,
        [parameter(Mandatory = $false,ParameterSetName = "Message")]
        [switch]
        $ExcludeDateTime,
        [parameter(Mandatory = $false,ParameterSetName = "Message")]
        [switch]
        $FullDateTime,
        [parameter(Mandatory = $false,ParameterSetName = "Message")]
        [switch]
        $IncludeMessageType,
        [parameter(Mandatory = $false,ParameterSetName = "Message")]
        [switch]
        $Quiet,
        [parameter(Mandatory = $false,ParameterSetName = "LogOut")]
        [switch]
        $Force,
        [parameter(Mandatory = $false,ParameterSetName = "ShowLog")]
        [switch]
        $ShowLog
    )
    if (!$script:_AddToLogContent) {
        $script:_AddToLogContent = @()
    }
    if (!$Script:_LogArray -and !$Script:_ObjectArray) {
        $Script:_LogArray = @()
        $Script:_ObjectArray = @()
    }
    if ($ShowLog) {
        $console = $Host.UI.RawUI
        $fore = $console.ForegroundColor
        $back = $console.BackgroundColor
        if ($PSBoundParameters.Keys -notcontains "ForegroundColor") {
            $PSBoundParameters["ForegroundColor"] = "Black"
        }
        if ($PSBoundParameters.Keys -notcontains "BackgroundColor") {
            $PSBoundParameters["BackgroundColor"] = "Cyan"
        }
        $console.ForegroundColor = $PSBoundParameters["ForegroundColor"]
        $console.BackgroundColor = $PSBoundParameters["BackgroundColor"]
        <# $colors = @{
            ForegroundColor = $PSBoundParameters["ForegroundColor"]
            BackgroundColor = $PSBoundParameters["BackgroundColor"]
        } #>
        Write-Host "__________ LOG CONTENTS __________`n$($script:_AddToLogContent -join "`n")" #@colors
        $console.ForegroundColor = $fore
        $console.BackgroundColor = $back
        return
    }
    if (!$Script:EventLogConfirmed -and $WriteToEventLog) {
        if (!(Get-EventLog -List | ? {$_.LogDisplayName -eq "Automation"})) {
            Write-Warning "Creating 'Automation' EventLog with source set as 'PSScript'"
            try {
                New-EventLog -LogName Automation -Source PSScript -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning $("Event log creation failed, skipping event logging for this run!`n" + 
                    "`t`t Please run the following command from an administrator Powershell console to create the event log manually:")
                Write-Host -ForegroundColor Cyan "`t`t`t"'New-EventLog -LogName Automation -Source PSScript'
                $WriteToEventLog = $false
            }
        }
        else {
            $Script:EventLogConfirmed = $true
        }
    }
    if ($SaveLogToPath) {
        try {
            if (!(Test-Path $SaveLogToPath)) {
                New-Item $SaveLogToPath -Type File | Out-Null
            }
            if ($Force) {
                "LOG STARTED: $(Get-Date -Format G)" | Out-File $SaveLogToPath -Encoding ascii -Force
            }
            else {
                "LOG STARTED: $(Get-Date -Format G)" | Out-File $SaveLogToPath -Encoding ascii -Append -Force
            }
            $Script:_LogArray | Out-File $SaveLogToPath -Encoding ascii -Append -Force
            "" | Out-File $SaveLogToPath -Encoding ascii -Append -Force
            $Script:_LogArray = $null
        }
        catch {
            Write-Error $Error[0]
        }
        return
    }
    if ($SaveCSVToPath) {
        try {
            $Script:_ObjectArray | Export-CSV -Path $SaveCSVToPath -NoTypeInformation -Force
            $Script:_ObjectArray = $null
        }
        catch {
            Write-Error $Error[0]
        }
        return
    }
    if ($RefreshLogCache) {
        $Script:_LogArray = $null
        $Script:_ObjectArray = $null
        $script:_AddToLogContent = $null
        return
    }
    if ($Message) {
        $script:_AddToLogContent += "$(Get-Date -Format "HH:mm:ss"): $Message"
    }
    if ($IncludeMessageType) {
        $Message = "$($MessageType)`t$($Message)"
    }
    if ($FullDateTime) {
        $Message = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")`t$($Message)"
    }
    elseif (!$ExcludeDateTime) {
        $Message = "$(Get-Date -Format "HH:mm:ss"): $Message"
    }
    $Script:_LogArray += $Message
    if ($InputObject) {
        $Script:_ObjectArray += $InputObject
    }
    if ($MessageType -eq "INFO") {
        $HostParams = @{}
        if ($ForegroundColor) {
            $HostParams.Add("ForegroundColor",$ForegroundColor)
        }
        if ($BackgroundColor) {
            $HostParams.Add("BackgroundColor",$BackgroundColor)
        }
        if (!$Quiet) {
            Write-Host $Message @HostParams
        }
        if ($WriteToEventLog) {
            Write-EventLog -LogName Automation -Source PSScript -EntryType Information -Message $Message -EventId 1000
        }
    }
    elseif ($MessageType -eq "WARNING") {
        Write-Warning $Message
        if ($WriteToEventLog) {
            Write-EventLog -LogName Automation -Source PSScript -EntryType Warning -Message $Message -EventId 1001
        }
    }
    elseif ($MessageType -eq "ERROR") {
        $ErrBack = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        Write-Error $Message
        Write-Host -ForegroundColor Red $Message
        $ErrorActionPreference = $ErrBack
        if ($WriteToEventLog) {
            Write-EventLog -LogName Automation -Source PSScript -EntryType Error -Message $Message -EventId 1002
        }
    }
    elseif ($MessageType -eq "VERBOSE") {
        $VerBack = $VerbosePreference
        $VerbosePreference = "Continue"
        Write-Verbose $Message
        $VerbosePreference = $VerBack
        if ($WriteToEventLog) {
            Write-EventLog -LogName Automation -Source PSScript -EntryType Information -Message $Message -EventId 1003
        }
    }
    elseif ($MessageType -eq "DEBUG") {
        $BugBack = $DebugPreference
        $DebugPreference = "Continue"
        Write-Debug $Message
        $DebugPreference = $BugBack
        if ($WriteToEventLog) {
            Write-EventLog -LogName Automation -Source PSScript -EntryType Information -Message $Message -EventId 1004
        }
    }
}