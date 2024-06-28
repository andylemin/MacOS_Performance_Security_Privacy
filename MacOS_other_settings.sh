#!/bin/sh
# This script contains a list of common performance optimisations for MacOS
# some useful settings, mostly cribbed from https://github.com/mathiasbynens/dotfiles/blob/master/.osx

echo "# Setting common system settings"
# Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Show remaining battery percentage
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
defaults write com.apple.menuextra.battery ShowTime -string "NO"

# Finder
echo
echo "# Setting common Finder settings"
# Show the ~/Library folder by default
chflags nohidden ~/Library
# Show all filename extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show all files in finder and open file dialogs
defaults write NSGlobalDomain AppleShowAllFiles -bool true
# Automatically open a new Finder window when a read only volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
# Empty Trash securely by default
defaults write com.apple.finder EmptyTrashSecurely -bool true
# Disable disk image verification
#defaults write com.apple.frameworks.diskimages skip-verify -bool true
#defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
#defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Map bottom right Trackpad corner to right-click
#defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
#defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true

# Safari
echo
echo "# Setting common Safari settings"
# Disable Safari’s thumbnail cache for History and Top Sites
defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2
# Enable Safari’s debug menu
defaults write com.apple.Safari IncludeDebugMenu -bool true
# Remove useless icons from Safari’s bookmarks bar
defaults write com.apple.Safari ProxiesInBookmarksBar "()"

# Disable the Ping sidebar in iTunes
echo
echo "# Setting common legacy iTunes settings"
defaults write com.apple.iTunes disablePingSidebar -bool true
# Disable all the other Ping stuff in iTunes
defaults write com.apple.iTunes disablePing -bool true

# Disable recent items in Quicktime
echo
echo "# Setting common Quicktime settings"
defaults write com.apple.QuickTimePlayerX NSRecentDocumentsLimit 0
defaults delete com.apple.QuickTimePlayerX.LSSharedFileList RecentDocuments
defaults write com.apple.QuickTimePlayerX.LSSharedFileList RecentDocuments -dict-add MaxAmount 0

echo
echo "# Disabling common system analytics"
# Disable (some) MacOS Analytics
/usr/bin/sudo defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -int 0
# Disable (some) MacOS Diagnostics
echo
echo "# Searching for configuration profiles configured for Apple Diagnostics; (* investigate if anything is returned *)"
/usr/bin/sudo /usr/sbin/system_profiler SPConfigurationProfileDataType | /usr/bin/grep allowDiagnosticSubmission

echo
echo "# Disabling DiagnosticMessagesHistory"
/usr/bin/sudo /usr/bin/defaults read "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" AutoSubmit
/usr/bin/sudo /usr/bin/defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" AutoSubmit -bool false
#/usr/bin/sudo /bin/chmod 644 /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist
#/usr/bin/sudo /usr/bin/chgrp admin /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist
sudo /usr/libexec/PlistBuddy -c "Add :AutoSubmit bool NO" "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist"
sudo /usr/libexec/PlistBuddy -c "Add :ThirdPartyDataSubmit bool NO" "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist"

# iTerm2
echo
echo "# Setting common iterm2 settings"
# Don't use native OSX full screen mode with iTerm2 (annoying animations)
defaults write com.googlecode.iterm2 UseLionStyleFullscreen -bool false
# Prompt on quit in iTerm2
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

# Apple Dock
echo
echo "# Setting common Apple Dock settings" # If using uBar4 changes are redundant, safe to always apply
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock expose-animation-duration -float 0
defaults write com.apple.dock springboard-show-duration -float 0
defaults write com.apple.dock springboard-hide-duration -float 0
defaults write com.apple.dock springboard-page-duration -float 0
defaults write com.apple.dock launchanim -bool false

# uBar4
echo
echo "# Setting common uBar4 settings"
# Hide 'uBar' from the uBar menu. Use YES instead of NO to restore it.
# defaults write ca.brawer.uBar menuAbout -bool NO
# Make apps that have a single window open, use the title of that window. Use NO instead of YES to use the app name.
defaults write ca.brawer.uBar singleWindowUsesTitle -bool YES
# Show the window count in grouped app tiles. Use NO instead of YES to hide the count.
defaults write ca.brawer.uBar showWindowCount -bool YES
# Use the document icon for windows. Use YES instead of NO to use the app icon when possible.
defaults write ca.brawer.uBar useAppIconForWindows -bool NO
# Practically hide the Apple Dock by making it’s auto-hide delay 1000 seconds.
defaults write com.apple.dock autohide-delay -float 1000 && killall Dock
# defaults delete com.apple.dock autohide-delay && killall Dock   # Restore Apple Dock

# Restarting affected applications
echo
echo "# Restarting Apps to apply changes"
for app in Finder Dock SystemUIServer Safari Mail; do killall "$app"; done

# DISABLING AirDrop; Apple advised Meter, UCLA, and other vendors, networking issues were caused by the “Apple Wireless Direct Link” interface, which helps power features like AirDrop and AirPlay:
# https://gist.github.com/pythoninthegrass/8073e5e3b24f385c9d9b712f6f243982
echo
echo "# Shutting 'Apple Wireless Direct Link' Interface (Handoff/Continuity/AirDrop/AirPlay etc)"
sudo ifconfig awdl0 down
echo "To make AirDrop Interface disable permanent. See; https://github.com/jamestut/awdlkiller"

echo
echo "# Installing Powerline fonts"
cd ~
git clone https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd ..
rm -rf fonts

echo
echo "# Installing XCode-Select"
xcode-select --install
sudo xcode-select --reset

echo
echo "# Disabling SpotLight"
sudo mdutil -a -i off
# mdutil -s /path/to/network/share/  # Check indexing for specific share
# mdutil -d /path/to/network/volume  # Disable indexing for specific share
# mdutil -E /path/to/network/share   # Erase index for specific share

echo
echo "# Disabling Brew Analytics"
brew analytics off

echo
echo "# Starting Cleanup Actions"
echo "Deleting all local timemachine snapshots (does not impact external backups)"
for d in $(tmutil listlocalsnapshotdates | grep "-"); do sudo tmutil deletelocalsnapshots $d; done
echo "Deleting all local temp Caches"
sudo rm -rf ~/Library/Caches/*
echo "Deleting all local temp logs"
sudo rm -rf ~/Library/Logs/*

echo
echo "# QuickView Reset/Clear Cache"
brew install qlvideo
sudo qlmanage -r cache
sudo qlmanage -r
echo "QuickView Configuring parameters"
defaults write uk.org.marginal.qlvideo SnapshotAlways -bool YES
defaults write uk.org.marginal.qlvideo SnapshotCount -int 1
defaults write uk.org.marginal.qlvideo SnapshotTime -int 60

echo
echo "# Cleaning syslog and aslmanager"
/usr/bin/sudo /bin/rm -rf /var/log/asl/*

# Disable Sleep
echo
echo "# Configuring Power (Disable Autopoweroff (hibernation), Powernap (dont wake), Standby, Proximitywake, TCPKeepalive)"
echo "# Enabling MacOS sleep - light sleep and powernap modes can break many workstation workloads (Disable on workstation, leave enabled on laptop)"
/usr/bin/sudo pmset -a disablesleep 0
# Enable sleep with 0, Disable sleep with 1
/usr/bin/sudo pmset -a autopoweroff 0
/usr/bin/sudo pmset -a powernap 0
/usr/bin/sudo pmset -a standby 0
/usr/bin/sudo pmset -a proximitywake 0
/usr/bin/sudo pmset -a tcpkeepalive 0

echo
echo "# SSD TRIM"
echo "Apple macOS enables Trim for internal official 'Apple' SSDs only by default."
echo "Advanced users can enable Trim for all SSDs (with Apple APFS formatted partitions) including USB devices."
echo "Apple macOS runs Trim when the file system is attached, on device connection or system restart."
echo "Apple does not provide a manual Trim tool like with Windows or Linux."
/usr/bin/sudo trimforce --enable

echo
echo "# JAVA - Uninstall manually if not required (or disable - Java can be disabled in System Preferences)"
echo "https://www.java.com/en/download/uninstalltool.jsp"

echo
echo "# Flash Player - Uninstall manually"

echo
echo "# Extras"
echo "The System profiler can be found with; sudo /usr/sbin/system_profiler"
echo "Enable 'Displays have separate spaces' in settings, so app menubars stay in same window as the Application.."
