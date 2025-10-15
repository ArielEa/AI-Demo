# ============================================
# ファイル検索スクリプト（カラー表示対応）
# 作成者: ChatGPT
# 説明:
#   指定フォルダ内のファイルを検索してCSV出力
#   単一ファイル or CSVリスト検索対応
#   マッチした行をカラー表示
# ============================================

function Search-InFile {
    param (
        [string]$FilePath,
        [string]$Keyword
    )

    $results = @()
    
    # ファイルを文字列として取得
    $lines = Get-Content -Path $FilePath -ErrorAction SilentlyContinue | ForEach-Object { [string]$_ }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $index = $line.IndexOf($Keyword)
        if ($index -ge 0) {
            # 結果オブジェクト作成
            $results += [PSCustomObject]@{
                FileName = (Split-Path $FilePath -Leaf)
                Status   = "FOUND"
                Content  = $line
                Line     = $i + 1
                CharPos  = $index + 1
            }

            # コンソールにカラー表示
            Write-Host "🔍 $($FilePath) 行 $($i + 1): " -NoNewline
            Write-Host $line -ForegroundColor Yellow
        }
    }
    return $results
}

# -----------------------------
# メイン処理
# -----------------------------

# 検索モード選択
Write-Host "検索モードを選択してください: 1=単一ファイル, 2=CSVリスト"
$mode = Read-Host

# デフォルトの検索フォルダ（必要に応じて変更可）
$defaultSearchPath = "C:\仕事用フォルダー横浜ＹＢＰ\調査\aslead資産調査\aslead資産_SH1769\st_dcpdevdir（20250714）"

# CSV 保存場所（スクリプトディレクトリ）
$csvDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$csvName = Join-Path $csvDir ("SearchResults_" + (Get-Date -Format "yyyyMMddHHmmss") + ".csv")

$allResults = @()

if ($mode -eq "1") {
    # 単一ファイル検索
    $keyword = Read-Host "検索するファイル名を入力"
    $searchPath = Read-Host "検索フォルダを入力（Enterでデフォルトを使用）"
    if ([string]::IsNullOrEmpty($searchPath)) { $searchPath = $defaultSearchPath }

    Write-Host "🔍 検索中: $keyword"

    # フォルダ内すべてのファイルを検索
    $files = Get-ChildItem -Path $searchPath -File -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $results = Search-InFile -FilePath $file.FullName -Keyword $keyword
        if ($results.Count -gt 0) { $allResults += $results }
    }
}
elseif ($mode -eq "2") {
    # CSV リスト検索
    $csvFile = Read-Host "CSVファイルパスを入力"
    $searchPath = Read-Host "検索フォルダを入力（Enterでデフォルトを使用）"
    if ([string]::IsNullOrEmpty($searchPath)) { $searchPath = $defaultSearchPath }

    $keywords = Import-Csv -Path $csvFile
    foreach ($row in $keywords) {
        $keyword = $row.YourColumnName  # ← CSV の列名に合わせて変更
        Write-Host "🔍 検索中: $keyword"
        $files = Get-ChildItem -Path $searchPath -File -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $results = Search-InFile -FilePath $file.FullName -Keyword $keyword
            if ($results.Count -gt 0) { $allResults += $results }
        }
    }
}
else {
    Write-Host "無効なモードです。1 または 2 を選択してください。"
}

# 結果があれば CSV 出力
if ($allResults.Count -gt 0) {
    $allResults | Export-Csv -Path $csvName -Encoding UTF8 -NoTypeInformation
    Write-Host "検索結果CSVを生成しました: $csvName"
}
else {
    Write-Host "検索結果はありませんでした。"
}

Write-Host "検索完了。スクリプトは終了せずに続行できます。"
