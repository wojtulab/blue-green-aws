# AWS RDS Blue/Green Deployment Tool

**Author:** Wojciech Kuncewicz DBA
**Version:** 2026.02.10.12

A comprehensive PowerShell-based interactive CLI tool for managing AWS RDS Blue/Green Deployments, Snapshots, and Database Upgrades. This tool simplifies complex AWS operations into an easy-to-use menu-driven interface.

## Features

- **Interactive Menu Interface:** Navigate using Arrow Keys, Select with Enter, Toggle multi-selection with Space.
- **AWS SSO Integration:** Automatically detects and configures AWS profiles.
- **Client (Session) Filtering:** Filters profiles by AWS SSO Session (Client) for easier navigation.
- **Environment Awareness:** Parses `env` and `type` fields from `.aws/config` to display visual warnings:
    - **Green:** Read-Only (RO) environments.
    - **Orange:** Non-Production Read-Write (RW) environments (e.g., Int/Dev/Pre).
    - **Red:** Production Read-Write (RW) environments.
- **RDS Management:**
    - **Blue/Green Deployments:** Interactive creation with dynamic Version and Parameter Group selection.
    - **Snapshot Management:** Create Single/Multiple snapshots, Delete snapshots, Monitor progress (shows 10 freshest snapshots from the last 10 days).
    - **Database Operations:** Upgrade Engine, View Logs, Check Replica Lag.
    - **Reporting:** Instance Details, Storage, Backup info (Export to CSV/HTML).
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
