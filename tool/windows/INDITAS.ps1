param(
    [ValidateSet('Web', 'Source')][string]$Mode = 'Web',
    [string]$WebDirectory = $PSScriptRoot,
    [switch]$NoBrowser
)
$ErrorActionPreference = 'Stop'
$listener = $null
try {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw 'Windows PowerShell 5.1 vagy ujabb szukseges.'
    }
    if ($Mode -eq 'Source') {
        $project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
        if (-not (Test-Path (Join-Path $project 'pubspec.yaml'))) {
            throw 'A forras inditojat a repository tool/windows mappajabol futtasd.'
        }
        if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
            throw 'A Flutter nem talalhato a PATH-ban. Telepits Flutter 3.47.7-et, add a bin mappajat a PATH-hoz, majd nyiss uj terminalt. A kesz web ZIP-hez nem kell Flutter.'
        }
        Push-Location $project
        try {
            & flutter --version
            if ($LASTEXITCODE -ne 0) { throw 'A Flutter nem indult el. Futtasd: flutter doctor -v' }
            & flutter pub get
            if ($LASTEXITCODE -ne 0) { throw 'A fuggosegek letoltese sikertelen. Ellenorizd az internetet es a flutter doctor -v eredmenyet.' }
            & flutter gen-l10n
            if ($LASTEXITCODE -ne 0) { throw 'A nyelvi fajlok eloallitasa sikertelen.' }
            & flutter build web --no-web-resources-cdn
            if ($LASTEXITCODE -ne 0) { throw 'A webbuild sikertelen. A fenti Flutter hiba reszletezi az okot.' }
        } finally { Pop-Location }
        $WebDirectory = Join-Path $project 'build/web'
    }
    $root = [IO.Path]::GetFullPath($WebDirectory).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not (Test-Path -LiteralPath (Join-Path $root 'index.html') -PathType Leaf)) {
        throw 'Nincs index.html. A teljes web ZIP-et bontsd ki, majd a kibontott INDITAS.cmd fajlt inditsd. Forrashoz: FORRAS_INDITAS.cmd.'
    }
    # TcpListener uses no HTTP.sys URL reservation and needs no administrator,
    # Python, Node, or downloaded runtime. Bind only the local loopback address.
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 7357)
    try { $listener.Start() } catch {
        throw 'A 7357-es port foglalt vagy nem erheto el. Ha a MennyiMent mar fut, nyisd meg: http://127.0.0.1:7357 . Kulonben allitsd le az elozo kiszolgalot (Ctrl+C), majd inditsd ujra. A portot ne valtoztasd meg.'
    }
    Write-Host 'MennyiMent? fut: http://127.0.0.1:7357'
    Write-Host 'Ezt az ablakot hagyd nyitva. Leallitas: Ctrl+C vagy az ablak bezarasa.'
    Write-Host 'A bongeszoadatok megmaradnak. Ugyanazt a Chrome-profilt hasznald.'
    if (-not $NoBrowser) {
        $chrome = @(${env:ProgramFiles}, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA) |
            Where-Object { $_ } |
            ForEach-Object { Join-Path $_ 'Google/Chrome/Application/chrome.exe' } |
            Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ($chrome) { Start-Process -FilePath $chrome -ArgumentList 'http://127.0.0.1:7357' }
        else { Write-Host 'Chrome nem talalhato a szokasos helyen. Nyisd meg kezzel a fenti cimet Chrome-ban.' }
    }
    $mime = @{
        '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8'
        '.json' = 'application/json'; '.wasm' = 'application/wasm'; '.css' = 'text/css'
        '.svg' = 'image/svg+xml'; '.png' = 'image/png'; '.webp' = 'image/webp'
        '.ico' = 'image/x-icon'; '.ttf' = 'font/ttf'; '.otf' = 'font/otf'
        '.woff' = 'font/woff'; '.woff2' = 'font/woff2'; '.txt' = 'text/plain; charset=utf-8'
    }
    while ($true) {
        # Polling lets PowerShell process Ctrl+C even when no browser is connected.
        if (-not $listener.Pending()) { Start-Sleep -Milliseconds 50; continue }
        $client = $listener.AcceptTcpClient()
        $client.ReceiveTimeout = 5000
        $client.SendTimeout = 15000
        try {
            $stream = $client.GetStream()
            $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
            $request = $reader.ReadLine()
            $headerBytes = 0
            do {
                $line = $reader.ReadLine()
                $headerBytes += $line.Length
                if ($headerBytes -gt 16384) { throw 'Tul nagy HTTP fejlec.' }
            } while ($line)
            $parts = $request -split ' '
            $status = '200 OK'
            $file = $null
            $contentType = 'text/plain; charset=utf-8'
            $body = [Text.Encoding]::UTF8.GetBytes('Nem talalhato.')
            if ($parts.Count -lt 3 -or $parts[0] -notin @('GET', 'HEAD')) {
                $status = '405 Method Not Allowed'
            } else {
                $urlPath = [Uri]::UnescapeDataString(($parts[1] -split '\?')[0])
                $relative = $urlPath.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
                if (-not $relative) { $relative = 'index.html' }
                $candidate = [IO.Path]::GetFullPath((Join-Path $root $relative))
                if (-not $candidate.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
                    $status = '403 Forbidden'
                } elseif (Test-Path -LiteralPath $candidate -PathType Leaf) {
                    $file = [IO.File]::OpenRead($candidate)
                    $extension = [IO.Path]::GetExtension($candidate).ToLowerInvariant()
                    $contentType = if ($mime.ContainsKey($extension)) { $mime[$extension] } else { 'application/octet-stream' }
                } else { $status = '404 Not Found' }
            }
            $length = if ($file) { $file.Length } else { $body.Length }
            $headers = "HTTP/1.1 $status`r`nContent-Type: $contentType`r`nContent-Length: $length`r`nCache-Control: no-store`r`nX-Content-Type-Options: nosniff`r`nConnection: close`r`n`r`n"
            $bytes = [Text.Encoding]::ASCII.GetBytes($headers)
            $stream.Write($bytes, 0, $bytes.Length)
            if ($parts[0] -ne 'HEAD') {
                if ($file) { $file.CopyTo($stream) } else { $stream.Write($body, 0, $body.Length) }
            }
        } catch {
            Write-Verbose "Bongeszo kapcsolat megszakadt: $_"
        } finally {
            if ($file) { $file.Dispose(); $file = $null }
            $client.Dispose()
        }
    }
} catch {
    Write-Host "HIBA: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if ($listener) { $listener.Stop() }
}
