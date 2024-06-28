#!/bin/sh
# This script contains a list of common performance optimisations for MacOS

# Disable UI Animations
echo "# Disabling UI Animations"
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
echo "# Disabling menu bar transparency"
defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool false

# Disable send and reply animations in Mail.app
echo "# Disabling send and reply animations in Mail"
defaults write com.apple.Mail DisableReplyAnimations -bool true
defaults write com.apple.Mail DisableSendAnimations -bool true

# Keyboard Speed
echo "# Increasing keyboard speed"
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
