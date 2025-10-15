# ===========================================
# SearchFiles.ps1
# 機能：
#   単一ワードまたはCSVリストを基にファイル内容検索
#   一致箇所のみCSV出力（未一致ファイルは除外）
#   実行ごとにログを新規作成
#   CSVには相対パスを含む
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

# === 検索モード選択 ===
Write-Host ""
Write-Host "検索方法を選択してください：" -ForegroundColor Yellow
Write-Host "1️ 単一キーワード検索"
Write-Host "2️ CSVファイルのリストで検索"
$mode = Read-Host "番号を入力 (1 または 2)"

# CSV検索は一度だけ実行
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

# === 単一ワード検索ループ ===
if ($mode -eq "1") {
    do {
        $searchWords = @()
        $word = Read-Host "検索したい文字列を入力してください (終了は空入力)"
        if ([string]::IsNullOrWhiteSpace($word)) { break }
        $searchWords += $word
        Write-Log "単一ワード検索: $word"

        $results = @()
        foreach ($file in Get-ChildItem -Path $searchPath -Recurse -File -ErrorAction SilentlyContinue) {
            try {
                $lines = Get-Content -Path $file.FullName -Encoding UTF8
            } catch {
                Write-Host "⚠ 読み取れないファイル: $($file.FullName)" -ForegroundColor Yellow
                Write-Log "読み取れない: $($file.FullName)"
                continue
            }

            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = [string]$lines[$i]
                foreach ($w in $searchWords) {
                    if ($line -like "*$w*") {
                        $posList = @()
                        $index = 0
                        while (($pos = $line.IndexOf($w, $index)) -ne -1) {
                            $posList += $pos + 1
                            $index = $pos + $w.Length
                        }
                        foreach ($p in $posList) {
                            $relativePath = $file.FullName.Substring($searchPath.Length)
                            if ($relativePath.StartsWith("\") -or $relativePath.StartsWith("/")) { $relativePath = $relativePath.Substring(1) }
                            $results += [PSCustomObject]@{
                                ファイル名   = $file.Name
                                相対パス     = $relativePath
                                ファイル状態 = "一致あり"
                                検索ワード   = $w
                                内容         = $line.Trim()
                                行号         = $i + 1
                                行内位置     = $p
                            }
                        }
                    }
                }
            }
        }

        if ($results.Count -gt 0) {
            Write-Host ""
            Write-Host "✅ 検索結果: $($results.Count) 件見つかりました！" -ForegroundColor Green
            $genCsv = Read-Host "CSVに出力しますか？(Y/N)"
            if ($genCsv -match "^[Yy]$") {
                $resultCsv = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "SearchResult_$timestamp.csv"
                $results | Export-Csv -Path $resultCsv -Encoding UTF8 -NoTypeInformation
                Write-Host "💾 結果を保存しました: $resultCsv" -ForegroundColor Cyan
                Write-Log "CSV生成: $($results.Count) 件"
            }
        } else {
            Write-Host ""
            Write-Host "❌ 一致する内容は見つかりませんでした。" -ForegroundColor Red
            Write-Log "一致結果なし"
        }

    } while ($true)

    Write-Host ""
    Write-Host "==============================="
    Write-Host "🎉 単一ワード検索を終了しました。" -ForegroundColor Cyan
    Write-Host "ログ: $logFile" -ForegroundColor DarkGray
    Write-Host "==============================="
}

# === CSVリスト検索 ===
elseif ($mode -eq "2") {
    $results = @()
    foreach ($file in Get-ChildItem -Path $searchPath -Recurse -File -ErrorAction SilentlyContinue) {
        try {
            $lines = Get-Content -Path $file.FullName -Encoding UTF8
        } catch {
            Write-Host "⚠ 読み取れないファイル: $($file.FullName)" -ForegroundColor Yellow
            Write-Log "読み取れない: $($file.FullName)"
            continue
        }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = [string]$lines[$i]
            foreach ($w in $searchWords) {
                if ($line -like "*$w*") {
                    $posList = @()
                    $index = 0
                    while (($pos = $line.IndexOf($w, $index)) -ne -1) {
                        $posList += $pos + 1
                        $index = $pos + $w.Length
                    }
                    foreach ($p in $posList) {
                        $relativePath = $file.FullName.Substring($searchPath.Length)
                        if ($relativePath.StartsWith("\") -or $relativePath.StartsWith("/")) { $relativePath = $relativePath.Substring(1) }
                        $results += [PSCustomObject]@{
                            ファイル名   = $file.Name
                            相対パス     = $relativePath
                            ファイル状態 = "一致あり"
                            検索ワード   = $w
                            内容         = $line.Trim()
                            行号         = $i + 1
                            行内位置     = $p
                        }
                    }
                }
            }
        }
    }

    if ($results.Count -gt 0) {
        $resultCsv = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "SearchResult_$timestamp.csv"
        $results | Export-Csv -Path $resultCsv -Encoding UTF8 -NoTypeInformation
        Write-Host ""
        Write-Host "✅ CSVに出力しました: $resultCsv" -ForegroundColor Green
        Write-Log "CSV生成: $($results.Count) 件"
    } else {
        Write-Host ""
        Write-Host "❌ 一致する内容は見つかりませんでした。" -ForegroundColor Red
        Write-Log "一致結果なし"
    }

    Write-Host ""
    Write-Host "==============================="
    Write-Host "🎉 CSVリスト検索終了" -ForegroundColor Cyan
    Write-Host "ログ: $logFile" -ForegroundColor DarkGray
    Write-Host "==============================="
}
