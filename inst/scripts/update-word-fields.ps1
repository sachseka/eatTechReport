param([Parameter(Mandatory = $true)][string]$DocumentPath)

$ErrorActionPreference = 'Stop'
$resolvedDocument = (Resolve-Path -LiteralPath $DocumentPath).Path
$documentDirectory = Split-Path -Parent $resolvedDocument
$marker = Join-Path $documentDirectory '.eatTechReport-render'
if ([System.IO.Path]::GetExtension($resolvedDocument) -ne '.docx' -or
    -not (Test-Path -LiteralPath $marker -PathType Leaf) -or
    [System.IO.Path]::GetFileName($documentDirectory) -notlike '.eatTechReport-render-*') {
    throw 'Only a newly generated eatTechReport staging document may be updated.'
}

$wordApplication = $null
$reportDocument = $null
try {
    $wordApplication = New-Object -ComObject Word.Application
    $wordApplication.Visible = $false
    $wordApplication.DisplayAlerts = 0
    $reportDocument = $wordApplication.Documents.Open($resolvedDocument, $false, $false, $false)
    $reportDocument.Repaginate()
    foreach ($contents in $reportDocument.TablesOfContents) { $contents.Update() }
    foreach ($story in $reportDocument.StoryRanges) {
        $storyRange = $story
        while ($null -ne $storyRange) {
            $fieldStatus = $storyRange.Fields.Update()
            if ($fieldStatus -ne 0) {
                throw "A document field could not be updated (story $($storyRange.StoryType), field $fieldStatus)."
            }
            $storyRange = $storyRange.NextStoryRange
        }
    }
    $reportDocument.Repaginate()
    foreach ($contents in $reportDocument.TablesOfContents) { $contents.UpdatePageNumbers() }
    $reportDocument.Save()
    [pscustomobject]@{
        fields_updated = $true
        pages = $reportDocument.ComputeStatistics(2)
        tables_of_contents = $reportDocument.TablesOfContents.Count
    } | ConvertTo-Json -Compress
} finally {
    if ($null -ne $reportDocument) {
        try { $reportDocument.Close(0) } catch { Write-Warning "Could not close the generated document: $($_.Exception.Message)" }
    }
    if ($null -ne $wordApplication) {
        try { $wordApplication.Quit() } catch { Write-Warning "Could not close the owned Word instance: $($_.Exception.Message)" }
    }
    if ($null -ne $reportDocument) {
        try {
            $null = [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($reportDocument)
        } catch { Write-Warning "Could not release the generated document object: $($_.Exception.Message)" }
    }
    if ($null -ne $wordApplication) {
        try {
            $null = [System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($wordApplication)
        } catch { Write-Warning "Could not release the owned Word object: $($_.Exception.Message)" }
    }
}
