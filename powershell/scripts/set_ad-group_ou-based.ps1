# OU definieren
$ou = "ou-path"


# Quell- und Zielgruppe definieren
$sourceGroup = "src_group"
$targetGroup = "trg_group"

# Gruppe als DistinguishedName holen
$groupDN = (Get-ADGroup -Identity $sourceGroup).DistinguishedName

# Benutzer aus der OU holen, die Mitglieder der Quellgruppe sind
$filteredUsers = Get-ADUser -SearchBase $ou -LDAPFilter "(memberOf=$groupDN)" -Properties memberOf

# Zielgruppen-Mitglieder im Voraus laden zur Prüfung
$targetGroupMembers = Get-ADGroupMember -Identity $targetGroup -Recursive | Where-Object { $_.objectClass -eq 'user' }

# Benutzer zur Zielgruppe hinzufügen – nur wenn noch nicht Mitglied
foreach ($user in $filteredUsers) {
    $isAlreadyMember = $targetGroupMembers | Where-Object { $_.SamAccountName -eq $user.SamAccountName }

    if (-not $isAlreadyMember) {
        try {
            Add-ADGroupMember -Identity $targetGroup -Members $user.SamAccountName -ErrorAction Stop
            Write-Host " $($user.SamAccountName) wurde zur Gruppe '$targetGroup' hinzugefügt."
        }
        catch {
            Write-Warning " Fehler beim Hinzufügen von $($user.SamAccountName): $_"
        }
    }
    else {
        Write-Host "  $($user.SamAccountName) ist bereits Mitglied der Gruppe '$targetGroup'."
    }
}
