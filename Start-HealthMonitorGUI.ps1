# ==========================================
# System Health Monitor - GUI Launcher
# Launches healthcheck_remote_html.ps1 with selected computers + email
# Author: Moustafa Obari
# ==========================================

# ---------- Robust App Root ----------
function Get-AppRoot {
    if ($PSScriptRoot) { return $PSScriptRoot }
    if ($PSCommandPath) { return Split-Path -Parent $PSCommandPath }
    $exe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    return Split-Path -Parent $exe
}
$AppRoot = Get-AppRoot

# ---------- Paths ----------
$ComputersFile = Join-Path $AppRoot 'computers.txt'
$MonitorScript = Join-Path $AppRoot 'healthcheck_remote_html.ps1'
$LogsDir       = Join-Path $AppRoot 'logs'
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }
$GuiLog = Join-Path $LogsDir 'gui.log'

function Write-GuiLog($msg) {
    ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg) | Add-Content -Path $GuiLog
}

# ---------- UI ----------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "System Health Monitor"
$form.Size = New-Object System.Drawing.Size(500,400)
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter computer names (one per line):"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($label)

$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Multiline = $true
$textbox.ScrollBars = "Vertical"
$textbox.Size = New-Object System.Drawing.Size(460,200)
$textbox.Location = New-Object System.Drawing.Point(10,50)
$form.Controls.Add($textbox)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Run Health Check"
$button.Size = New-Object System.Drawing.Size(150,30)
$button.Location = New-Object System.Drawing.Point(10,270)
$form.Controls.Add($button)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(10,310)
$form.Controls.Add($statusLabel)

# ---------- Email Prompt ----------
function Show-EmailPrompt([System.Windows.Forms.Form]$Owner, [string]$Default='') {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Report recipient"
    $dlg.StartPosition = "CenterParent"
    $dlg.Size = New-Object System.Drawing.Size(420,160)
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.TopMost = $true

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Enter recipient email address:"
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point(12,15)
    $dlg.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Size = New-Object System.Drawing.Size(370,22)
    $txt.Location = New-Object System.Drawing.Point(12,38)
    $txt.Text = $Default
    $dlg.Controls.Add($txt)

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "OK"
    $btnOK.Location = New-Object System.Drawing.Point(212,75)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dlg.AcceptButton = $btnOK
    $dlg.Controls.Add($btnOK)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(297,75)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dlg.CancelButton = $btnCancel
    $dlg.Controls.Add($btnCancel)

    $dlg.Add_Shown({ $dlg.Activate(); $txt.Focus() })

    :promptLoop while ($true) {
        $result = $dlg.ShowDialog($Owner)
        if ($result -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
        $email = $txt.Text.Trim()
        if (-not [string]::IsNullOrWhiteSpace($email) -and $email -match '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
            return $email
        }
        [System.Windows.Forms.MessageBox]::Show($dlg, "That doesn't look like a valid email address.", "Invalid Email")
    }
}

# ---------- Button Handler ----------
$button.Add_Click({
    try {
        Write-GuiLog "Button clicked"

        $computers = $textbox.Lines | Where-Object { $_.Trim() -ne "" }
        if ($computers.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show($form,"Please enter at least one computer name.","Error")
            return
        }

        $computers | Set-Content -Path $ComputersFile -Encoding UTF8
        Write-GuiLog "computers.txt written to $ComputersFile"

        if (-not (Test-Path $MonitorScript)) {
            Write-GuiLog "Monitor script missing: $MonitorScript"
            [System.Windows.Forms.MessageBox]::Show($form,"Missing script:`n$MonitorScript","File Not Found")
            return
        }

               $email = Show-EmailPrompt -Owner $form
        if (-not $email) { Write-GuiLog "Email prompt cancelled/empty"; return }

        $statusLabel.Text = "Running health check... please wait."
        Write-GuiLog "Launching $MonitorScript with Recipient=$email"

        # Start-Process (no line continuations)
        Start-Process "powershell.exe" -WorkingDirectory $AppRoot -WindowStyle Normal -ArgumentList `
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$MonitorScript`"", "-Recipient", "$email"

        $statusLabel.Text = "Health check started. Reports will be emailed."
        Write-GuiLog "Process launched"

    }
    catch {
        $statusLabel.Text = "An error occurred while running the script."
        Write-GuiLog ("ERROR: " + $_)
        [System.Windows.Forms.MessageBox]::Show($form,$_.Exception.Message,"Run Error")
    }
})

$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
