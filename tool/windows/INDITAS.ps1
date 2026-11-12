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

    # Pure .NET workers also run on Windows PowerShell 5.1: no runspace,
    # Python, Node, administrator permission or downloaded dependency needed.
    if (-not ('MennyiMentLocalWebServer' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Net.Sockets;
using System.Text;
using System.Threading;

public static class MennyiMentLocalWebServer {
    private static readonly SemaphoreSlim Slots = new SemaphoreSlim(64, 64);
    public static void Serve(TcpClient client, string root) {
        if (!Slots.Wait(0)) { client.Close(); return; }
        ThreadPool.QueueUserWorkItem(delegate(object unused) {
            try { Handle(client, root); }
            finally { client.Close(); Slots.Release(); }
        });
    }
    private static string Mime(string path) {
        switch (Path.GetExtension(path).ToLowerInvariant()) {
            case ".html": return "text/html; charset=utf-8";
            case ".js": return "text/javascript; charset=utf-8";
            case ".json": return "application/json";
            case ".wasm": return "application/wasm";
            case ".css": return "text/css";
            case ".svg": return "image/svg+xml";
            case ".png": return "image/png";
            case ".webp": return "image/webp";
            case ".ico": return "image/x-icon";
            case ".ttf": return "font/ttf";
            case ".otf": return "font/otf";
            case ".woff": return "font/woff";
            case ".woff2": return "font/woff2";
            case ".txt": return "text/plain; charset=utf-8";
            default: return "application/octet-stream";
        }
    }
    private static void Handle(TcpClient client, string root) {
        FileStream file = null;
        try {
            // Chrome preconnects may stay idle while other assets are loading.
            // Each accepted connection has its own worker, so it blocks no peer.
            client.ReceiveTimeout = 30000;
            client.SendTimeout = 15000;
            using (NetworkStream stream = client.GetStream())
            using (StreamReader reader = new StreamReader(stream, Encoding.ASCII, false, 1024, true)) {
                StringBuilder request = new StringBuilder();
                bool complete = false;
                while (request.Length < 16384) {
                    int next = reader.Read();
                    if (next < 0) return;
                    request.Append((char)next);
                    int n = request.Length;
                    if (n >= 4 && request[n-4]=='\r' && request[n-3]=='\n' &&
                        request[n-2]=='\r' && request[n-1]=='\n') { complete = true; break; }
                }
                string[] parts = request.ToString().Split('\n')[0].TrimEnd('\r')
                    .Split(new char[] {' '}, StringSplitOptions.RemoveEmptyEntries);
                string status = "200 OK", type = "text/plain; charset=utf-8";
                byte[] body = Encoding.UTF8.GetBytes("Nem talalhato.");
                if (!complete) status = "431 Request Header Fields Too Large";
                else if (parts.Length != 3 || (parts[0] != "GET" && parts[0] != "HEAD"))
                    status = "405 Method Not Allowed";
                else {
                    try {
                        string target = Uri.UnescapeDataString(parts[1].Split('?')[0]);
                        string relative = target.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
                        if (relative.Length == 0) relative = "index.html";
                        string candidate = Path.GetFullPath(Path.Combine(root, relative));
                        StringComparison comparison = Path.DirectorySeparatorChar == '\\'
                            ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal;
                        if (!candidate.StartsWith(root, comparison)) status = "403 Forbidden";
                        else if (File.Exists(candidate)) {
                            file = File.OpenRead(candidate); type = Mime(candidate);
                        } else status = "404 Not Found";
                    } catch (ArgumentException) { status = "400 Bad Request"; }
                    catch (NotSupportedException) { status = "400 Bad Request"; }
                    catch (UnauthorizedAccessException) { status = "403 Forbidden"; }
                }
                long length = file == null ? body.Length : file.Length;
                string headers = "HTTP/1.1 " + status + "\r\nContent-Type: " + type +
                    "\r\nContent-Length: " + length +
                    "\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff" +
                    "\r\nConnection: close\r\n\r\n";
                byte[] bytes = Encoding.ASCII.GetBytes(headers);
                stream.Write(bytes, 0, bytes.Length);
                if (parts.Length == 0 || parts[0] != "HEAD") {
                    if (file != null) file.CopyTo(stream);
                    else stream.Write(body, 0, body.Length);
                }
            }
        } catch (IOException) {
            // Closing a browser tab or an idle preconnect is not a server error.
        } catch (SocketException) {
        } catch (Exception) {
            Console.Error.WriteLine("HTTP kiszolgalasi hiba. Ellenorizd a web ZIP fajljait.");
        } finally { if (file != null) file.Dispose(); }
    }
}
'@
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
    while ($true) {
        # Polling lets PowerShell process Ctrl+C when no browser is connected.
        if (-not $listener.Pending()) { Start-Sleep -Milliseconds 50; continue }
        [MennyiMentLocalWebServer]::Serve($listener.AcceptTcpClient(), $root)
    }

} catch {
    Write-Host "HIBA: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if ($listener) { $listener.Stop() }
}
