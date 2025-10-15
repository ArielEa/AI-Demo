# 文件搜索器 PowerShell 脚本
# 功能：支持单个关键字或 CSV 批量关键字搜索，输出匹配结果
# 作者：ChatGPT 改进版

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
                LineNum  = $i + 1
                CharPos  = $index + 1
            }
        }
    }
    return $results
}

function Run-Search {
    # 创建日志文件
    $logFile = New-SearchLogName
    $csvResults = @()

    Write-Host "请选择搜索模式："
    Write-Host "1. 单个关键字搜索"
    Write-Host "2. CSV 批量搜索"
    $mode = Read-Host "输入 1 或 2"

    if ($mode -eq "1") {
        $keyword = Read-Host "请输入要搜索的关键字"
        $keywords = @($keyword)
    }
    elseif ($mode -eq "2") {
        $csvPath = Read-Host "请输入 CSV 文件路径"
        $columnName = Read-Host "请输入要读取的列名"
        $data = Import-Csv -Path $csvPath
        $keywords = $data | ForEach-Object { $_.$columnName } | Where-Object { $_ -ne "" }
    }
    else {
        Write-Host "输入无效，请重新选择。"
        return
    }

    $folder = Read-Host "请输入要搜索的文件夹路径"
    if (!(Test-Path $folder)) {
        Write-Host "❌ 文件夹不存在。"
        return
    }

    $files = Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue

    foreach ($keyword in $keywords) {
        Write-Host "`n🔍 正在搜索关键字：$keyword"
        foreach ($file in $files) {
            $found = Search-InFile -FilePath $file.FullName -Keyword $keyword
            if ($found.Count -gt 0) {
                $csvResults += $found
                $found | ForEach-Object {
                    Add-Content -Path $logFile -Value ("[$($_.FileName)] Line $($_.LineNum): $($_.Content)")
                }
            }
        }
    }

    if ($csvResults.Count -gt 0) {
        $csvName = "SearchResult_$(Get-Date -Format 'yyyyMMddHHmmss').csv"
        $csvResults | Export-Csv -Path $csvName -NoTypeInformation -Encoding UTF8
        Write-Host "`n✅ 搜索结束，结果已保存至 $csvName"
    }
    else {
        Write-Host "`n⚠️ 未找到任何匹配结果。"
    }

    Write-Host "`n📘 日志文件：$logFile"
}

# 主循环，可持续搜索
while ($true) {
    Run-Search
    $cont = Read-Host "`n是否继续搜索？(Y/N)"
    if ($cont -ne "Y" -and $cont -ne "y") {
        Write-Host "👋 程序结束，再见。"
        break
    }
}
