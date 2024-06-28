#!/usr/bin/env ksh

echo "From MacOS Catalina 10.15.3, /etc/sysctl.conf values are no longer respected. You need to set sysctls via plists instead (this script does this)"
echo
echo "Updating sysctl values on Ventura is generally not required anymore as Apple have already provided sane defaults to achieve 10Gbps performance"
echo "Make sure you have read the changes in 'Library_LaunchDaemons_com.startup.sysctl.plist'"
echo "In particular make sure you understand 'net.inet.tcp.tso' & 'kern.ipc.nmbclusters' and configure for your use case (info in README.md). These have the most impact."
read -r -p "Are you sure you want to increase sysctl values? [y/n]" iamsure
if [[ "$iamsure" != "y" ]]; then
    exit
fi
echo
read -r -p "Have you disabled SIP? [y/n]" recmode
if [[ "$recmode" != "y" ]]; then
    echo "Disable SIP first (reboot, cmd# + R, 'csrutil disable')"
    echo "Re-enable SIP when done (reboot, cmd# + R, 'csrutil enable') - Only if not using Disable-VenturaBloatware.sh"
    exit
fi

# Needs further testing (requires machine with at least 32 or 64 GB RAM);
#             <string>kern.sysv.shmmax=4194304</string>
#             <string>kern.sysv.shmmin=1</string>
#             <string>kern.sysv.shmmni=32</string>
#             <string>kern.sysv.shmseg=8</string>
#             <string>kern.sysv.shmall=1024</string>

# kern.maxvnodes (old macs default 66560, Ventura default 263168, serverperfmode default 300000)
# kern.maxproc (old macs default 1064, Ventura default 16000, serverperfmode default 5000)
# kern.maxfilesperproc (old macs default 10240, Ventura default 245760, serverperfmode default 150000)
# kern.maxprocperuid (old macs default 709, Ventura default 10666, serverperfmode default 3750)
# kern.ipc.maxsockbuf (old macs default 4194304, Ventura default 8388608, serverperfmode default 8388608)
# kern.ipc.somaxconn (old macs default 128, Ventura default 128, serverperfmode default 1024)
# kern.ipc.nmbclusters (old macs default 32768, Ventura default 262144, serverperfmode default 65536)

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

echo "Current System Limits"
limit

echo "NOTICE; You can Re-enable SIP now if used! (reboot, cmd# + R, csrutil enable)"
