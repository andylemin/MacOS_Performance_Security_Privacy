#!/usr/bin/env ksh

# From MacOS Catalina 10.15.3, /etc/sysctl.conf values are no longer respected (set using plists instead)

read -p "Have you disabled SIP? [y/n]" recmode
if [[ "$recmode" != "y" ]]; then
    echo "Disable SIP first (reboot, cmd# + R, 'csrutil disable')"
    echo "Re-nable SIP when done (reboot, cmd# + R, 'csrutil enable')"
    exit
fi

# Needs further testing (requires machine with at least 32 or 64 GB RAM);
#             <string>kern.sysv.shmmax=4194304</string>
#             <string>kern.sysv.shmmin=1</string>
#             <string>kern.sysv.shmmni=32</string>
#             <string>kern.sysv.shmseg=8</string>
#             <string>kern.sysv.shmall=1024</string>

echo "Ventura - Updating /Library/LaunchDaemons/com.startup.sysctl.plist"
sudo cp -f ./Library_LaunchDaemons_com.startup.sysctl.plist /Library/LaunchDaemons/com.startup.sysctl.plist
sudo chown root:wheel /Library/LaunchDaemons/com.startup.sysctl.plist
# validate key-value pairs
plutil /Library/LaunchDaemons/com.startup.sysctl.plist
# load plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.startup.sysctl.plist
# check logs
tail /tmp/sysctl.out
tail /tmp/sysctl.err

echo "Ventura - Updating /Library/LaunchDaemons/limit.maxfiles.plist"
sudo cp -f ./Library_LaunchDaemons_limit.maxfiles.plist /Library/LaunchDaemons/limit.maxfiles.plist
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
plutil /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/limit.maxfiles.plist
echo

echo "System Limits"
limit

echo "NOTICE; You can Re-enable SIP now!!! (reboot, cmd# + R, csrutil enable)"
sleep 5
