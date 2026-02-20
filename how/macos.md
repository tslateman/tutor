# macOS CLI Cheat Sheet

macOS-specific commands and tools.

## Finder & Files

| Command                   | Description                |
| ------------------------- | -------------------------- |
| `open .`                  | Open current dir in Finder |
| `open file.pdf`           | Open file with default app |
| `open -a "App Name" file` | Open with specific app     |
| `open -R file`            | Reveal in Finder           |
| `open -e file`            | Open in TextEdit           |
| `open https://...`        | Open URL in browser        |
| `qlmanage -p file`        | Quick Look preview         |

## Clipboard

| Command                   | Description                     |
| ------------------------- | ------------------------------- |
| `pbcopy < file`           | Copy file contents to clipboard |
| `pbpaste > file`          | Paste clipboard to file         |
| `echo "text" \| pbcopy`   | Copy text to clipboard          |
| `pbpaste \| grep pattern` | Process clipboard contents      |
| `pbpaste \| wc -l`        | Count lines in clipboard        |

## Spotlight / Search

| Command                              | Description               |
| ------------------------------------ | ------------------------- |
| `mdfind "query"`                     | Spotlight search          |
| `mdfind -name "filename"`            | Search by filename        |
| `mdfind -onlyin ~/Documents "query"` | Search in directory       |
| `mdfind "kMDItemKind == 'PDF'"`      | Search by file type       |
| `mdfind "date:today"`                | Files modified today      |
| `mdls file`                          | Show file metadata        |
| `mdutil -s /`                        | Spotlight indexing status |

## System

| Command                              | Description            |
| ------------------------------------ | ---------------------- |
| `sw_vers`                            | macOS version info     |
| `system_profiler`                    | Full system info       |
| `system_profiler SPHardwareDataType` | Hardware info          |
| `uname -a`                           | Kernel info            |
| `sysctl -n machdep.cpu.brand_string` | CPU model              |
| `sysctl hw.memsize`                  | Total RAM              |
| `hostname`                           | Computer name          |
| `scutil --get ComputerName`          | Friendly computer name |

## Power & Sleep

| Command              | Description                    |
| -------------------- | ------------------------------ |
| `caffeinate`         | Prevent sleep (Ctrl+C to stop) |
| `caffeinate -t 3600` | Prevent sleep for 1 hour       |
| `caffeinate -s`      | Prevent sleep while on AC      |
| `caffeinate -d`      | Prevent display sleep          |
| `pmset -g`           | Power management settings      |
| `pmset sleepnow`     | Sleep immediately              |
| `shutdown -h now`    | Shutdown                       |
| `shutdown -r now`    | Restart                        |

## Audio & Speech

| Command                                       | Description           |
| --------------------------------------------- | --------------------- |
| `say "Hello world"`                           | Text to speech        |
| `say -v "?"`                                  | List available voices |
| `say -v Samantha "Hello"`                     | Specific voice        |
| `say -o audio.aiff "text"`                    | Save to file          |
| `afplay audio.mp3`                            | Play audio file       |
| `osascript -e 'set volume 5'`                 | Set volume (0-7)      |
| `osascript -e 'set volume output muted true'` | Mute                  |

## Disk Management

| Command                                                    | Description      |
| ---------------------------------------------------------- | ---------------- |
| `diskutil list`                                            | List all disks   |
| `diskutil info disk0`                                      | Disk info        |
| `diskutil mount disk2s1`                                   | Mount volume     |
| `diskutil unmount /Volumes/Name`                           | Unmount volume   |
| `diskutil eject disk2`                                     | Eject disk       |
| `diskutil eraseDisk APFS "Name" disk2`                     | Erase and format |
| `hdiutil create -size 1g -fs APFS -volname "Vol" disk.dmg` | Create DMG       |
| `hdiutil attach disk.dmg`                                  | Mount DMG        |
| `hdiutil detach /Volumes/Vol`                              | Unmount DMG      |

## User Management

| Command                                                         | Description        |
| --------------------------------------------------------------- | ------------------ |
| `whoami`                                                        | Current user       |
| `id`                                                            | User ID and groups |
| `dscl . -list /Users`                                           | List all users     |
| `dscl . -read /Users/username`                                  | User details       |
| `dscacheutil -q user -a name username`                          | Query user info    |
| `dscacheutil -flushcache`                                       | Flush DNS cache    |
| `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder` | Full DNS flush     |

## Services (launchctl)

| Command                                                     | Description          |
| ----------------------------------------------------------- | -------------------- |
| `launchctl list`                                            | List loaded services |
| `launchctl list \| grep name`                               | Find service         |
| `launchctl load ~/Library/LaunchAgents/com.example.plist`   | Load service         |
| `launchctl unload ~/Library/LaunchAgents/com.example.plist` | Unload service       |
| `launchctl start com.example.service`                       | Start service        |
| `launchctl stop com.example.service`                        | Stop service         |

### LaunchAgent Locations

| Path                            | Scope         |
| ------------------------------- | ------------- |
| `~/Library/LaunchAgents`        | Current user  |
| `/Library/LaunchAgents`         | All users     |
| `/Library/LaunchDaemons`        | System (root) |
| `/System/Library/LaunchDaemons` | Apple system  |

## Defaults (Preferences)

| Command                                                 | Description                  |
| ------------------------------------------------------- | ---------------------------- |
| `defaults read`                                         | All preferences              |
| `defaults read com.apple.finder`                        | App preferences              |
| `defaults read com.apple.dock autohide`                 | Specific key                 |
| `defaults write com.apple.dock autohide -bool true`     | Set boolean                  |
| `defaults write com.apple.dock autohide-delay -float 0` | Set float                    |
| `defaults delete com.apple.dock autohide`               | Remove key                   |
| `killall Dock`                                          | Restart Dock (apply changes) |
| `killall Finder`                                        | Restart Finder               |

### Useful Defaults

```bash
# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Disable press-and-hold for keys (enable key repeat)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Screenshot location
defaults write com.apple.screencapture location ~/Screenshots
killall SystemUIServer

# Screenshot format (png, jpg, pdf)
defaults write com.apple.screencapture type png
```

## Homebrew

| Command                      | Description          |
| ---------------------------- | -------------------- |
| `brew install package`       | Install package      |
| `brew install --cask app`    | Install GUI app      |
| `brew uninstall package`     | Remove package       |
| `brew list`                  | List installed       |
| `brew list --cask`           | List installed apps  |
| `brew search name`           | Search packages      |
| `brew info package`          | Package info         |
| `brew update`                | Update Homebrew      |
| `brew upgrade`               | Upgrade all packages |
| `brew upgrade package`       | Upgrade specific     |
| `brew outdated`              | List outdated        |
| `brew cleanup`               | Remove old versions  |
| `brew doctor`                | Diagnose issues      |
| `brew services list`         | List services        |
| `brew services start name`   | Start service        |
| `brew services stop name`    | Stop service         |
| `brew services restart name` | Restart service      |

## Software Updates

| Command                            | Description                       |
| ---------------------------------- | --------------------------------- |
| `softwareupdate -l`                | List available updates            |
| `softwareupdate -i -a`             | Install all updates               |
| `softwareupdate -i "update-name"`  | Install specific update           |
| `softwareupdate --install-rosetta` | Install Rosetta 2 (Apple Silicon) |

## Network (macOS-specific)

| Command                                 | Description                     |
| --------------------------------------- | ------------------------------- |
| `networksetup -listallhardwareports`    | List network interfaces         |
| `networksetup -getairportnetwork en0`   | Current WiFi network            |
| `networksetup -setairportpower en0 off` | Turn off WiFi                   |
| `networksetup -setairportpower en0 on`  | Turn on WiFi                    |
| `airport -s`                            | Scan for WiFi networks          |
| `ifconfig en0`                          | Interface info                  |
| `ipconfig getifaddr en0`                | Local IP address                |
| `networkQuality`                        | Internet speed test (macOS 12+) |

## Security & Privacy

| Command                                                                 | Description                           |
| ----------------------------------------------------------------------- | ------------------------------------- |
| `security find-generic-password -a "account" -s "service" -w`           | Get password from Keychain            |
| `security add-generic-password -a "account" -s "service" -w "password"` | Add to Keychain                       |
| `spctl --status`                                                        | Gatekeeper status                     |
| `spctl --master-disable`                                                | Disable Gatekeeper                    |
| `xattr -l file`                                                         | List extended attributes              |
| `xattr -d com.apple.quarantine file`                                    | Remove quarantine flag                |
| `xattr -cr /Applications/App.app`                                       | Clear all xattrs (fix "damaged" apps) |
| `codesign -v /Applications/App.app`                                     | Verify code signature                 |

## File System

| Command                 | Description              |
| ----------------------- | ------------------------ |
| `xattr -l file`         | List extended attributes |
| `xattr -c file`         | Clear all attributes     |
| `GetFileInfo file`      | Classic file info        |
| `SetFile -a V file`     | Make invisible           |
| `chflags hidden file`   | Hide file                |
| `chflags nohidden file` | Unhide file              |

## Screenshots

| Command                             | Description          |
| ----------------------------------- | -------------------- |
| `screencapture -i screenshot.png`   | Interactive capture  |
| `screencapture -c`                  | Capture to clipboard |
| `screencapture -T 5 screenshot.png` | Delay 5 seconds      |
| `screencapture -w screenshot.png`   | Capture window       |
| `screencapture -x screenshot.png`   | No sound             |

### Keyboard Shortcuts

| Shortcut            | Action                 |
| ------------------- | ---------------------- |
| `Cmd+Shift+3`       | Full screen screenshot |
| `Cmd+Shift+4`       | Selection screenshot   |
| `Cmd+Shift+4+Space` | Window screenshot      |
| `Cmd+Shift+5`       | Screenshot toolbar     |

## Application Management

| Command                                       | Description       |
| --------------------------------------------- | ----------------- |
| `mdfind "kMDItemKind == 'Application'"`       | List all apps     |
| `system_profiler SPApplicationsDataType`      | Detailed app list |
| `lsappinfo list`                              | Running apps info |
| `osascript -e 'quit app "App Name"'`          | Quit app          |
| `osascript -e 'tell app "Finder" to restart'` | Restart Finder    |
| `killall "App Name"`                          | Force quit app    |

## AppleScript One-Liners

```bash
# Display notification
osascript -e 'display notification "Body" with title "Title"'

# Display dialog
osascript -e 'display dialog "Message" buttons {"OK"}'

# Get frontmost app
osascript -e 'tell application "System Events" to get name of first process whose frontmost is true'

# Set volume
osascript -e 'set volume output volume 50'

# Get clipboard
osascript -e 'the clipboard'

# Empty trash
osascript -e 'tell application "Finder" to empty trash'
```

## Useful Patterns

```bash
# Watch file changes
fswatch -o . | xargs -n1 -I{} echo "Changed"

# Copy file path to clipboard
pwd | pbcopy

# Open man page in Preview as PDF
man -t ls | open -f -a Preview

# Get bundle ID of app
osascript -e 'id of app "Safari"'

# Set default app for file type (requires duti)
duti -s com.apple.Safari .html all

# Quick timer
caffeinate -t 1800 && say "Timer done"

# Flush DNS
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# Show/hide desktop icons
defaults write com.apple.finder CreateDesktop false && killall Finder
defaults write com.apple.finder CreateDesktop true && killall Finder

# Reset Launchpad
defaults write com.apple.dock ResetLaunchPad -bool true && killall Dock

# Prevent .DS_Store on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
```

## See Also

- [Shell](shell.md) — Scripting patterns, loops, conditionals, functions
- [Unix](unix.md) — Shell commands, file ops, text processing
- [Terminal Emulators](terminal-emulators.md) — iTerm2 vs Ghostty, rendering,
  decision guide
- [CLI-First](../why/cli-first.md) — Why terminal-first workflows
