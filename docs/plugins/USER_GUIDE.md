# Plug-in User Guide

## Installation paths

| Platform | Folder |
|---------|-------|
| **Android** | `/data/data/<package>/files/plugins` |
| **iOS** | `Library/Application Support/plugins` inside the app sandbox |
| **macOS** | `Library/Application Support/plugins` in the app container |
| **Windows** | `%APPDATA%\poker_analyzer\plugins` |
| **Linux** | `~/.local/share/poker_analyzer/plugins` |
| **Web** | use **Download** in `PluginManagerScreen` |

Copy `<Name>Plugin.dart` into the folder for your platform.

## Enabling plug-ins

1. Open `PluginManagerScreen` from the side menu.
2. Toggle the required files.
3. Tap **Reload Plugins**.
