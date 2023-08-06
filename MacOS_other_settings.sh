#!/bin/sh
# This script contains a list of common performance optimisations for MacOS

# some useful settings, mostly cribbed from https://github.com/mathiasbynens/dotfiles/blob/master/.osx

defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool NO

# Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Show remaining battery percentage
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
defaults write com.apple.menuextra.battery ShowTime -string "NO"

# Show all filename extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show all files in finder and open file dialogs
defaults write NSGlobalDomain AppleShowAllFiles -bool true

# Disable disk image verification
#defaults write com.apple.frameworks.diskimages skip-verify -bool true
#defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
#defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Automatically open a new Finder window when a read only volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Empty Trash securely by default
defaults write com.apple.finder EmptyTrashSecurely -bool true

# Map bottom right Trackpad corner to right-click
#defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
#defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true

# Disable Safari’s thumbnail cache for History and Top Sites
defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

# Enable Safari’s debug menu
defaults write com.apple.Safari IncludeDebugMenu -bool true

# Remove useless icons from Safari’s bookmarks bar
defaults write com.apple.Safari ProxiesInBookmarksBar "()"

# Disable the Ping sidebar in iTunes
defaults write com.apple.iTunes disablePingSidebar -bool true

# Disable all the other Ping stuff in iTunes
defaults write com.apple.iTunes disablePing -bool true

# Disable recent items in Quicktime
defaults write com.apple.QuickTimePlayerX NSRecentDocumentsLimit 0
defaults delete com.apple.QuickTimePlayerX.LSSharedFileList RecentDocuments
defaults write com.apple.QuickTimePlayerX.LSSharedFileList RecentDocuments -dict-add MaxAmount 0

# Disable (some) MacOS Analytics
sudo defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -int 0

# Disable (some) MacOS Diagnostics
echo "Checking if a configuration profile is configured for Apple Diagnostics; (investigate if something is returned)"
/usr/bin/sudo /usr/sbin/system_profiler SPConfigurationProfileDataType | /usr/bin/grep allowDiagnosticSubmission
/usr/bin/defaults read "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" AutoSubmit
/usr/bin/sudo /usr/bin/defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" AutoSubmit -bool false
#/usr/bin/sudo /bin/chmod 644 /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist
#/usr/bin/sudo /usr/bin/chgrp admin /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist
sudo /usr/libexec/PlistBuddy -c "Add :AutoSubmit bool NO" "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist"
sudo /usr/libexec/PlistBuddy -c "Add :ThirdPartyDataSubmit bool NO" "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist"

# Show the ~/Library folder
chflags nohidden ~/Library

# Don't use native OSX full screen mode with iTerm2 (annoying animations)
defaults write com.googlecode.iterm2 UseLionStyleFullscreen -bool false

# prompt on quit in iTerm2
defaults write com.googlecode.iterm2 PromptOnQuit -bool true
# Use visual bell in iTerm2
defaults write com.googlecode.iterm2 "Silence Bell" -bool false
defaults write com.googlecode.iterm2 "Flashing Bell" -bool true
# Show tabs immediately in full screen mode when pressing cmd key
defaults write com.googlecode.iterm2 FsTabDelay "0.1"
# Ignore test releases when checking for iTerm2 updates
defaults write com.googlecode.iterm2 CheckTestRelease -bool false
# Disable iTerm2 new output indicator, indicates new output when none
defaults write com.googlecode.iterm2 ShowNewOutputIndicator -bool false
# Hide iTerm2 tab number, I prefer to see more of the cwd path
defaults write com.googlecode.iterm2 HideTabNumber -bool true

# Don't use native OSX full screen mode with MacVim (annoying animations)
defaults write org.vim.MacVim MMNativeFullScreen -int 0

# Kill affected applications
for app in Finder Dock SystemUIServer Safari Mail; do killall "$app"; done
