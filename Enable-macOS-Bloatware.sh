#!/bin/bash

# Restores Apple LaunchAgents/LaunchDaemons previously disabled by the Disable-*-Bloatware.sh scripts.
# Must be run in Recovery mode with the system volume mounted read-write (README steps 1-7).
# The restores only take effect after creating and blessing a new snapshot (README steps 10-14).

MYROOTDISK="/Volumes/Macintosh HD"

read -p "Please confirm; Running in Recovery mode with '${MYROOTDISK}' mounted read-write? [y/n]" recmode
if [[ "$recmode" != "y" ]]; then
    echo "This script must be run from within Recovery mode (see README steps 1-7)!"
    echo
    exit 1
fi

for dir in LaunchAgents LaunchDaemons
do
    for f in "${MYROOTDISK}/System/Library/${dir}/"*.plist.bak; do
        [ -e "$f" ] || [ -L "$f" ] || continue
        o="${f%.bak}"
        echo "${dir}: Restoring $(basename "$f") to $(basename "$o")"
        mv "$f" "$o"
    done
done

# Restore the geod XPC binary renamed by the disable script
GEOD_BIN="${MYROOTDISK}/System/Library/PrivateFrameworks/GeoServices.framework/Versions/A/XPCServices/com.apple.geod.xpc/Contents/MacOS/com.apple.geod"
if [ -e "${GEOD_BIN}.bak" ]; then
    echo "Geod: Restoring com.apple.geod XPC binary"
    mv "${GEOD_BIN}.bak" "${GEOD_BIN}"
fi

# The launchctl override database lives on the Data volume, not the sealed system volume
for db in "${MYROOTDISK}/System/Volumes/Data/private/var/db/com.apple.xpc.launchd" \
          "${MYROOTDISK} - Data/private/var/db/com.apple.xpc.launchd"
do
    if ls "${db}"/disabled.* >/dev/null 2>&1; then
        echo "Removing launchctl disable overrides in ${db}"
        rm -f "${db}"/disabled.*
    fi
done
echo "If no override database was found above, run in normal mode after reboot;"
echo "  sudo rm /private/var/db/com.apple.xpc.launchd/disabled.*"

echo
echo "Done. Now create and bless a new snapshot (README steps 10-14), then reboot in Normal mode."
