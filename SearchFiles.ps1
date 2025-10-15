# ===========================================
# ログファイル（毎回新規作成）
# ===========================================
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$logFile = Join-Path $PSScriptRoot "SearchLog_$timestamp.txt"

function Write-Log($text) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$time] $text"
}

# ===========================================
# SearchFiles.ps1
# 機能：
# 1. 単一ファイル名 or CSV列による複数検索
# 2. フォルダ選択
# 3. ファイル存在チェック + 内容検索（行番号、行内位置）
# 4. CSV出力とログ記録
# ===========================================

# ログファイル
$logFile = Join-Path $PSScriptRoot "SearchLog.txt"
function Write-Log($text) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $text"
}

# 検索モード選択
Write-Host "検索モードを選択してください: 1=単一ファイル, 2=CSVリスト" -ForegroundColor Cyan
$mode = Read-Host

# キーワード取得
$searchList = @()
if ($mode -eq "1") {
    $searchList = @(Read-Host "検索するファイル名を入力")
} elseif ($mode -eq "2") {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "CSVファイル (*.csv)|*.csv"
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit }
    $csvPath = $dialog.FileName
    $searchList = (Import-Csv -Path $csvPath -Header "Keyword") | ForEach-Object { $_.Keyword }
} else {
    Write-Host "無効な選択です。" -ForegroundColor Red
    exit
}

# フォルダ選択
Add-Type -AssemblyName System.Windows.Forms
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "検索対象のフォルダを選択してください"
if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $searchPath = $folderDialog.SelectedPath
    Write-Host "検索フォルダ: $searchPath" -ForegroundColor Green
} else { exit }

# 結果格納用
$output = @()

# メイン検索ループ
foreach ($name in $searchList) {
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host "検索中: $name" -ForegroundColor Yellow

    # ファイル存在チェック
    $foundInFolder = Get-ChildItem -Path $searchPath -Recurse -File | Where-Object { $_.Name -like "*$name*" }

    if ($foundInFolder) {
        foreach ($file in $foundInFolder) {
            Write-Host "✅ ファイル存在: $($file.Name)" -ForegroundColor Green
            Write-Log "ファイル [$name] がフォルダ内に存在: $($file.FullName)"
            $output += [PSCustomObject]@{
                ファイル名 = $file.Name
                ファイル状態 = "存在"
                内容 = ""
                行号 = ""
                行内位置 = ""
            }
        }
    } else {
        # ファイル内容検索
        $allFiles = Get-ChildItem -Path $searchPath -Recurse -File
        foreach ($file in $allFiles) {
            $lines = Get-Content -Path $file.FullName
            for ($i=0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                $index = 0
                while (($pos = $line.IndexOf($name, $index)) -ne -1) {
                    Write-Host "🔍 内容検索ヒット: $($file.Name) 行 $($i+1) 位置 $($pos+1)" -ForegroundColor Magenta
                    Write-Log "ファイル [$file.Name] 行 $($i+1) 位置 $($pos+1) -> $line"

                    $output += [PSCustomObject]@{
                        ファイル名 = $file.Name
                        ファイル状態 = "内容検索"
                        内容 = $line
                        行号 = $i+1
                        行内位置 = $pos+1
                    }
                    $index = $pos + 1
                }
            }
        }
    }
}

# CSV出力
$csvOut = Join-Path $PSScriptRoot "SearchResult.csv"
$output | Export-Csv -Path $csvOut -NoTypeInformation -Encoding UTF8
Write-Host "検索結果を出力しました: $csvOut" -ForegroundColor Green
Write-Log "検索完了: CSV生成 -> $csvOut"
