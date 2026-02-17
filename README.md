# AWS RDS Blue/Green Deployment Tool

**Author:** Wojciech Kuncewicz DBA
**Version:** 2026.02.16.07

A comprehensive PowerShell-based interactive CLI tool for managing AWS RDS Blue/Green Deployments, Snapshots, and Database Upgrades. This tool simplifies complex AWS operations into an easy-to-use menu-driven interface.

## Features

- **Performance Optimization:**
    - **Data Caching:** RDS Instance lists are cached for 60 seconds to provide instant menu navigation. Press **F5** to force refresh.
    - **Parallel Execution:** Batch operations (Create Multiple Snapshots, Update OS) now execute in parallel (requires PowerShell 7+), drastically reducing wait times.
    - **Optimized Rendering & Parsing:** Uses `System.Text.StringBuilder` for flicker-free UI and streamlined JSON parsing logic for faster AWS CLI response handling.
    - **Resilience:** Built-in Exponential Backoff for handling AWS Throttling and Rate Limit errors.
- **Interactive Menu Interface:** Major UI/UX overhaul featuring "Frozen Headers" and viewport scrolling. Navigate large lists easily without losing context. Supports Search-as-you-type, multi-selection, and fast navigation.
- **Flicker-Free Rendering:** Implements a Double-Buffered Virtual Screen engine using `System.Text.StringBuilder` and ANSI escape codes to eliminate screen flickering during menu navigation.
- **AWS SSO Integration:** Automatically detects and configures AWS profiles.
- **Client (Session) Filtering:** Filters profiles by AWS SSO Session (Client) for easier navigation.
- **Environment Awareness:** Parses `env` and `type` fields from `.aws/config` to display visual warnings:
    - **Green:** Read-Only (RO) environments.
    - **Orange:** Non-Production Read-Write (RW) environments (e.g., Int/Dev/Pre).
    - **Red:** Production Read-Write (RW) environments.
- **RDS Management:**
    - **Blue/Green Deployments:** Interactive creation with dynamic Version and Parameter Group selection. Deletion now includes Replica Lag checks. Includes "Search-as-you-type" instance selection.
    - **Snapshot Management:** Create Single/Multiple snapshots, Delete snapshots, Monitor progress (shows 10 freshest snapshots from the last 10 days, prioritizing in-progress ones). **Includes Pre-flight Quota Check** (verifies 100 manual snapshot limit).
    - **Database Operations:** Upgrade Engine, View Logs, Check Replica Lag.
    - **Update OS:** Specialized workflow for `system-update` maintenance with safeguards (Snapshots, Monitoring alerts).
    - **Apply Pending Maintenance:** Interactive selection and batch application of pending maintenance actions.
    - **Reporting:** Instance Details, Storage, Backup info, **Recommendation List** (Compute Optimizer).
- **EC2 Management:**
    - **Control:** Start/Stop instances interactively.
    - **Snapshots:** Create snapshots of all volumes attached to an instance; Delete snapshots.
    - **Reporting:** List instances by Status, Type, Availability Zone.
- **Configuration:** External configuration file (`rds_bg_manager.config.ps1`) for customization.
- **Self-Update (OTA):** built-in mechanism to check and download the latest version of the script. Checks automatically at startup.

## Requirements

- **Operating System:** Windows (PowerShell 5.1 or PowerShell Core 7+) or Linux/macOS (PowerShell Core).
- **AWS CLI v2:** Must be installed and available in PATH.
- **AWS Permissions:** The configured AWS Profile must have permissions to manage RDS, Blue/Green Deployments, Snapshots, and CloudWatch metrics.

## Installation

1. Clone the repository or download `rds_bg_manager.ps1`.
2. Ensure you have `rds_bg_manager.config.ps1` in the same directory (created automatically if missing on first run, though usually distributed with the script).
3. Open PowerShell terminal.

## Configuration

### AWS Config Metadata
You can add `env` and `type` fields to your `~/.aws/config` profiles to enable color-coded warnings in the tool:

```ini
[profile my-prod-db]
sso_session = my-session
sso_account_id = 123456789012
sso_role_name = Admin
env = PROD
type = RW
```

- **Green:** Profiles with `type = RO`, `type = READONLY`, or containing `_ro` / `-ro` in the name.
- **Orange:** Profiles where `env` is NOT 'prod' (e.g., INT, DEV, PRE) and `type = RW`.
- **Red:** Profiles where `env = PROD` and `type = RW`.

### Script Configuration
You can customize basic settings in `rds_bg_manager.config.ps1`:

```powershell
@{
    WindowTitle = "AWS RDS BLUE/GREEN DEPLOYMENT TOOL by WK"
    UpdateUrl = "https://raw.githubusercontent.com/..."
    LogFileFormat = "rds_manager_{0:yyyyMMdd}.log"
}
```

## Usage

Run the script:

```powershell
.\rds_bg_manager.ps1
```

### Initial Setup
On the first run, you will be prompted to select a **Client (SSO Session)**:
1.  Select the Client (based on `sso_session` in your `.aws/config`).
2.  Select the **AWS Profile** associated with that client.
    - Profiles are color-coded based on Environment/Type.
3.  If you don't have one configured, select **"Add New Profile (aws configure sso)"**.
4.  You can also **Delete** old profiles from the profile selection menu.

### Main Menu Options

**1. RDS Management**
   - Access all RDS-related features: Reports, Snapshots, B/G Deployments, Upgrades, Log Viewing.
   - **Create Blue/Green Deployment:** Now supports interactive selection of Target Engine Version and Parameter Group.

**2. EC2 Management**
   - **Select Active EC2:** Choose an instance to operate on.
   - **EC2 Reports:** View status, type, and launch time of instances.
   - **Other Reports:** Group instances by Availability Zone.
   - **Start/Stop EC2:** Control power state of the selected instance.
   - **Create Snapshot:** Create snapshots for all volumes of the active EC2 instance.
   - **Remove Snapshot:** Batch delete EC2 snapshots.

**3. Check for Updates (OTA)**
   - Displays `[founded new: VERSION]` if a new version was detected at startup.
   - Select to update the script.

## Troubleshooting

- **"Cannot bind argument to parameter 'Path'..." during update:** Ensure you are running the script from a saved file, not an untitled editor buffer.
- **TLS/SSL Errors:** The script attempts to enforce TLS 1.2. Ensure your .NET framework is up to date.
- **AWS CLI Errors:** Run `aws sso login` manually if the script fails to refresh credentials.

## License

Internal Tool.

## Changelog

### 2026-02-16 (Part 3)
- **Optimization:** Replaced array concatenation with `System.Collections.Generic.List` in menu engine.
- **Optimization:** Global JSON parsing refactor for speed.
- **Resilience:** Implemented Exponential Backoff for AWS Throttling errors.

### 2026-02-16 (Part 2)
- **Data Caching:** Added global caching for RDS instances (TTL 60s) to speed up UI navigation.
- **F5 Refresh:** Added ability to force data refresh in menus and monitors.
- **Parallel Processing:** Enabled parallel execution for batch snapshots and OS updates (PS 7+).

### 2026-02-16 (Part 1)
- Major Rendering Engine Overhaul: Implemented Double-Buffered "Virtual Screen" rendering for interactive menus to eliminate flickering.
- Added ANSI helper functions for improved UI performance and string manipulation.
- Updated core UI components to support non-blocking rendering.

### 2026-02-12
- Refactored 'Delete Snapshots' to use the new viewport engine, allowing search, multi-selection, and bulk deletion of all manual snapshots (removed 50-item limit).
- Added 'Pre-flight Snapshot Quota Check' for single and multiple snapshot workflows.

### 2026-02-11
- Maintenance Release: Verified stability of recent safety patches.
- Documentation Update: Refined internal documentation strings.

### 2026-02-10
- Enhanced 'Apply Pending Maintenance': The confirmation prompt is now cancellable.
- Updated Show-Menu to support 'q' key for cancellation.
- Fixed critical safety bug in Multi-Select menus (Update OS, Apply Maintenance, Create Multiple Snapshots).
- Fixed 'Delete Blue/Green Deployment': Removed redundant 'Cancel' option.
- Improved error logging for 'Create Blue/Green Deployment'.
- Added 'Update OS' feature to RDS Management menu.
- Added 'Apply Pending Maintenance' feature to RDS Management menu.
- Removed pre-filtering by Engine in 'Select Active Instance'.
- Added 'Monitor Instance State' to RDS Management menu.
- Updated text in Upgrade Database reminder.
- Fixed 'Upgrade Database Engine' logic (added --include-all).
- Added 'Recommendation list' report (Compute Optimizer).
- Enhanced 'Delete Instance(s)' to automatically disable 'Deletion Protection'.
- Fixed 'Monitor-Snapshot-Progress' to correctly include and prioritize in-progress snapshots.
- Updated snapshot sorting logic.
- Added automatic SSO Token refresh prompt.
- Fixed critical 'No instances selected' bug in Start/Stop/Delete workflows.
- Enhanced 'Delete Blue/Green Deployment': Added Replica Lag check.
- Improved Menu UI.
- Fixed 'Create Blue/Green Deployment' bug (Green DB Name).
- Removed 'Green DB Name' user input prompt.

### 2026-02-09
- Fixed 'Create Blue/Green Deployment' error handling (stderr capture).
- Fixed 'Could not determine parameter group family' error.
- Added argument trimming to Engine and EngineVersion.
- Fixed 'Delete Blue/Green Deployment' menu bug.
- Improved error logging for 'Create Blue/Green Deployment'.
- Improved debugging info for Parameter Group Family.
- Added F1 key navigation.
- Modified Monitor-Snapshot-Progress to be a global monitor.
- Updated profile color logic (Green/Orange/Red).
- Added DarkYellow (Orange) warning color.
- Added automatic OTA update check at startup.
- Added parsing of 'env' and 'type' fields from .aws/config.
- Added color-coded environment warnings.
- Updated 'Create Blue/Green Deployment' menus.
- Added 'MaxSelectionCount' support to Show-Menu.
- Fixed bug in single-instance selection menu.

### 2026-02-06
- Fixed critical bug in Client (Session) selection.
- Improved AWS Config parsing robustness.
- Added Client (Session) Selection step.
- Window Title now reflects Client | Profile - Role.
- Added interactive 'Delete Profile' option.
- Added README.md documentation.
- Changed default Window Title.
- Fixed OTA version check logic.
- Added 'Create multiple snapshots' feature.
- Added 'Delete Snapshots' feature.
- Moved configuration to external file.
- Modified Show-Menu to support multi-selection.
- Modified Monitor-Snapshot-Progress (Last 10 snapshots).
- Updated snapshot monitoring columns.

### 2026-02-04
- Split DB Versions report.
- Added full script logging to file.
- Added CSV/HTML export.
- Added dynamic AWS Profile discovery and SSO setup.
- Added Engine filtering.
- Added interactive Log Viewer.
- Fixed Write-Host formatting.

### 2026-02-03
- Initial implementation of interactive arrow-key navigation.
- Added visual highlighting for Blue/Green instances.
- Added Instance Reports structure.
- Added Other Reports.
