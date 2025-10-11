# ==========================================
# System Health Monitoring Script 
# Reads SMTP from config.json; optional -Recipient param
# Author: Moustafa Obari
# ==========================================

param([string]$Recipient)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# ---------- App Root ----------
function Get-AppRoot {
    if ($PSScriptRoot) { return $PSScriptRoot }
    if ($PSCommandPath) { return Split-Path -Parent $PSCommandPath }
    return (Get-Location).Path
}
$AppRoot = Get-AppRoot

# ---------- Paths ----------
$timestamp      = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logsPath       = Join-Path $AppRoot "logs"
if (-not (Test-Path $logsPath)) { New-Item -ItemType Directory -Path $logsPath | Out-Null }

$htmlFile       = Join-Path $logsPath "HealthReport_$timestamp.html"
$userReportFile = Join-Path $logsPath "UserReport_$timestamp.html"

# ---------- Config ----------
$configPath = Join-Path $AppRoot "config.json"
if (-not (Test-Path $configPath)) { throw "ERROR: config.json not found at $configPath" }
$config     = Get-Content $configPath | ConvertFrom-Json

$smtpServer = $config.smtpServer
$smtpPort   = [int]$config.smtpPort
$smtpUser   = $config.smtpUser
$smtpPass   = $config.smtpPass
$from       = $config.from
$to         = if ($Recipient) { $Recipient } else { Read-Host "Enter recipient email address" }
$subject    = "System Health Report - $timestamp"
$body       = "Attached are the technical and user-friendly system health reports."

# ---------- HTML Style ----------
$style = @"
<style>
body { font-family: Segoe UI, Arial, sans-serif; background:#f9f9f9; color:#333; padding:20px; }
h1 { color:#2d3e50; }
h2 { color:#4a5a6a; margin-top:30px; }
h3 { color:#4a5a6a; }
table { border-collapse: collapse; width: 90%; margin-bottom: 20px; }
th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
th { background-color: #e9ecef; }
ul { margin-bottom: 20px; }
span { font-weight: bold; }
</style>
"@

$tech = New-Object System.Text.StringBuilder
[void]$tech.Append("<html><head><title>System Health Report - $timestamp</title>$style</head><body><h1>System Health Report - $timestamp</h1>")

$user = New-Object System.Text.StringBuilder
[void]$user.Append("<html><head><title>User Friendly System Health Report - $timestamp</title>$style</head><body><h1>User Friendly System Health Report - $timestamp</h1>")

# ---------- Computers ----------
$computersFile = Join-Path $AppRoot "computers.txt"
if (-not (Test-Path $computersFile)) { throw "computers.txt not found at $computersFile" }
$computers = Get-Content $computersFile | Where-Object { $_.Trim() -ne "" }
if (-not $computers) { throw "computers.txt is empty." }

function Test-IsLocal([string]$name) {
    $n = $name.Trim().ToLower()
    return $n -in @('localhost','.', '127.0.0.1', $env:COMPUTERNAME.ToLower())
}

# ---------- Collector ScriptBlock ----------
$collectSB = {
    $ErrorActionPreference = 'Stop'
    try {
        # Disk
        $disk = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
            [PSCustomObject]@{
                Name    = $_.Name
                FreeGB  = [math]::Round($_.Free/1GB,2)
                TotalGB = [math]::Round((($_.Used/1GB)+($_.Free/1GB)),2)
            }
        }

        # Memory
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $mem = [PSCustomObject]@{
            TotalMB = [math]::Round($os.TotalVisibleMemorySize / 1024,0)
            FreeMB  = [math]::Round($os.FreePhysicalMemory / 1024,0)
        }

        # CPU
        $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3 |
                    Select-Object -ExpandProperty CounterSamples |
                    Measure-Object -Property CookedValue -Average).Average
        $cpuLoad = [math]::Round($cpuLoad,1)

        # Uptime
        $uptime = $os.LastBootUpTime
        $uptimeDays = (New-TimeSpan -Start $uptime -End (Get-Date)).Days

        # Windows Update
        $wu = Get-Service -Name wuauserv -ErrorAction SilentlyContinue | 
              Select-Object -First 1 -Property Status,Name

        # Ping
        $ping = Test-Connection -ComputerName 'google.com' -Count 2 -ErrorAction SilentlyContinue |
                Select-Object Address, StatusCode, ResponseTime

        # Event Logs
        $events = Get-WinEvent -LogName System -MaxEvents 10 |
                  Where-Object { $_.LevelDisplayName -in @('Error','Warning') } |
                  Select-Object TimeCreated, Id, LevelDisplayName, Message

        [PSCustomObject]@{
            Ok      = $true
            Disk    = $disk
            Memory  = $mem
            CPU     = $cpuLoad
            Uptime  = $uptimeDays
            Service = $wu
            Ping    = $ping
            Events  = $events
            Error   = $null
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        [PSCustomObject]@{
            Ok      = $false
            Disk    = $null
            Memory  = $null
            CPU     = $null
            Uptime  = $null
            Service = $null
            Ping    = $null
            Events  = $null
            Error   = "Could not connect to $($computer): $errMsg"
        }
    }
}

# ---------- Run in Parallel ----------
$jobs = foreach ($c in $computers) {
    Start-Job -Name "health-$c" -ArgumentList $c, (Test-IsLocal $c) -ScriptBlock {
        param($computer,$isLocal)

        # define collector INSIDE the job so it's treated as scriptblock
        $collector = {
            $ErrorActionPreference = 'Stop'
            try {
                $disk = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
                    [PSCustomObject]@{
                        Name    = $_.Name
                        FreeGB  = [math]::Round($_.Free/1GB,2)
                        TotalGB = [math]::Round((($_.Used/1GB)+($_.Free/1GB)),2)
                    }
                }

                $os = Get-CimInstance -ClassName Win32_OperatingSystem
                $mem = [PSCustomObject]@{
                    TotalMB = [math]::Round($os.TotalVisibleMemorySize / 1024,0)
                    FreeMB  = [math]::Round($os.FreePhysicalMemory / 1024,0)
                }

                $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3 |
                            Select-Object -ExpandProperty CounterSamples |
                            Measure-Object -Property CookedValue -Average).Average
                $cpuLoad = [math]::Round($cpuLoad,1)

                $uptime = $os.LastBootUpTime
                $uptimeDays = (New-TimeSpan -Start $uptime -End (Get-Date)).Days

                $wu = Get-Service -Name wuauserv -ErrorAction SilentlyContinue | 
                      Select-Object -First 1 -Property Status,Name

                $ping = Test-Connection -ComputerName 'google.com' -Count 2 -ErrorAction SilentlyContinue |
                        Select-Object Address, StatusCode, ResponseTime

                $events = Get-WinEvent -LogName System -MaxEvents 10 |
                          Where-Object { $_.LevelDisplayName -in @('Error','Warning') } |
                          Select-Object TimeCreated, Id, LevelDisplayName, Message

                [PSCustomObject]@{
                    Ok      = $true
                    Disk    = $disk
                    Memory  = $mem
                    CPU     = $cpuLoad
                    Uptime  = $uptimeDays
                    Service = $wu
                    Ping    = $ping
                    Events  = $events
                    Error   = $null
                }
            }
            catch {
                [PSCustomObject]@{
                    Ok      = $false
                    Disk    = $null
                    Memory  = $null
                    CPU     = $null
                    Uptime  = $null
                    Service = $null
                    Ping    = $null
                    Events  = $null
                    Error   = "Could not connect to $($computer): $($_.Exception.Message)"
                }
            }
        }

        if ($isLocal) {
            $result = & $collector
        } else {
            try {
                $result = Invoke-Command -ComputerName $computer -ScriptBlock $collector -ErrorAction Stop
            }
            catch {
                $result = [PSCustomObject]@{
                    Ok      = $false
                    Disk    = $null
                    Memory  = $null
                    CPU     = $null
                    Uptime  = $null
                    Service = $null
                    Ping    = $null
                    Events  = $null
                    Error   = "Could not connect to $($computer): $($_.Exception.Message)"
                }
            }
        }

        [PSCustomObject]@{ Computer=$computer; Result=$result }
    }
}

# ---------- Collect Results ----------
$results = Receive-Job -Job $jobs -Wait -AutoRemoveJob
# ---------- Build Reports ----------
foreach ($entry in $results | Sort-Object Computer) {
    $computer = $entry.Computer
    $r = $entry.Result

    [void]$tech.Append("<h2>Machine: $computer</h2>")
    [void]$user.Append("<h2>Machine: $computer</h2><ul>")

    if (-not $r.Ok) {
        $msg = [System.Web.HttpUtility]::HtmlEncode($r.Error)
        [void]$tech.Append("<p style='color:red;'>ERROR: $msg</p>")
        [void]$user.Append("<li style='color:red;'>$msg</li></ul>")
        continue
    }

    # Disk
    $diskTable = "<table><tr><th>Drive</th><th>Free GB</th><th>Total GB</th></tr>"
    foreach ($d in $r.Disk) { $diskTable += "<tr><td>$($d.Name)</td><td>$($d.FreeGB)</td><td>$($d.TotalGB)</td></tr>" }
    $diskTable += "</table>"
    [void]$tech.Append("<h3>Disk Space</h3>$diskTable")
    $minFree = ($r.Disk | Measure-Object -Property FreeGB -Minimum).Minimum
    $diskCheck = if ([double]$minFree -lt 5) { "[X] Low disk space" } else { "[OK] Disk space OK" }
    [void]$user.Append("<li>Disk: $diskCheck</li>")

    # Memory
    [void]$tech.Append("<h3>Memory Usage</h3><ul><li>Total: $($r.Memory.TotalMB) MB</li><li>Free: $($r.Memory.FreeMB) MB</li></ul>")
    $memCheck = if ($r.Memory.FreeMB -lt 500) { "[X] Low memory" } else { "[OK] Memory OK" }
    [void]$user.Append("<li>Memory: $memCheck</li>")

    # CPU
    [void]$tech.Append("<h3>CPU</h3><p>Average CPU Load: $($r.CPU)%</p>")
    $cpuCheck = if ($r.CPU -gt 80) { "[!] High CPU load ($($r.CPU)%)" } else { "[OK] CPU normal ($($r.CPU)%)" }
    [void]$user.Append("<li>CPU: $cpuCheck</li>")

    # Uptime
    [void]$tech.Append("<h3>Uptime</h3><p>$($r.Uptime) days</p>")
    [void]$user.Append("<li>Uptime: $($r.Uptime) days</li>")

    # Service
    if ($r.Service) {
        [void]$tech.Append("<h3>Windows Update Service</h3><p>Status: $($r.Service.Status)</p>")
        $svcCheck = if ($r.Service.Status -eq 'Running') { "[OK] Windows Update running" } else { "[!] Windows Update $($r.Service.Status)" }
        [void]$user.Append("<li>Service: $svcCheck</li>")
    }

    # Ping
    if ($r.Ping) {
        $avg = [math]::Round(($r.Ping | Measure-Object ResponseTime -Average).Average,0)
        [void]$tech.Append("<h3>Ping</h3><p>Average: ${avg} ms</p>")
        [void]$user.Append("<li>Ping avg: ${avg}ms</li>")
    }

    # Event Logs
    if ($r.Events) {
        $evtTable = "<table><tr><th>Time</th><th>ID</th><th>Level</th><th>Message</th></tr>"
        foreach ($evt in $r.Events) {
            $evtTable += "<tr><td>$($evt.TimeCreated)</td><td>$($evt.Id)</td><td>$($evt.LevelDisplayName)</td><td>$([System.Web.HttpUtility]::HtmlEncode($evt.Message))</td></tr>"
        }
        $evtTable += "</table>"
        [void]$tech.Append("<h3>Recent Event Logs</h3>$evtTable")
        [void]$user.Append("<li>Event Logs: See technical report</li>")
    }

    [void]$user.Append("</ul>")
}

[void]$tech.Append("</body></html>")
[void]$user.Append("</body></html>")

# Save files
$tech.ToString() | Out-File -FilePath $htmlFile -Encoding UTF8
$user.ToString() | Out-File -FilePath $userReportFile -Encoding UTF8

# ---------- Email ----------
Send-MailMessage `
    -From $from `
    -To $to `
    -Subject $subject `
    -Body $body `
    -SmtpServer $smtpServer `
    -Port $smtpPort `
    -Credential (New-Object System.Management.Automation.PSCredential($smtpUser,(ConvertTo-SecureString $smtpPass -AsPlainText -Force))) `
    -UseSsl `
    -Attachments $htmlFile,$userReportFile
