# NordVPN Uninstaller for macOS

Script per la rimozione completa di NordVPN da macOS.

## Uso

```bash
sudo bash clean.sh
```

## Cosa rimuove

### Applicazioni
- NordVPN.app da `/Applications/`
- Tutte le app con bundle ID `com.nordvpn.*`

### File di sistema (richiede sudo)
- `/Library/LaunchDaemons/com.nordvpn.*.helper.plist`
- `/Library/PrivilegedHelperTools/com.nordvpn.*.helper`
- `/Library/PrivilegedHelperTools/com.nordvpn.*.ovpnDnsManager`

### File utente
- `~/Library/Preferences/com.nordvpn.*.plist`
- `~/Library/Preferences/group.com.nordvpn.*.plist`
- `~/Library/Caches/com.nordvpn.*`
- `~/Library/HTTPStorages/com.nordvpn.*`
- `~/Library/Application Support/NordVPN`
- `~/Library/Logs/NordVPN`
- `~/Library/Saved Application State/com.nordvpn.*`
- `~/Library/Group Containers/*nordvpn*`

### Processi
- Termina l'applicazione NordVPN
- Termina i daemon OpenVPN
- Termina gli helper privilegiati
