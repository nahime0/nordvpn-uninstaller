# NordVPN Uninstaller for macOS

## Why this script?

A standard NordVPN uninstall (dragging the app to Trash) does **not** completely remove the application. NordVPN leaves behind system daemons, privileged helpers, launch agents, cached files, and various configuration files scattered across your system.

This script performs a **complete removal** of all NordVPN components from macOS. It is based on information gathered from various online sources about NordVPN's file locations and system components.

### My use case

I created this script because NordVPN was interfering with **Claude Cowork**, preventing it from working correctly. Even after uninstalling NordVPN through the standard method, the leftover system components continued to cause issues. Only a complete removal solved the problem.

## Disclaimer

**USE AT YOUR OWN RISK.** This script removes files and kills processes on your system. While it has been tested, the author takes no responsibility for any damage, data loss, or system issues that may occur. Make sure you have backups before running this script. Review the code before executing it.

## Usage

```bash
sudo bash clean.sh
```

## What it removes

### Applications
- NordVPN.app from `/Applications/`
- All apps with bundle ID `com.nordvpn.*`

### System files (requires sudo)
- `/Library/LaunchDaemons/com.nordvpn.*.helper.plist`
- `/Library/PrivilegedHelperTools/com.nordvpn.*.helper`
- `/Library/PrivilegedHelperTools/com.nordvpn.*.ovpnDnsManager`

### User files
- `~/Library/Preferences/com.nordvpn.*.plist`
- `~/Library/Preferences/group.com.nordvpn.*.plist`
- `~/Library/Caches/com.nordvpn.*`
- `~/Library/HTTPStorages/com.nordvpn.*`
- `~/Library/Application Support/NordVPN`
- `~/Library/Logs/NordVPN`
- `~/Library/Saved Application State/com.nordvpn.*`
- `~/Library/Group Containers/*nordvpn*`

### Processes
- Terminates the NordVPN application
- Terminates OpenVPN daemons
- Terminates privileged helpers
