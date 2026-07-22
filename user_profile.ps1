# =============================================================
#  user_profile.improved.ps1   (2026-07-22)
#  user_profile.ps1 の改善版（動作確認できたら差し替える用）
#  変更点:
#   - 起動時間表示のバグ修正
#   - gh 補完をキャッシュして毎回 gh を起動しない（高速化）
#   - PSReadLine に履歴予測入力(2.2+)を追加、Emacs キーバインドは維持
#   - oh-my-posh を 5.1/7 でシェル種別自動判定
#   - 情報メッセージは $ProfileVerbose で制御（既定は静か）
# =============================================================

$startTime = Get-Date

# 情報メッセージの表示切替。$true にすると "... loaded." 等が出る。
$ProfileVerbose = $false
function _log($msg) { if ($ProfileVerbose) { Write-Host $msg } }

# --- 遅延インポート（必要時に手動で呼ぶ）---
function Use-TerminalIcons {
    if (Get-Module -ListAvailable Terminal-Icons) {
        Import-Module Terminal-Icons
        _log "Terminal-Icons loaded."
    } else {
        Write-Host "Terminal-Icons module not installed. Run 'Install-Module Terminal-Icons'."
    }
}

# --- oh-my-posh（Windows PowerShell 5.1 / PowerShell 7 でシェル種別を自動判定）---
function Use-OhMyPosh {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        $ompShell = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }
        oh-my-posh init $ompShell --config "$env:USERPROFILE\scoop\apps\oh-my-posh\current\themes\avit.omp.json" | Invoke-Expression
        _log "oh-my-posh loaded."
    } else {
        Write-Host "oh-my-posh is not installed. Run 'scoop install oh-my-posh'."
    }
}
Use-OhMyPosh

# --- uutils で GNU coreutils を関数化 ---
if (Get-Command uutils -ErrorAction SilentlyContinue) {
    @"
arch, base32, base64, basename, cat, cksum, comm, cp, cut, date, df, dircolors, dirname,
echo, env, expand, expr, factor, false, fmt, fold, hashsum, head, hostname, join, link, ln,
md5sum, mkdir, mktemp, more, mv, nl, nproc, od, paste, printenv, printf, ptx, pwd,
readlink, realpath, relpath, rm, rmdir, seq, sha1sum, sha224sum, sha256sum, sha3-224sum,
sha3-256sum, sha3-384sum, sha3-512sum, sha384sum, sha3sum, sha512sum, shake128sum,
shake256sum, shred, shuf, sleep, sort, split, sum, sync, tac, tail, tee, test, touch, tr,
true, truncate, tsort, unexpand, uniq, wc, whoami, yes
"@ -split ',' |
    ForEach-Object { $_.trim() } |
    Where-Object { ! @('tee', 'sort', 'sleep').Contains($_) } |
    ForEach-Object {
        $cmd = $_
        if (Test-Path Alias:$cmd) { Remove-Item -Path Alias:$cmd }
        $fn = '$input | uutils ' + $cmd + ' $args'
        Invoke-Expression "function global:$cmd { $fn }"
    }
} else {
    Write-Host "uutils is not installed. Please install it first."
}

# --- ls を BusyBox に ---
if (Test-Path alias:ls) { Remove-Item alias:ls }
if (Test-Path "C:\src\busybox\busybox64u.exe") {
    if (Test-Path function:ls) { Remove-Item function:ls }
    function ls { & "C:\src\busybox\busybox64u.exe" ls --color $args }
    _log "ls redefined to use BusyBox."
} else {
    Write-Host "BusyBox not found at C:\src\busybox\busybox64u.exe."
}

# --- scoop 補完（遅延ロード）---
Register-ArgumentCompleter -CommandName scoop -ScriptBlock {
    $scoopCompletionPath = "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)\modules\scoop-completion"
    if (Test-Path $scoopCompletionPath) {
        Import-Module $scoopCompletionPath
    }
}

# --- GitHub CLI (gh) 補完（キャッシュ。gh 更新時のみ再生成）---
if (Get-Command gh -ErrorAction SilentlyContinue) {
    $ghComp = Join-Path $HOME '.cache\gh-completion.ps1'
    $ghExe  = (Get-Command gh).Source
    $needGen = (-not (Test-Path $ghComp)) -or ((Get-Item $ghExe).LastWriteTime -gt (Get-Item $ghComp).LastWriteTime)
    if ($needGen) {
        New-Item -ItemType Directory -Force -Path (Split-Path $ghComp) | Out-Null
        gh completion -s powershell | Out-File -Encoding utf8 $ghComp
    }
    . $ghComp
    _log "GitHub CLI (gh) completions loaded."
} else {
    Write-Host "GitHub CLI (gh) is not installed. Run 'scoop install gh'."
}

# --- posh-git ---
function Use-PoshGit {
    if (Get-Module -ListAvailable posh-git) {
        Import-Module posh-git
        _log "posh-git loaded."
        $GitPromptSettings = @{
            BeforeText = '('
            AfterText  = ')'
            BranchText = 'branch: '
        }
    } else {
        Write-Host "posh-git module not installed. Run 'scoop install posh-git'."
    }
}
Use-PoshGit

# --- PSReadLine（Emacs キーバインド + 履歴からの予測入力）---
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -BellStyle None
    # 予測入力は PSReadLine 2.2 以降のみ有効化（古い版で落ちないようガード）
    if ((Get-Module PSReadLine).Version -ge [version]'2.2.0') {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    _log "PSReadLine configured."
} else {
    Write-Host "PSReadLine module not installed. Run 'Install-Module PSReadLine'."
}

# --- PATH 追加 ---
$pathsToAdd = @("$HOME\.cargo\bin", "C:\src\busybox")
foreach ($path in $pathsToAdd) {
    if (-not ($env:Path -split ';' -contains $path)) {
        $env:Path += ";$path"
        _log "Added $path to PATH."
    }
}

# --- emacs (emacsclient) ---
# GUI は emacsclientw、-a '' で未起動ならデーモンを自動起動。
# ※ enw(-nw) は native Windows では不可（tty 非対応。WSL のみ）。
function e     { emacsclientw -n  -a '' @args }    # 既存フレームで開く
function eg    { emacsclientw -c  -n -a '' @args } # 新規フレームで開く
function enw   { emacsclient  -nw -a '' @args }    # 端末内(WSLのみ)
function ekill { emacsclient  -e '(kill-emacs)' }  # デーモン終了

# 起動時間
$elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
Write-Host "Profile loaded in $elapsed s."
