# AWS RDS Blue/Green Deployment Manager

Interactive PowerShell tool for managing AWS RDS instances, Blue/Green deployments, snapshots, and maintenance — built for DBA workflows with IAM Identity Center (SSO) authentication.

> **Author:** Wojciech Kuncewicz DBA

---

## Features

### RDS Instance Management

| Feature | Description |
|---------|-------------|
| **Select Active Instance** | Choose an instance to work with (live search filter) |
| **Start / Stop / Delete Instance(s)** | Multi-select batch operations with safety confirmations |
| **Monitor Instance State** | Real-time dashboard with live name filtering and PgUp/PgDn pagination |

### Blue/Green Deployments

| Feature | Description |
|---------|-------------|
| **Create Blue/Green Deployment** | Interactive wizard with engine version and parameter group selection |
| **Monitor Deployment Status** | Full dashboard: status, tasks checklist, replica lag, engine versions, elapsed time |
| **Execute Switchover** | Promote Green to production with safety checks |
| **Delete Blue/Green Deployment** | Pre-deletion replica lag check, auto-disable deletion protection |
| **Upgrade Database Engine** | Guided version upgrade workflow |
| **Update OS** | Batch system-update application with safeguards |

### Snapshots

| Feature | Description |
|---------|-------------|
| **Create Snapshot** | Single instance with custom naming |
| **Create Multiple Snapshots** | Multi-select, parallel execution (PS7+), quota pre-check (100 limit) |
| **Delete Snapshots** | Search, multi-select, bulk deletion |
| **Active Snapshots Progress** | Real-time progress monitor for in-flight snapshots |

### Reports

| Report | Description |
|--------|-------------|
| **Instance Details** | Full instance configuration dump |
| **Recent Snapshots / Last 30 Days** | Per-instance snapshot history |
| **Blue/Green Replica Lag** | Real-time CloudWatch metrics |
| **Database Logs** | Interactive log file viewer |
| **RDS Events (24h)** | Recent event stream |
| **Pending OS Upgrade** | Instances with pending maintenance |
| **DB All Details / Versions** | Cross-instance engine comparison |
| **Recommendation List** | AWS Compute Optimizer findings |

All reports support **CSV/HTML export**.

### EC2 Management

Basic EC2 instance operations: select, start, stop, create/remove snapshots, and reports.

### AWS Sessions

- **IAM Identity Center (SSO)** authentication flow
- **Assume Role / Granted** session management
- Automatic SSO token refresh on expiration
- Color-coded profiles by environment: 🟢 Read-Only | 🟠 Non-Prod RW | 🔴 Prod RW

---

## Requirements

| Requirement | Version |
|-------------|---------|
| **PowerShell** | 5.1+ (7+ recommended for parallel execution) |
| **AWS CLI** | v2, configured with IAM Identity Center |
| **OS** | Windows (primary), Linux/macOS (partial) |

---

## Installation

```powershell
# Clone the repository
git clone https://github.com/wojtulab/blue-green-aws.git
cd blue-green-aws

# Run the tool
pwsh ./rds_bg_manager.ps1
# or on Windows PowerShell:
powershell -ExecutionPolicy Bypass -File rds_bg_manager.ps1
```

### AWS CLI Setup

The tool requires AWS CLI v2 with at least one SSO profile configured:

```bash
aws configure sso
```

Profiles should be defined in `~/.aws/config` with optional `env` and `type` fields for color-coding:

```ini
[profile my-prod-admin]
sso_session = my-company
sso_account_id = 123456789012
sso_role_name = AdministratorAccess
region = eu-west-1
# Optional metadata for UI color-coding:
# env = PRD
# type = RW
```

---

## Configuration

External config file: **`rds_bg_manager.config.ps1`** (same directory as the script).

```powershell
@{
    WindowTitle   = "AWS RDS BLUE/GREEN DEPLOYMENT TOOL by WK"
    UpdateUrl     = "https://raw.githubusercontent.com/wojtulab/blue-green-aws/refs/heads/main/rds_bg_manager.ps1"
    LogFileFormat = "rds_manager_{0:yyyyMMdd}.log"
}
```

| Key | Description | Default |
|-----|-------------|---------|
| `WindowTitle` | Terminal window title | `AWS RDS Blue/Green Manager` |
| `UpdateUrl` | URL for OTA update check | GitHub raw URL |
| `LogFileFormat` | Log filename pattern (`{0}` = date) | `rds_manager_YYYYMMDD.log` |

---

## Keyboard Controls

### Menus

| Key | Action |
|-----|--------|
| `↑` `↓` | Navigate |
| `Enter` | Select |
| `Space` | Toggle selection (multi-select menus) |
| `Esc` | Back / Cancel |
| `F1` | Return to Client/Session selection |
| `F5` | Force cache refresh |
| Type text | Live search filter |

### Monitor Views

| Key | Action |
|-----|--------|
| Type text | Live filter by instance name |
| `Backspace` | Remove last filter character |
| `Esc` | Clear filter (or exit if filter empty) |
| `PgUp` / `PgDn` | Navigate pages |
| `F5` | Force data refresh |
| `Enter` | Exit monitor |

---

## Architecture

```
rds_bg_manager.ps1          Main script (~4400 lines)
rds_bg_manager.config.ps1   External configuration (optional)
rds_manager_YYYYMMDD.log    Daily log file (auto-created)
```

### Key Technical Details

- **Flicker-free rendering** — `StringBuilder` + `[Console]::SetCursorPosition` instead of `Clear-Host`
- **Data caching** — RDS instances cached with 60-second TTL, force refresh via F5
- **AWS API resilience** — `Invoke-AWS-WithRetry` with exponential backoff + jitter for throttling
- **Automatic SSO refresh** — detects expired tokens and prompts re-login
- **OTA updates** — checks GitHub for new versions at startup (10s timeout)
- **Parallel execution** — multi-snapshot and OS update use `ForEach-Object -Parallel` on PS7+

---

## Logging

All operations are logged to daily files (`rds_manager_YYYYMMDD.log`) in the script directory. Log entries include timestamps and are written via the `Write-Log` function which outputs to both console and file.

---

## License

Internal tool — © Wojciech Kuncewicz
