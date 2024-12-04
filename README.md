
# PowerShell Configuration Setup Guide

This guide explains how to set up a shared PowerShell profile using OneDrive for synchronization across multiple machines.

---

## 1. Prerequisites

Before you begin, ensure you have the following installed:

- **PowerShell** (version 5.1 or later)
- **OneDrive** configured on your machine

---

## 2. Installing Required Tools

We use `scoop` to manage and install required tools.

### 2.1 Installing Scoop

- **Overview**: Scoop is a package manager for Windows that simplifies software installation.
- **Installation Command**:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
  ```
- **Add Additional Buckets**:
  ```powershell
  scoop bucket add extras
  ```

### 2.2 Installing Essential Tools

Install the following tools via `scoop`:

- `sudo`: Easily elevate privileges in PowerShell.
- `emacs`: A powerful text editor.
- `vim`: Lightweight and feature-rich text editor.
- `wget`: Command-line file downloader.
- `curl`: Data transfer tool.
- `git`: Version control system.

**Installation Command**:
```powershell
scoop install sudo emacs vim wget curl git
```

---

## 3. Configuring Additional Tools

### 3.1 oh-my-posh

- **Overview**: Customizes your PowerShell prompt.
- **Installation**:
  ```powershell
  scoop install oh-my-posh
  ```
- **Configuration**: Add the following to your `$PROFILE`:

  ```powershell
  function Use-OhMyPosh {
      if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
          oh-my-posh init pwsh --config "$env:USERPROFILE\scoop\apps\oh-my-posh\current\themes\avit.omp.json" | Invoke-Expression
          Write-Host "oh-my-posh loaded."
      } else {
          Write-Host "oh-my-posh is not installed. Run 'scoop install oh-my-posh'."
      }
  }
  Use-OhMyPosh
  ```

### 3.2 posh-git

- **Overview**: Adds Git status and tab completion to the PowerShell prompt.
- **Installation**:
  ```powershell
  scoop install posh-git
  ```
- **Configuration**: Add the following to your `$PROFILE`:

  ```powershell
  function Use-PoshGit {
      if (Get-Module -ListAvailable posh-git) {
          Import-Module posh-git
          Write-Host "posh-git loaded."

          $GitPromptSettings = @{
              BeforeText = '('
              AfterText = ')'
              BranchText = 'branch: '
          }
      } else {
          Write-Host "posh-git module not installed. Run 'scoop install posh-git'."
      }
  }
  Use-PoshGit
  ```

### 3.3 GitHub CLI (gh)

- **Overview**: Command-line interface for GitHub.
- **Installation**:
  ```powershell
  scoop install gh
  ```
- **Completion Configuration**:
  Add the following to your `$PROFILE`:
  ```powershell
  if (Get-Command gh -ErrorAction SilentlyContinue) {
      gh completion -s powershell | Out-String | Invoke-Expression
      Write-Host "GitHub CLI (gh) completions loaded."
  } else {
      Write-Host "GitHub CLI (gh) is not installed. Run 'scoop install gh'."
  }
  ```

### 3.4 BusyBox

- **Overview**: Provides Unix utilities for Windows.
- **Official Website**: [https://frippery.org/busybox/](https://frippery.org/busybox/)
- **Installation Steps**:
  1. Download `busybox64u.exe`.
  2. Place the file in `C:\src\busybox`.

- **Configuration**:
  Add the following to your `$PROFILE`:

  ```powershell
  if (Test-Path "C:\src\busybox\busybox64u.exe") {
      if (Test-Path function:ls) { Remove-Item function:ls }
      function ls { & "C:\src\busybox\busybox64u.exe" ls --color $args }
      Write-Host "ls redefined to use BusyBox."
  } else {
      Write-Host "BusyBox not found at C:\src\busybox\busybox64u.exe. Please check the path."
  }
  ```

---

## 4. Setting Up a Shared PowerShell Profile

Instead of using symbolic links, we directly modify the default profile to include the shared profile.

### 4.1 Move Profile to OneDrive

Move your existing PowerShell profile file to OneDrive for synchronization:

```powershell
Move-Item -Path "$Profile.CurrentUserCurrentHost" -Destination "$env:USERPROFILE\OneDrive\development\powershell\user_profile.ps1"
```

### 4.2 Modify Default Profile to Load Shared Profile

Append the shared profile's path to the default PowerShell profile file:

```powershell
Add-Content -Value "`r`n. `"C:\Users\shimo\OneDrive`\development\powershell\user_profile.ps1`"`r`n" `
            -Encoding utf8 `
            -Path $Profile.CurrentUserCurrentHost
```

### 4.3 Confirm Changes

Verify the changes by viewing the default profile:

```powershell
Get-Content $Profile.CurrentUserCurrentHost
```

Expected output:
```
. "C:\Users\shimo\OneDrive\development\powershell\user_profile.ps1"
```

### 4.4 Edit and Reload the Profile

- To edit the shared profile:
  ```powershell
  code "$env:USERPROFILE\OneDrive\development\powershell\user_profile.ps1"
  ```
- To reload the profile after changes:
  ```powershell
  . "$Profile.CurrentUserCurrentHost"
  ```

---

## Troubleshooting

### Common Errors

1. **Path Not Found**
   - Ensure the OneDrive directory and file paths are correct.
   - Use the following command to list the contents of the target directory:
     ```powershell
     Get-ChildItem "$env:USERPROFILE\OneDrive\development\powershell"
     ```

2. **Permission Denied**
   - Run PowerShell as an administrator.

3. **Changes Not Applied**
   - Reload the profile using:
     ```powershell
     . "$Profile.CurrentUserCurrentHost"
     ```

---


## Reference
1. symbolic link : https://www.itechtics.com/enable-gpedit-msc-windows-11/?utm_content=cmp-true
2. setting : https://scrapbox.io/hotchpotch/MacOS_%E3%83%A6%E3%83%BC%E3%82%B6%E3%81%8C_WSL_%E3%81%A7%E3%81%AF%E3%81%AA%E3%81%84_Windows_%E3%81%AE%E9%96%8B%E7%99%BA%E7%92%B0%E5%A2%83%E3%82%92%E6%95%B4%E3%81%88%E3%82%8B%E3%83%A1%E3%83%A2
3. setting ref : https://secon.dev/entry/2020/08/17/070735/#f-3360128f