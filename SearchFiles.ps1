# ===========================================
# SearchFiles_Fast.ps1
# 機能：Sakura型高速ファイル内容検索
#       単一ワードまたはCSVリストに基づき検索
#       一致した結果をTXTに書き込み
#       メモリ負荷を最小化、大ファイルでも高速
# ===========================================

Add-Type -AssemblyName System.Windows.Forms

# === ログファイル作成 ===
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$logFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "SearchLog_$timestamp.txt"
function Write-Log($msg) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$time] $msg"
}

Write-Host ""
Write-Host "===============================" -ForegroundColor White
Write-Host "📁 高速ファイル内容検索ツール 起動" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor White
Write-Host ""

# === 検索モード選択 ===
Write-Host "検索方法を選択してください：" -ForegroundColor Yellow
Write-Host "1️⃣ 単一キーワード検索"
Write-Host "2️⃣ CSVファイルのリストで検索"
$mode = Read-Host "番号を入力 (1 または 2)"

$searchWords = @()
$useCsv = $false

if ($mode -eq "1") {
    $word = Read-Host "検索したい文字列を入力してください"
    $searchWords += $word
    Write-Log "単一ワード検索: $word"
}
elseif ($mode -eq "2") {
    $useCsv = $true
    Write-Host ""
    Write-Host "📄 CSVファイルを選択してください..." -ForegroundColor Cyan
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "CSV ファイル (*.csv)|*.csv|すべてのファイル (*.*)|*.*"

    if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $csvPath = $fileDialog.FileName
        $searchWords = Import-Csv -Path $csvPath | ForEach-Object { $_.PSObject.Properties.Value } | Where-Object { $_ -ne "" }
        Write-Host "✅ CSVから $($searchWords.Count) 件のワードを読み込みました。" -ForegroundColor Green
        Write-Log "CSVワード数: $($searchWords.Count)"
    }
    else {
        Write-Host "❌ ファイルが選択されませんでした。終了します。" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "❌ 無効な入力。終了します。" -ForegroundColor Red
    exit
}

# === フォルダ選択 ===
Write-Host ""
Write-Host "🔍 検索対象フォルダを選択してください..." -ForegroundColor Cyan
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
if ($folderDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "❌ フォルダが選択されませんでした。終了します。" -ForegroundColor Red
    exit
}
$searchPath = $folderDialog.SelectedPath
Write-Host "➡ 対象フォルダ: $searchPath" -ForegroundColor Green
Write-Log "検索フォルダ: $searchPath"

# === 結果保存ファイル ===
$resultTxt = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "SearchResult_$timestamp.txt"

# === 検索処理関数 ===
function Search-Files {
    param (
        [string[]]$words,
        [string]$path
    )

    foreach ($file in Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue) {
        try {
            $reader = [System.IO.File]::OpenText($file.FullName)
        } catch {
            Write-Host "⚠ 読み取れないファイル: $($file.FullName)" -ForegroundColor Yellow
            Write-Log "読み取れない: $($file.FullName)"
            continue
        }

        $lineNum = 0
        while (($line = $reader.ReadLine()) -ne $null) {
            $lineNum++
            $lineStr = [string]$line
            foreach ($word in $words) {
                $index = 0
                while (($pos = $lineStr.IndexOf($word, $index)) -ne -1) {
                    $relativePath = $file.FullName.Substring($searchPath.Length).TrimStart('\')
                    $output = "$($file.Name),一致あり,$word,$($lineStr.Trim()),$lineNum,$($pos+1),$relativePath"
                    Add-Content -Path $resultTxt -Value $output
                    $index = $pos + $word.Length
                }
            }
        }

        $reader.Close()
    }
}

# === 実行 ===
Write-Host ""
Write-Host "🚀 検索を開始します..." -ForegroundColor Cyan
Write-Log "検索開始"

Search-Files -words $searchWords -path $searchPath

Write-Host ""
Write-Host "✅ 検索完了しました！" -ForegroundColor Green
Write-Host "💾 結果TXT: $resultTxt" -ForegroundColor Cyan
Write-Log "検索終了"

Write-Host ""
Write-Host "===============================" -ForegroundColor White
Write-Host "🎉 処理完了！お疲れさまでした！" -ForegroundColor Cyan
Write-Host "ログ: $logFile" -ForegroundColor DarkGray
Write-Host "===============================" -ForegroundColor White
