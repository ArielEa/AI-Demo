# ===========================================
# SearchFiles.ps1
# 機能：指定フォルダ後、複数回ファイル名検索が可能。
#       ログ記録付き、起動時に前回フォルダを使うか新規選択するか選択可能
# ===========================================

# ログファイル
$logFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "SearchLog.txt"

# 前回の検索フォルダ確認
if (Test-Path ".\search_config.txt") {
    $oldPath = (Get-Content ".\search_config.txt" -Raw).Trim()
    Write-Host "前回保存された検索フォルダ：" -ForegroundColor Cyan
    Write-Host "➡ $oldPath" -ForegroundColor Green

    $choice = Read-Host "1: 前回のフォルダを使用  2: 新しいフォルダを選択"

    if ($choice -eq "1") {
        $searchPath = $oldPath
    } else {
        $searchPath = $null
    }
}

# 新規フォルダ選択
if (-not $searchPath) {
    Add-Type -AssemblyName System.Windows.Forms
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "検索するフォルダを選択してください"

    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $searchPath = $folderDialog.SelectedPath
        Out-File -FilePath ".\search_config.txt" -InputObject $searchPath -Encoding utf8
        Write-Host "`n検索フォルダを保存しました：" -ForegroundColor Green
        Write-Host "➡ $searchPath" -ForegroundColor Green
    } else {
        Write-Host "フォルダが選択されませんでした。プログラムを終了します。" -ForegroundColor Yellow
        exit
    }
}

# パスの有効性確認
if (-not (Test-Path $searchPath)) {
    Write-Host "エラー：フォルダパスが存在しません。search_config.txt を確認してください。" -ForegroundColor Red
    exit
}

# ログ記録関数
function Write-Log($text) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $text"
}

# メイン検索ループ
Write-Host "`n=== ファイル検索システム開始 ===" -ForegroundColor White
Write-Host "検索したいファイル名（部分一致可）を入力してください。終了する場合は exit と入力。" -ForegroundColor Yellow

do {
    $inputName = Read-Host "ファイル名を入力"
    if ($inputName -eq "exit") {
        Write-Host "`n検索を終了します。お疲れさまでした！" -ForegroundColor Cyan
        Write-Log "ユーザーが検索プログラムを終了しました。"
        break
    }

    Write-Host "`n検索中..." -ForegroundColor Cyan
    $startTime = Get-Date

    $results = Get-ChildItem -Path $searchPath -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*$inputName*" }

    $endTime = Get-Date
    $duration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)

    if ($results) {
        Write-Host "`n✅ 次のファイルが見つかりました：" -ForegroundColor Green
        foreach ($file in $results) {
            Write-Host $file.FullName
            Write-Log "ファイル [$inputName] -> $($file.FullName) を発見"
        }
        Write-Host "`n検索時間：$duration 秒" -ForegroundColor DarkGray
    } else {
        Write-Host "`n❌ 一致するファイルは見つかりませんでした。" -ForegroundColor Red
        Write-Log "一致するファイルなし [$inputName]"
    }

    Write-Host "`n--------------------------------------`n"

} while ($true)
