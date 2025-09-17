<# 
.SYNOPSIS
Entfernt alle Benutzer aus einer bestimmten OU aus der Gruppe $groupToClean (inkl. verschachtelter Mitgliedschaften).

WARNUNG: Das Skript nimmt Änderungen vor.
#>

# === Parameter anpassen ===
$ou            = "ou-path"
$groupToClean  = "group"
$doCsvBackup   = $true
$exportFolder  = "export_path"

# === Vorbereitung ===
if ($doCsvBackup) {
    if (-not (Test-Path $exportFolder)) { New-Item -ItemType Directory -Path $exportFolder | Out-Null }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
}

# Gruppe DN holen
$groupDN = (Get-ADGroup -Identity $groupToClean -ErrorAction Stop).DistinguishedName

# Rekursiver LDAP-Filter (IN CHAIN)
$ldapFilter = "(memberOf:1.2.840.113556.1.4.1941:=$groupDN)"

# Benutzer aus der OU holen, die (rekursiv) Mitglied der Gruppe sind
$usersInGroupFromOU = Get-ADUser `
  -SearchBase $ou `
  -LDAPFilter $ldapFilter `
  -SearchScope Subtree `
  -ResultSetSize $null `
  -ResultPageSize 2000 `
  -Properties displayName, samAccountName, distinguishedName

# Optional: Backup/Report erzeugen
if ($doCsvBackup) {
    $csvPath = Join-Path $exportFolder "report_before_removal_$($groupToClean)_$timestamp.csv"
    $usersInGroupFromOU |
        Select-Object samAccountName, displayName, distinguishedName |
        Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Backup-Report gespeichert: $csvPath" -ForegroundColor Cyan
}

# Nichts zu tun?
if (-not $usersInGroupFromOU -or $usersInGroupFromOU.Count -eq 0) {
    Write-Host "Keine betroffenen Benutzer gefunden. Es wurden keine Änderungen vorgenommen." -ForegroundColor Green
    return
}

Write-Host "Starte Entfernung aus '$groupToClean' für Benutzer aus OU:" -ForegroundColor Yellow
Write-Host " $ou" -ForegroundColor Yellow
Write-Host "Gefunden: $($usersInGroupFromOU.Count) Benutzer" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"

$removed = 0
$failed  = 0

foreach ($user in $usersInGroupFromOU | Sort-Object samAccountName) {
    try {
        # Entfernen ohne Rückfrage
        Remove-ADGroupMember -Identity $groupToClean -Members $user.DistinguishedName -Confirm:$false -ErrorAction Stop
        $removed++
        Write-Host "[ENTFERNT] $($user.samAccountName) `t $($user.displayName)"
    }
    catch {
        $failed++
        Write-Warning "[FEHLER]  $($user.samAccountName) `t $($user.displayName) :: $($_.Exception.Message)"
    }
}

Write-Host "------------------------------------------------------------"
Write-Host "Fertig. Erfolgreich entfernt: $removed | Fehlgeschlagen: $failed" -ForegroundColor Yellow

# Optional: Nachher-Report
if ($doCsvBackup) {
    $afterCsvPath = Join-Path $exportFolder "report_after_removal_$($groupToClean)_$timestamp.csv"
    $stillMembers = Get-ADUser -SearchBase $ou -LDAPFilter $ldapFilter -SearchScope Subtree -ResultSetSize $null -ResultPageSize 2000 -Properties samAccountName,displayName,distinguishedName
    $stillMembers | Select-Object samAccountName,displayName,distinguishedName |
        Export-Csv -Path $afterCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Nachher-Report gespeichert: $afterCsvPath" -ForegroundColor Cyan
}
