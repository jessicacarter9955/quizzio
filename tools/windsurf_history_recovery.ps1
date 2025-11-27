param(
    [Parameter(Mandatory = $true)]
    [string]$HistoryRoot,

    [Parameter(Mandatory = $true)]
    [string]$TargetFileName
)

if (-not (Test-Path $HistoryRoot)) {
    Write-Error "History root path not found: $HistoryRoot"
    exit 1
}

# 1) List candidate directories, most recent first
$dirs = Get-ChildItem -Directory -Path $HistoryRoot |
    Sort-Object LastWriteTime -Descending

Write-Host "Scanning $($dirs.Count) history directories under $HistoryRoot ..." 

$matches = @()

foreach ($dir in $dirs) {
    try {
        $dartFiles = Get-ChildItem -Path $dir.FullName -Filter *.dart -File -Recurse -ErrorAction SilentlyContinue
        foreach ($f in $dartFiles) {
            $content = Get-Content -Raw -Path $f.FullName
            if ($content -like "*${TargetFileName}*") {
                $matches += [PSCustomObject]@{
                    DartPath      = $f.FullName
                    DartModified  = $f.LastWriteTime
                    HistoryFolder = $dir.FullName
                }
            }
        }
    } catch {
        # Ignore folders we can't read
    }
}

if ($matches.Count -eq 0) {
    Write-Host "No matches found that mention '$TargetFileName' in their contents."
} else {
    Write-Host "Found $($matches.Count) candidates that reference $TargetFileName. Showing most recent first:" 
    $matches | Sort-Object DartModified -Descending | Select-Object -First 20
}
