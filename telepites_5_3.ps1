param(
    [string]$Project = 'D:\mobil app\mennyiment'
)
$ErrorActionPreference = 'Stop'
$main = Join-Path $Project 'lib\main.dart'
if (-not (Test-Path $main)) { throw "Nem található: $main" }
$original = [System.IO.File]::ReadAllText($main, [System.Text.Encoding]::UTF8)
if ($original -notmatch 'class MennyiMentApp' -or $original -notmatch 'Widget _shortcut\(' -or $original -notmatch 'Widget _panelCard\(') {
    throw 'A jelenlegi main.dart szerkezete eltér a várt verziótól. Nem módosítottam semmit.'
}
if ($original -match 'MENNYIMENT 5.3 DESIGN') {
    Write-Host 'Az 5.3 arculati módosítás már szerepel a fájlban.'; exit 0
}
$updated = $original
function Replace-Exact([string]$old, [string]$new) {
    $script:updated = $script:updated.Replace($old, $new)
    if ($script:updated -eq $script:previous) { throw "Nem található a várt kódrészlet: $old" }
}
# Biztonságos, rögzített főképernyő-cserék: sem az adatmodell, sem a mentések nem változnak.
$script:previous = $updated
Replace-Exact 'static const Color _mint = Color(0xFFFF9E2C);' 'static const Color _mint = Color(0xFFFFA329); // MENNYIMENT 5.3 DESIGN'
$script:previous = $updated
Replace-Exact 'static const Color _panel = Color(0xFF21182B);' 'static const Color _panel = Color(0xFF24172E);'
$script:previous = $updated
Replace-Exact 'static const Color _muted = Color(0xFFD0C1D2);' 'static const Color _muted = Color(0xFFD8C7DE);'
$script:previous = $updated
Replace-Exact 'color: const Color(0xFF172923),' 'color: const Color(0xFF27182F),'
$script:previous = $updated
Replace-Exact 'foregroundColor: const Color(0xFF082017),' 'foregroundColor: const Color(0xFF1A101B),'
$script:previous = $updated
Replace-Exact "const Text('MENNYIMENT? 5.0 • TÖBB MINT EGY ITALNAPLÓ'," "const Text('MENNYIMENT? 5.3 • TÖBB MINT EGY ITALNAPLÓ',"
$script:previous = $updated
Replace-Exact 'color: Colors.white.withValues(alpha: 0.055)' 'color: const Color(0xFF322039)'
$script:previous = $updated
Replace-Exact 'color: const Color(0xFF254536)' 'color: const Color(0xFF3E254F)'
# A központi arculat többi eleme a MaterialApp témájában található.
$script:previous = $updated
Replace-Exact 'indicatorColor: const Color(0xFF4B2959)' 'indicatorColor: const Color(0xFF753C80)'
$script:previous = $updated
Replace-Exact 'CardThemeData(color: const Color(0xFF21182B)' 'CardThemeData(color: const Color(0xFF24172E)'
$script:previous = $updated
Replace-Exact 'seedColor: const Color(0xFFFF9E2C)' 'seedColor: const Color(0xFFFFA329)'
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path $Project ("main_backup_before_53_$timestamp.dart.txt")
[System.IO.File]::WriteAllText($backup, $original, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($main, $updated, [System.Text.UTF8Encoding]::new($false))
Write-Host "Arculati módosítás kész. Biztonsági mentés: $backup" -ForegroundColor Green
Write-Host 'Következő lépés: flutter analyze, flutter test, flutter run -d chrome'
