# VERSION: 2026.02.18.02
<#
.SYNOPSIS
    AWS RDS Blue/Green Deployment Manager
    Platform: Windows (PowerShell)
    Dependencies: AWS CLI v2 configured with IAM Identity Center (SSO)

.AUTHOR
    Wojciech Kuncewicz DBA

.CHANGELOG
    2026-02-18 (Part 2)
    - FEATURE: Expanded `Monitor-BGStatus-Interactive` into a full dashboard with SwitchoverDetails table, Tasks checklist, Replica Lag, engine versions, elapsed time, and flicker-free rendering.
    - RELIABILITY: Fixed exponential backoff starting at 1s instead of 2s (`retryCount + 1`).
    - RELIABILITY: Migrated 8 raw `aws` CLI calls to `Invoke-AWS-WithRetry` for consistent throttling/SSO-token handling.
    - RELIABILITY: Added `$LASTEXITCODE` checks to EC2 Start/Stop commands.
    - UX: Added ESC/Enter exit to `Monitor-BGStatus-Interactive` (was CTRL+C only).
    - UX: Replaced `Clear-Host` with `SetCursorPosition` in `Monitor-RDS-State` and `Monitor-Snapshot-Progress` to eliminate screen flicker.
    - PERFORMANCE: Replaced array concatenation in `Get-EC2Instances` with `List[object].Add()`.
    - REFACTOR: Extracted `Get-InstanceIdFromArn` helper to deduplicate ARN parsing (was 7x inline).
    - REFACTOR: Replaced `$detailsText +=` loop with `ForEach-Object` pipeline in `Show-PendingMaintenance`.
    - BUGFIX: Added `-Encoding UTF8` to `Export-Report` CSV/HTML exports (was system default = UTF-16 BOM on PS 5.1).
    - BUGFIX: Added input validation (`[int]` cast) to `View-LogContent` line count prompt.

    2026-02-18
    - SECURITY: Replaced dangerous `Invoke-Expression` config loading with safe dot-sourcing (`. $ConfigPath`).
    - BUGFIX: Fixed operator precedence bug in SSO token expiration detection (`-or`/`-and` without parentheses caused false negatives).
    - BUGFIX: Added `$LASTEXITCODE` check in `Check-SSOSession` — native AWS CLI errors were silently ignored.
    - BUGFIX: Renamed reserved `$input` variable to `$userInput` to avoid PowerShell automatic variable shadowing.
    - SCOPE FIX: Added `global:` prefix to `Get-AnsiColor`, `Get-AnsiString`, `Strip-Ansi`, and `Pad-Line` to fix "not recognized" errors in `.GetNewClosure()` scriptblocks on Windows PowerShell.
    - PERFORMANCE: `Get-RDSInstances` now delegates to `Get-CachedRDSInstances` — eliminates ~10 redundant AWS API calls per session.
    - PERFORMANCE: AWS config data (`Get-AWSConfigData`) is now cached in `$global:AWSConfigDataCache`.
    - PERFORMANCE: Replaced array concatenation (`$exportData +=`) with `List[PSCustomObject].Add()` in 5 export/report functions (O(n) vs O(n²)).
    - REFACTOR: Extracted `Get-AWSDirectoryPath` helper to deduplicate `.aws` directory resolution logic.
    - REFACTOR: Removed dead/unused `$header` scriptblock in `Show-Menu` (21 lines).
    - REFACTOR: Replaced recursive `Select-AWSProfile` calls with `__RESTART__` signal pattern and loop wrapper to prevent stack overflow.
    - CACHE: Added cache invalidation (`$global:RDSInstancesCache = $null`) after Start/Stop/Delete instance operations.
    - OTA: Added 10-second timeout to update check (`HttpWebRequest`) to prevent startup hang when GitHub is unreachable.
    - UI: Fixed typo "founded new" → "new version found" in OTA menu label.
    - UI: Fixed inconsistent indentation in Main Menu options and switch block.

    2026-02-17
    - UI FIX: Fixed "ghosting" artifacts in the interactive menu footer by implementing exclusive rendering logic and screen clearing padding.
    - UI: Standardized menu navigation hints in the footer for consistent UX.
    - REFACTOR: Exported core UI functions (Show-Header, Show-Menu, Invoke-InteractiveViewportSelection) to the global scope to prevent potential syntax/scope issues in certain execution contexts.
    - MONITORING: Updated 'Monitor RDS State' to refresh every 10 seconds (previously 5s) while preserving manual F5 refresh.

    2026-02-16 (Part 3)
    - ARCHITECTURAL OPTIMIZATION: Replaced array concatenation (`+=`) with `System.Collections.Generic.List[psobject]` in the interactive menu engine (`Invoke-InteractiveViewportSelection`) to improve rendering performance.
    - JSON PARSING OPTIMIZATION: Global refactor of AWS CLI JSON parsing. Replaced slower `| Out-String | ConvertFrom-Json` pattern with faster `($output -join "") | ConvertFrom-Json`.
    - RESILIENCE: Implemented Exponential Backoff with Jitter in `Invoke-AWS-WithRetry` to handle AWS Throttling and Rate Limit exceptions gracefully (Max Retries increased to 3).

    2026-02-16 (Part 2)
    - PERFORMANCE OPTIMIZATION: Implemented Data Caching for RDS Instance lists (TTL: 60s).
      This drastically speeds up menu navigation by avoiding repetitive AWS CLI calls.
    - ADDED F5 REFRESH: Users can now press 'F5' in interactive menus and monitoring views to force a cache refresh.
    - PARALLEL EXECUTION: 'Create Multiple Snapshots' and 'Update OS' now run in parallel (PowerShell 7+), significantly reducing execution time for batch operations.
    - UI: Added "Data age" indicator to the frozen header.

    2026-02-16 (Part 1)
    - Major Rendering Engine Overhaul: Implemented Double-Buffered "Virtual Screen" rendering for interactive menus.
      This eliminates screen flickering by constructing the full frame in memory and updating it in a single pass using [Console]::SetCursorPosition.
    - Added ANSI helper functions to replace direct Write-Host calls, improving performance and enabling complex string manipulation for the UI.
    - Updated 'Show-Menu', 'Select-RDSInstance-Live', and 'Remove-RDSSnapshot-Interactive' to support the new non-blocking rendering architecture.

    2026-02-12
    - Refactored 'Delete Snapshots' to use the new viewport engine, allowing search, multi-selection, and bulk deletion of all manual snapshots (removed 50-item limit).
    - Added 'Pre-flight Snapshot Quota Check' for single and multiple snapshot workflows.
      The tool now verifies if the 100 manual snapshot limit is reached before attempting creation, allowing users to retry after cleanup.

    2026-02-11
    - Maintenance Release: Verified stability of recent safety patches.
    - Documentation Update: Refined internal documentation strings.

    2026-02-10
    - Enhanced 'Apply Pending Maintenance': The confirmation prompt ("Apply Immediately?") is now a cancellable menu supporting 'q' and 'ESC' to exit safely at any time.
    - Updated Show-Menu to support 'q' key for cancellation when filtering is disabled.
    - Fixed critical safety bug in Multi-Select menus (Update OS, Apply Maintenance, Create Multiple Snapshots) where cancelling via ESC could trigger actions on the last item.
    - Fixed 'Delete Blue/Green Deployment': Removed redundant 'Cancel' option from instance termination menu (ESC is used to exit).
    - Improved error logging for 'Create Blue/Green Deployment' to capture full exception details (including stack trace) for better debugging.
    - Added 'Update OS' feature to RDS Management menu. This specialized workflow focuses on applying 'system-update' actions with mandatory safeguards (Snapshot and Monitoring alerts) and immediate application.
    - Added 'Apply Pending Maintenance' feature to RDS Management menu. Allows interactive selection and batch application of pending maintenance actions (e.g., OS updates) with immediate or scheduled opt-in.
    - Removed pre-filtering by Engine in 'Select Active Instance' to allow immediate access to the full instance list with live filtering.
    - Added 'Monitor Instance State' to RDS Management menu for real-time status tracking of all instances.
    - Updated text in Upgrade Database reminder to be generic ("Disable monitoring") rather than specific.
    - Fixed 'Upgrade Database Engine' logic: Now explicitly queries 'describe-db-engine-versions' with '--include-all' to ensure the current version's metadata is found, resolving the "No valid upgrade targets found" issue for older/non-default versions.
    - Added 'Recommendation list' report to 'Other Reports' menu.
    - This new feature fetches RDS instances and correlates them with AWS Compute Optimizer findings to display optimization recommendations (Over/Under-provisioned status, recommended instance class, reason codes).
    - Enhanced 'Delete Instance(s)' to automatically disable 'Deletion Protection' (if enabled) before attempting deletion, notifying the user of this action.
    - Fixed 'Monitor-Snapshot-Progress' to correctly include and prioritize in-progress snapshots ('creating', 'backing-up') which often lack a creation timestamp initially.
    - Updated snapshot sorting logic to treat missing timestamps as "newest" so they appear at the top of the list.
    - Added automatic SSO Token refresh prompt: If AWS CLI returns 'Token has expired', the tool now prompts to run 'aws sso login' and retries the command.
    - Fixed critical 'No instances selected' bug in Start/Stop/Delete workflows by preventing array unrolling in Show-Menu and updating boolean checks.
    - Enhanced 'Delete Blue/Green Deployment': Added Replica Lag check (Source & Green) before deletion.
    - Improved Menu UI: Added separator lines for better readability and updated navigation logic to skip them.
    - Fixed 'Create Blue/Green Deployment' bug: Removed unsupported '--target-db-instance-identifier' parameter. Green DB names are generated by AWS.
    - Removed 'Green DB Name' user input prompt to avoid confusion.

    2026-02-09
    - Fixed 'Create Blue/Green Deployment' error handling: Now correctly captures and displays AWS CLI stderr messages by separating output streams.
    - Fixed 'Could not determine parameter group family' error by adding --include-all to engine version lookup.
    - Added argument trimming to Engine and EngineVersion to prevent whitespace issues.
    - Fixed 'Delete Blue/Green Deployment' menu bug (Removed 'Cancel' option to prevent list misalignment).
    - Improved error logging for 'Create Blue/Green Deployment' (Full error trace capture to file).
    - Improved debugging info for Parameter Group Family detection.
    - Added F1 key navigation in menus to return to Client/Session Selection screen.
    - Modified Monitor-Snapshot-Progress to be a global monitor (Last 10 snapshots) without parameters.
    - Updated profile color logic: All non-production environments in RW mode are now Orange (DarkYellow).
    - Refined color rules: Green (Any RO), Orange (Non-Prod RW), Red (Prod RW).
    - Added DarkYellow (Orange) warning color for INT/PRE/DEV environments in RW mode
    - Added automatic OTA update check at startup; Menu displays [founded new: VER] if update exists
    - Added parsing of 'env' and 'type' fields from .aws/config
    - Added color-coded environment warnings in Header and Profile Selection
    - Updated 'Create Blue/Green Deployment' to use interactive menus for Target Version and Parameter Group selection
    - Added 'MaxSelectionCount' support to Show-Menu to enable single-select mode with checkbox-style interaction
    - Fixed bug in single-instance selection menu where options were not array-wrapped

    2026-02-06
    - Fixed critical bug in Client (Session) selection when only one session exists (array vs string casting)
    - Improved AWS Config parsing robustness (correctly handles interleaved [sso-session] sections)
    - Added Client (Session) Selection step before Profile Selection
    - Window Title now reflects Client | Profile - Role
    - Added interactive 'Delete Profile' option to AWS Profile selection menu
    - Added README.md documentation
    - Changed default Window Title to 'AWS RDS BLUE/GREEN DEPLOYMENT TOOL by WK'
    - Fixed OTA version check logic to use [version] type comparison and handle regex robustness
    - Added 'Create multiple snapshots' feature with multi-select menu
    - Added 'Delete Snapshots' feature
    - Moved configuration to external file (rds_bg_manager.config.ps1)
    - Modified Show-Menu to support multi-selection (Space to toggle)
    - Modified Monitor-Snapshot-Progress to show last 10 snapshots (all types) using --max-items
    - Updated snapshot monitoring columns to include storage and reordered fields

    2026-02-04
    - Split DB Versions report into 'DB All Details' and 'DB Versions (Compact)'
    - Added full script logging to file (rds_manager_YYYYMMDD.log)
    - Added CSV/HTML export for all reports
    - Added dynamic AWS Profile discovery (aws configure list-profiles) and SSO setup
    - Added Engine filtering for instance lists
    - Added interactive Log Viewer (tail -last 20)
    - Fixed Write-Host formatting and PowerShell 5.1 compatibility issues

    2026-02-03
    - Initial implementation of interactive arrow-key navigation
    - Added visual highlighting for Blue/Green instances
    - Added Instance Reports structure (Details, Snapshots, Replica Lag, Logs, Events)
    - Added Other Reports (Pending OS Upgrade, DB Versions)
#>

# --- CONFIGURATION ---
$ConfigPath = Join-Path $PSScriptRoot "rds_bg_manager.config.ps1"
$Global:Config = @{
    WindowTitle = "AWS RDS Blue/Green Manager"
    UpdateUrl = "https://raw.githubusercontent.com/wojtulab/blue-green-aws/refs/heads/main/rds_bg_manager.ps1"
    LogFileFormat = "rds_manager_{0:yyyyMMdd}.log"
}

if (Test-Path $ConfigPath) {
    try {
        # Dot-source config file instead of Invoke-Expression for security
        $LoadedConfig = $null
        . $ConfigPath
        if ($LoadedConfig -is [System.Collections.IDictionary]) {
            foreach ($key in $LoadedConfig.Keys) {
                $Global:Config[$key] = $LoadedConfig[$key]
            }
        }
    } catch {
        Write-Host "Warning: Failed to load config file: $_" -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}

$Host.UI.RawUI.WindowTitle = $Global:Config.WindowTitle
$ErrorActionPreference = "Stop"
$global:AWSProfile = $null
$global:SelectedInstance = $null
$global:LogFile = $Global:Config.LogFileFormat -f (Get-Date)
$global:UpdateUrl = $Global:Config.UpdateUrl

# --- HELPER FUNCTIONS ---

# Tu zaczynaja sie funkcje pomocnicze / Helper functions start here
# Troche balagan ale dziala / A bit messy but works

# --- DATA CACHING ---
$global:RDSInstancesCache = $null
$global:RDSInstancesCacheTime = $null
$global:AWSConfigDataCache = $null

function Get-AWSDirectoryPath {
    $path = Join-Path $env:USERPROFILE ".aws"
    if (-not (Test-Path $path) -and $env:HOME) {
        $candidate = Join-Path $env:HOME ".aws"
        if (Test-Path $candidate) { $path = $candidate }
    }
    return $path
}

function Get-InstanceIdFromArn {
    param([string]$Arn)
    if ($Arn -match ":db:(.+)$") { return $matches[1] }
    return $Arn
}

function Get-CachedRDSInstances {
    param(
        [switch]$Force
    )
    $cacheDuration = 60 # seconds

    $shouldRefresh = $true
    if ($global:RDSInstancesCache -and $global:RDSInstancesCacheTime) {
        $age = (Get-Date) - $global:RDSInstancesCacheTime
        if ($age.TotalSeconds -lt $cacheDuration) {
            $shouldRefresh = $false
        }
    }

    if ($Force) { $shouldRefresh = $true }

    if ($shouldRefresh) {
        Write-Log "Refreshing RDS Instance Cache..." -ForegroundColor DarkGray
        try {
            # Use specific query as requested for speed
            $argsList = @("rds", "describe-db-instances", "--query", "DBInstances[*]", "--output", "json", "--profile", $global:AWSProfile)
            $output = Invoke-AWS-WithRetry -Arguments $argsList -ReturnJson
            $json = $output -join ""

            if (![string]::IsNullOrWhiteSpace($json)) {
                $data = $json | ConvertFrom-Json
                if ($data -is [Array]) {
                    $global:RDSInstancesCache = $data
                } elseif ($data) {
                    $global:RDSInstancesCache = @($data)
                } else {
                    $global:RDSInstancesCache = @()
                }
                $global:RDSInstancesCacheTime = Get-Date
            }
        } catch {
            Write-Log "Error refreshing cache: $_" -ForegroundColor Red
            # Return old cache if available on error? Or rethrow?
            # User wants speed, but correctness matters. Return empty or throw?
            # Let's keep old cache if available to avoid breaking UI flow completely
            if (!$global:RDSInstancesCache) { $global:RDSInstancesCache = @() }
        }
    }

    return $global:RDSInstancesCache
}

# --- ANSI CONSTANTS & HELPERS ---
$global:ESC = [char]27
$global:ANSI = @{
    Reset      = "$($global:ESC)[0m"
    Black      = "$($global:ESC)[30m"
    Red        = "$($global:ESC)[31m"
    Green      = "$($global:ESC)[32m"
    Yellow     = "$($global:ESC)[93m" # Bright Yellow
    Blue       = "$($global:ESC)[34m"
    Magenta    = "$($global:ESC)[35m"
    Cyan       = "$($global:ESC)[36m"
    White      = "$($global:ESC)[37m"
    Gray       = "$($global:ESC)[90m"
    DarkGray   = "$($global:ESC)[90m"
    DarkYellow = "$($global:ESC)[33m" # Standard Dim Yellow/Orange
}

function global:Get-AnsiColor {
    param([string]$ColorName)
    if ($global:ANSI.ContainsKey($ColorName)) { return $global:ANSI[$ColorName] }
    return $global:ANSI.White
}

function global:Get-AnsiString {
    param(
        [string]$Text,
        [string]$Color = "White",
        [string]$BgColor = $null
    )
    $c = Get-AnsiColor $Color
    return "$c$Text$($global:ANSI.Reset)"
}

function global:Strip-Ansi {
    param([string]$Text)
    return $Text -replace "\e\[[0-9;]*m", ""
}

function global:Pad-Line {
    param(
        [string]$Line,
        [int]$Width = 0
    )
    if ($Width -eq 0) {
        try { $Width = $Host.UI.RawUI.WindowSize.Width } catch { $Width = 120 }
    }

    $clean = Strip-Ansi $Line
    $len = $clean.Length

    if ($len -lt $Width) {
        return $Line + (" " * ($Width - $len))
    }
    return $Line
}

function Write-Log {
    param (
        [string]$Message,
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::Gray,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
        [switch]$NoNewline
    )

    # Write to Console
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }

    # Write to File (strip colors, add timestamp)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $cleanMessage = $Message -replace "\e\[[0-9;]*m", "" # Basic ANSI strip if present, usually not needed for simple strings
    Add-Content -Path $global:LogFile -Value "[$timestamp] $cleanMessage" -ErrorAction SilentlyContinue
}

function Invoke-AWS-WithRetry {
    param(
        [string[]]$Arguments,
        [switch]$ReturnJson
    )

    $maxRetries = 3
    $retryCount = 0
    $commandSuccess = $false
    $output = $null
    $baseBackoff = 2 # seconds for exponential backoff

    while (-not $commandSuccess -and $retryCount -le $maxRetries) {
        try {
            # Execute AWS CLI
            # We use & operator. Arguments array is passed.
            # We redirect stderr to stdout to catch it in $output for analysis

            # Note: We need to handle output formatting.
            # If $ReturnJson is set, we might want to ensure --output json is in args or handled.
            # But usually args already contain it.

            # To capture error properly in PowerShell 5.1 with Stop preference:
            $origEAP = $ErrorActionPreference
            $ErrorActionPreference = "Continue" # Capture error in stream

            $outputRaw = & aws $Arguments 2>&1
            $ErrorActionPreference = $origEAP

            # Check for native execution failure (exit code)
            if ($LASTEXITCODE -ne 0) {
                # Convert output to string to check for specific messages
                $outputStr = $outputRaw | Out-String
                throw $outputStr
            }

            $output = $outputRaw
            $commandSuccess = $true

        } catch {
            # Cholera, znowu blad / Damn, error again
            $err = $_
            $errStr = "$($err)"

            # Check for Token Expired Error
            if ($errStr -match "Token has expired" -or ($errStr -match "expired" -and $errStr -match "sso")) {
                 Write-Log "AWS SSO Token has expired." -ForegroundColor Yellow
                 if ($retryCount -lt $maxRetries) {
                     $resp = Read-Host "Do you want to run 'aws sso login' and retry? (Y/n)"
                     if ($resp -ne 'n') {
                         Write-Log "Running aws sso login..." -ForegroundColor Cyan
                         try {
                             aws sso login --profile $global:AWSProfile
                             Write-Log "Login completed. Retrying command..." -ForegroundColor Green
                             $retryCount++
                             continue
                         } catch {
                             Write-Log "Login failed: $_" -ForegroundColor Red
                             throw $err # Re-throw original or new error
                         }
                     }
                 }
            }

            # Check for Throttling / Rate Limiting
            if ($errStr -match "Throttling" -or $errStr -match "RateExceeded" -or $errStr -match "RequestLimitExceeded") {
                 if ($retryCount -lt $maxRetries) {
                     # Exponential Backoff with Jitter
                     $exponent = [math]::Pow($baseBackoff, $retryCount + 1)
                     $jitter = Get-Random -Minimum 0 -Maximum 1000
                     $sleepMs = ([int]($exponent * 1000)) + $jitter

                     Write-Log "AWS Throttling detected. Retrying in $($sleepMs)ms..." -ForegroundColor DarkGray
                     Start-Sleep -Milliseconds $sleepMs
                     $retryCount++
                     continue
                 }
            }

            # If we are here, it's either not a token error or user said no, or login failed (caught above).
            # Re-throw
            throw $err
        }
    }

    return $output
}

function Get-TimeStamp {
    return Get-Date -Format "yyyyMMdd-HHmm"
}

function Get-ProfileColor {
    param (
        [string]$ProfileName,
        [string]$Type,
        [string]$Env
    )

    $roRegex = "(?i)(^|[-_])(ro|readonly)($|[-_])"
    $isRO = ($Type -match $roRegex -or $ProfileName -match $roRegex)

    if ($isRO) { return "Green" }

    # Use generic logic for non-prod
    $isProd = ($Env -match "(?i)^prod")

    if (-not $isProd) {
        return "DarkYellow" # Orange
    }

    return "Red"
}

function global:Get-Header-Lines {
    $lines = @()

    $lines += Pad-Line (Get-AnsiString "==========================================" -Color Cyan)
    $lines += Pad-Line (Get-AnsiString "   AWS RDS BLUE/GREEN DEPLOYMENT TOOL     " -Color Cyan)

    if ($global:AWSProfile) {
        $profileStr = "   PROFILE: $global:AWSProfile (SSO)"

        # Data Age Indicator
        if ($global:RDSInstancesCacheTime) {
            $age = [math]::Round(((Get-Date) - $global:RDSInstancesCacheTime).TotalSeconds)
            $ageStr = " | Data age: ${age}s | Press F5 to refresh"
            $profileStr += $ageStr
        }
        $line = ""

        if ($global:AWSConfigMetadata -and $global:AWSConfigMetadata.ContainsKey($global:AWSProfile)) {
            $meta = $global:AWSConfigMetadata[$global:AWSProfile]
            if ($meta.Env -or $meta.Type) {
                $envStr = if ($meta.Env) { $meta.Env } else { "?" }
                $typeStr = if ($meta.Type) { $meta.Type } else { "?" }
                $warnStr = " [ $envStr / $typeStr ]"

                $warnColor = Get-ProfileColor -ProfileName $global:AWSProfile -Type $typeStr -Env $envStr

                # Combine parts manually to preserve colors in one line
                $part1 = Get-AnsiString $profileStr -Color Magenta
                $part2 = Get-AnsiString $warnStr -Color $warnColor
                $line = "$part1$part2"
            } else {
                 $line = Get-AnsiString $profileStr -Color Magenta
            }
        } else {
            $line = Get-AnsiString $profileStr -Color Magenta
        }
        $lines += Pad-Line $line
    }
    if ($global:SelectedInstance) {
        $lines += Pad-Line (Get-AnsiString "   ACTIVE INSTANCE: $($global:SelectedInstance.DBInstanceIdentifier)" -Color Green)
    }
    $lines += Pad-Line (Get-AnsiString "==========================================" -Color Cyan)

    return $lines
}

function global:Show-Header {
    Clear-Host
    $lines = Get-Header-Lines
    foreach ($line in $lines) {
        [Console]::WriteLine($line)
    }
}

function global:Show-Menu {
    param (
        [string]$Title,
        [object[]]$Options,
        [switch]$EnableFilter,
        [switch]$MultiSelect,
        [int]$MaxSelectionCount = 0
    )

    # Bridge Show-Menu to Invoke-InteractiveViewportSelection
    # Since Show-Menu returns Index (or Indices), we use -ReturnIndex switch.

    # We need to make sure $Title is captured.
    $capturedTitle = $Title
    $capturedEnable = $EnableFilter

    $headerLogic = {
        param($SearchString, $TotalItems, $FilteredCount)
        $lines = @(Get-Header-Lines)
        if (![string]::IsNullOrEmpty($capturedTitle)) {
            $lines += Get-AnsiString "$capturedTitle" -Color Yellow
            $lines += "------------------------------------------"
        }
        if ($capturedEnable) {
            $lines += Get-AnsiString "Filter: $SearchString" -Color Cyan
            $lines += "------------------------------------------"
        }
        return $lines
    }.GetNewClosure()

    # Footer logic
    $footerLogic = {
        param($MultiSelect)
        $lines = @()
        if ($MultiSelect) {
             $lines += Get-AnsiString "UP/DOWN: Navigate | SPACE: Toggle | ENTER: Confirm | Type to Filter" -Color DarkGray
        } elseif ($capturedEnable) {
            $lines += Get-AnsiString "UP/DOWN: Navigate | ENTER: Select | Type to Filter | ESC: Back" -Color DarkGray
        } else {
            $lines += Get-AnsiString "UP/DOWN: Navigate | ENTER: Select | ESC: Back" -Color DarkGray
        }
        return $lines
    }.GetNewClosure()

    return Invoke-InteractiveViewportSelection -Items $Options `
        -HeaderContent $headerLogic `
        -FooterContent $footerLogic `
        -MultiSelect:$MultiSelect `
        -MaxSelectionCount $MaxSelectionCount `
        -ReturnIndex
}

function Get-Instance-BG-Role {
    param (
        [string]$InstanceIdentifier,
        [array]$BGDeployments
    )
    if (!$BGDeployments) { return $null }

    foreach ($bg in $BGDeployments) {
        # Source and Target are ARNs (e.g. arn:aws:rds:us-east-1:123456789012:db:my-db-instance)
        # We match against the end of the ARN to support standard RDS identifiers
        if ($bg.Source -match ":db:$InstanceIdentifier$") { return "Blue (Source)" }

        # Target is also an ARN
        if ($bg.Target -match ":db:$InstanceIdentifier$") { return "Green (Target)" }
    }
    return $null
}

function global:Invoke-InteractiveViewportSelection {
    param (
        [Parameter(Mandatory=$true)] [System.Collections.IList]$Items,
        [scriptblock]$HeaderContent, # Should return string array
        [scriptblock]$FooterContent, # Should return string array
        [string[]]$FilterProperties, # If null, filter on ToString or Label
        [switch]$MultiSelect,
        [int]$MaxSelectionCount = 0,
        [switch]$ReturnIndex
    )

    # Initialize State
    $searchString = ""
    $currentIndex = 0
    $windowStart = 0

    # Store indices of selected items (Hash Set for O(1) lookup)
    $selectedIndices = New-Object System.Collections.Generic.HashSet[int]

    # Hide cursor
    try { [Console]::CursorVisible = $false } catch {}

    # Initialize StringBuilder for Double Buffering
    $sb = [System.Text.StringBuilder]::new()

    while ($true) {
        # 1. Filter Data
        $wrappedItems = New-Object System.Collections.Generic.List[psobject]
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $item = $Items[$i]
            $label = if ($item -is [string]) { $item }
                     elseif ($item.PSObject.Properties['Label']) { $item.Label }
                     elseif ($item.DBInstanceIdentifier) { "$($item.DBInstanceIdentifier) ($($item.Engine))" }
                     else { $item.ToString() }

            $match = $true
            if (![string]::IsNullOrEmpty($searchString)) {
                if ($FilterProperties) {
                    $match = $false
                    foreach ($prop in $FilterProperties) {
                        if ($item.$prop -like "*$searchString*") { $match = $true; break }
                    }
                } else {
                    if ($label -notlike "*$searchString*") { $match = $false }
                }
            }

            if ($match) {
                $wrappedItems.Add([PSCustomObject]@{ OriginalIndex = $i; Item = $item; Label = $label; Color = $item.Color })
            }
        }

        # 2. Boundary Checks
        if ($wrappedItems.Count -eq 0) {
            $currentIndex = 0
        } elseif ($currentIndex -ge $wrappedItems.Count) {
            $currentIndex = $wrappedItems.Count - 1
        }
        if ($currentIndex -lt 0) { $currentIndex = 0 }

        # Scroll Logic
        try { $winHeight = $Host.UI.RawUI.WindowSize.Height } catch { $winHeight = 24 }
        try { $winWidth = $Host.UI.RawUI.WindowSize.Width } catch { $winWidth = 80 }

        $reservedLines = 12
        $viewportHeight = $winHeight - $reservedLines
        if ($viewportHeight -lt 5) { $viewportHeight = 5 }

        if ($currentIndex -lt $windowStart) {
            $windowStart = $currentIndex
        } elseif ($currentIndex -ge ($windowStart + $viewportHeight)) {
            $windowStart = $currentIndex - $viewportHeight + 1
        }
        if ($wrappedItems.Count -lt $viewportHeight) { $windowStart = 0 }

        # 3. Render to Buffer
        [void]$sb.Clear()
        try { [Console]::SetCursorPosition(0, 0) } catch {}

        # Execute Header ScriptBlock
        if ($HeaderContent) {
            $headerLines = & $HeaderContent -SearchString $searchString -TotalItems $Items.Count -FilteredCount $wrappedItems.Count
            if ($headerLines -is [string]) { $headerLines = @($headerLines) }
            foreach ($l in $headerLines) {
                [void]$sb.AppendLine((Pad-Line $l $winWidth))
            }
        } else {
            [void]$sb.AppendLine((Pad-Line (Get-AnsiString "--- Select Item ---" -Color Cyan) $winWidth))
            [void]$sb.AppendLine((Pad-Line (Get-AnsiString "Filter: $searchString" -Color Yellow) $winWidth))
            [void]$sb.AppendLine((Pad-Line "----------------------------------------" $winWidth))
        }

        # Render Viewport
        $endRow = $windowStart + $viewportHeight - 1
        if ($endRow -ge $wrappedItems.Count) { $endRow = $wrappedItems.Count - 1 }

        if ($wrappedItems.Count -eq 0) {
            [void]$sb.AppendLine((Pad-Line (Get-AnsiString "   (No matches)" -Color DarkGray) $winWidth))
        } else {
            for ($i = $windowStart; $i -le $endRow; $i++) {
                $wItem = $wrappedItems[$i]
                $isHighlighted = ($i -eq $currentIndex)
                $isSelected = $selectedIndices.Contains($wItem.OriginalIndex)

                $prefix = if ($MultiSelect) {
                    if ($isSelected) { "[*] " } else { "[ ] " }
                } else {
                    if ($isHighlighted) { "-> " } else { "   " }
                }

                $rawLabel = "$prefix$($wItem.Label)"
                if ($rawLabel.Length -gt $winWidth) {
                    $rawLabel = $rawLabel.Substring(0, $winWidth - 1)
                }

                # Colors
                $fg = "Gray"
                if ($wItem.Color) { $fg = $wItem.Color }

                if ($isHighlighted) {
                    # Cyan FG on DarkGray (Bright Black) BG
                    $fgCode = "$($global:ESC)[36m"
                    $bgCode = "$($global:ESC)[100m"
                    $lineAnsi = "$fgCode$bgCode$rawLabel$($global:ANSI.Reset)"
                } elseif ($isSelected) {
                    $fg = "Green"
                    $lineAnsi = Get-AnsiString $rawLabel -Color $fg
                } else {
                    $lineAnsi = Get-AnsiString $rawLabel -Color $fg
                }

                [void]$sb.AppendLine((Pad-Line $lineAnsi $winWidth))
            }
        }

        # Fill remaining lines
        $linesPrinted = if ($wrappedItems.Count -gt 0) { $endRow - $windowStart + 1 } else { 1 }
        $remaining = $viewportHeight - $linesPrinted
        if ($remaining -gt 0) {
            for ($k = 0; $k -lt $remaining; $k++) {
                [void]$sb.AppendLine((Pad-Line "" $winWidth))
            }
        }

        [void]$sb.AppendLine((Pad-Line (Get-AnsiString "----------------------------------------" -Color DarkGray) $winWidth))

        # Execute Footer ScriptBlock
        if ($FooterContent) {
            $footerLines = & $FooterContent -MultiSelect $MultiSelect
            if ($footerLines -is [string]) { $footerLines = @($footerLines) }
            foreach ($l in $footerLines) {
                [void]$sb.AppendLine((Pad-Line $l $winWidth))
            }
        } else {
            # Default Instructions (Exclusive)
            if ($MultiSelect) {
                [void]$sb.AppendLine((Pad-Line (Get-AnsiString "UP/DOWN: Navigate | SPACE: Toggle | ENTER: Confirm | Type to Filter" -Color Gray) $winWidth))
            } else {
                [void]$sb.AppendLine((Pad-Line (Get-AnsiString "UP/DOWN: Navigate | ENTER: Select | Type to Filter | ESC: Cancel" -Color Gray) $winWidth))
            }
        }

        # Render blank lines to clear any residual text from previous frames (Ghosting fix)
        # This acts as an eraser for any footer lines that might have existed in the previous frame but not this one.
        [void]$sb.AppendLine((Pad-Line "" $winWidth))
        [void]$sb.AppendLine((Pad-Line "" $winWidth))

        # 4. Flush and Write Buffer
        try { [Console]::Write($sb.ToString()) } catch {}

        # 5. Input Handling Loop
        while (-not [Console]::KeyAvailable) {
            Start-Sleep -Milliseconds 20
        }

        try {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } catch {
            Start-Sleep -Seconds 1
            return -1
        }

        switch ($key.VirtualKeyCode) {
            27 { # Escape
                try { [Console]::CursorVisible = $true } catch {}
                if ($ReturnIndex) { return -1 } else { return $null }
            }
            13 { # Enter
                try { [Console]::CursorVisible = $true } catch {}
                if ($MultiSelect) {
                    $res = @($selectedIndices)
                    return ,$res
                } else {
                    if ($wrappedItems.Count -gt 0) {
                        $sel = $wrappedItems[$currentIndex]
                        if ($ReturnIndex) { return $sel.OriginalIndex }
                        else { return $sel.Item }
                    }
                }
            }
            32 { # Space
                if ($MultiSelect -and $wrappedItems.Count -gt 0) {
                    $sel = $wrappedItems[$currentIndex]
                    $oid = $sel.OriginalIndex
                    if ($selectedIndices.Contains($oid)) {
                        $selectedIndices.Remove($oid) | Out-Null
                    } else {
                        if ($MaxSelectionCount -gt 0 -and $selectedIndices.Count -ge $MaxSelectionCount) {
                            if ($MaxSelectionCount -eq 1) {
                                $selectedIndices.Clear()
                                $selectedIndices.Add($oid) | Out-Null
                            }
                        } else {
                            $selectedIndices.Add($oid) | Out-Null
                        }
                    }
                }
            }
            38 { # Up
                if ($currentIndex -gt 0) { $currentIndex-- }
                elseif ($currentIndex -eq 0 -and $wrappedItems.Count -gt 0) { $currentIndex = $wrappedItems.Count - 1 }
            }
            40 { # Down
                if ($currentIndex -lt $wrappedItems.Count - 1) { $currentIndex++ }
                elseif ($currentIndex -eq $wrappedItems.Count - 1) { $currentIndex = 0 }
            }
            8 { # Backspace
                if ($searchString.Length -gt 0) {
                    $searchString = $searchString.Substring(0, $searchString.Length - 1)
                    $currentIndex = 0
                    $windowStart = 0
                }
            }
            112 { # F1
                 if ($ReturnIndex) {
                     $global:RestartSessionSelection = $true
                     return -99
                 }
            }
            116 { # F5
                try { [Console]::CursorVisible = $true } catch {}
                return -98 # Signal Refresh
            }
            Default {
                $char = $key.Character
                if (![char]::IsControl($char)) {
                    $searchString += $char
                    $currentIndex = 0
                    $windowStart = 0
                } else {
                    if ($searchString.Length -eq 0 -and $char -eq 'q') {
                        try { [Console]::CursorVisible = $true } catch {}
                        if ($ReturnIndex) { return -1 } else { return $null }
                    }
                }
            }
        }
    }
}

function Select-RDSInstance-Live {
    # Wrapper for legacy/specific calls using the new engine
    param (
        [array]$Instances, # Not used if we fetch from cache inside? No, passed by val.
        # We need to ignore passed $Instances if we want live refresh in loop,
        # or caller loops.
        # The pattern: this function is called once.
        # To support F5 refresh, we must loop here and refetch if needed.
        # But $Instances is a param.
        # If we want cache usage, we should fetch inside if null?
        # User refactor request implied using Get-CachedRDSInstances.
        [string]$Title = "Select Instance"
    )

    # Initial fetch if passed $Instances is null or we want to use cache primarily?
    # The caller usually passes Get-RDSInstances.
    # We will override $Instances with cache if we are in the loop.

    $currentItems = if ($Instances) { $Instances } else { Get-CachedRDSInstances }
    if (!$currentItems) { return $null }

    $header = {
        param($SearchString, $TotalItems, $FilteredCount)
        $lines = @(Get-Header-Lines)
        $lines += Get-AnsiString "$Title" -Color Cyan
        $lines += Get-AnsiString "Search filter: $SearchString_" -Color Yellow
        $lines += Get-AnsiString "Showing $FilteredCount / $TotalItems items" -Color DarkGray
        $lines += Get-AnsiString "--------------------------------------------------" -Color DarkGray
        return $lines
    }.GetNewClosure()

    while ($true) {
        $result = Invoke-InteractiveViewportSelection -Items $currentItems -HeaderContent $header -FilterProperties @("DBInstanceIdentifier", "Engine")

        if ($result -eq -98) {
            # Refresh
            $currentItems = Get-CachedRDSInstances -Force
            continue
        }

        return $result
    }
}

function Check-SSOSession {
    <#
    .DESCRIPTION
    Checks if the SSO session is valid. If not, prompts to login.
    #>
    Write-Log "Checking AWS SSO session for '$global:AWSProfile'..." -ForegroundColor Gray
    try {
        # sts get-caller-identity verifies if we have valid credentials
        aws sts get-caller-identity --profile $global:AWSProfile > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "STS check failed (exit code: $LASTEXITCODE)"
        }
    } catch {
        Write-Log "Session expired or invalid." -ForegroundColor Yellow
        $resp = Read-Host "Do you want to run 'aws sso login' now? (Y/n)"
        if ($resp -ne 'n') {
            aws sso login --profile $global:AWSProfile
        }
    }
}

function Remove-AWSProfile-Interactive {
    Write-Log "Fetching profiles to delete..." -ForegroundColor Green
    try {
        $profilesRaw = aws configure list-profiles
        if ($profilesRaw -is [string]) { $profiles = @($profilesRaw) }
        elseif ($profilesRaw -is [Array]) { $profiles = $profilesRaw }
        else { $profiles = @() }
    } catch { return }

    if ($profiles.Count -eq 0) {
        Write-Host "No profiles found." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }

    $profiles += "Cancel"
    $idx = Show-Menu -Title "Select Profile to DELETE" -Options $profiles -EnableFilter

    if ($idx -lt 0 -or $idx -eq ($profiles.Count - 1)) { return }

    $profileToDelete = $profiles[$idx]

    # Lepiej zapytac dwa razy niz zalowac / Better ask twice than sorry
    $confirm = Read-Host "Are you sure you want to delete profile '$profileToDelete'? (Type 'DELETE' to confirm)"
    if ($confirm -ne "DELETE") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        return
    }

    # Locate .aws directory
    $awsPath = Get-AWSDirectoryPath

    $configFile = Join-Path $awsPath "config"
    $credsFile = Join-Path $awsPath "credentials"

    $files = @($configFile, $credsFile)
    $removedAny = $false

    foreach ($file in $files) {
        if (Test-Path $file) {
            try {
                $lines = Get-Content $file
                $newLines = @()
                $skip = $false
                $foundInFile = $false

                foreach ($line in $lines) {
                    # Match [profile name] or [name]
                    # Regex escape is important for names with dots etc
                    if ($line -match "^\[(profile\s+)?$([regex]::Escape($profileToDelete))\]\s*$") {
                        $skip = $true
                        $foundInFile = $true
                        continue
                    }

                    if ($skip) {
                        # If we encounter next section start [..., stop skipping
                        if ($line -match "^\[.*\]") {
                            $skip = $false
                            $newLines += $line
                        }
                        # Else: skip properties of the deleted profile
                    } else {
                        $newLines += $line
                    }
                }

                if ($foundInFile) {
                    Set-Content -Path $file -Value $newLines -Force
                    Write-Host "Removed from $file" -ForegroundColor Cyan
                    $removedAny = $true
                }
            } catch {
                Write-Host "Error editing $($file): $_" -ForegroundColor Red
            }
        }
    }

    if ($removedAny) {
        Write-Host "Profile '$profileToDelete' successfully deleted." -ForegroundColor Green
    } else {
        Write-Host "Profile not found in config/credentials files (it might be environment variable based?)." -ForegroundColor Yellow
    }
    Read-Host "Press Enter..."
}

function Get-AWSConfigData {
    # Parse .aws/config to get sessions and roles
    $data = @{
        Sessions = @{} # SessionName -> List of Profiles
        Roles = @{}    # ProfileName -> RoleName
        Metadata = @{} # ProfileName -> { Env, Type }
    }

    $awsPath = Get-AWSDirectoryPath
    $configFile = Join-Path $awsPath "config"

    if (Test-Path $configFile) {
        $content = Get-Content $configFile
        $currentProfile = $null
        $sourceProfiles = @{} # ChildProfile -> ParentProfile

        foreach ($line in $content) {
            $line = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#") -or $line.StartsWith(";")) { continue }

            # Check for section headers
            if ($line -match "^\[(?<header>.*)\]$") {
                $header = $matches['header'].Trim()
                if ($header -eq "default") {
                    $currentProfile = "default"
                } elseif ($header -match "^profile\s+(?<name>.+)") {
                    $currentProfile = $matches['name'].Trim()
                } else {
                    # Any other section (e.g. sso-session) resets the context so we don't map properties wrongly
                    $currentProfile = $null
                }
                continue
            }

            if ($currentProfile) {
                if ($line -match "^sso_session\s*=\s*(?<val>.+)") {
                    $session = $matches['val'].Trim()
                    if (-not $data.Sessions.ContainsKey($session)) {
                        $data.Sessions[$session] = @()
                    }
                    # Avoid duplicates
                    if (-not ($data.Sessions[$session] -contains $currentProfile)) {
                        $data.Sessions[$session] += $currentProfile
                    }
                } elseif ($line -match "^source_profile\s*=\s*(?<val>.+)") {
                    $source = $matches['val'].Trim()
                    $sourceProfiles[$currentProfile] = $source
                } elseif ($line -match "^sso_role_name\s*=\s*(?<val>.+)") {
                    $data.Roles[$currentProfile] = $matches['val'].Trim()
                } elseif ($line -match "^env\s*=\s*(?<val>.+)") {
                    if (-not $data.Metadata.ContainsKey($currentProfile)) { $data.Metadata[$currentProfile] = @{} }
                    $data.Metadata[$currentProfile]['Env'] = $matches['val'].Trim()
                } elseif ($line -match "^type\s*=\s*(?<val>.+)") {
                    if (-not $data.Metadata.ContainsKey($currentProfile)) { $data.Metadata[$currentProfile] = @{} }
                    $data.Metadata[$currentProfile]['Type'] = $matches['val'].Trim()
                }
            }
        }

        # Second Pass: Resolve Source Profiles
        foreach ($child in $sourceProfiles.Keys) {
            $parent = $sourceProfiles[$child]
            # Find which session the parent belongs to
            foreach ($session in $data.Sessions.Keys) {
                if ($data.Sessions[$session] -contains $parent) {
                    # Add child to the same session
                    if (-not ($data.Sessions[$session] -contains $child)) {
                        $data.Sessions[$session] += $child
                    }
                    break
                }
            }
        }
    }
    return $data
}

# niespodzianka, a myslales ze znajdziesz tu ai?

function Select-Client-Session {
    Write-Log "Reading AWS Configuration..." -ForegroundColor Green
    $configData = Get-AWSConfigData

    # Ensure array even if single session
    $sessions = @($configData.Sessions.Keys | Sort-Object)
    if ($sessions.Count -eq 0) {
        return $null # No sessions found, fall back to listing all profiles
    }

    $options = @($sessions)
    $options += "Show All Profiles"

    $idx = Show-Menu -Title "Select Client (SSO Session)" -Options $options -EnableFilter

    if ($idx -eq ($options.Count - 1)) { return $null } # Show All
    if ($idx -lt 0) { exit } # Cancel

    $selectedSession = $sessions[$idx]
    return @{
        SessionName = $selectedSession
        Profiles = $configData.Sessions[$selectedSession]
        ConfigData = $configData
    }
}

function Select-AWSProfile {
    # 1. Select Session
    $sessionInfo = Select-Client-Session

    Write-Log "Loading AWS Profiles..." -ForegroundColor Green
    try {
        $allProfiles = aws configure list-profiles
        if ($allProfiles -is [string]) { $allProfiles = @($allProfiles) }
        elseif ($allProfiles -is [Array]) { }
        else { $allProfiles = @() }
    } catch {
        Write-Log "Error listing profiles: $_" -ForegroundColor Red
        $allProfiles = @()
    }

    # Store config metadata globally for header use
    if ($sessionInfo) {
        $global:AWSConfigMetadata = $sessionInfo.ConfigData.Metadata
    } else {
        # Cache AWS config data to avoid re-parsing
        if (!$global:AWSConfigDataCache) {
            $global:AWSConfigDataCache = Get-AWSConfigData
        }
        $global:AWSConfigMetadata = $global:AWSConfigDataCache.Metadata
    }

    # 2. Filter Profiles if session selected
    if ($sessionInfo) {
        # Filter allProfiles to only those in sessionInfo.Profiles
        $filteredProfiles = $allProfiles | Where-Object { $sessionInfo.Profiles -contains $_ }
        $displayProfilesRaw = @($filteredProfiles)
    } else {
        $displayProfilesRaw = $allProfiles
    }

    # Create Color-Coded Options
    # Kolorki dla lepszej czytelnosci / Colors for better readability
    $displayProfiles = @()
    foreach ($prof in $displayProfilesRaw) {
        $meta = if ($global:AWSConfigMetadata.ContainsKey($prof)) { $global:AWSConfigMetadata[$prof] } else { $null }
        $type = if ($meta -and $meta.Type) { $meta.Type } else { "" }
        $env = if ($meta -and $meta.Env) { $meta.Env } else { "" }

        $color = Get-ProfileColor -ProfileName $prof -Type $type -Env $env

        $label = $prof
        if ($env -or $type) { $label += " [$env / $type]" }

        $displayProfiles += [PSCustomObject]@{ Label = $label; Color = $color; Value = $prof }
    }

    # Add options
    $displayProfiles += "Add New Profile (aws configure sso)"
    $displayProfiles += "Delete Profile"
    $displayProfiles += "Back/Exit"

    $title = if ($sessionInfo) { "Select AWS Profile (Client: $($sessionInfo.SessionName))" } else { "Select AWS Profile" }
    $idx = Show-Menu -Title $title -Options $displayProfiles -EnableFilter
    
    # Exit/Back
    if ($idx -eq -1 -or $idx -eq ($displayProfiles.Count - 1)) {
        if ($sessionInfo) { return "__RESTART__" } # Signal outer loop to restart
        try { [Console]::CursorVisible = $true } catch {}
        exit
    }

    # Delete Profile
    if ($idx -eq ($displayProfiles.Count - 2)) {
        Remove-AWSProfile-Interactive
        return "__RESTART__" # Reload profiles after deletion
    }

    # Add New Profile
    if ($idx -eq ($displayProfiles.Count - 3)) {
        try { [Console]::CursorVisible = $true } catch {}
        Clear-Host
        Write-Log "Starting AWS SSO Configuration..." -ForegroundColor Cyan
        aws configure sso
        Write-Log "Configuration complete." -ForegroundColor Green
        Read-Host "Press Enter to reload profiles..."
        return "__RESTART__" # Signal outer loop to reload instead of recursive call
    }
    
    $selectedItem = $displayProfiles[$idx]
    if ($selectedItem -is [string]) {
        # Fallback for simple strings (Add New / Delete) - though we handled index logic above
        $global:AWSProfile = $selectedItem
    } else {
        $global:AWSProfile = $selectedItem.Value
    }

    # Update Window Title
    # Format: Client | Profile - Role
    $clientName = if ($sessionInfo) { $sessionInfo.SessionName } else { "UnknownClient" }

    # Try to find role if we have config data, otherwise parse again or skip
    $roleName = "UnknownRole"
    if ($sessionInfo -and $sessionInfo.ConfigData.Roles.ContainsKey($global:AWSProfile)) {
        $roleName = $sessionInfo.ConfigData.Roles[$global:AWSProfile]
    } else {
        # Fallback parsing if we didn't get session info (e.g. Show All)
        $tempData = Get-AWSConfigData
        if ($tempData.Roles.ContainsKey($global:AWSProfile)) {
            $roleName = $tempData.Roles[$global:AWSProfile]
        }
        # Try to find session if missing
        if ($clientName -eq "UnknownClient") {
             foreach ($key in $tempData.Sessions.Keys) {
                 if ($tempData.Sessions[$key] -contains $global:AWSProfile) {
                     $clientName = $key
                     break
                 }
             }
        }
    }

    $Host.UI.RawUI.WindowTitle = "$clientName | $global:AWSProfile - $roleName"

    Check-SSOSession
}

function Export-Report {
    param (
        [array]$Data,
        [string]$DefaultFileName
    )

    if (!$Data -or $Data.Count -eq 0) { return }

    $userInput = Read-Host "Press Enter to menu, or 'E' to export data"
    if ($userInput -eq 'E' -or $userInput -eq 'e') {
        Write-Host "`nSelect Export Format:"
        Write-Host "1. CSV"
        Write-Host "2. HTML"
        $format = Read-Host "Select (1/2)"

        $ext = ""
        if ($format -eq "1") { $ext = ".csv" }
        elseif ($format -eq "2") { $ext = ".html" }
        else {
            Write-Host "Invalid format. Export cancelled." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        $defaultPath = ".\$DefaultFileName$ext"
        $path = Read-Host "Enter output file path (default: $defaultPath)"
        if ([string]::IsNullOrWhiteSpace($path)) { $path = $defaultPath }

        try {
            # Eksport do CSV jest kluczowy / CSV export is crucial
            if ($format -eq "1") {
                $Data | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
            } elseif ($format -eq "2") {
                $Data | ConvertTo-Html | Out-File -FilePath $path -Encoding UTF8
            }
            Write-Host "Exported successfully to $path" -ForegroundColor Green
        } catch {
            Write-Host "Export failed: $_" -ForegroundColor Red
        }
        Read-Host "Press Enter to menu..."
    }
}

# --- EC2 WRAPPERS AND FUNCTIONS ---

function Get-EC2Instances {
    Write-Log "Fetching EC2 Instances..." -ForegroundColor Green
    try {
        $argsList = @("ec2", "describe-instances", "--output", "json", "--profile", $global:AWSProfile)
        $output = Invoke-AWS-WithRetry -Arguments $argsList -ReturnJson
        $json = $output -join ""

        if ([string]::IsNullOrWhiteSpace($json)) { return @() }

        $data = $json | ConvertFrom-Json
        $instances = [System.Collections.Generic.List[object]]::new()
        if ($data.Reservations) {
            foreach ($res in $data.Reservations) {
                if ($res.Instances) { $res.Instances | ForEach-Object { $instances.Add($_) } }
            }
        }
        return @($instances)
    } catch {
        Write-Log "Error fetching EC2 instances: $_" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return @()
    }
}

function Select-ActiveEC2 {
    $instances = Get-EC2Instances
    if (!$instances) {
        Write-Host "No EC2 instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $options = @()
    foreach ($inst in $instances) {
        $nameTag = $inst.Tags | Where-Object { $_.Key -eq "Name" }
        $name = if ($nameTag) { $nameTag.Value } else { "(No Name)" }
        $state = if ($inst.State) { $inst.State.Name } else { "Unknown" }

        $options += "$name ($($inst.InstanceId)) [$state]"
    }
    $options += "Cancel"

    $idx = Show-Menu -Title "Select Active EC2 Instance" -Options $options -EnableFilter

    if ($idx -eq -1 -or $idx -eq ($options.Count - 1)) { return }

    $global:SelectedEC2 = $instances[$idx]

    # Update active display name for easier ref
    $nameTag = $global:SelectedEC2.Tags | Where-Object { $_.Key -eq "Name" }
    $name = if ($nameTag) { $nameTag.Value } else { $global:SelectedEC2.InstanceId }
    Write-Log "EC2 Selected: $name" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

function Show-EC2Reports {
    $instances = Get-EC2Instances
    if (!$instances) {
        Write-Host "No EC2 instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    Show-Header
    Write-Host "EC2 INSTANCE REPORT" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------------------------------"
    Write-Host ("{0,-30} {1,-15} {2,-15} {3,-20}" -f "Name", "Instance ID", "Status", "Type")
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray

    $exportData = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($inst in $instances) {
        $nameTag = $inst.Tags | Where-Object { $_.Key -eq "Name" }
        $name = if ($nameTag) { $nameTag.Value } else { "(No Name)" }
        $state = if ($inst.State) { $inst.State.Name } else { "Unknown" }

        Write-Host ("{0,-30} {1,-15} {2,-15} {3,-20}" -f $name, $inst.InstanceId, $state, $inst.InstanceType)

        $exportData.Add([PSCustomObject]@{
            Name = $name
            InstanceId = $inst.InstanceId
            Status = $state
            Type = $inst.InstanceType
            LaunchTime = $inst.LaunchTime
        })
    }
    Write-Host "--------------------------------------------------------------------------------"

    Export-Report -Data $exportData -DefaultFileName "EC2Report"
}

function Show-OtherEC2Reports {
    # Example: List instances by Availability Zone
    $instances = Get-EC2Instances
    if (!$instances) { return }

    Show-Header
    Write-Host "EC2 INSTANCES BY AVAILABILITY ZONE" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------"

    $grouped = $instances | Group-Object -Property {$_.Placement.AvailabilityZone}

    foreach ($g in $grouped) {
        Write-Host "Zone: $($g.Name) (Count: $($g.Count))" -ForegroundColor Cyan
        foreach ($inst in $g.Group) {
            $nameTag = $inst.Tags | Where-Object { $_.Key -eq "Name" }
            $name = if ($nameTag) { $nameTag.Value } else { $inst.InstanceId }
            Write-Host "  - $name ($($inst.InstanceId))"
        }
        Write-Host ""
    }

    Read-Host "Press Enter to menu..."
}

function Start-EC2-Interactive {
    if (!$global:SelectedEC2) {
        Write-Host "No active EC2 instance selected." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $id = $global:SelectedEC2.InstanceId
    Write-Host "Starting EC2 instance: $id" -ForegroundColor Green

    try {
        aws ec2 start-instances --instance-ids $id --profile $global:AWSProfile | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "EC2 start failed (exit code $LASTEXITCODE)" }
        Write-Host "Start command issued." -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to start instance: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

function Stop-EC2-Interactive {
    if (!$global:SelectedEC2) {
        Write-Host "No active EC2 instance selected." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $id = $global:SelectedEC2.InstanceId
    Write-Host "Stopping EC2 instance: $id" -ForegroundColor Red
    $confirm = Read-Host "Are you sure? (Type 'STOP' to confirm)"

    if ($confirm -eq "STOP") {
        try {
            aws ec2 stop-instances --instance-ids $id --profile $global:AWSProfile | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "EC2 stop failed (exit code $LASTEXITCODE)" }
            Write-Host "Stop command issued." -ForegroundColor Cyan
        } catch {
            Write-Host "Failed to stop ${id}: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Cancelled."
    }
    Read-Host "Press Enter to menu..."
}

function Create-EC2Snapshot-Interactive {
    # Creates snapshots for all volumes attached to the selected instance
    if (!$global:SelectedEC2) {
        Write-Host "No active EC2 instance selected." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $inst = $global:SelectedEC2
    $id = $inst.InstanceId

    # Get volumes
    $mappings = $inst.BlockDeviceMappings
    if (!$mappings) {
        Write-Host "No volumes attached to $id." -ForegroundColor Yellow
        Read-Host "Press Enter..."
        return
    }

    Show-Header
    Write-Host "Creating Snapshots for $id" -ForegroundColor Green
    $nameTag = $inst.Tags | Where-Object { $_.Key -eq "Name" }
    $instName = if ($nameTag) { $nameTag.Value } else { $id }

    foreach ($map in $mappings) {
        if ($map.Ebs) {
            $volId = $map.Ebs.VolumeId
            $desc = "Snapshot of $instName ($id) volume $volId via RDS/EC2 Tool"
            $defaultName = "snap-$instName-$volId-$(Get-TimeStamp)"

            Write-Host "Volume: $volId" -ForegroundColor Cyan
            try {
                aws ec2 create-snapshot --volume-id $volId --description "$desc" --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=$defaultName}]" --profile $global:AWSProfile | Out-Null
                Write-Host "  -> Snapshot initiated: $defaultName" -ForegroundColor Green
            } catch {
                Write-Host "  -> Failed: $_" -ForegroundColor Red
            }
        }
    }
    Read-Host "Press Enter to menu..."
}

function Remove-EC2Snapshot-Interactive {
    Show-Header
    Write-Host "Fetching your recent EC2 Snapshots (Owner: Self, limit 50)..." -ForegroundColor Green

    try {
        # Filter by Owner Self to avoid public snapshots
        $json = (aws ec2 describe-snapshots --owner-ids self --max-items 50 --output json --profile $global:AWSProfile) -join ""
        if ([string]::IsNullOrWhiteSpace($json)) {
            Write-Host "No snapshots found." -ForegroundColor Yellow
            Read-Host "Press Enter..."
            return
        }
        $data = $json | ConvertFrom-Json
        $snaps = $data.Snapshots

        if (!$snaps) {
            Write-Host "No snapshots found." -ForegroundColor Yellow
            Read-Host "Press Enter..."
            return
        }

        $options = @()
        foreach ($s in $snaps) {
            $nameTag = $s.Tags | Where-Object { $_.Key -eq "Name" }
            $name = if ($nameTag) { $nameTag.Value } else { "(No Name)" }
            $size = if ($s.VolumeSize) { "$($s.VolumeSize)GB" } else { "?GB" }
            $options += "$name ($($s.SnapshotId)) [$size]"
        }

        $selectedIndices = Show-Menu -Title "Select EC2 Snapshots to DELETE (SPACE to Select)" -Options $options -EnableFilter -MultiSelect

        if ($selectedIndices -eq $null -or $selectedIndices.Count -eq 0) { return }

        $confirm = Read-Host "Type 'DELETE' to confirm deletion of $($selectedIndices.Count) snapshot(s)"
        if ($confirm -eq "DELETE") {
            foreach ($idx in $selectedIndices) {
                $snapId = $snaps[$idx].SnapshotId
                Write-Host "Deleting $snapId..." -ForegroundColor Yellow
                try {
                    aws ec2 delete-snapshot --snapshot-id $snapId --profile $global:AWSProfile | Out-Null
                    Write-Host "Deleted." -ForegroundColor Green
                } catch {
                    Write-Host "Failed: $_" -ForegroundColor Red
                }
            }
        }

    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

function Monitor-RDS-State {
    Show-Header
    Write-Host "Monitoring RDS Instance States..." -ForegroundColor Yellow

    while ($true) {
        $instances = Get-CachedRDSInstances

        # Render Frame — use cursor repositioning instead of Clear-Host to avoid flicker
        try { [Console]::SetCursorPosition(0, 0) } catch {}
        $headerLines = Get-Header-Lines
        foreach ($hl in $headerLines) {
            [Console]::WriteLine((Pad-Line $hl))
        }
        Write-Host "REAL-TIME INSTANCE STATE MONITOR (Press ENTER/ESC to return | F5 to Refresh)" -ForegroundColor Cyan
        Write-Host "------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ("{0,-35} {1,-15} {2,-15} {3}" -f "Identifier", "Engine", "Status", "Endpoint")
        Write-Host "------------------------------------------------------------------------------------------------" -ForegroundColor DarkGray

        if ($instances) {
            foreach ($inst in $instances) {
                $status = $inst.DBInstanceStatus
                $color = "White"
                if ($status -eq "available") { $color = "Green" }
                elseif ($status -in @("stopped", "stopping")) { $color = "Red" }
                elseif ($status -in @("creating", "starting", "modifying", "rebooting")) { $color = "Yellow" }

                $endpoint = if ($inst.Endpoint) { $inst.Endpoint.Address } else { "-" }

                Write-Host ("{0,-35} {1,-15} {2,-15} {3}" -f $inst.DBInstanceIdentifier, $inst.Engine, $status, $endpoint) -ForegroundColor $color
            }
        } else {
            Write-Host "No instances found." -ForegroundColor Yellow
        }

        # Input Loop
        $loops = 100 # 10 seconds approx (100ms * 100)
        $refresh = $false

        if ($global:TEST_RUN_ONCE) { $loops = 0 }

        for ($i = 0; $i -lt $loops; $i++) {
            if ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq 'Enter' -or $k.Key -eq 'Escape') { return }
                if ($k.Key -eq 'F5') {
                    $refresh = $true
                    break
                }
            }
            Start-Sleep -Milliseconds 100
        }

        if ($refresh) {
            Get-CachedRDSInstances -Force | Out-Null
        }

        if ($global:TEST_RUN_ONCE) { break }
    }
}

function Show-RDS-Menu {
    while ($true) {
        if ($global:RestartSessionSelection) { return }

        $menuOptions = @(
            "Select Active Instance",
            "------------------------------------------",
            "Instance Reports",
            "Other Reports",
            "------------------------------------------",
            "Start Instance(s)",
            "Stop Instance(s)",
            "Delete Instance(s)",
            "Monitor Instance State",
            "------------------------------------------",
            "Create Snapshot",
            "Create Multiple Snapshots",
            "Delete Snapshots",
            "Active Snapshots Progress",
            "------------------------------------------",
            "Create Blue/Green Deployment",
            "Delete Blue/Green Deployment",
            "Monitor Deployment Status",
            "Upgrade Database Engine",
            "Update OS",
            "Execute Switchover",
            "Apply Pending Maintenance",
            "------------------------------------------",
            "Back to Main Menu"
        )

        $selection = Show-Menu -Title "RDS Management" -Options $menuOptions

        if ($global:RestartSessionSelection) { return }

        switch ($selection) {
            0 { Select-ActiveInstance }
            2 { Show-InstanceReports-Menu }
            3 { Show-OtherReports-Menu }
            5 { Start-RDS-Interactive }
            6 { Stop-RDS-Interactive }
            7 { Remove-RDS-Interactive }
            8 { Monitor-RDS-State }
            10 { New-RDSSnapshot-Interactive }
            11 { New-MultipleRDSSnapshots-Interactive }
            12 { Remove-RDSSnapshot-Interactive }
            13 { Monitor-Snapshot-Progress }
            15 { New-BGDeployment-Interactive }
            16 { Remove-BGDeployment-Interactive }
            17 { Monitor-BGStatus-Interactive }
            18 { Upgrade-Database-Interactive }
            19 { Update-OperatingSystem }
            20 { Invoke-Switchover-Interactive }
            21 { Apply-PendingMaintenance }
            23 { return }
        }
    }
}

function Show-EC2-Menu {
    while ($true) {
        if ($global:RestartSessionSelection) { return }

        $ec2Name = if ($global:SelectedEC2) {
            $t = $global:SelectedEC2.Tags | Where-Object { $_.Key -eq "Name" }
            if ($t) { $t.Value } else { $global:SelectedEC2.InstanceId }
        } else { "None" }

        $menuOptions = @(
            "Select Active EC2 (Current: $ec2Name)",
            "EC2 Reports",
            "Other Reports (Zones)",
            "Start EC2",
            "Stop EC2",
            "Create Snapshot",
            "Remove Snapshot",
            "Back to Main Menu"
        )

        $selection = Show-Menu -Title "EC2 Management" -Options $menuOptions

        if ($global:RestartSessionSelection) { return }

        switch ($selection) {
            0 { Select-ActiveEC2 }
            1 { Show-EC2Reports }
            2 { Show-OtherEC2Reports }
            3 { Start-EC2-Interactive }
            4 { Stop-EC2-Interactive }
            5 { Create-EC2Snapshot-Interactive }
            6 { Remove-EC2Snapshot-Interactive }
            7 { return }
        }
    }
}

# --- AWS WRAPPERS ---

function Get-RDSInstances {
    <#
    .DESCRIPTION
    Returns an array of RDS instance objects (uses cache for performance).
    #>
    return Get-CachedRDSInstances
}

function Get-BlueGreenDeployments {
    <#
    .DESCRIPTION
    Returns an array of Blue/Green deployment objects.
    #>
    Write-Log "Fetching Blue/Green Deployments..." -ForegroundColor Green
    try {
        $argsList = @("rds", "describe-blue-green-deployments", "--output", "json", "--profile", $global:AWSProfile)
        $output = Invoke-AWS-WithRetry -Arguments $argsList -ReturnJson
        $json = $output -join ""

        if ([string]::IsNullOrWhiteSpace($json)) { return @() }

        $data = $json | ConvertFrom-Json
        if (!$data.BlueGreenDeployments) { return @() }
        return $data.BlueGreenDeployments
    } catch {
        Write-Log "Error fetching BG deployments: $_" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return $null
    }
}

function Get-ManualSnapshotCount {
    <#
    .DESCRIPTION
    Returns the count of manual DB snapshots (Quota Check).
    #>
    Write-Log "Checking manual snapshot quota..." -ForegroundColor Cyan
    try {
        # Using --query "length(DBSnapshots)" to get count directly from server side
        $argsList = @("rds", "describe-db-snapshots", "--snapshot-type", "manual", "--query", "length(DBSnapshots)", "--output", "text", "--profile", $global:AWSProfile)

        # We don't use -ReturnJson because we want raw text
        $output = Invoke-AWS-WithRetry -Arguments $argsList

        $countStr = $output | Out-String
        if ([string]::IsNullOrWhiteSpace($countStr)) { return 0 }

        return [int]($countStr.Trim())
    } catch {
        Write-Log "Error checking snapshot count: $_" -ForegroundColor Red
        return 999 # Fail safe (assume full)
    }
}

# --- REPORTS FUNCTIONS ---

function Show-Instance-Details {
    $Instance = $global:SelectedInstance
    Show-Header
    Write-Host "INSTANCE DETAILS: $($Instance.DBInstanceIdentifier)" -ForegroundColor Yellow
    Write-Host "------------------------------------------"
    
    # Endpoint
    $endpoint = if ($Instance.Endpoint) { "$($Instance.Endpoint.Address):$($Instance.Endpoint.Port)" } else { "N/A" }
    Write-Host "Endpoint:        $endpoint" -ForegroundColor White
    
    # Engine
    Write-Host "Engine:          $($Instance.Engine) ($($Instance.EngineVersion))" -ForegroundColor White
    
    # Class
    Write-Host "Class:           $($Instance.DBInstanceClass)" -ForegroundColor White
    
    # Parameter Groups
    $pgs = if ($Instance.DBParameterGroups) { ($Instance.DBParameterGroups | ForEach-Object { $_.DBParameterGroupName }) -join ", " } else { "None" }
    Write-Host "Param Groups:    $pgs" -ForegroundColor White
    
    # Status
    Write-Host "Status:          $($Instance.DBInstanceStatus)" -ForegroundColor White
    
    # Replica Info / Lag
    if ($Instance.ReadReplicaSourceDBInstanceIdentifier) {
        Write-Host "Read Replica of: $($Instance.ReadReplicaSourceDBInstanceIdentifier)" -ForegroundColor Cyan
        Write-Host "Replica Lag:     (Check CloudWatch 'ReplicaLag' metric)" -ForegroundColor Gray
    } else {
        Write-Host "Replica Lag:     N/A (Not a Read Replica)" -ForegroundColor Gray
    }
    
    Write-Host "------------------------------------------"
    
    $exportObj = [PSCustomObject]@{
        DBInstanceIdentifier = $Instance.DBInstanceIdentifier
        Endpoint = $endpoint
        Engine = "$($Instance.Engine) ($($Instance.EngineVersion))"
        Class = $Instance.DBInstanceClass
        ParameterGroups = $pgs
        Status = $Instance.DBInstanceStatus
        ReplicaLag = if ($Instance.ReadReplicaSourceDBInstanceIdentifier) { "Check CloudWatch" } else { "N/A" }
    }
    
    Export-Report -Data @($exportObj) -DefaultFileName "InstanceDetails-$($Instance.DBInstanceIdentifier)"
}

function Show-RecentSnapshots {
    Show-Header
    $id = $global:SelectedInstance.DBInstanceIdentifier
    Write-Host "Fetching recent snapshots for $id..." -ForegroundColor Green
    
    try {
        $snapArgs = @("rds", "describe-db-snapshots", "--db-instance-identifier", $id, "--output", "json", "--profile", $global:AWSProfile)
        $snapOutput = Invoke-AWS-WithRetry -Arguments $snapArgs -ReturnJson
        $json = $snapOutput -join ""
        if ([string]::IsNullOrWhiteSpace($json)) { 
            Write-Host "No snapshots found." -ForegroundColor Yellow
            Pause
            return 
        }

        $data = $json | ConvertFrom-Json
        if (!$data.DBSnapshots) { 
            Write-Host "No snapshots found." -ForegroundColor Yellow
            Pause
            return 
        }

        $snaps = $data.DBSnapshots | Sort-Object SnapshotCreateTime -Descending | Select-Object -First 5
        
        Write-Host "LAST 5 SNAPSHOTS FOR $($id):" -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------"
        Write-Host ("{0,-35} {1,-20} {2,10}" -f "Identifier", "Create Time", "Size (GB)")
        Write-Host "------------------------------------------------------------" -ForegroundColor Gray
        
        foreach ($s in $snaps) {
            Write-Host ("{0,-35} {1,-20} {2,10}" -f $s.DBSnapshotIdentifier, $s.SnapshotCreateTime, $s.AllocatedStorage)
        }
        Write-Host "------------------------------------------------------------"
        
        Export-Report -Data $snaps -DefaultFileName "Snapshots-$id"
        return
    } catch {
        Write-Host "Error fetching snapshots: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

# niespodzianka, a myslales ze znajdziesz tu ai?

function Show-Last30DaysSnapshots {
    Show-Header
    $id = $global:SelectedInstance.DBInstanceIdentifier
    Write-Host "Fetching snapshots from the last 30 days for $id..." -ForegroundColor Green
    
    try {
        $snapArgs = @("rds", "describe-db-snapshots", "--db-instance-identifier", $id, "--output", "json", "--profile", $global:AWSProfile)
        $snapOutput = Invoke-AWS-WithRetry -Arguments $snapArgs -ReturnJson
        $json = $snapOutput -join ""
        if ([string]::IsNullOrWhiteSpace($json)) { 
            Write-Host "No snapshots found." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return 
        }

        $data = $json | ConvertFrom-Json
        if (!$data.DBSnapshots) { 
            Write-Host "No snapshots found." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return 
        }

        # Filter last 30 days
        $cutoff = (Get-Date).AddDays(-30)
        
        $snaps = $data.DBSnapshots | Where-Object { 
            try { [datetime]$_.SnapshotCreateTime -ge $cutoff } catch { $false }
        } | Sort-Object SnapshotCreateTime -Descending
        
        if (!$snaps) {
            Write-Host "No snapshots found in the last 30 days." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        Write-Host "SNAPSHOTS (LAST 30 DAYS) FOR $($id):" -ForegroundColor Yellow
        Write-Host "------------------------------------------------------------"
        Write-Host ("{0,-35} {1,-20} {2,10}" -f "Identifier", "Create Time", "Size (GB)")
        Write-Host "------------------------------------------------------------" -ForegroundColor Gray
        
        foreach ($s in $snaps) {
            Write-Host ("{0,-35} {1,-20} {2,10}" -f $s.DBSnapshotIdentifier, $s.SnapshotCreateTime, $s.AllocatedStorage)
        }
        Write-Host "------------------------------------------------------------"
        
        Export-Report -Data $snaps -DefaultFileName "Snapshots-30Days-$id"
        return
    } catch {
        Write-Host "Error fetching snapshots: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

function Show-BGReplicaLag {
    Show-Header
    $id = $global:SelectedInstance.DBInstanceIdentifier
    Write-Host "Fetching Blue/Green Replica Lag for Source: $id..." -ForegroundColor Green
    
    $bgs = Get-BlueGreenDeployments
    if (!$bgs) {
        Write-Host "No active Blue/Green deployments found." -ForegroundColor Yellow
        Pause
        return
    }

    # Find if selected instance is Source in any BG deployment
    $foundBG = $null
    foreach ($bg in $bgs) {
        if ($bg.Source -match ":db:$id$") {
            $foundBG = $bg
            break
        }
    }

    if (!$foundBG) {
        Write-Host "Selected instance '$id' is NOT the Source of any active Blue/Green Deployment." -ForegroundColor Yellow
        Pause
        return
    }

    $endTime = Get-Date
    $startTime = $endTime.AddMinutes(-10)
    $endStr = $endTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $startStr = $startTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Extract DB Identifier from Target ARN
    if ($foundBG.Target -match ":db:(.+)$") {
        $targetId = $matches[1]
    } else {
        $targetId = "Unknown"
    }

    $lag = "N/A"
    if ($targetId -ne "Unknown") {
        try {
            $metricArgs = @("cloudwatch", "get-metric-statistics", "--namespace", "AWS/RDS", "--metric-name", "ReplicaLag", "--dimensions", "Name=DBInstanceIdentifier,Value=$targetId", "--start-time", $startStr, "--end-time", $endStr, "--period", "600", "--statistics", "Maximum", "--output", "json", "--profile", $global:AWSProfile)
            $metricOutput = Invoke-AWS-WithRetry -Arguments $metricArgs -ReturnJson
            $metricJson = $metricOutput -join ""
            if (![string]::IsNullOrWhiteSpace($metricJson)) {
                $metricData = $metricJson | ConvertFrom-Json
                if ($metricData.Datapoints) {
                    $point = $metricData.Datapoints | Sort-Object Timestamp -Descending | Select-Object -First 1
                    $lag = $point.Maximum
                } else {
                    $lag = "No Data"
                }
            }
        } catch {
            $lag = "Error"
        }
    }

    Write-Host "BG Deployment:  $($foundBG.BlueGreenDeploymentName)" -ForegroundColor White
    Write-Host "Green DB:       $targetId" -ForegroundColor White
    Write-Host "Replica Lag:    $lag seconds" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------------------"
    
    $exportObj = [PSCustomObject]@{
        BGDeployment = $foundBG.BlueGreenDeploymentName
        SourceDB = $id
        GreenDB = $targetId
        ReplicaLagSeconds = $lag
    }
    Export-Report -Data @($exportObj) -DefaultFileName "ReplicaLag-$id"
}

function View-LogContent {
    param (
        [string]$LogFileName,
        [string]$InstanceIdentifier
    )
    
    $lines = Read-Host "Enter number of last lines to view (default: 20)"
    if ([string]::IsNullOrWhiteSpace($lines)) { $lines = 20 }
    else { try { $lines = [int]$lines } catch { $lines = 20 } }
    
    Write-Host "Downloading log '$LogFileName'..." -ForegroundColor Green
    
    try {
        # download-db-log-file-portion returns text.
        # We handle pagination loosely here by just grabbing the default (which is usually start-to-end or large chunk).
        # For huge files, this might be slow, but for typical error logs it's okay.
        $content = aws rds download-db-log-file-portion --db-instance-identifier $InstanceIdentifier --log-file-name $LogFileName --output text --profile $global:AWSProfile
        
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Host "Log file is empty." -ForegroundColor Yellow
        } else {
            $logLines = $content -split "`n"
            $count = $logLines.Count
            
            $start = $count - $lines
            if ($start -lt 0) { $start = 0 }
            
            Write-Host "`n--- LAST $lines LINES OF $LogFileName ---" -ForegroundColor Cyan
            for ($i = $start; $i -lt $count; $i++) {
                Write-Host $logLines[$i]
            }
            Write-Host "--- END OF LOG PREVIEW ---`n" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "Failed to download log: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

function Show-DatabaseLogs {
    $selectedID = $global:SelectedInstance.DBInstanceIdentifier
    
    while ($true) {
        Show-Header
        Write-Host "Fetching logs for $selectedID (Last 10)..." -ForegroundColor Green

        try {
            $logArgs = @("rds", "describe-db-log-files", "--db-instance-identifier", $selectedID, "--output", "json", "--profile", $global:AWSProfile)
            $logOutput = Invoke-AWS-WithRetry -Arguments $logArgs -ReturnJson
            $json = $logOutput -join ""
            if ([string]::IsNullOrWhiteSpace($json)) { 
                Write-Host "No logs found." -ForegroundColor Yellow
                Read-Host "Press Enter to menu..."
                return
            }

            $data = $json | ConvertFrom-Json
            if (!$data.DescribeDBLogFiles) {
                Write-Host "No logs returned." -ForegroundColor Yellow
                Read-Host "Press Enter to menu..."
                return
            }
            
            $logs = $data.DescribeDBLogFiles | Sort-Object LastWritten -Descending | Select-Object -First 10
            
            # Create menu options
            $options = @()
            $epoch = Get-Date -Date "1970-01-01 00:00:00Z"
            
            foreach ($log in $logs) {
                $sizeKB = [math]::Round($log.Size / 1024, 2)
                $date = $epoch.AddMilliseconds($log.LastWritten).ToLocalTime()
                
                # Format label for menu
                # Using fixed width in label might break alignment if font is not monospace, but we try.
                $label = "{0,-45} | {1,10} KB | {2}" -f $log.LogFileName, $sizeKB, $date
                $options += $label
            }
            $options += "Export List"
            $options += "Back"
            
            $idx = Show-Menu -Title "Select Log File to View" -Options $options
            
            # Back/Exit
            if ($idx -eq -1 -or $idx -eq ($options.Count - 1)) { return }
            
            # Export List
            if ($idx -eq ($options.Count - 2)) {
                Export-Report -Data $logs -DefaultFileName "LogList-$selectedID"
                continue
            }
            
            $selectedLog = $logs[$idx]
            View-LogContent -LogFileName $selectedLog.LogFileName -InstanceIdentifier $selectedID

        } catch {
            Write-Host "Error fetching logs: $_" -ForegroundColor Red
            Read-Host "Press Enter to menu..."
            return
        }
        
    }
}

function Show-RDSEvents {
    $selectedID = $global:SelectedInstance.DBInstanceIdentifier
    Show-Header
    Write-Host "Fetching RDS Events for $selectedID (Last 24 Hours)..." -ForegroundColor Green
    
    try {
        $evArgs = @("rds", "describe-events", "--source-identifier", $selectedID, "--source-type", "db-instance", "--duration", "1440", "--output", "json", "--profile", $global:AWSProfile)
        $evOutput = Invoke-AWS-WithRetry -Arguments $evArgs -ReturnJson
        $json = $evOutput -join ""
        if ([string]::IsNullOrWhiteSpace($json)) { 
            Write-Host "No events found." -ForegroundColor Yellow
        } else {
            $data = $json | ConvertFrom-Json
            if ($data.Events) {
                Write-Host ("{0,-25} {1,-30} {2}" -f "Time", "Source ID", "Message")
                Write-Host "---------------------------------------------------------------------------------------" -ForegroundColor Gray
                
                $exportData = [System.Collections.Generic.List[PSCustomObject]]::new()
                foreach ($ev in $data.Events) {
                    Write-Host ("{0,-25} {1,-30} {2}" -f $ev.Date, $ev.SourceIdentifier, $ev.Message)
                    
                    $categories = if ($ev.EventCategories) { $ev.EventCategories -join ", " } else { "" }
                    $exportData.Add([PSCustomObject]@{
                        Date = $ev.Date
                        SourceIdentifier = $ev.SourceIdentifier
                        Message = $ev.Message
                        EventCategories = $categories
                    })
                }
                Write-Host "---------------------------------------------------------------------------------------"
                
                Export-Report -Data $exportData -DefaultFileName "Events-$selectedID"
                return
            } else {
                Write-Host "No events found in the last 24 hours." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "Error fetching events: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

function Show-PendingMaintenance {
    Show-Header
    Write-Host "Fetching Pending Maintenance Actions..." -ForegroundColor Green
    
    try {
        $mntArgs = @("rds", "describe-pending-maintenance-actions", "--output", "json", "--profile", $global:AWSProfile)
        $mntOutput = Invoke-AWS-WithRetry -Arguments $mntArgs -ReturnJson
        $json = $mntOutput -join ""
        if ([string]::IsNullOrWhiteSpace($json)) {
            Write-Host "No pending maintenance actions found." -ForegroundColor Yellow
        } else {
            $data = $json | ConvertFrom-Json
            if ($data.PendingMaintenanceActions) {
                Write-Host ("{0,-30} {1,-20} {2}" -f "Instance ID", "Action", "Description")
                Write-Host "---------------------------------------------------------------------------------------" -ForegroundColor Gray
                
                $exportData = [System.Collections.Generic.List[PSCustomObject]]::new()
                foreach ($item in $data.PendingMaintenanceActions) {
                    # Extract Instance ID from ARN
                    $instanceId = Get-InstanceIdFromArn $item.ResourceIdentifier
                    
                    # Flatten details for export
                    foreach ($detail in $item.PendingMaintenanceActionDetails) {
                        Write-Host ("{0,-30} {1,-20} {2}" -f $instanceId, $detail.Action, $detail.Description)
                    }
                    $detailsText = $item.PendingMaintenanceActionDetails | ForEach-Object { "$($_.Action): $($_.Description)" }
                    
                    $exportData.Add([PSCustomObject]@{
                        InstanceID = $instanceId
                        ResourceIdentifier = $item.ResourceIdentifier
                        Details = $detailsText -join "; "
                    })
                }
                Write-Host "---------------------------------------------------------------------------------------"
                
                Export-Report -Data $exportData -DefaultFileName "PendingMaintenance"
                return
            } else {
                Write-Host "No pending maintenance actions found." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "Error fetching maintenance info: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

function Show-DBAllDetails {
    $instances = Get-RDSInstances
    if (!$instances) { 
        Write-Host "No instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return 
    }
    
    Show-Header
    Write-Host "DB ALL DETAILS (Versions, Storage, Backup)" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------------------"
    Write-Host ("{0,-30} {1,-15} {2,-10} {3,-20} {4,-10}" -f "Identifier", "Engine", "Version", "Storage", "Backup(d)")
    Write-Host "------------------------------------------------------------------------------------------------" -ForegroundColor Gray
    
    foreach ($inst in $instances) {
        $storage = "$($inst.StorageType) ($($inst.AllocatedStorage)GB)"
        $backup = if ($inst.BackupRetentionPeriod -ne $null) { $inst.BackupRetentionPeriod } else { "0" }
        
        Write-Host ("{0,-30} {1,-15} {2,-10} {3,-20} {4,-10}" -f $inst.DBInstanceIdentifier, $inst.Engine, $inst.EngineVersion, $storage, $backup)
    }
    Write-Host "------------------------------------------------------------------------------------------------"
    
    Export-Report -Data $instances -DefaultFileName "DBAllDetails"
}

function Show-DBVersionsCompact {
    $instances = Get-RDSInstances
    if (!$instances) { 
        Write-Host "No instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return 
    }
    
    Show-Header
    Write-Host "DB VERSIONS (Compact)" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------------------"
    Write-Host ("{0,-35} {1,-15} {2,-10} {3}" -f "Identifier", "Engine", "Version", "AutoMinorUpgrade")
    Write-Host "------------------------------------------------------------------------------------------------" -ForegroundColor Gray
    
    $exportData = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($inst in $instances) {
        $auto = if ($inst.AutoMinorVersionUpgrade) { "True" } else { "False" }
        Write-Host ("{0,-35} {1,-15} {2,-10} {3}" -f $inst.DBInstanceIdentifier, $inst.Engine, $inst.EngineVersion, $auto)
        
        $exportData.Add([PSCustomObject]@{
            DBInstanceIdentifier = $inst.DBInstanceIdentifier
            Engine = $inst.Engine
            EngineVersion = $inst.EngineVersion
            AutoMinorVersionUpgrade = $inst.AutoMinorVersionUpgrade
        })
    }
    Write-Host "------------------------------------------------------------------------------------------------"
    
    Export-Report -Data $exportData -DefaultFileName "DBVersionsCompact"
}

function Show-RDSRecommendations {
    Show-Header
    Write-Host "Fetching RDS Recommendations (Compute Optimizer)..." -ForegroundColor Green

    # 1. Fetch Instances
    $instances = Get-RDSInstances
    if (!$instances) {
        Write-Host "No instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    # 2. Fetch Recommendations
    try {
        $argsList = @("compute-optimizer", "get-rds-database-recommendations", "--output", "json", "--profile", $global:AWSProfile)
        $output = Invoke-AWS-WithRetry -Arguments $argsList -ReturnJson
        $json = $output -join ""

        if ([string]::IsNullOrWhiteSpace($json)) {
            Write-Host "No recommendations returned (Response empty)." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        $recData = $json | ConvertFrom-Json
        $recommendations = $recData.rdsDatabaseRecommendations

        if (!$recommendations) {
            Write-Host "No active recommendations found." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }
    } catch {
        Write-Host "Error fetching recommendations: $_" -ForegroundColor Red
        Write-Host "Ensure Compute Optimizer is enabled in this region/account." -ForegroundColor DarkGray
        Read-Host "Press Enter to menu..."
        return
    }

    # 3. Join and Display
    Show-Header
    Write-Host "RDS RECOMMENDATIONS (Compute Optimizer)" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------------------------------------------------"
    Write-Host ("{0,-30} {1,-15} {2,-10} {3,-20} {4,-20} {5}" -f "Identifier", "Current Class", "Engine", "Finding", "Recommendation", "Reason")
    Write-Host "------------------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray

    $exportData = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($inst in $instances) {
        # Find matching recommendation by ARN
        $arn = $inst.DBInstanceArn
        $rec = $recommendations | Where-Object { $_.resourceArn -eq $arn } | Select-Object -First 1

        $finding = "No Data"
        $recClass = "-"
        $reason = "-"
        $color = "Gray"

        if ($rec) {
            $finding = $rec.finding

            # Extract first recommendation option if available
            if ($rec.recommendationOptions -and $rec.recommendationOptions.Count -gt 0) {
                $recClass = $rec.recommendationOptions[0].dbInstanceClass
            }

            # Extract reasons
            if ($rec.findingReasonCodes) {
                $reason = $rec.findingReasonCodes -join ", "
            }

            # Color Logic
            switch ($finding) {
                "Optimized" { $color = "Green" }
                "OverProvisioned" { $color = "Yellow" } # API returns OverProvisioned (PascalCase usually)
                "UnderProvisioned" { $color = "Red" }
                Default { $color = "White" }
            }
        }

        Write-Host ("{0,-30} {1,-15} {2,-10} {3,-20} {4,-20} {5}" -f $inst.DBInstanceIdentifier, $inst.DBInstanceClass, $inst.Engine, $finding, $recClass, $reason) -ForegroundColor $color

        $exportData.Add([PSCustomObject]@{
            Identifier = $inst.DBInstanceIdentifier
            CurrentClass = $inst.DBInstanceClass
            Engine = $inst.Engine
            Finding = $finding
            Recommendation = $recClass
            Reason = $reason
        })
    }
    Write-Host "------------------------------------------------------------------------------------------------------------------------"

    Export-Report -Data $exportData -DefaultFileName "RDSRecommendations"
    Read-Host "Press Enter to menu..."
}

function Show-InstanceReports-Menu {
    if (!$global:SelectedInstance) {
        Write-Host "No active instance selected. Please select an instance first." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    while ($true) {
        $menuOptions = @("Details", "Recent Snapshots (Last 5)", "Last 30 Days Snapshots", "Blue/Green Replica Lag", "Database Logs (Last 10)", "RDS Events (Last 24h)", "Back")
        $sel = Show-Menu -Title "Instance Reports: $($global:SelectedInstance.DBInstanceIdentifier)" -Options $menuOptions
        
        switch ($sel) {
            0 { Show-Instance-Details }
            1 { Show-RecentSnapshots }
            2 { Show-Last30DaysSnapshots }
            3 { Show-BGReplicaLag }
            4 { Show-DatabaseLogs }
            5 { Show-RDSEvents }
            6 { return }
        }
    }
}

function Show-OtherReports-Menu {
    while ($true) {
        $menuOptions = @("Pending OS Upgrade", "DB All Details", "DB Versions (Compact)", "Recommendation list", "Back")
        $sel = Show-Menu -Title "Other Reports" -Options $menuOptions
        
        switch ($sel) {
            0 { Show-PendingMaintenance }
            1 { Show-DBAllDetails }
            2 { Show-DBVersionsCompact }
            3 { Show-RDSRecommendations }
            4 { return }
        }
    }
}

# --- INTERACTIVE FUNCTIONS ---

function Select-ActiveInstance {
    $instances = Get-RDSInstances
    if (!$instances) { 
        Write-Host "No instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return 
    }
    
    # Fetch BGs to identify roles
    $bgs = Get-BlueGreenDeployments

    $options = @()
    $instances | ForEach-Object {
        $role = Get-Instance-BG-Role -InstanceIdentifier $_.DBInstanceIdentifier -BGDeployments $bgs
        $label = "$($_.DBInstanceIdentifier) ($($_.Engine)) [$($_.DBInstanceStatus)]"
        
        if ($role) {
            $label += " [$role]"
            $options += [PSCustomObject]@{ Label = $label; Color = "Green" }
        } else {
            $options += [PSCustomObject]@{ Label = $label; Color = "Gray" }
        }
    }
    $options += "Cancel"
    
    $idx = Show-Menu -Title "Select Active Instance" -Options $options -EnableFilter
    
    if ($idx -eq -1 -or $idx -eq ($options.Count - 1)) { return } # Cancel or ESC
    
    $global:SelectedInstance = $instances[$idx]
    Write-Log "Instance Selected: $($global:SelectedInstance.DBInstanceIdentifier)" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

function New-RDSSnapshot-Interactive {
    if (!$global:SelectedInstance) {
        Write-Log "No active instance selected. Please select an instance first." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $selectedID = $global:SelectedInstance.DBInstanceIdentifier

    # --- QUOTA CHECK ---
    $maxManualSnapshots = 100
    $requiredSlots = 1

    while ($true) {
        $currentCount = Get-ManualSnapshotCount

        if (($currentCount + $requiredSlots) -le $maxManualSnapshots) {
            Write-Log "Quota Check Passed: $currentCount manual snapshots used. Slots available." -ForegroundColor Green
            break
        } else {
            Write-Host "WARNING: AWS Quota Limit Reached!" -ForegroundColor Red
            Write-Host "You have $currentCount manual snapshots (Limit: $maxManualSnapshots). You need $requiredSlots slot(s)." -ForegroundColor Yellow

            $resp = Read-Host "Please delete old snapshots manually. Press ENTER to re-check, or type 'Q' to quit"
            if ($resp -eq 'Q' -or $resp -eq 'q') {
                return
            }
        }
    }
    # -------------------

    Write-Host "Creating snapshot for active instance: $selectedID" -ForegroundColor Green

    $defaultSnapName = "$selectedID-pre-bg-$(Get-TimeStamp)"

    # Ask for optional suffix (ticket number)
    $usrSuffix = Read-Host "Do you want to add a ticket number/suffix to the snapshot name? (Leave blank for default)"
    if (![string]::IsNullOrWhiteSpace($usrSuffix)) {
        $defaultSnapName = "$defaultSnapName-$usrSuffix"
    }

    Write-Host "`nDefault Snapshot Name: $defaultSnapName" -ForegroundColor Gray
    $inputName = Read-Host "Enter snapshot name [Press Enter for default]"
    
    $snapName = if ([string]::IsNullOrWhiteSpace($inputName)) { $defaultSnapName } else { $inputName }

    $retry = $true
    while ($retry) {
        Write-Log "`nCreating snapshot '$snapName'..." -ForegroundColor Green
        try {
            aws rds create-db-snapshot --db-instance-identifier $selectedID --db-snapshot-identifier $snapName --profile $global:AWSProfile | Out-Null
            Write-Log "Success! Snapshot creation initiated in background." -ForegroundColor Cyan

            $retry = $false # Success, exit retry loop

            $monitor = Read-Host "Do you want to monitor progress? (Y/n)"
            if ($monitor -ne "n") {
                Monitor-Snapshot-Progress
            }
        } catch {
            Write-Log "Failed to create snapshot: $_" -ForegroundColor Red

            $retryChoice = Read-Host "An error occurred. Do you want to retry the snapshot creation? (y to retry, n to return to main menu)"
            if ($retryChoice -ne 'y') {
                $retry = $false
                Read-Host "Press Enter to menu..."
            } else {
                Write-Host "Retrying..." -ForegroundColor Yellow
            }
        }
    }
}

function New-MultipleRDSSnapshots-Interactive {
    $instances = Get-RDSInstances
    if (!$instances) {
        Write-Host "No instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    # Options for menu
    $options = @($instances | ForEach-Object { "$($_.DBInstanceIdentifier) ($($_.Engine))" })

    # Show Multi-Select Menu
    $selectedIndices = Show-Menu -Title "Create Multiple Snapshots (SPACE to Select)" -Options $options -EnableFilter -MultiSelect

    if ($selectedIndices -eq -99) { $global:RestartSessionSelection = $true; return }
    if ($selectedIndices -is [int] -and $selectedIndices -lt 0) { return }

    if ($selectedIndices -eq $null -or $selectedIndices.Count -eq 0) {
        Write-Host "No instances selected." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    # --- QUOTA CHECK ---
    $maxManualSnapshots = 100
    $requiredSlots = $selectedIndices.Count

    while ($true) {
        $currentCount = Get-ManualSnapshotCount

        if (($currentCount + $requiredSlots) -le $maxManualSnapshots) {
             Write-Log "Quota Check Passed: $currentCount used + $requiredSlots required <= $maxManualSnapshots Limit." -ForegroundColor Green
             break
        } else {
             Write-Host "WARNING: AWS Quota Limit Reached!" -ForegroundColor Red
             Write-Host "You have $currentCount manual snapshots (Limit: $maxManualSnapshots). You need $requiredSlots slot(s)." -ForegroundColor Yellow

             $resp = Read-Host "Please delete old snapshots manually. Press ENTER to re-check, or type 'Q' to quit"
             if ($resp -eq 'Q' -or $resp -eq 'q') {
                 return
             }
        }
    }
    # -------------------

    Show-Header
    Write-Host "SELECTED INSTANCES FOR SNAPSHOT:" -ForegroundColor Green
    foreach ($idx in $selectedIndices) {
        Write-Host " - $($instances[$idx].DBInstanceIdentifier)"
    }

    $defaultPrefix = "multisnap-$(Get-TimeStamp)"

    # Ask for optional suffix (ticket number)
    $usrSuffix = Read-Host "Do you want to add a ticket number/suffix to the snapshot names? (Leave blank for default)"

    $displayFormat = if (![string]::IsNullOrWhiteSpace($usrSuffix)) { "$defaultPrefix-{DBInstanceIdentifier}-$usrSuffix" } else { "$defaultPrefix-{DBInstanceIdentifier}" }
    Write-Host "`nSnapshot Name Pattern: $displayFormat" -ForegroundColor Gray

    $confirm = Read-Host "Press Enter to execute, or type 'cancel'"
    if ($confirm -eq "cancel") { return }

    # Execution
    Write-Host "Processing $($selectedIndices.Count) snapshots in parallel..." -ForegroundColor Cyan

    # Prepare list for parallel processing
    $taskList = @()
    foreach ($idx in $selectedIndices) {
        $inst = $instances[$idx]
        $taskList += [PSCustomObject]@{
            Identifier = $inst.DBInstanceIdentifier
            SnapName = if (![string]::IsNullOrWhiteSpace($usrSuffix)) { "$defaultPrefix-$($inst.DBInstanceIdentifier)-$usrSuffix" } else { "$defaultPrefix-$($inst.DBInstanceIdentifier)" }
        }
    }

    # Pass profile to parallel scope
    $prof = $global:AWSProfile

    $retrySnapshots = $true
    $currentTaskList = $taskList

    while ($retrySnapshots) {
        $retrySnapshots = $false
        $results = @()

        try {
            # Check if PowerShell 7+ for parallel support
            if ($PSVersionTable.PSVersion.Major -lt 7) {
                Write-Host "PowerShell 7+ required for parallel execution. Falling back to sequential." -ForegroundColor Yellow
                foreach ($task in $currentTaskList) {
                    try {
                        aws rds create-db-snapshot --db-instance-identifier $task.Identifier --db-snapshot-identifier $task.SnapName --profile $prof | Out-Null
                        $results += [PSCustomObject]@{ Id = $task.Identifier; Status = "OK"; Msg = "Snapshot Initiated" }
                        Write-Host "Snapshot initiated: $($task.Identifier)" -ForegroundColor Green
                    } catch {
                        $errMsg = if ($_.Exception.Message) { $_.Exception.Message } else { $_.ToString() }
                        $results += [PSCustomObject]@{ Id = $task.Identifier; Status = "ERROR"; Msg = $errMsg }
                        Write-Host "Failed ($($task.Identifier)): $errMsg" -ForegroundColor Red
                    }
                }
            } else {
                $results = $currentTaskList | ForEach-Object -Parallel {
                    $t = $_
                    $p = $using:prof
                    try {
                        $output = aws rds create-db-snapshot --db-instance-identifier $t.Identifier --db-snapshot-identifier $t.SnapName --profile $p 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            $errText = ($output | Out-String).Trim()
                            return [PSCustomObject]@{ Id = $t.Identifier; Status = "ERROR"; Msg = $errText }
                        }
                        return [PSCustomObject]@{ Id = $t.Identifier; Status = "OK"; Msg = "Snapshot Initiated" }
                    } catch {
                        $errMsg = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } elseif ($_.Exception.Message) { $_.Exception.Message } else { $_.ToString() }
                        return [PSCustomObject]@{ Id = $t.Identifier; Status = "ERROR"; Msg = $errMsg }
                    }
                } -ThrottleLimit 10
            }
        } catch {
            $errMsg = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } elseif ($_.Exception.Message) { $_.Exception.Message } else { $_.ToString() }
            Write-Host "`nParallel Execution Error: $errMsg" -ForegroundColor Red
        }

        # Display Summary
        if ($results.Count -gt 0) {
            Write-Host "`nEXECUTION SUMMARY" -ForegroundColor Magenta
            Write-Host "------------------------------------------------------------"
            foreach ($r in $results) {
                if ($r.Status -eq "OK") {
                    Write-Host "  [OK]    $($r.Id): $($r.Msg)" -ForegroundColor Green
                } else {
                    Write-Host "  [FAIL]  $($r.Id): $($r.Msg)" -ForegroundColor Red
                }
            }
            Write-Host "------------------------------------------------------------"

            $failed = @($results | Where-Object { $_.Status -eq "ERROR" })
            $succeeded = @($results | Where-Object { $_.Status -eq "OK" })

            Write-Host "Results: $($succeeded.Count) succeeded, $($failed.Count) failed" -ForegroundColor $(if ($failed.Count -gt 0) { "Yellow" } else { "Green" })

            if ($failed.Count -gt 0) {
                # Check if it looks like a quota issue
                $isQuotaIssue = ($failed | Where-Object { $_.Msg -match "(?i)(quota|limit|SnapshotQuotaExceeded|maximum.*snapshot)" }).Count -gt 0

                Write-Host ""
                if ($isQuotaIssue) {
                    Write-Host "QUOTA LIMIT EXCEEDED" -ForegroundColor Red -BackgroundColor Yellow
                    Write-Host "The AWS manual snapshot limit has been reached." -ForegroundColor Yellow
                    Write-Host "Current quota: $maxManualSnapshots manual snapshots per account/region." -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "RECOMMENDED ACTION:" -ForegroundColor Cyan
                    Write-Host "  1. Go to Snapshot Management -> Delete Snapshots" -ForegroundColor White
                    Write-Host "  2. Remove old/unnecessary manual snapshots" -ForegroundColor White
                    Write-Host "  3. Return here to retry the failed snapshots" -ForegroundColor White
                } else {
                    Write-Host "Some snapshots failed to create. Check the error messages above." -ForegroundColor Yellow
                    Write-Host "This may be caused by:" -ForegroundColor Yellow
                    Write-Host "  - Snapshot quota limit reached (check manual snapshot count)" -ForegroundColor White
                    Write-Host "  - A snapshot with the same name already exists" -ForegroundColor White
                    Write-Host "  - Instance is in a state that doesn't allow snapshots" -ForegroundColor White
                    Write-Host "  - Network/API throttling issues" -ForegroundColor White
                }

                Write-Host ""
                $retryChoice = Read-Host "Type 'R' to RETRY failed snapshots, or press ENTER to continue"
                if ($retryChoice -eq 'R' -or $retryChoice -eq 'r') {
                    # Rebuild task list with only failed items
                    $failedIds = $failed | ForEach-Object { $_.Id }
                    $currentTaskList = @($taskList | Where-Object { $_.Identifier -in $failedIds })
                    Write-Host "`nRetrying $($currentTaskList.Count) failed snapshot(s)..." -ForegroundColor Cyan
                    $retrySnapshots = $true

                    # Re-check quota before retry
                    $currentCount = Get-ManualSnapshotCount
                    if (($currentCount + $currentTaskList.Count) -gt $maxManualSnapshots) {
                        Write-Host "WARNING: Quota still insufficient! $currentCount used + $($currentTaskList.Count) required > $maxManualSnapshots limit." -ForegroundColor Red
                        Write-Host "Please delete old snapshots first." -ForegroundColor Yellow
                        $retrySnapshots = $false
                        Read-Host "Press Enter to menu..."
                        return
                    }
                }
            }
        }
    }

    $monitor = Read-Host "Do you want to monitor progress of all snapshots? (Y/n)"
    if ($monitor -ne "n") {
        Monitor-Snapshot-Progress
    }
}

function Remove-RDSSnapshot-Interactive {
    Show-Header
    Write-Host "Fetching ALL manual snapshots (this may take a moment)..." -ForegroundColor Green

    try {
        # Fetch ALL manual snapshots (no pagination limit)
        $snapArgs = @("rds", "describe-db-snapshots", "--snapshot-type", "manual", "--output", "json", "--profile", $global:AWSProfile)
        $snapOutput = Invoke-AWS-WithRetry -Arguments $snapArgs -ReturnJson
        $json = $snapOutput -join ""
        if ([string]::IsNullOrWhiteSpace($json)) {
            Write-Host "No snapshots found." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }
        $data = $json | ConvertFrom-Json
        $snaps = $data.DBSnapshots

        if (!$snaps) {
            Write-Host "No snapshots found." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        # Sort by creation time descending
        $snaps = $snaps | Sort-Object SnapshotCreateTime -Descending

        # Define headers for Viewport Engine
        $header = {
            param($SearchString, $TotalItems, $FilteredCount)
            $lines = @(Get-Header-Lines)
            $lines += Get-AnsiString "DELETE SNAPSHOTS (Manual)" -Color Red
            $lines += "------------------------------------------"
            $lines += Get-AnsiString "Filter: $SearchString" -Color Yellow
            $lines += Get-AnsiString "Showing $FilteredCount / $TotalItems snapshots" -Color DarkGray
            $lines += "------------------------------------------"
            return $lines
        }.GetNewClosure()

        $footer = {
            param($MultiSelect)
            return @(Get-AnsiString "SPACE: Toggle Selection | ENTER: Confirm | Type to Filter" -Color DarkGray)
        }.GetNewClosure()

        # Call Viewport Engine
        # We pass filter property DBSnapshotIdentifier
        $selectedIndices = Invoke-InteractiveViewportSelection -Items $snaps -HeaderContent $header -FooterContent $footer -FilterProperties @("DBSnapshotIdentifier") -MultiSelect -ReturnIndex

        if ($selectedIndices -eq -99) { $global:RestartSessionSelection = $true; return }
        if ($selectedIndices -is [int] -and $selectedIndices -lt 0) { return }

        if ($selectedIndices -eq $null -or $selectedIndices.Count -eq 0) {
            Write-Host "No snapshots selected." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        # Confirmation Screen
        Show-Header
        Write-Host "WARNING: You have selected $($selectedIndices.Count) manual snapshots for deletion." -ForegroundColor Red -BackgroundColor Yellow
        Write-Host "--------------------------------------------------" -ForegroundColor Red

        $limitDisplay = 10
        $count = 0
        foreach ($idx in $selectedIndices) {
            if ($count -lt $limitDisplay) {
                Write-Host " - $($snaps[$idx].DBSnapshotIdentifier)" -ForegroundColor Red
            }
            $count++
        }
        if ($selectedIndices.Count -gt $limitDisplay) {
            Write-Host " ... and $($selectedIndices.Count - $limitDisplay) more." -ForegroundColor Red
        }
        Write-Host "--------------------------------------------------" -ForegroundColor Red

        $confirm = Read-Host "Are you sure you want to permanently delete them? (y/n)"
        if ($confirm -eq "y") {
             foreach ($idx in $selectedIndices) {
                $s = $snaps[$idx]
                Write-Host "Deleting '$($s.DBSnapshotIdentifier)'..." -ForegroundColor Yellow
                try {
                    aws rds delete-db-snapshot --db-snapshot-identifier $s.DBSnapshotIdentifier --profile $global:AWSProfile | Out-Null
                    Write-Host "Deleted." -ForegroundColor Green
                } catch {
                    Write-Host "Failed: $_" -ForegroundColor Red
                }
             }
        } else {
            Write-Host "Operation cancelled."
        }

    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

function Monitor-Snapshot-Progress {
    Show-Header
    Write-Host "Monitoring Snapshot Progress (Press ENTER or ESC to return to menu)..." -ForegroundColor Yellow
    
    while ($true) {
        # Check for key press (skip in test mode or if console unavailable)
        if (!$global:TEST_RUN_ONCE) {
            try {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ($key.Key -eq 'Enter' -or $key.Key -eq 'Escape') { break }
                }
            } catch {}
        }

        try {
            $snaps = @()
            
            # General monitoring: Last 10 freshest snapshots (filtered by last 10 days)
            $TenDaysAgo = (Get-Date).AddDays(-10).ToString("yyyy-MM-dd")

            # Query: Filter snapshots (creating/backing-up OR >= 10 days ago).
            # Sort by SnapshotCreateTime (treating null as future '9999-12-31') so they appear at end of list, then take last 10.
            $query = "DBSnapshots[?Status=='creating' || Status=='backing-up' || SnapshotCreateTime >= '$TenDaysAgo'] | sort_by(@, &SnapshotCreateTime || '9999-12-31')[-10:]"

            $snapMonArgs = @("rds", "describe-db-snapshots", "--query", $query, "--output", "json", "--profile", $global:AWSProfile)
            $snapMonOutput = Invoke-AWS-WithRetry -Arguments $snapMonArgs -ReturnJson
            $json = $snapMonOutput -join ""

            if (![string]::IsNullOrWhiteSpace($json)) {
                # When using --query with a slice, output is a JSON array.
                $rawSnaps = $json | ConvertFrom-Json
                if ($rawSnaps -is [Array]) {
                    $snaps = $rawSnaps
                } elseif ($rawSnaps) {
                    $snaps = @($rawSnaps)
                }
            }

            # Move cursor to top to avoid flicker
            try { [Console]::SetCursorPosition(0, 0) } catch {}
            $headerLines = Get-Header-Lines
            foreach ($hl in $headerLines) {
                [Console]::WriteLine((Pad-Line $hl))
            }

            Write-Host "Monitoring Snapshots (Last 10) (Press ENTER/ESC to return)..." -ForegroundColor Yellow

            # Columns: snapshot name, engine, engine version, db instance, status, progress, storage
            Write-Host "------------------------------------------------------------------------------------------------------------------------"
            Write-Host ("{0,-35} {1,-10} {2,-10} {3,-20} {4,-15} {5,-8} {6,8}" -f "Snapshot Name", "Engine", "Version", "DB Instance", "Status", "Progress", "Storage")
            Write-Host "------------------------------------------------------------------------------------------------------------------------" -ForegroundColor Gray

            if ($snaps.Count -gt 0) {
                # We sort the fetched batch by CreateTime Descending to show newest at top.
                $sortedSnaps = $snaps | Sort-Object {
                    if ($_.SnapshotCreateTime) { Get-Date $_.SnapshotCreateTime } else { [datetime]::MaxValue }
                } -Descending

                foreach ($s in $sortedSnaps) {
                    $pct = if ($s.PercentProgress) { "$($s.PercentProgress)%" } else { "0%" }
                    $storage = if ($s.AllocatedStorage) { "$($s.AllocatedStorage)G" } else { "-" }

                    # Color coding
                    $color = "White"
                    if ($s.Status -eq "available") { $color = "Green" }
                    elseif ($s.Status -in @("creating", "backing-up")) { $color = "Cyan" }

                    Write-Host ("{0,-35} {1,-10} {2,-10} {3,-20} {4,-15} {5,-8} {6,8}" -f $s.DBSnapshotIdentifier, $s.Engine, $s.EngineVersion, $s.DBInstanceIdentifier, $s.Status, $pct, $storage) -ForegroundColor $color
                }
            } else {
                Write-Host "No snapshots found." -ForegroundColor Gray
            }

        } catch {
             Write-Log "Error checking snapshots: $_" -ForegroundColor Red
        }
        
        if ($global:TEST_RUN_ONCE) { break }
        Start-Sleep -Seconds 5
    }
}

function New-BGDeployment-Interactive {
    # 1. Select Source
    $instances = Get-RDSInstances
    if (!$instances) {
        Write-Log "No instances found. Cannot create BG deployment." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    # Use new Live Filter Menu
    $sourceObj = Select-RDSInstance-Live -Instances $instances -Title "Step 1: Select Source DB for Blue/Green Deployment"
    if (!$sourceObj) { return }

    # Source ARN is required for --source
    $sourceARN = $sourceObj.DBInstanceArn
    $sourceDB = $sourceObj.DBInstanceIdentifier
    $engine = $sourceObj.Engine.Trim()
    $currentVer = $sourceObj.EngineVersion.Trim()

    Show-Header
    Write-Host "Configuration for Source: $sourceDB ($engine $currentVer)" -ForegroundColor Cyan

    # 2. Target Version Selection
    Write-Log "Fetching valid upgrade targets..." -ForegroundColor Green
    $targetVer = $null

    try {
        # Added --include-all to ensure we find the version even if it's not the default
        $json = (aws rds describe-db-engine-versions --engine $engine --engine-version $currentVer --include-all --output json --profile $global:AWSProfile) -join ""
        if (![string]::IsNullOrWhiteSpace($json)) {
             $data = $json | ConvertFrom-Json
             $validUpgrades = $data.DBEngineVersions.ValidUpgradeTarget

             $upgradeOptions = @()
             # Option 0: Keep Current
             $upgradeOptions += "Keep Current ($currentVer)"

             if ($validUpgrades) {
                 foreach ($up in $validUpgrades) {
                     $upgradeOptions += "$($up.EngineVersion) $(if($up.IsMajorVersionUpgrade){'[MAJOR]'}else{'[minor]'}) - $($up.Description)"
                 }
             }

             $selIndices = Show-Menu -Title "Select Target Engine Version (SPACE to Select, ENTER to Confirm, ESC to Cancel)" -Options $upgradeOptions -EnableFilter -MultiSelect -MaxSelectionCount 1

             # Handle ESC or F1 (return -99)
             if ($selIndices -eq -99) { $global:RestartSessionSelection = $true; return } # F1
             if ($selIndices -eq -1) { return } # ESC if single select? But multiselect returns array or empty.
             # Wait, Show-Menu returns array for MultiSelect only if Enter pressed. If ESC, it might return empty or logic differs?
             # Show-Menu (multiselect) logic: if ESC -> returns -1 (actually logic in switch 27 -> return -1).
             # But return type is usually array. If -1 returned, it's not array.
             # Let's check type.
             if ($selIndices -is [int] -and $selIndices -lt 0) { return }

             if ($selIndices.Count -gt 0) {
                 $idxVer = $selIndices[0]
                 if ($idxVer -eq 0) {
                     $targetVer = $null # Keep Current
                 } else {
                     $targetVer = $validUpgrades[$idxVer - 1].EngineVersion
                 }
             } else {
                 $targetVer = $null
             }
        }
    } catch {
        Write-Log "Error fetching versions: $_" -ForegroundColor Red
        $in = Read-Host "Enter Target Version manually (or Enter to keep current, 'q' to quit)"
        if ($in -eq 'q') { return }
        $targetVer = if ([string]::IsNullOrWhiteSpace($in)) { $null } else { $in }
    }

    $displayVer = if ($targetVer) { $targetVer } else { "Current ($currentVer)" }
    Write-Host "Target Version Selected: $displayVer" -ForegroundColor Green
    Start-Sleep -Seconds 1

    # 3. Parameter Group Selection
    $targetFamily = $null
    $verToQuery = if ($targetVer) { $targetVer } else { $currentVer }

    Write-Log "Fetching parameter groups for $engine $verToQuery..." -ForegroundColor Green
    $pgName = $null

    try {
        # Get Family
        $famJson = (aws rds describe-db-engine-versions --engine $engine --engine-version $verToQuery --include-all --output json --profile $global:AWSProfile) -join ""
        if (![string]::IsNullOrWhiteSpace($famJson)) {
            $famData = $famJson | ConvertFrom-Json
            if ($famData.DBEngineVersions) {
                $targetFamily = $famData.DBEngineVersions[0].DBParameterGroupFamily
            }
        }

        if ($targetFamily) {
             # Get Parameter Groups by Family
             $pgJson = (aws rds describe-db-parameter-groups --filters "Name=db-parameter-group-family,Values=$targetFamily" --output json --profile $global:AWSProfile) -join ""
             if (![string]::IsNullOrWhiteSpace($pgJson)) {
                 $pgData = $pgJson | ConvertFrom-Json
                 $pgs = $pgData.DBParameterGroups

                 if ($pgs) {
                     $pgOptions = @()
                     $pgOptions += "Default (Use Source's Group or Engine Default)"

                     foreach ($p in $pgs) {
                         $pgOptions += "$($p.DBParameterGroupName) ($($p.Description))"
                     }

                     $selPGIndices = Show-Menu -Title "Select Parameter Group (Family: $targetFamily)" -Options $pgOptions -EnableFilter -MultiSelect -MaxSelectionCount 1

                     if ($selPGIndices -eq -99) { $global:RestartSessionSelection = $true; return }
                     if ($selPGIndices -is [int] -and $selPGIndices -lt 0) { return }

                     if ($selPGIndices.Count -gt 0) {
                         $idxPG = $selPGIndices[0]
                         if ($idxPG -gt 0) {
                             $pgName = $pgs[$idxPG - 1].DBParameterGroupName
                         }
                     }
                 }
             }
        } else {
            Write-Log "Could not determine parameter group family automatically." -ForegroundColor Yellow
            # Enhanced Logging for debugging
            Write-Log "DEBUG: Version Data for Family Determination: $($famJson | Out-String)" -ForegroundColor DarkGray

            $manualPG = Read-Host "Enter Parameter Group Name manually [Press Enter for Default]"
            if (![string]::IsNullOrWhiteSpace($manualPG)) {
                $pgName = $manualPG
            }
        }
    } catch {
        $err = $_
        Write-Log "Error fetching parameter groups: $($err.Exception.Message)" -ForegroundColor Red
        Write-Log "Full Error: $($err | Out-String)" -ForegroundColor DarkGray

        $manualPG = Read-Host "Enter Parameter Group Name manually [Press Enter for Default]"
        if (![string]::IsNullOrWhiteSpace($manualPG)) {
            $pgName = $manualPG
        }
    }

    $displayPG = if ($pgName) { $pgName } else { "Default" }
    Write-Host "Parameter Group Selected: $displayPG" -ForegroundColor Green
    Start-Sleep -Seconds 1

    # 4. BG Deployment Name & Green DB Name
    $defaultBGName = "bg-deployment-$sourceDB"

    Write-Host "`n[Deployment Naming]" -ForegroundColor Cyan
    Write-Host "Default Deployment Name: $defaultBGName" -ForegroundColor Gray
    $inputName = Read-Host "Enter BG Deployment Name [Press Enter for default, 'q' to quit]"
    if ($inputName -eq 'q') { return }
    $bgName = if ([string]::IsNullOrWhiteSpace($inputName)) { $defaultBGName } else { $inputName }

    Write-Host "Green DB Identifier:     (Generated automatically by AWS)" -ForegroundColor Gray
    
    Write-Log "`nConstructing deployment '$bgName'..." -ForegroundColor Gray

    # Use Source ARN instead of Source Identifier
    $sourceParam = if ($sourceARN) { $sourceARN } else { $sourceDB }

    $argsList = @("rds", "create-blue-green-deployment", "--blue-green-deployment-name", $bgName, "--source", $sourceParam, "--profile", $global:AWSProfile)
    if (![string]::IsNullOrWhiteSpace($targetVer)) {
        $argsList += "--target-engine-version", $targetVer
    }
    if (![string]::IsNullOrWhiteSpace($pgName)) {
        $argsList += "--target-db-parameter-group-name", $pgName
    }

    Write-Log "Executing AWS CLI..." -ForegroundColor Green
    Write-Log "DEBUG Command: aws $($argsList -join ' ')" -ForegroundColor DarkGray

    try {
        # Temporarily relax ErrorActionPreference to capture stderr without immediate throw
        $origEAP = $ErrorActionPreference
        $ErrorActionPreference = "Continue"

        # Execute and capture all output (stdout + stderr mixed)
        $outputRaw = & aws $argsList --output json 2>&1

        # Restore EAP
        $ErrorActionPreference = $origEAP

        # Separate stdout and stderr
        $errRecords = $outputRaw | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
        $stdOutLines = $outputRaw | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
        $stdOutStr = $stdOutLines -join ""

        if ($LASTEXITCODE -ne 0) {
            $errMsg = if ($errRecords) { ($errRecords | ForEach-Object { $_.ToString() }) -join "`n" } else { $stdOutStr }
            throw "AWS CLI Error (Exit Code: $LASTEXITCODE): $errMsg"
        }

        if ([string]::IsNullOrWhiteSpace($stdOutStr)) {
             throw "AWS CLI returned no output."
        }

        $result = $stdOutStr | ConvertFrom-Json
        $bgId = $result.BlueGreenDeployment.BlueGreenDeploymentIdentifier

        if (!$bgId) {
             throw "Response did not contain a valid BlueGreenDeploymentIdentifier."
        }

        Write-Log "Deployment Created Successfully!" -ForegroundColor Cyan
        Write-Log "BG Identifier: $bgId" -ForegroundColor Yellow
        Write-Log "Use the 'Monitor' function to track progress." 
    } catch {
        $err = $_
        $msg = if ($err.Exception) { $err.Exception.Message } else { $err.ToString() }

        Write-Log "Deployment Failed: $msg" -ForegroundColor Red
        Write-Log "Full Error Details:" -ForegroundColor DarkGray

        # Log extensive error details
        $errDetails = $err | Select-Object * | Out-String
        Write-Log $errDetails

        if ($err.ScriptStackTrace) {
             Write-Log "Script Stack Trace:`n$($err.ScriptStackTrace)"
        }
    }
    Read-Host "Press Enter to menu..."
}

function Monitor-BGStatus-Interactive {
    $bgs = Get-BlueGreenDeployments
    if (!$bgs) {
        Write-Log "No active Blue/Green deployments found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $options = @($bgs | ForEach-Object { "$($_.BlueGreenDeploymentName) ($($_.BlueGreenDeploymentIdentifier)) [$($_.Status)]" })
    $options += "Cancel"

    $idx = Show-Menu -Title "Select Deployment to Monitor" -Options $options
    if ($idx -eq -1 -or $idx -eq ($options.Count - 1)) { return }

    $bgObj = $bgs[$idx]
    $bgId = $bgObj.BlueGreenDeploymentIdentifier
    $bgName = $bgObj.BlueGreenDeploymentName

    # --- One-time fetch: Source/Target engine info ---
    $sourceId = Get-InstanceIdFromArn $bgObj.Source
    $targetId = Get-InstanceIdFromArn $bgObj.Target
    $sourceEngine = ""; $sourceVersion = ""
    $targetEngine = ""; $targetVersion = ""

    try {
        $srcArgs = @("rds", "describe-db-instances", "--db-instance-identifier", $sourceId, "--query", "DBInstances[0].{Engine:Engine,EngineVersion:EngineVersion}", "--output", "json", "--profile", $global:AWSProfile)
        $srcOut = Invoke-AWS-WithRetry -Arguments $srcArgs -ReturnJson
        $srcData = ($srcOut -join "") | ConvertFrom-Json
        if ($srcData) { $sourceEngine = $srcData.Engine; $sourceVersion = $srcData.EngineVersion }
    } catch { $sourceEngine = "?"; $sourceVersion = "?" }

    try {
        $tgtArgs = @("rds", "describe-db-instances", "--db-instance-identifier", $targetId, "--query", "DBInstances[0].{Engine:Engine,EngineVersion:EngineVersion}", "--output", "json", "--profile", $global:AWSProfile)
        $tgtOut = Invoke-AWS-WithRetry -Arguments $tgtArgs -ReturnJson
        $tgtData = ($tgtOut -join "") | ConvertFrom-Json
        if ($tgtData) { $targetEngine = $tgtData.Engine; $targetVersion = $tgtData.EngineVersion }
    } catch { $targetEngine = "?"; $targetVersion = "?" }

    # --- Rendering buffer ---
    $sb = [System.Text.StringBuilder]::new()

    # Hide cursor
    try { [Console]::CursorVisible = $false } catch {}

    while ($true) {
        # --- Key press check ---
        if ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq 'Enter' -or $k.Key -eq 'Escape') { break }
            if ($k.Key -eq 'F5') {
                # Force refresh — continue loop immediately
            }
        }

        # --- Fetch deployment status ---
        try {
            $bgArgs = @("rds", "describe-blue-green-deployments", "--blue-green-deployment-identifier", $bgId, "--output", "json", "--profile", $global:AWSProfile)
            $bgOutput = Invoke-AWS-WithRetry -Arguments $bgArgs -ReturnJson
            $statusData = ($bgOutput -join "") | ConvertFrom-Json

            if (!$statusData.BlueGreenDeployments -or $statusData.BlueGreenDeployments.Count -eq 0) {
                Write-Log "Deployment not found or deleted." -ForegroundColor Red
                break
            }

            $bg = $statusData.BlueGreenDeployments[0]
        } catch {
            Write-Log "`nError fetching deployment status: $_" -ForegroundColor Red
            Start-Sleep -Seconds 5
            continue
        }

        # --- Fetch Replica Lag (non-blocking, best-effort) ---
        $lag = "N/A"
        if ($bg.Status -ne "PROVISIONING" -and $targetId -ne "Unknown") {
            try {
                $endTime = Get-Date
                $startTime = $endTime.AddMinutes(-10)
                $endStr = $endTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                $startStr = $startTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

                $lagArgs = @("cloudwatch", "get-metric-statistics", "--namespace", "AWS/RDS", "--metric-name", "ReplicaLag", "--dimensions", "Name=DBInstanceIdentifier,Value=$targetId", "--start-time", $startStr, "--end-time", $endStr, "--period", "300", "--statistics", "Maximum", "--output", "json", "--profile", $global:AWSProfile)
                $lagOut = Invoke-AWS-WithRetry -Arguments $lagArgs -ReturnJson
                $lagJson = $lagOut -join ""
                if (![string]::IsNullOrWhiteSpace($lagJson)) {
                    $lagData = $lagJson | ConvertFrom-Json
                    if ($lagData.Datapoints -and $lagData.Datapoints.Count -gt 0) {
                        $point = $lagData.Datapoints | Sort-Object Timestamp -Descending | Select-Object -First 1
                        $lag = "$($point.Maximum)s"
                    } else {
                        $lag = "No Data"
                    }
                }
            } catch {
                $lag = "Error"
            }
        }

        # --- Build frame ---
        try { $winWidth = $Host.UI.RawUI.WindowSize.Width } catch { $winWidth = 120 }
        [void]$sb.Clear()

        # Header
        $headerLines = Get-Header-Lines
        foreach ($hl in $headerLines) {
            [void]$sb.AppendLine((Pad-Line $hl $winWidth))
        }

        # Title
        [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  BLUE/GREEN DEPLOYMENT MONITOR" -Color Yellow) $winWidth))
        [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  ID:   $bgId" -Color White) $winWidth))
        [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  Name: $bgName" -Color White) $winWidth))
        [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  ────────────────────────────────────────────────────────────────────" -Color DarkGray) $winWidth))

        # Status + Elapsed
        $status = $bg.Status
        $statusColor = switch ($status) {
            "AVAILABLE" { "Green" }
            "SWITCHOVER_COMPLETED" { "Green" }
            "PROVISIONING" { "Yellow" }
            "SWITCHOVER_IN_PROGRESS" { "Cyan" }
            "INVALID_CONFIGURATION" { "Red" }
            "SWITCHOVER_FAILED" { "Red" }
            "DELETING" { "DarkYellow" }
            default { "White" }
        }

        $elapsed = ""
        if ($bg.CreateTime) {
            try {
                $createDt = [datetime]::Parse($bg.CreateTime).ToLocalTime()
                $diff = (Get-Date) - $createDt
                $elapsed = "{0:d2}:{1:d2}:{2:d2}" -f [int]$diff.TotalHours, $diff.Minutes, $diff.Seconds
            } catch { $elapsed = "?" }
        }

        $statusLine = "  STATUS: $(Get-AnsiString $status -Color $statusColor)"
        if ($elapsed) { $statusLine += "$(Get-AnsiString "           Elapsed: $elapsed" -Color DarkGray)" }
        [void]$sb.AppendLine((Pad-Line $statusLine $winWidth))

        # StatusDetails
        if ($bg.StatusDetails) {
            [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  Details: $($bg.StatusDetails)" -Color DarkGray) $winWidth))
        }

        [void]$sb.AppendLine((Pad-Line "" $winWidth))

        # Blue / Green info
        $srcLabel = "  Blue (Source):  $sourceId"
        if ($sourceEngine) { $srcLabel += "  [$sourceEngine $sourceVersion]" }
        [void]$sb.AppendLine((Pad-Line (Get-AnsiString $srcLabel -Color Cyan) $winWidth))

        $tgtLabel = "  Green (Target): $targetId"
        if ($targetEngine) { $tgtLabel += "  [$targetEngine $targetVersion]" }
        [void]$sb.AppendLine((Pad-Line (Get-AnsiString $tgtLabel -Color Green) $winWidth))

        $lagColor = if ($lag -match "^\d" -and [double]($lag -replace 's$','') -lt 1) { "Green" } elseif ($lag -eq "N/A" -or $lag -eq "No Data") { "DarkGray" } else { "Yellow" }
        [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  Replica Lag:    $lag" -Color $lagColor) $winWidth))

        [void]$sb.AppendLine((Pad-Line "" $winWidth))

        # SwitchoverDetails table
        if ($bg.SwitchoverDetails -and $bg.SwitchoverDetails.Count -gt 0) {
            [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  SWITCHOVER RESOURCES:" -Color Yellow) $winWidth))
            [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  ────────────────────────────────────────────────────────────────────" -Color DarkGray) $winWidth))
            $colFmt = "  {0,-35} {1,-35} {2}"
            [void]$sb.AppendLine((Pad-Line (Get-AnsiString ($colFmt -f "Source (Blue)", "Target (Green)", "Status") -Color White) $winWidth))

            foreach ($sd in $bg.SwitchoverDetails) {
                $srcMember = Get-InstanceIdFromArn $sd.SourceMember
                $tgtMember = Get-InstanceIdFromArn $sd.TargetMember
                $sdStatus = $sd.Status

                $sdColor = switch ($sdStatus) {
                    "AVAILABLE" { "Green" }
                    "SWITCHOVER_COMPLETED" { "Green" }
                    "PROVISIONING" { "Yellow" }
                    "SWITCHOVER_IN_PROGRESS" { "Cyan" }
                    "SWITCHOVER_FAILED" { "Red" }
                    "MISSING_SOURCE" { "Red" }
                    "MISSING_TARGET" { "Red" }
                    default { "White" }
                }

                $rowText = $colFmt -f $srcMember, $tgtMember, $sdStatus
                [void]$sb.AppendLine((Pad-Line (Get-AnsiString $rowText -Color $sdColor) $winWidth))
            }
            [void]$sb.AppendLine((Pad-Line "" $winWidth))
        }

        # Tasks checklist
        if ($bg.Tasks -and $bg.Tasks.Count -gt 0) {
            [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  TASKS:" -Color Yellow) $winWidth))
            [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  ────────────────────────────────────────────────────────────────────" -Color DarkGray) $winWidth))

            foreach ($task in $bg.Tasks) {
                $icon = switch ($task.Status) {
                    "COMPLETED" { "[#]" }
                    "IN_PROGRESS" { "[~]" }
                    "PENDING" { "[ ]" }
                    "FAILED" { "[X]" }
                    default { "[?]" }
                }
                $taskColor = switch ($task.Status) {
                    "COMPLETED" { "Green" }
                    "IN_PROGRESS" { "Cyan" }
                    "PENDING" { "DarkGray" }
                    "FAILED" { "Red" }
                    default { "White" }
                }
                $taskName = ($task.Name -replace '_', ' ').ToLower()
                # Capitalize first letter of each word
                $taskName = (Get-Culture).TextInfo.ToTitleCase($taskName)

                $taskLine = "  $icon $("{0,-45}" -f $taskName) $($task.Status)"
                [void]$sb.AppendLine((Pad-Line (Get-AnsiString $taskLine -Color $taskColor) $winWidth))
            }
            [void]$sb.AppendLine((Pad-Line "" $winWidth))
        }

        # Footer separator + instructions
        [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  ────────────────────────────────────────────────────────────────────" -Color DarkGray) $winWidth))
        $refreshTime = Get-Date -Format "HH:mm:ss"
        [void]$sb.AppendLine((Pad-Line (Get-AnsiString "  Last refresh: $refreshTime | F5: Force Refresh | ENTER/ESC: Exit" -Color DarkGray) $winWidth))

        # Blank lines to clear residual text from previous frames
        for ($i = 0; $i -lt 4; $i++) {
            [void]$sb.AppendLine((Pad-Line "" $winWidth))
        }

        # --- Flush frame ---
        try { [Console]::SetCursorPosition(0, 0) } catch {}
        try { [Console]::Write($sb.ToString()) } catch {}

        # --- Wait loop (15 seconds, check for keypress) ---
        $waitLoops = 150  # 15 seconds (100ms * 150)
        for ($w = 0; $w -lt $waitLoops; $w++) {
            if ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq 'Enter' -or $k.Key -eq 'Escape') {
                    try { [Console]::CursorVisible = $true } catch {}
                    return
                }
                if ($k.Key -eq 'F5') { break }  # Break inner loop to force refresh
            }
            Start-Sleep -Milliseconds 100
        }
    }

    try { [Console]::CursorVisible = $true } catch {}
}

function Show-AWSSessions-Menu {
    # Check for granted tools in script directory
    # Priority: assume.ps1 (PowerShell wrapper) > assume.bat > granted.exe > assumego.exe
    $tools = @("assume.ps1", "assume.bat", "assume", "granted.exe", "assumego.exe")
    $foundTool = $null

    foreach ($t in $tools) {
        $path = Join-Path $PSScriptRoot $t
        if (Test-Path $path) {
            $foundTool = $path
            break
        }
    }

    $title = "AWS Sessions (Granted/Assume)"
    if ($foundTool) {
        $menuOptions = @(
            "Run Assume/Granted ($foundTool)",
            "Back"
        )
    } else {
        $menuOptions = @(
            "Tool not found (Instructions)",
            "Back"
        )
    }

    $idx = Show-Menu -Title $title -Options $menuOptions
    if ($idx -eq ($menuOptions.Count - 1)) { return } # Back
    if ($idx -lt 0) { return } # ESC

    if ($foundTool) {
        Write-Host "Launching $foundTool..." -ForegroundColor Green
        try {
            if ($foundTool.EndsWith(".ps1")) {
                # Run PowerShell script directly in current console
                & $foundTool
            } elseif ($foundTool.EndsWith(".bat") -or $foundTool.EndsWith(".cmd")) {
                # Run Batch file
                & $foundTool
            } else {
                # Executables
                Start-Process -FilePath $foundTool -Wait -NoNewWindow
            }
        } catch {
            Write-Host "Error running tool: $_" -ForegroundColor Red
            Read-Host "Press Enter to continue..."
        }
    } else {
        Show-Header
        Write-Host "INSTRUCTIONS" -ForegroundColor Yellow
        Write-Host "To use this feature, please download 'granted' or 'assume' tools."
        Write-Host "Place one of the following files in the script directory:"
        Write-Host " - $PSScriptRoot"
        Write-Host "`nSupported files: $($tools -join ', ')"
        Write-Host "`nVisit: https://docs.commonfate.io/granted/getting-started" -ForegroundColor Cyan
        Read-Host "Press Enter to return..."
    }
}

function Remove-BGDeployment-Interactive {
    $bgs = Get-BlueGreenDeployments
    if (!$bgs) {
        Write-Host "No active Blue/Green deployments found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $options = @($bgs | ForEach-Object { "$($_.BlueGreenDeploymentName) ($($_.Status))" })

    $idx = Show-Menu -Title "Select Blue/Green Deployment to DELETE" -Options $options

    # Check return values carefully. Show-Menu returns index int.
    # If $idx is array (from MultiSelect?), take first. But MultiSelect is OFF here.
    if ($idx -is [Array]) { $idx = $idx[0] }

    if ($idx -eq -99) { return } # F1
    if ($idx -lt 0) { return }   # ESC

    $bgObj = $bgs[$idx]
    $bgId = $bgObj.BlueGreenDeploymentIdentifier

    # Identify Source and Target
    # We need to extract IDs from ARNs for display
    $sourceArn = $bgObj.Source
    $targetArn = $bgObj.Target

    $sourceId = Get-InstanceIdFromArn $sourceArn
    $targetId = Get-InstanceIdFromArn $targetArn

    Show-Header
    Write-Host "DELETING BLUE/GREEN DEPLOYMENT: $bgId" -ForegroundColor Magenta
    Write-Host "------------------------------------------------------------"
    Write-Host "You must identify if you want to delete a member instance (e.g. Old Blue)."
    Write-Host "Usually, you want to delete the deployment resource AND the old source instance."
    Write-Host "------------------------------------------------------------"

    $instanceOptions = @(
        "None (Delete Deployment Resource Only)",
        "Instance 1: $sourceId (Source in BG definition)",
        "Instance 2: $targetId (Target in BG definition)"
    )

    $instIdx = Show-Menu -Title "Select Instance to TERMINATE (Delete)" -Options $instanceOptions

    if ($instIdx -is [Array]) { $instIdx = $instIdx[0] }

    if ($instIdx -eq -99) { return } # F1
    if ($instIdx -lt 0) { return } # ESC

    $instanceToDelete = $null
    if ($instIdx -eq 1) { $instanceToDelete = $sourceId }
    elseif ($instIdx -eq 2) { $instanceToDelete = $targetId }

    # Fetch Replica Lag for Safety Check
    $endTime = Get-Date
    $startTime = $endTime.AddMinutes(-15)
    $endStr = $endTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $startStr = $startTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    $sourceLag = "Unknown"
    $targetLag = "Unknown"

    foreach ($pair in @(@{ID=$sourceId; Ref=[ref]$sourceLag; IsPrimary=$true}, @{ID=$targetId; Ref=[ref]$targetLag; IsPrimary=$false})) {
        if ($pair.IsPrimary) {
            # Source is the primary — ReplicaLag metric doesn't exist for it
            $pair.Ref.Value = "N/A (Primary)"
            continue
        }
        if ($pair.ID) {
            try {
                $lagArgs = @("cloudwatch", "get-metric-statistics", "--namespace", "AWS/RDS", "--metric-name", "ReplicaLag", "--dimensions", "Name=DBInstanceIdentifier,Value=$($pair.ID)", "--start-time", $startStr, "--end-time", $endStr, "--period", "300", "--statistics", "Maximum", "--output", "json", "--profile", $global:AWSProfile)
                $lagOut = Invoke-AWS-WithRetry -Arguments $lagArgs -ReturnJson
                $lagJson = $lagOut -join ""
                if (![string]::IsNullOrWhiteSpace($lagJson)) {
                    $lagData = $lagJson | ConvertFrom-Json
                    if ($lagData.Datapoints -and $lagData.Datapoints.Count -gt 0) {
                        $point = $lagData.Datapoints | Sort-Object Timestamp -Descending | Select-Object -First 1
                        $pair.Ref.Value = "$($point.Maximum) sec"
                    } else {
                        $pair.Ref.Value = "No Data (Last 15m)"
                    }
                } else {
                    $pair.Ref.Value = "No Data (Last 15m)"
                }
            } catch {
                $pair.Ref.Value = "Error fetching"
            }
        }
    }

    Show-Header
    Write-Host "CONFIRM DELETION" -ForegroundColor Red
    Write-Host "Deployment: $bgId" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------"
    Write-Host "Replica Lag Check (Last 15 mins):" -ForegroundColor Cyan
    Write-Host "  Source ($sourceId): $sourceLag" -ForegroundColor White
    Write-Host "  Green  ($targetId): $targetLag" -ForegroundColor White
    Write-Host "------------------------------------------------------------"

    if ($instanceToDelete) {
        Write-Host "Instance:   $instanceToDelete (WILL BE DELETED)" -ForegroundColor Red -BackgroundColor Yellow
        Write-Host "            (Deletion protection will be disabled)" -ForegroundColor Red
    } else {
        Write-Host "Instance:   None selected (Instances will remain)" -ForegroundColor Green
    }

    $confirmPhrase = Read-Host "`nType 'DELETE ME' to confirm execution"
    if ($confirmPhrase -ne "DELETE ME") {
        Write-Host "Operation Cancelled." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    # Execution
    if ($instanceToDelete) {
        Write-Host "Disabling deletion protection on $instanceToDelete..." -ForegroundColor Cyan
        try {
            aws rds modify-db-instance --db-instance-identifier $instanceToDelete --no-deletion-protection --apply-immediately --profile $global:AWSProfile | Out-Null
            Write-Host "Done." -ForegroundColor Green
        } catch {
            Write-Host "Failed to disable protection: $_" -ForegroundColor Red
            # Should we continue? Maybe the user already disabled it. Let's try.
        }
    }

    # Delete Deployment
    Write-Host "Deleting Blue/Green Deployment Resource..." -ForegroundColor Cyan
    try {
        # --no-delete-target ensures we don't accidentally delete the NEW target if we didn't mean to.
        # But wait, create-blue-green-deployment creates a new target.
        # delete-blue-green-deployment deletes the resource.
        # If we want to delete a SPECIFIC instance, we should do it manually via delete-db-instance as planned below.
        # Using --delete-target is risky if roles swapped.
        # Safest is to delete BG resource WITHOUT target deletion, then delete instance manually.
        aws rds delete-blue-green-deployment --blue-green-deployment-identifier $bgId --no-delete-target --profile $global:AWSProfile | Out-Null
        Write-Host "Deployment deletion initiated." -ForegroundColor Green
    } catch {
        Write-Host "Failed to delete BG Deployment: $_" -ForegroundColor Red
        Read-Host "Press Enter to menu..."
        return
    }

    if ($instanceToDelete) {
        Write-Host "Deleting Instance $instanceToDelete..." -ForegroundColor Red
        try {
            aws rds delete-db-instance --db-instance-identifier $instanceToDelete --skip-final-snapshot --profile $global:AWSProfile | Out-Null
            Write-Host "Instance deletion initiated." -ForegroundColor Green
        } catch {
            Write-Host "Failed to delete instance: $_" -ForegroundColor Red
        }
    }

    Read-Host "Press Enter to menu..."
}

function Invoke-Switchover-Interactive {
    $bgs = Get-BlueGreenDeployments
    if (!$bgs) {
        Write-Host "No active Blue/Green deployments found." -ForegroundColor Yellow
        Pause
        return
    }

    # Filter for AVAILABLE only? Or allow user to try anyway? 
    # Better to show all but mark them.
    $options = @($bgs | ForEach-Object {
        $mark = if ($_.Status -eq "AVAILABLE") { "[READY]" } else { "[NOT READY]" }
        "$mark $($_.BlueGreenDeploymentName) ($($_.Status))" 
    })
    $options += "Cancel"

    $idx = Show-Menu -Title "Select Deployment to PROMOTE (Switchover)" -Options $options
    if ($idx -eq ($options.Count - 1)) { return }

    $bgObj = $bgs[$idx]
    
    if ($bgObj.Status -ne "AVAILABLE") {
        # Ostrzegamy uzytkownika / We warn the user
        Write-Log "Warning: Status is '$($bgObj.Status)'. Switchover will likely fail." -ForegroundColor Red
        $proceed = Read-Host "Do you want to proceed anyway? (y/n)"
        if ($proceed -ne 'y') { return }
    }

    $bgId = $bgObj.BlueGreenDeploymentIdentifier
    
    Show-Header
    Write-Host "PREPARING TO SWITCHOVER: $bgId" -ForegroundColor Magenta

    # Check Replica Lag
    if ($bgObj.Target -match ":db:(.+)$") {
        $targetId = $matches[1]
        Write-Host "Checking Replica Lag for Green DB ($targetId)..." -ForegroundColor Cyan

        try {
            $endTime = Get-Date
            $startTime = $endTime.AddMinutes(-15)
            $endStr = $endTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $startStr = $startTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

            $lagArgs = @(
                "cloudwatch", "get-metric-statistics",
                "--namespace", "AWS/RDS",
                "--metric-name", "ReplicaLag",
                "--dimensions", "Name=DBInstanceIdentifier,Value=$targetId",
                "--start-time", $startStr,
                "--end-time", $endStr,
                "--period", "60",
                "--statistics", "Maximum",
                "--query", "Datapoints | sort_by(@, &Timestamp) | [-1].Maximum",
                "--output", "text",
                "--profile", $global:AWSProfile
            )

            # Execute using our robust retry wrapper (returns array of strings or raw object)
            $lagOutput = Invoke-AWS-WithRetry -Arguments $lagArgs
            $lagText = ($lagOutput -join "").Trim()

            $lagVal = "Unknown"
            if (![string]::IsNullOrWhiteSpace($lagText) -and $lagText -ne "None") {
                $lagVal = "$lagText seconds"
            } else {
                $lagVal = "No Data (CloudWatch delay or metric not available)"
            }
            Write-Host "Current Replica Lag: $lagVal" -ForegroundColor Yellow
        } catch {
            Write-Host "Could not fetch lag: $_" -ForegroundColor Red
        }
    }

    $confirm = Read-Host "Type 'PROMOTE' to confirm switchover"
    if ($confirm -eq "PROMOTE") {
        $timeout = Read-Host "Enter Timeout in seconds (default: 300)"
        if ([string]::IsNullOrWhiteSpace($timeout)) { $timeout = "300" }

        Write-Log "Executing Switchover..." -ForegroundColor Green
        try {
            aws rds switchover-blue-green-deployment --blue-green-deployment-identifier $bgId --switchover-timeout $timeout --profile $global:AWSProfile
            Write-Log "Switchover initiated! The database is flipping to Green." -ForegroundColor Cyan
        } catch {
            Write-Log "Switchover Failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
    }
    Read-Host "Press Enter to menu..."
}

function Update-OperatingSystem {
    Show-Header
    Write-Host "Fetching Pending OS Updates (system-update)..." -ForegroundColor Green

    # To zajmuje wieki / This takes ages
    try {
        $argsList = @("rds", "describe-pending-maintenance-actions", "--output", "json", "--profile", $global:AWSProfile)
        $output = Invoke-AWS-WithRetry -Arguments $argsList -ReturnJson
        $json = $output -join ""

        if ([string]::IsNullOrWhiteSpace($json)) {
            Write-Host "No pending maintenance actions found." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        $data = $json | ConvertFrom-Json

        # Filter for system-update
        $pendingOS = @()
        if ($data.PendingMaintenanceActions) {
            foreach ($p in $data.PendingMaintenanceActions) {
                if ($p.PendingMaintenanceActionDetails) {
                    $osActions = $p.PendingMaintenanceActionDetails | Where-Object { $_.Action -eq 'system-update' }
                    if ($osActions) {
                        # Add to list
                        $id = Get-InstanceIdFromArn $p.ResourceIdentifier

                        foreach ($a in $osActions) {
                            $pendingOS += [PSCustomObject]@{
                                ResourceArn = $p.ResourceIdentifier
                                InstanceID = $id
                                Action = $a.Action
                                Description = $a.Description
                            }
                        }
                    }
                }
            }
        }

        if (!$pendingOS -or $pendingOS.Count -eq 0) {
            Write-Host "No pending OS upgrades found." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        # Build Menu Options
        $options = @()
        foreach ($item in $pendingOS) {
            $options += "$($item.InstanceID) - $($item.Description)"
        }

        $selectedIndices = Show-Menu -Title "Select Instances to Update OS (SPACE to Select)" -Options $options -EnableFilter -MultiSelect

        # niespodzianka, a myslales ze znajdziesz tu ai?

        if ($selectedIndices -eq -99) { $global:RestartSessionSelection = $true; return }
        if ($selectedIndices -is [int] -and $selectedIndices -lt 0) { return }

        if ($selectedIndices -eq $null -or $selectedIndices.Count -eq 0) {
            Write-Host "No instances selected." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        # Pre-Update: Snapshot
        Show-Header
        Write-Host "PRE-UPDATE SAFEGUARDS" -ForegroundColor Cyan
        $snap = Read-Host "Do you want to create a generic snapshot for these instances before updating? (y/n)"

        if ($snap -eq 'y') {
            $ts = Get-TimeStamp
            foreach ($idx in $selectedIndices) {
                $item = $pendingOS[$idx]
                $snapName = "pre-os-update-$($item.InstanceID)-$ts"
                Write-Host "Creating snapshot '$snapName'..." -ForegroundColor Yellow

                try {
                    $snapArgs = @("rds", "create-db-snapshot", "--db-instance-identifier", $item.InstanceID, "--db-snapshot-identifier", $snapName, "--profile", $global:AWSProfile)
                    Invoke-AWS-WithRetry -Arguments $snapArgs | Out-Null
                    Write-Host "Snapshot initiated." -ForegroundColor Green
                } catch {
                    Write-Host "Snapshot failed: $_" -ForegroundColor Red
                    $cont = Read-Host "Continue with update anyway? (y/N)"
                    if ($cont -ne 'y') { return }
                }
            }
        }

        # Pre-Update: Monitoring Reminder
        Clear-Host
        Show-Header
        Write-Host "REMINDER: Please ensure you have disabled external monitoring (Datadog, Zabbix, CloudWatch Alarms) to avoid false positive alerts during the reboot/update process." -ForegroundColor Red -BackgroundColor Yellow
        Read-Host "Press ENTER to acknowledge and proceed..."

        # Execution
        Write-Host "Applying updates in parallel..." -ForegroundColor Cyan

        $taskList = @()
        foreach ($idx in $selectedIndices) {
            $taskList += $pendingOS[$idx]
        }
        $prof = $global:AWSProfile

        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $results = $taskList | ForEach-Object -Parallel {
                $t = $_
                $p = $using:prof
                try {
                    aws rds apply-pending-maintenance-action --resource-identifier $t.ResourceArn --apply-action "system-update" --opt-in-type "immediate" --profile $p | Out-Null
                    return [PSCustomObject]@{ Id = $t.InstanceID; Status = "OK" }
                } catch {
                    return [PSCustomObject]@{ Id = $t.InstanceID; Status = "ERROR"; Msg = $_.ToString() }
                }
            } -ThrottleLimit 10

            $results | Format-Table -AutoSize
        } else {
            foreach ($task in $taskList) {
                try {
                    aws rds apply-pending-maintenance-action --resource-identifier $task.ResourceArn --apply-action "system-update" --opt-in-type "immediate" --profile $prof | Out-Null
                    Write-Host "OK: $($task.InstanceID)" -ForegroundColor Green
                } catch {
                    Write-Host "Failed ($($task.InstanceID)): $_" -ForegroundColor Red
                }
            }
        }

    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

function Apply-PendingMaintenance {
    Show-Header
    Write-Host "Fetching Pending Maintenance Actions..." -ForegroundColor Green

    try {
        $argsList = @("rds", "describe-pending-maintenance-actions", "--output", "json", "--profile", $global:AWSProfile)
        $output = Invoke-AWS-WithRetry -Arguments $argsList -ReturnJson
        $json = $output -join ""

        if ([string]::IsNullOrWhiteSpace($json)) {
            Write-Host "No pending maintenance actions found." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        $data = $json | ConvertFrom-Json
        # Filter for actual details
        $pending = @()
        if ($data.PendingMaintenanceActions) {
            $pending = $data.PendingMaintenanceActions | Where-Object { $_.PendingMaintenanceActionDetails }
        }

        if (!$pending -or $pending.Count -eq 0) {
            Write-Host "No pending maintenance actions found." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        # Flatten list for display
        # We might have multiple actions per resource, but usually one block.
        # Let's flatten: Resource -> Detail
        $flatList = @()
        foreach ($p in $pending) {
            $id = Get-InstanceIdFromArn $p.ResourceIdentifier

            foreach ($d in $p.PendingMaintenanceActionDetails) {
                $flatList += [PSCustomObject]@{
                    ResourceArn = $p.ResourceIdentifier
                    InstanceID = $id
                    Action = $d.Action
                    Status = $d.CurrentApplyDate ? "Scheduled" : "Available" # Simplified status check
                    Description = $d.Description
                    AutoApplied = $d.AutoAppliedAfterDate
                }
            }
        }

        # Build options for Show-Menu
        $options = @()
        foreach ($item in $flatList) {
            $label = "{0,-20} | {1,-15} | {2}" -f $item.InstanceID, $item.Action, $item.Description
            $options += $label
        }

        $selectedIndices = Show-Menu -Title "Select Maintenance Actions to APPLY (SPACE to Select)" -Options $options -EnableFilter -MultiSelect

        if ($selectedIndices -eq -99) { $global:RestartSessionSelection = $true; return }
        if ($selectedIndices -is [int] -and $selectedIndices -lt 0) { return }

        if ($selectedIndices -eq $null -or $selectedIndices.Count -eq 0) {
            Write-Host "No actions selected." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        Show-Header
        Write-Host "ACTIONS TO APPLY:" -ForegroundColor Cyan
        foreach ($idx in $selectedIndices) {
            $item = $flatList[$idx]
            Write-Host " - $($item.InstanceID): $($item.Action)"
        }

        Write-Host ""
        # Using Show-Menu for timing selection to support ESC/q cancellation
        $timingOptions = @("Apply Immediately", "Schedule for Next Maintenance Window", "Cancel")
        $timingIdx = Show-Menu -Title "Select Application Timing (ESC/q to Cancel)" -Options $timingOptions # No Filter enabled implies 'q' quits

        if ($timingIdx -lt 0 -or $timingIdx -eq 2) {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        $optIn = if ($timingIdx -eq 0) { "immediate" } else { "next-maintenance" }

        foreach ($idx in $selectedIndices) {
            $item = $flatList[$idx]
            Write-Host "Applying '$($item.Action)' to '$($item.InstanceID)' ($optIn)..." -ForegroundColor Yellow

            try {
                $applyArgs = @("rds", "apply-pending-maintenance-action", "--resource-identifier", $item.ResourceArn, "--apply-action", $item.Action, "--opt-in-type", $optIn, "--profile", $global:AWSProfile)
                Invoke-AWS-WithRetry -Arguments $applyArgs | Out-Null
                Write-Host "Successfully requested update for $($item.InstanceID)." -ForegroundColor Green
            } catch {
                Write-Host "Failed: $_" -ForegroundColor Red
            }
        }

    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

function Remove-RDS-Interactive {
    $instances = Get-RDSInstances
    if (!$instances) {
        Write-Host "No instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $options = @($instances | ForEach-Object { "$($_.DBInstanceIdentifier) ($($_.DBInstanceStatus))" })

    $selectedIndices = Show-Menu -Title "Select Instances to DELETE (SPACE to Select)" -Options $options -EnableFilter -MultiSelect

    if ($selectedIndices -eq -99) { $global:RestartSessionSelection = $true; return }
    if ($selectedIndices -is [int] -and $selectedIndices -lt 0) { return }

    if ($selectedIndices -eq $null -or $selectedIndices.Count -eq 0) {
        Write-Host "No instances selected." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    Show-Header
    Write-Host "INSTANCES TO DELETE:" -ForegroundColor Red
    foreach ($idx in $selectedIndices) {
        Write-Host " - $($instances[$idx].DBInstanceIdentifier)" -ForegroundColor Red
    }

    $confirm = Read-Host "Type 'DELETE' to confirm DESTRUCTION of these instances"
    if ($confirm -eq "DELETE") {

        $snapChoice = Read-Host "Create Final Snapshot? [Y=Yes (Default) / n=No]"
        if ([string]::IsNullOrWhiteSpace($snapChoice)) { $snapChoice = "y" }

        foreach ($idx in $selectedIndices) {
            $inst = $instances[$idx]
            $id = $inst.DBInstanceIdentifier

            # 1. Disable Deletion Protection
            if ($inst.DeletionProtection) {
                Write-Host "Disabling deletion protection for '$id'..." -ForegroundColor Cyan
                try {
                    $modArgs = @("rds", "modify-db-instance", "--db-instance-identifier", $id, "--no-deletion-protection", "--apply-immediately", "--output", "json", "--profile", $global:AWSProfile)
                    Invoke-AWS-WithRetry -Arguments $modArgs -ReturnJson | Out-Null
                    Write-Host "Deletion protection disabled." -ForegroundColor Green
                } catch {
                    Write-Host "Failed to disable deletion protection for ${id}: $_" -ForegroundColor Red
                    # We continue attempting deletion, though it will likely fail if protection is still on.
                }
            }

            # 2. Delete Instance
            Write-Host "Deleting '$id'..." -ForegroundColor Yellow

            $argsList = @("rds", "delete-db-instance", "--db-instance-identifier", $id, "--profile", $global:AWSProfile)

            if ($snapChoice -eq "n") {
                $argsList += "--skip-final-snapshot"
            } else {
                $snapName = "final-snap-$id-$(Get-TimeStamp)"
                $argsList += "--db-snapshot-identifier", $snapName
                Write-Host "  Snapshot will be named: $snapName" -ForegroundColor Gray
            }

            try {
                # Use retry wrapper for consistency
                Invoke-AWS-WithRetry -Arguments $argsList | Out-Null
                Write-Host "Delete command issued for $id." -ForegroundColor Green
                $global:RDSInstancesCache = $null  # Invalidate cache after deletion
            } catch {
                Write-Host "Failed to delete ${id}: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
    }
    Read-Host "Press Enter to menu..."
}

function Start-RDS-Interactive {
    $instances = Get-RDSInstances
    if (!$instances) {
        Write-Host "No instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $options = @($instances | ForEach-Object { "$($_.DBInstanceIdentifier) ($($_.DBInstanceStatus))" })

    $selectedIndices = Show-Menu -Title "Select Instances to START (SPACE to Select)" -Options $options -EnableFilter -MultiSelect

    if ($selectedIndices -eq -99) { $global:RestartSessionSelection = $true; return }
    if ($selectedIndices -is [int] -and $selectedIndices -lt 0) { return }

    if ($selectedIndices -eq $null -or $selectedIndices.Count -eq 0) {
        Write-Host "No instances selected." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    foreach ($idx in $selectedIndices) {
        $inst = $instances[$idx]
        $id = $inst.DBInstanceIdentifier

        Write-Host "Starting '$id'..." -ForegroundColor Cyan
        try {
            aws rds start-db-instance --db-instance-identifier $id --profile $global:AWSProfile | Out-Null
            Write-Host "Start command issued for $id." -ForegroundColor Green
            $global:RDSInstancesCache = $null  # Invalidate cache after state change
        } catch {
            Write-Host "Failed to start ${id}: $_" -ForegroundColor Red
        }
    }
    Read-Host "Press Enter to menu..."
}

function Stop-RDS-Interactive {
    $instances = Get-RDSInstances
    if (!$instances) {
        Write-Host "No instances found." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $options = @($instances | ForEach-Object { "$($_.DBInstanceIdentifier) ($($_.DBInstanceStatus))" })

    $selectedIndices = Show-Menu -Title "Select Instances to STOP (SPACE to Select)" -Options $options -EnableFilter -MultiSelect

    if ($selectedIndices -eq -99) { $global:RestartSessionSelection = $true; return }
    if ($selectedIndices -is [int] -and $selectedIndices -lt 0) { return }

    if ($selectedIndices -eq $null -or $selectedIndices.Count -eq 0) {
        Write-Host "No instances selected." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    Show-Header
    Write-Host "INSTANCES TO STOP:" -ForegroundColor Red
    foreach ($idx in $selectedIndices) {
        Write-Host " - $($instances[$idx].DBInstanceIdentifier)" -ForegroundColor Red
    }

    $confirm = Read-Host "Type 'STOP' to confirm shutdown of these instances"
    if ($confirm -eq "STOP") {
        foreach ($idx in $selectedIndices) {
            $inst = $instances[$idx]
            $id = $inst.DBInstanceIdentifier

            Write-Host "Stopping '$id'..." -ForegroundColor Yellow
            try {
                aws rds stop-db-instance --db-instance-identifier $id --profile $global:AWSProfile | Out-Null
                Write-Host "Stop command issued for $id." -ForegroundColor Green
                $global:RDSInstancesCache = $null  # Invalidate cache after state change
            } catch {
                Write-Host "Failed to stop ${id}: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
    }
    Read-Host "Press Enter to menu..."
}

function Check-For-Updates-Silent {
    try {
        # Force TLS 1.2 for GitHub connection compatibility
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "RDS-BG-Manager")
        # Use HttpWebRequest internally with timeout to avoid hanging on unreachable hosts
        $uri = [System.Uri]::new($global:UpdateUrl)
        $request = [System.Net.HttpWebRequest]::Create($uri)
        $request.Timeout = 10000 # 10 second timeout
        $request.UserAgent = "RDS-BG-Manager"
        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
        $newScriptContent = $reader.ReadToEnd()
        $reader.Close()
        $response.Close()
        
        # Regex to handle potential whitespace
        $versionRegex = '# VERSION:\s*(\d+\.\d+\.\d+\.\d+)'

        # Parse version from content
        if ($newScriptContent -match $versionRegex) {
            $remoteVerStr = $matches[1]
            
            # Parse current version
            $scriptPath = $MyInvocation.MyCommand.Path
            if ([string]::IsNullOrWhiteSpace($scriptPath)) {
                $scriptPath = $PSCommandPath
            }
            if ([string]::IsNullOrWhiteSpace($scriptPath)) {
                # Fallback to current directory if all else fails
                $scriptPath = Join-Path $PSScriptRoot "rds_bg_manager.ps1"
            }

            if (Test-Path $scriptPath) {
                $currentContent = Get-Content -Path $scriptPath -Raw
                $currentVerStr = "0.0.0.0"
                if ($currentContent -match $versionRegex) {
                    $currentVerStr = $matches[1]
                }

                $vRemote = [version]$remoteVerStr
                $vCurrent = [version]$currentVerStr

                if ($vRemote -gt $vCurrent) {
                    return @{
                        HasUpdate = $true
                        NewVersion = $remoteVerStr
                        CurrentVersion = $currentVerStr
                        NewContent = $newScriptContent
                        ScriptPath = $scriptPath
                    }
                }
            }
        }
    } catch {}
    return $null
}

function Check-For-Updates-Interactive {
    Show-Header
    Write-Host "Checking for updates..." -ForegroundColor Green
    Write-Host "Source: $global:UpdateUrl" -ForegroundColor Gray

    $updateInfo = Check-For-Updates-Silent

    if ($updateInfo) {
        Write-Host "`nCurrent Version: $($updateInfo.CurrentVersion)" -ForegroundColor White
        Write-Host "Remote Version:  $($updateInfo.NewVersion)" -ForegroundColor White
        Write-Host "`nNew version available!" -ForegroundColor Green

        $update = Read-Host "Update now? (Y/n)"
        if ($update -ne 'n') {
            try {
                $backupPath = "$($updateInfo.ScriptPath).bak"
                Copy-Item -Path $updateInfo.ScriptPath -Destination $backupPath -Force
                Write-Host "Backup saved to: $backupPath" -ForegroundColor Gray

                Set-Content -Path $updateInfo.ScriptPath -Value $updateInfo.NewContent
                Write-Host "Update successful! Please restart the script." -ForegroundColor Green
                Read-Host "Press Enter to exit..."
                exit
            } catch {
                Write-Host "Update failed: $_" -ForegroundColor Red
            }
        }
    } else {
        # Check current version just for display
        $scriptPath = $MyInvocation.MyCommand.Path
        if ([string]::IsNullOrWhiteSpace($scriptPath)) { $scriptPath = $PSCommandPath }
        if ([string]::IsNullOrWhiteSpace($scriptPath)) { $scriptPath = Join-Path $PSScriptRoot "rds_bg_manager.ps1" }

        if (Test-Path $scriptPath) {
             $content = Get-Content $scriptPath -Raw
             if ($content -match '# VERSION:\s*(\d+\.\d+\.\d+\.\d+)') {
                 Write-Host "Current Version: $($matches[1])" -ForegroundColor White
             }
        }
        Write-Host "You are running the latest version." -ForegroundColor Green
    }
    Read-Host "Press Enter to menu..."
}

function Upgrade-Database-Interactive {
    if (!$global:SelectedInstance) {
        Write-Host "No active instance selected. Please select an instance first." -ForegroundColor Yellow
        Read-Host "Press Enter to menu..."
        return
    }

    $instance = $global:SelectedInstance
    Show-Header
    Write-Host "UPGRADE DATABASE ENGINE" -ForegroundColor Yellow
    Write-Host "------------------------------------------"
    Write-Host "Current Instance: $($instance.DBInstanceIdentifier)" -ForegroundColor White
    Write-Host "Current Engine:   $($instance.Engine)" -ForegroundColor White
    Write-Host "Current Version:  $($instance.EngineVersion)" -ForegroundColor White
    Write-Host "------------------------------------------"

    Write-Host "Fetching available upgrade versions..." -ForegroundColor Green
    try {
        # Check valid upgrades for this specific engine and version
        # Added --include-all to ensure non-default versions are found
        $argsVer = @("rds", "describe-db-engine-versions", "--engine", $instance.Engine, "--engine-version", $instance.EngineVersion, "--include-all", "--output", "json", "--profile", $global:AWSProfile)
        $output = Invoke-AWS-WithRetry -Arguments $argsVer -ReturnJson
        $json = $output -join ""

        if ([string]::IsNullOrWhiteSpace($json)) {
            Write-Log "Could not fetch engine version info." -ForegroundColor Red
            Read-Host "Press Enter to menu..."
            return
        }
        
        $data = $json | ConvertFrom-Json
        # Extract ValidUpgradeTarget from the specific version object
        $currentEngineVerObj = if ($data.DBEngineVersions -is [array]) { $data.DBEngineVersions[0] } else { $data.DBEngineVersions }
        $validUpgrades = $currentEngineVerObj.ValidUpgradeTarget
        
        if (!$validUpgrades) {
            Write-Host "No valid upgrade targets found for this version ($($instance.EngineVersion))." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        # List targets
        $targets = $validUpgrades | Sort-Object EngineVersion
        $options = @($targets | ForEach-Object { "$($_.EngineVersion) $(if($_.IsMajorVersionUpgrade){'[MAJOR]'}else{'[minor]'}) - $($_.Description)" })
        $options += "Cancel"

        $idx = Show-Menu -Title "Select Target Version (Current: $($instance.EngineVersion))" -Options $options -EnableFilter
        
        if ($idx -eq -1 -or $idx -eq ($options.Count - 1)) { return }

        $selectedTarget = $targets[$idx]
        $targetVer = $selectedTarget.EngineVersion
        
        Show-Header
        Write-Host "UPGRADE CONFIRMATION" -ForegroundColor Magenta
        Write-Host "------------------------------------------"
        Write-Host "Instance:       $($instance.DBInstanceIdentifier)" -ForegroundColor White
        Write-Host "Target Version: $targetVer" -ForegroundColor Yellow
        Write-Host "Is Major:       $($selectedTarget.IsMajorVersionUpgrade)" -ForegroundColor Gray
        Write-Host "------------------------------------------"
        Write-Host "REMINDER: Disable monitoring before proceeding!" -ForegroundColor Red -BackgroundColor Yellow
        Write-Host "------------------------------------------"

        # Check Read-Only Profile
        $isReadOnly = $global:AWSProfile -match "ro" -or $global:AWSProfile -match "readonly"
        
        if ($isReadOnly) {
            Write-Host "`n[BLOCK] You are using a Read-Only profile ('$global:AWSProfile')." -ForegroundColor Red
            Write-Host "Upgrade cannot be performed. This is a simulation." -ForegroundColor Yellow
            Read-Host "Press Enter to menu..."
            return
        }

        # Snapshot Option
        $defaultSnapName = "rds-before-upgrade-$($instance.DBInstanceIdentifier)-$(Get-TimeStamp)"
        Write-Host "`n[Snapshot Options]" -ForegroundColor Cyan
        Write-Host "Default Name: $defaultSnapName" -ForegroundColor Gray
        $snapChoice = Read-Host "Create Pre-Upgrade Snapshot? [Y=Yes (Default) / n=No / c=Change Name]"
        if ([string]::IsNullOrWhiteSpace($snapChoice)) { $snapChoice = "y" }

        if ($snapChoice -eq "c") {
            $customName = Read-Host "Enter Snapshot Name"
            if (![string]::IsNullOrWhiteSpace($customName)) {
                $defaultSnapName = $customName
            }
            $snapChoice = "y" # Proceed to create
        }

        if ($snapChoice -eq "y") {
            Write-Host "Creating snapshot '$defaultSnapName'..." -ForegroundColor Green
            try {
                $snapArgs = @("rds", "create-db-snapshot", "--db-instance-identifier", $instance.DBInstanceIdentifier, "--db-snapshot-identifier", $defaultSnapName, "--profile", $global:AWSProfile)
                Invoke-AWS-WithRetry -Arguments $snapArgs | Out-Null
                Write-Host "Snapshot creation initiated successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to create snapshot: $_" -ForegroundColor Red
                $proceed = Read-Host "Do you want to continue with upgrade anyway? (y/N)"
                if ($proceed -ne "y") { return }
            }
        } else {
            Write-Log "Skipping snapshot." -ForegroundColor Yellow
        }

        Write-Host ""
        $applyNow = Read-Host "Apply Immediately? (y/n) [Default: n]"
        $confirm = Read-Host "Type 'UPGRADE' to proceed"
        
        if ($confirm -eq "UPGRADE") {
            Write-Host "Initiating modification..." -ForegroundColor Green
            
            $argsList = @("rds", "modify-db-instance", "--db-instance-identifier", $instance.DBInstanceIdentifier, "--engine-version", $targetVer, "--output", "json", "--profile", $global:AWSProfile)
            
            if ($applyNow -eq 'y') {
                $argsList += "--apply-immediately"
            }
            if ($selectedTarget.IsMajorVersionUpgrade) {
                $argsList += "--allow-major-version-upgrade"
            }

            try {
                $output = Invoke-AWS-WithRetry -Arguments $argsList -ReturnJson
                $res = $output | ConvertFrom-Json
                Write-Host "Upgrade initiated successfully!" -ForegroundColor Cyan
                Write-Host "Status: $($res.DBInstance.DBInstanceStatus)" -ForegroundColor Gray
            } catch {
                Write-Host "Upgrade failed: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
        }

    } catch {
        Write-Host "Error fetching upgrade info: $_" -ForegroundColor Red
    }
    Read-Host "Press Enter to menu..."
}

# --- INITIALIZATION ---

if ($MyInvocation.InvocationName -ne '.') {
    # Startup Update Check
    Write-Host "Checking for updates..." -ForegroundColor Gray
    $global:UpdateAvailable = Check-For-Updates-Silent
    if ($global:UpdateAvailable) {
        Write-Host "New version found: $($global:UpdateAvailable.NewVersion)" -ForegroundColor Green
        Start-Sleep -Seconds 1
    }

    while ($true) {
        $global:RestartSessionSelection = $false
        $global:AWSConfigDataCache = $null  # Clear config cache on session restart
        # Loop wrapper for Select-AWSProfile to avoid deep recursion (3.7)
        while ($true) {
            $result = Select-AWSProfile
            if ($result -ne "__RESTART__") { break }
        }

        # --- MAIN LOOP ---

        while ($true) {
            if ($global:RestartSessionSelection) { break }

            $otaLabel = "Check for Updates (OTA)"
            if ($global:UpdateAvailable) {
                 $otaLabel += " [new version found: $($global:UpdateAvailable.NewVersion)]"
            }

            $menuOptions = @(
                "RDS Management",
                "EC2 Management",
                "AWS Sessions (Assume/Granted)",
                $otaLabel,
                "Quit"
            )

            $selection = Show-Menu -Title "Main Menu" -Options $menuOptions

            if ($global:RestartSessionSelection) { break }

            switch ($selection) {
                0 { Show-RDS-Menu }
                1 { Show-EC2-Menu }
                2 { Show-AWSSessions-Menu }
                3 { Check-For-Updates-Interactive }
                4 {
                    # Restore cursor before exit
                    try { [Console]::CursorVisible = $true } catch {}
                    Clear-Host
                    Write-Host "Exiting..."
                    exit
                }
            }
        }
    }
}
