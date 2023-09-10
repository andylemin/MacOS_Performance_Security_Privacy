#!/bin/sh

LAUNCH_AGENTS=/System/Library/LaunchAgents/*

sudo rm /private/var/db/com.apple.xpc.launchd/disabled.*

for f in $LAUNCH_AGENTS
do
if [[ "$f" == *".bak" ]]; then
    o="${f#.bak}"
    echo "Re-naming $f to $o"
    #mv $f $o
fi
done

