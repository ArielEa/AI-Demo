# ===========================================
# SearchFiles.ps1
# 機能：
#   単一ワードまたはCSVリストを基にファイル内容検索
#   一致箇所をTXTに直接出力（CSV形式で記録）
#   実行ごとに新しいログを作成
#   相対パス対応
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
Write-Host "==============================="
Write-Host "📁 ファイル内容検索ツール 起動" -ForegroundColor Cyan
Write-Host "==============================="

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

# === 検索方法選択 ===
Write-Host ""
Write-Host "検索方法を選択してください：" -ForegroundColor Yellow
Write-Host "1️⃣ 単一キーワード検索"
Write-Host "2️⃣ CSVファイルのリストで検索"
$mode = Read-Host "番号を入力 (1 または 2)"

# === 検索ワードの取得 ===
$searchWords = @()

if ($mode -eq "2") {
    Write-Host ""
    Write-Host "📄 CSVファイルを選択してください..." -ForegroundColor Cyan
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "CSV ファイル (*.csv)|*.csv|すべてのファイル (*.*)|*.*"

    if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $csvPath = $fileDialog.FileName
        $searchWords = Import-Csv -Path $csvPath | ForEach-Object { $_.PSObject.Properties.Value } | Where-Object { $_ -ne "" }
        Write-Host "✅ CSVから $($searchWords.Count) 件のワードを読み込みました。" -ForegroundColor Green
        Write-Log "CSVワード数: $($searchWords.Count)"
    } else {
        Write-Host "❌ ファイルが選択されませんでした。終了します。" -ForegroundColor Red
        exit
    }
}

# === 出力ヘッダ ===
Add-Content -Path $logFile -Value "ファイル名,相対パス,検索ワード,内容,行号,行内位置"

function Search-InFiles($searchWords) {
    $matchCount = 0

    foreach ($file in Get-ChildItem -Path $searchPath -Recurse -File -ErrorAction SilentlyContinue) {
        try {
            $lines = Get-Content -Path $file.FullName -Encoding UTF8
        } catch {
            Write-Log "⚠ 読み取れない: $($file.FullName)"
            continue
        }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = [string]$lines[$i]
            foreach ($w in $searchWords) {
                if ($line -like "*$w*") {
                    $index = 0
                    while (($pos = $line.IndexOf($w, $index)) -ne -1) {
                        $index = $pos + $w.Length
                        $relativePath = $file.FullName.Substring($searchPath.Length)
                        if ($relativePath.StartsWith("\") -or $relativePath.StartsWith("/")) { $relativePath = $relativePath.Substring(1) }
                        $record = "$($file.Name),$relativePath,$w,""$($line.Trim())"",$($i + 1),$($pos + 1)"
                        Add-Content -Path $logFile -Value $record
                        $matchCount++
                    }
                }
            }
        }
    }
    return $matchCount
}

# === 実行 ===
if ($mode -eq "1") {
    do {
        $word = Read-Host "検索したい文字列を入力してください (終了は空入力)"
        if ([string]::IsNullOrWhiteSpace($word)) { break }
        $searchWords = @($word)
        Write-Log "単一検索: $word"

        $count = Search-InFiles $searchWords
        if ($count -gt 0) {
            Write-Host "✅ $count 件見つかりました！" -ForegroundColor Green
        } else {
            Write-Host "❌ 一致する内容はありませんでした。" -ForegroundColor Red
        }

        Write-Host ""
        $cont = Read-Host "続けますか？(Y/N)"
    } while ($cont -match "^[Yy]$")

    Write-Host ""
    Write-Host "🎉 検索終了。結果: $logFile" -ForegroundColor Cyan
    Write-Log "単一モード終了"
}

elseif ($mode -eq "2") {
    $count = Search-InFiles $searchWords
    if ($count -gt 0) {
        Write-Host "✅ $count 件見つかりました！" -ForegroundColor Green
    } else {
        Write-Host "❌ 一致する内容はありませんでした。" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "🎉 CSVリスト検索終了。結果: $logFile" -ForegroundColor Cyan
    Write-Log "CSVモード終了"
}
