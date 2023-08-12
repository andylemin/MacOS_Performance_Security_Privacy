#!/usr/bin/env ksh

# From MacOS Catalina 10.15.3, /etc/sysctl.conf values are no longer respected (set using plists instead)

read -p "Have you disabled SIP? [y/n]" recmode
if [[ "$recmode" != "y" ]]; then
    echo "Disable SIP first (reboot, cmd# + R, 'csrutil disable')"
    echo "Re-nable SIP when done (reboot, cmd# + R, 'csrutil enable')"
    exit
fi

# Needs further testing (requires machine with at least 32 or 64 GB RAM);
#  18             <string>kern.sysv.shmmax=4194304</string>
  # 19             <string>kern.sysv.shmmin=1</string>
  # 20             <string>kern.sysv.shmmni=32</string>
  # 21             <string>kern.sysv.shmseg=8</string>
  # 22             <string>kern.sysv.shmall=1024</string>
  # 23             <string>kern.maxfiles=524288</string>
  # 24             <string>kern.maxfilesperproc=524288</string>

echo "Ventura - Updating com.startup.sysctl.plist"
sudo cp -f ./Library_LaunchDaemons_com.startup.sysctl.plist /Library/LaunchDaemons/com.startup.sysctl.plist
sudo chown root:wheel /Library/LaunchDaemons/com.startup.sysctl.plist
# validate key-value pairs
plutil /Library/LaunchDaemons/com.startup.sysctl.plist
# load plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.startup.sysctl.plist
# check logs
tail /tmp/sysctl.out
tail /tmp/sysctl.err

echo "Ventura - Updating limit.maxfiles.plist"
sudo cp -f ./limit.maxfiles.plist /Library/LaunchDaemons/limit.maxfiles.plist
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
plutil /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/limit.maxfiles.plist
echo

echo "Limits"
limit

echo "NOTICE; You can Re-enable SIP now!!! (reboot, cmd# + R, csrutil enable)"
sleep 5
