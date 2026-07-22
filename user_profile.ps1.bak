# 起動時間の測定開始
$startTime = Get-Date
Write-Host "Starting profile load at $startTime"

# 必要に応じてモジュールを遅延インポート
function Use-TerminalIcons {
    if (Get-Module -ListAvailable Terminal-Icons) {
        Import-Module Terminal-Icons
        Write-Host "Terminal-Icons loaded."
    } else {
        Write-Host "Terminal-Icons module not installed. Run 'Install-Module Terminal-Icons'."
    }
}

function Use-OhMyPosh {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        oh-my-posh init pwsh --config "$env:USERPROFILE\scoop\apps\oh-my-posh\current\themes\avit.omp.json" | Invoke-Expression
        Write-Host "oh-my-posh loaded."
    } else {
        Write-Host "oh-my-posh is not installed. Run 'scoop install oh-my-posh'."
    }
}
# 関数を実行して oh-my-posh を適用
Use-OhMyPosh

# エイリアス削除と再定義
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


# ls の再定義
if (Test-Path alias:ls) { Remove-Item alias:ls }
if (Test-Path "C:\src\busybox\busybox64u.exe") {
    if (Test-Path function:ls) { Remove-Item function:ls }
    function ls { & "C:\src\busybox\busybox64u.exe" ls --color $args }
    Write-Host "ls redefined to use BusyBox."
} else {
    Write-Host "BusyBox not found at C:\src\busybox\busybox64u.exe. Please check the path."
}

# scoop-completion モジュールの遅延ロード
Register-ArgumentCompleter -CommandName scoop -ScriptBlock {
    $scoopCompletionPath = "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)\modules\scoop-completion"
    if (Test-Path $scoopCompletionPath) {
        Import-Module $scoopCompletionPath
        Write-Host "scoop-completion loaded."
    } else {
        Write-Host "scoop-completion module not found. Check your scoop installation."
    }
}

# GitHub CLI (gh) の補完
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh completion -s powershell | Out-String | Invoke-Expression
    Write-Host "GitHub CLI (gh) completions loaded."
} else {
    Write-Host "GitHub CLI (gh) is not installed. Run 'scoop install gh'."
}
# posh-git のインポートと設定
# posh-git の遅延インポート関数
function Use-PoshGit {
    if (Get-Module -ListAvailable posh-git) {
        Import-Module posh-git
        Write-Host "posh-git loaded."

        # Git プロンプトの設定
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

# PSReadLine の設定
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    Write-Host "PSReadLine configured."
} else {
    Write-Host "PSReadLine module not installed. Run 'Install-Module PSReadLine'."
}

# パスの設定
$pathsToAdd = @("$HOME\.cargo\bin", "C:\src\busybox")
foreach ($path in $pathsToAdd) {
    if (-not $env:Path.Contains($path)) {
        $env:Path += ";$path"
        Write-Host "Added $path to PATH."
    }
}

# 起動時間の測定終了
Write-Host "Profile loaded in $((Get-Date) - $startTime).Seconds seconds."
