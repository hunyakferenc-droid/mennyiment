param([Parameter(Mandatory=$true)][string]$Normal, [Parameter(Mandatory=$true)][string]$Review, [Parameter(Mandatory=$true)][string]$Evidence)
$ErrorActionPreference='Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This gate requires real Windows, not Linux PowerShell.' }
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence=[IO.Path]::GetFullPath($Evidence)
$chrome=Join-Path $env:ProgramFiles 'Google/Chrome/Application/chrome.exe'
if (-not (Test-Path $chrome)) { throw 'Real Google Chrome was not found.' }
$env:CHROME_BIN=$chrome
$env:MENTI_APP_VERSION='3.0.1+43'
$results=@()
foreach ($variant in @('normal','review')) {
    $download=if ($variant -eq 'normal') {$Normal} else {$Review}
    $zip=Join-Path $Evidence "$variant-web.zip"
    Compress-Archive -Path (Join-Path $download '*') -DestinationPath $zip
    $web=Join-Path $Evidence "$variant-unpacked"
    Expand-Archive -LiteralPath $zip -DestinationPath $web
    if (-not (Get-Content (Join-Path $web 'build-info.txt') -Raw).Contains($env:MENTI_SOURCE_COMMIT)) {throw 'Artifact source mismatch.'}
    $server=$null
    try {
        # Exercise the user-facing CMD launcher and Windows PowerShell 5.1.
        $server=Start-Process -FilePath 'cmd.exe' -ArgumentList '/d','/c','INDITAS.cmd' -WorkingDirectory $web -PassThru -RedirectStandardOutput (Join-Path $Evidence "$variant-server.log") -RedirectStandardError (Join-Path $Evidence "$variant-server-error.log")
        $ready=$false
        for ($i=0;$i -lt 120;$i++) {
            try {$r=Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:7357/build-info.txt'; if ($r.StatusCode -eq 200 -and $r.Content.Contains($env:MENTI_SOURCE_COMMIT)) {$ready=$true;break}} catch {}
            Start-Sleep -Milliseconds 500
        }
        if (-not $ready) {throw 'INDITAS.cmd did not serve the exact artifact on 127.0.0.1:7357.'}
        $env:MENTI_EVIDENCE_DIR=Join-Path $Evidence $variant
        if ($variant -eq 'normal') {
            node tool/verify_collection_chrome.cjs
            if ($LASTEXITCODE -ne 0) {throw 'Windows normal Chrome regression failed.'}
            node tool/verify_collection_journey_chrome.cjs
            if ($LASTEXITCODE -ne 0) {throw 'Windows fresh onboarding/XP regression failed.'}
            node tool/verify_journal_228_chrome.cjs
            if ($LASTEXITCODE -ne 0) {throw 'Windows journal editing regression failed.'}
        } else {
            node tool/verify_menti_alive_chrome.cjs
            if ($LASTEXITCODE -ne 0) {throw 'Windows native video regression failed.'}
            node tool/verify_animation_studio_chrome.cjs
            if ($LASTEXITCODE -ne 0) {throw 'Windows Animation Studio regression failed.'}
            $clip=Get-ChildItem (Join-Path $web 'assets/assets/menti_life/clips/*.mp4') | Select-Object -First 1
            $media=Invoke-WebRequest -Method Head -UseBasicParsing ("http://127.0.0.1:7357/assets/assets/menti_life/clips/"+$clip.Name)
            if ($media.Headers['Content-Type'] -ne 'video/mp4') {throw 'Wrong MP4 MIME type.'}
        }
        $results+=@{variant=$variant;zipExtracted=$true;cmdLauncher=$true;host='127.0.0.1:7357';realWindows=$true;chrome=$chrome;sourceCommit=$env:MENTI_SOURCE_COMMIT}
    } finally {
        if ($server) { & taskkill.exe /PID $server.Id /T /F | Out-Null }
    }
}
$results | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $Evidence 'windows-results.json')
