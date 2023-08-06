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

# DISABLING AirDrop; Apple advised Meter, UCLA, and other vendors, networking issues were caused by the “Apple Wireless Direct Link” interface, which helps power features like AirDrop and AirPlay: 
# https://gist.github.com/pythoninthegrass/8073e5e3b24f385c9d9b712f6f243982
echo "DISABLING AirDrop Interface"
sudo ifconfig awdl0 down
echo "TODO - Make AirDrop Interface disable permanent. See; https://github.com/jamestut/awdlkiller"

echo "Installing Powerline fonts"
cd ~
git clone https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd ..
rm -rf fonts

echo "Deleting all local timemachine snapshots"
for d in $(tmutil listlocalsnapshotdates | grep "-"); do sudo tmutil deletelocalsnapshots $d; done

echo "Deleting all local temp Caches"
sudo rm -rf ~/Library/Caches/*

xcode-select --install
sudo xcode-select --reset

echo "Disabling SpotLight"
sudo mdutil -a -i off

echo "Disabling Brew Analytics"
brew analytics off

echo "TODO - Delete any found JAVA (or disable - Java can be disabled in System Preferences)"
echo "TODO - Remove any found Flash Player"

echo "NOTICE; You can Re-enable SIP now!!! (reboot, cmd# + R, csrutil enable)"
sleep 5

echo "Run system profiler with; sudo /usr/sbin/system_profiler"
echo "Clean up syslog and aslmanager etc; sudo rm -rf /var/log/asl/*"
echo "Enable "Displays have separate spaces" in settings, so menubars for applications stay in same window as the Application.."
