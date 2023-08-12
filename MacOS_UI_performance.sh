#!/bin/sh
# This script contains a list of common performance optimisations for MacOS

# Disable UI Animations
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
defaults write -g NSWindowResizeTime -float 0.001
defaults write -g QLPanelAnimationDuration -float 0
defaults write -g NSScrollViewRubberbanding -bool false
defaults write -g NSDocumentRevisionsWindowTransformAnimation -bool false
defaults write -g NSToolbarFullScreenAnimationDuration -float 0
defaults write -g NSBrowserColumnAnimationSpeedMultiplier -float 0
defaults write com.apple.finder DisableAllAnimations -bool true
defaults write com.apple.Mail DisableSendAnimations -bool true
defaults write com.apple.Mail DisableReplyAnimations -bool true
defaults write com.apple.Safari WebKitInitialTimedLayoutDelay 0.2
# Disable menu bar transparency
defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool false
# Disable send and reply animations in Mail.app
defaults write com.apple.Mail DisableReplyAnimations -bool true
defaults write com.apple.Mail DisableSendAnimations -bool true

# If using uBar4 these are redundant
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock expose-animation-duration -float 0
defaults write com.apple.dock springboard-show-duration -float 0
defaults write com.apple.dock springboard-hide-duration -float 0
defaults write com.apple.dock springboard-page-duration -float 0
defaults write com.apple.dock launchanim -bool false

# uBar 4 Changes
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

# Keyboard Speed
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
