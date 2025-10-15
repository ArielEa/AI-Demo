# ===========================================
# SearchFiles.ps1
# 機能：
#   単一ワードまたはCSVリストを基にファイル内容検索
#   一致箇所（行番号・列位置）を特定しCSVに出力
#   未一致ファイルはCSVに出力せず
#   マッチファイルのフルパスもCSVに追加
#   スクリプト終了後もPowerShellを閉じない
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
Write-Host "📁 ファイル内容検索ツール 起動" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor White
Write-Host ""

# === 検索モード選択 ===
Write-Host "検索方法を選択してください：" -ForegroundColor Yellow
Write-Host "1️⃣ 単一キーワード検索"
Write-Host "2️⃣ CSVファイルのリストで検索"
$mode = Read-Host "番号を入力 (1 または 2)"

$searchWords = @()

if ($mode -eq "1") {
    $word = Read-Host "検索したい文字列を入力してください"
    $searchWords += $word
    Write-Log "単一ワード検索: $word"
}
elseif ($mode -eq "2") {
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
$resultCsv = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "SearchResult_$timestamp.csv"

# === 検索処理 ===
Write-Host ""
Write-Host "🚀 検索を開始します..." -ForegroundColor Cyan
Write-Log "検索開始"

$results = @()

foreach ($file in Get-ChildItem -Path $searchPath -Recurse -File -ErrorAction SilentlyContinue) {
    try {
        $lines = Get-Content -Path $file.FullName -Encoding UTF8
    } catch {
        Write-Host "⚠ 読み取れないファイル: $($file.FullName)" -ForegroundColor Yellow
        Write-Log "読み取れない: $($file.FullName)"
        continue
    }

    $fileMatched = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = [string]$lines[$i]

        foreach ($word in $searchWords) {
            if ($line -like "*$word*") {
                $fileMatched = $true
                $posList = @()
                $index = 0
                while (($pos = $line.IndexOf($word, $index)) -ne -1) {
                    $posList += $pos + 1
                    $index = $pos + $word.Length
                }

                foreach ($p in $posList) {
                    $results += [PSCustomObject]@{
                        ファイル名   = $file.Name
                        フルパス     = $file.FullName
                        ファイル状態 = "一致あり"
                        検索ワード   = $word
                        内容         = $line.Trim()
                        行号         = $i + 1
                        行内位置     = $p
                    }
                }

                # コンソール表示（キーワード部分を黄色ハイライト）
                $highlightedLine = $line -replace "($word)", "`e[33m$1`e[0m"
                Write-Host "🔍 $($file.Name) 行 $($i + 1): $highlightedLine"
            }
        }
    }
}

# === 結果出力 ===
if ($results.Count -gt 0) {
    Write-Host ""
    Write-Host "✅ 検索結果: $($results.Count) 件見つかりました！" -ForegroundColor Green
    $results | Export-Csv -Path $resultCsv -Encoding UTF8 -NoTypeInformation
    Write-Host "💾 結果を保存しました: $resultCsv" -ForegroundColor Cyan
    Write-Log "結果: $($results.Count) 件"
} else {
    Write-Host ""
    Write-Host "❌ 一致する内容は見つかりませんでした。" -ForegroundColor Red
    Write-Log "一致結果なし"
}

Write-Host ""
Write-Host "===============================" -ForegroundColor White
Write-Host "🎉 処理完了しました。PowerShellは閉じません。" -ForegroundColor Cyan
Write-Host "ログ: $logFile" -ForegroundColor DarkGray
Write-Host "===============================" -ForegroundColor White

# === スクリプト終了後も続行可能 ===
Write-Host "`n💡 次のコマンドを入力して続行できます..." -ForegroundColor Cyan
