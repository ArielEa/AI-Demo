# ファイル検索 PowerShell スクリプト
# 機能:
# - 単一キーワードまたはCSVリストによる複数キーワード検索をサポート
# - 選択したフォルダ内のテキストファイルを再帰的に検索
# - 結果にはファイル名、ステータス、行内容、行番号、文字位置を出力
# - タイムスタンプ付きのログとCSVファイルを生成
# - ユーザーが終了するまで繰り返し実行可能

function New-SearchLogName {
    $timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
    return "searchLog_$timestamp.txt"
}

function Search-InFile {
    param (
        [string]$FilePath,
        [string]$Keyword
    )

    $results = @()
    $lines = Get-Content -Path $FilePath -ErrorAction SilentlyContinue

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $index = $line.IndexOf($Keyword)
        if ($index -ge 0) {
            $results += [PSCustomObject]@{
                FileName = (Split-Path $FilePath -Leaf)
                Status   = "FOUND"
                Content  = $line
                Line     = $i + 1
                CharPos  = $index + 1
            }
        }
    }
    return $results
}

# ログファイル生成
$logFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) (New-SearchLogName)

# 検索モード選択
Write-Host "検索モードを選択してください: 1=単一ファイル, 2=CSVリスト" -ForegroundColor Yellow
$mode = Read-Host

# キーワードリストの準備
$keywords = @()
if ($mode -eq "1") {
    $inputName = Read-Host "検索するファイル名を入力"
    $keywords += $inputName
} elseif ($mode -eq "2") {
    Add-Type -AssemblyName System.Windows.Forms
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "CSV Files (*.csv)|*.csv"
    $fileDialog.Title  = "検索キーワードCSVを選択してください"
    if ($fileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $csvPath = $fileDialog.FileName
        $keywords = Import-Csv -Path $csvPath | ForEach-Object { $_.A }
    } else {
        Write-Host "CSVファイルが選択されませんでした。" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "無効な選択です。" -ForegroundColor Red
    exit
}

# 検索フォルダ選択
Add-Type -AssemblyName System.Windows.Forms
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "検索するフォルダを選択してください"
if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $searchPath = $folderDialog.SelectedPath
    Write-Host "検索フォルダ: $searchPath" -ForegroundColor Green
} else {
    Write-Host "フォルダが選択されませんでした。" -ForegroundColor Red
    exit
}

# 検索処理ループ
do {
    $allResults = @()

    foreach ($kw in $keywords) {
        Write-Host "🔍 検索中: $kw" -ForegroundColor Cyan
        $files = Get-ChildItem -Path $searchPath -Recurse -File -ErrorAction SilentlyContinue

        foreach ($f in $files) {
            $res = Search-InFile -FilePath $f.FullName -Keyword $kw
            if ($res.Count -gt 0) {
                $allResults += $res
                foreach ($r in $res) {
                    Write-Host "ヒット: $($r.FileName) 行 $($r.Line) 位置 $($r.CharPos)" -ForegroundColor Green
                }
            }
        }
    }

    # 結果がある場合のみCSV生成
    if ($allResults.Count -gt 0) {
        $csvName = Join-Path $searchPath ("SearchResults_" + (Get-Date -Format "yyyyMMddHHmmss") + ".csv")
        $allResults | Export-Csv -Path $csvName -Encoding UTF8 -NoTypeInformation
        Write-Host "検索結果CSVを生成しました: $csvName" -ForegroundColor Magenta
    } else {
        Write-Host "一致するファイルは見つかりませんでした。" -ForegroundColor Yellow
    }

    # 続行確認
    $cont = Read-Host "検索を続けますか？ Y=続ける, N=終了"
    if ($cont -ne "Y" -and $cont -ne "y") {
        break
    }

} while ($true)

Write-Host "検索プログラムを終了しました。" -ForegroundColor Cyan
