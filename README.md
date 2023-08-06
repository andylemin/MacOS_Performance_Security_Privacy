
#### Collection of scripts to speed up MacOS for software development, BigData and scientific research systems

### `Disable-Ventura-Bloatware.sh`
Credit: Original idea and script (disable.sh) by pwnsdx https://gist.github.com/pwnsdx/d87b034c4c0210b988040ad2f85a68d3 and others

This script disables unwanted Apple services on macOS Ventura (13)\
May still work with older versions macOS Big Sur (11), macOS Monterey (12) - but not tested (older versions use different agents/daemons)\
Running this tool is entirely at your own risk, and no support is provided. Make sure you have backups..\
Your experience may vary, my machine was much faster, CPU usage was lower, and battery lasted longer :) But these should not be your sole goals (Mine is a research machine)

#### Overview
Disabling SIP is still required before running this script (run `csrutil disable` using Terminal in Recovery mode)\
Using this new process you will now also be able to re-enable SIP (Full Security) and even Lockdown-Mode again afterwards (strongly recommended)\
So there is no need to leave SIP disabled or run the script every boot like others. But you will need to run this after every MacOS Software Update (OS updates restore the default SSV disk image and the disabled functions)

In later versions of Ventura from 13.1, disabling SIP is not enough. _Many services (like cloudd etc) still remain active despite being correctly disabled_!\
Apple seem to now consider 'launchctl' service controls as only "requests" rather than "orders"!\
This script gives you back control to demand it disables what you ask (use wisely - all actions can be reversed).

You must disable FileVault disk encryption BEFORE starting, you can re-enable it again afterward (strongly recommended), after the new boot disk snapshot has been created and signed (without unwanted services)\
It is recommended to place this script onto a USB stick, to make it easier to access the script while in the Recovery mode Terminal

Ventura; Service start modifications (via launchctl) are written to `disabled.plist` & `disabled.501.plist` in `/private/var/db/com.apple.xpc.launchd/`\
To revert all launchctl changes, you can delete /private/var/db/com.apple.xpc.launchd/, disabled.plist, disabled.501.plist files, and reboot\
However many services now ignore the launchctl commands! So they also have to be forcefully renamed while in Recovery mode..\
Each of those name changes can be reverted by renaming back (remove .bak) to restore any agents/daemons

#### High Level Process
- Disable SIP, FileVault and Lockdown-Mode,\
- Mount SSV disk image (Signed System Volume),\
- Remount SSV image RW mode,\
- Make changes to disable ande rename unwanted Agents/Daemons,\
- Create new disk snapshot (APFS snapshots are conceptually like OpenZFS block-level snapshots),\
- Mark new custom snapshot 'bootable',\
- Reboot using your new custom base MacOS image :)\
- Repeat after each MacOS software Update

#### Full Procedure
1) Reboot into Recovery mode (Many guides for this, Eg; https://www.lifewire.com/restart-a-mac-into-recovery-mode-5184142)
2) Open 'Terminal' application while in Recovery mode
3) Disable SIP; Run command `csrutil authenticated-root disable`
4) List all disk volumes and identifiers; Run Command `diskutil list`
5) Identify your system disk identifier - (Eg, 'disk3s3' for Volume 'Macintosh HD') in the diskutil output under the "(synthesized)" set
6) Mount the volume; Run Command `diskutil mount disk3s3` (replace 'disk3s3' with your own disk identifier if different)
7) Make the mounted volume writable; Run Command `mount -uw /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' with your own disk volume name if different)
8) Update the `${MYROOTDISK}` variable in the Disable-Ventura-Bloatware.sh script (Line 97), and in the commands below (steps 11, 12), if it is different from (`/Volumes/Macintosh\ HD`)
9) Make the script executable; `chmod 775 ./Disable-Ventura-Bloatware.sh` and execute `./Disable-Ventura-Bloatware.sh` in the Recovery Mode Terminal
10) Check existing snapshots; Run Command `diskutil apfs listSnapshots disk3s3` (change disk and partition to match yours)
11) Create new disk snapshot; Run Command `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -s "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)
12) Tag new snapshot bootable; Run Command `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -r "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)
13) Check all new snapshots; Run Command `diskutil apfs listSnapshots disk3s3` (change disk and partition to match yours) - Should show your new customised SSV Volume is the new MacOS Boot image
14) Reboot in Normal mode (first reboot with new snapshot might take upto 10 minutes)
15) Verify LaunchAgents and Daemons are stopped with command `launchctl list | grep -v "\-\t0"`, and use your system for a while (test everything you use)
16) If some things are not working as desired, you will need to experiment and try restoring Agents and Daemons one by one.\
Restoring functionality can be done by following the process manually in reverse and restoring the plists names;\
Ie, Follow steps 1-8 again, Remove `.bak` extension from .plists names, restore enable launchctl loading.\
When happy, complete steps 10-17 again. And finally update the script for future you..\
Eg to restore agents;
```
mv ${MYROOTDISK}/System/Library/LaunchAgents/<AgentToRestore>.plist.bak ${MYROOTDISK}/System/Library/LaunchAgents/<AgentToRestore>.plist
launchctl enable user/0/${agent}    # Root shell user
launchctl enable gui/501/${agent}   # UI Login User
launchctl enable user/501/${agent}  # Shell Login User
launchctl bootstrap user/0/${agent}    # Root shell user
launchctl bootstrap gui/501/${agent}   # UI Login User
launchctl bootstrap user/501/${agent}  # Shell Login User
launchctl start user/0/${agent}     # Root shell user
launchctl start gui/501/${agent}    # UI Login User
launchctl start user/501/${agent}   # Shell Login User
```
Eg to restore agents;
```
mv ${MYROOTDISK}/System/Library/LaunchDaemons/<DaemonToRestore>.plist.bak ${MYROOTDISK}/System/Library/LaunchDaemons/<DaemonToRestore>.plist
```
17) Once everything you use is working as desired (and the things you don't use are gone), reboot into Recovery mode again
18) Finally, re-enable SIP `csrutil authenticated-root enable`, enable disk Encryption/FileVault, and Lockdown mode as well if desired

#### Notes;
NB; If you are doing this only for improved privacy and security, rather than research stability;\
*Checkout https://www.privacyguides.org for an overview of other areas to investigate.*\
Install an outbound firewall like LittleSnitch (if you are using a script like this, this is highly recommended)\
Disable the awdl0 interface if you dont use Handoff/Continuity features like Universal Control, AirDrop and AirPlay etc (https://github.com/jamestut/awdlkiller)\
Disable your Camera and Microphone if you dont do Video calls\
Replace Spotlight (Spotlight searches sent to Apple). Eg, LaunchBar or Alfred etc\
You should also investigate options for full cookie management/cleanup. Eg, SweetPProduction's Cookie App, and content blockers etc\
Many MacOS packages perform multiple actions, so the following groups are only best effort collections and not guaranteed to be accurate (corrections/improvements welcome)\
This script assumes just one user account exists with UID 501. Check yours with 'id' command. Add extra commands below for any extra UIDs.\
Even if you do not unregister the services/daemons for all user IDs, the script renames the plists so they will be disabled for all users anyway\
You can get detailed information about most Agents/Daemons with;
```
launchctl list
launchctl print gui/$(id -u)/com.foo.http
launchctl print gui/501/com.apple.Safari.History
```

#### Agents not to disable
Removing `com.apple.speech.speechdatainstallerd` `com.apple.speech.speechsynthesisd` `com.apple.speech.synthesisserver` will freeze Edit menus\
Removing `com.apple.bird` will prevent saving prompts from being shown\
`com.apple.imklaunchagent` is not related to iMessage\
Removing `com.apple.WebKit.PluginAgent` can cause video problems in Safari\
`com.apple.nsurlsessiond` invokes and handles network download requests for many applications and services on macOS (inc iOS and tvOS and watchOS) - Use LittleSnitch to control who it talks to instead

-----------------------------------------

### `MacOS_UI_performance.sh`
Applies common MacOS UI performance settings.

### `MacOS_other_settings.sh`
Applies common MacOS general optimisation settings.

### `MacOS_sysctl.sh`
Requires SIP to be disabled. Can re-enable after

Advanced; Deploys custom sysctl plist settings (`Library_LaunchDaemons_com.startup.sysctl.plist`) for local 10Gbps+ networks - useful for local BigData access\
Warning; sysctl `net.inet.tcp.tso` controls the size of packets sent to the NIC\
`net.inet.tcp.tso=1` (Default) Send massive frames to NIC and let NIC break into MTU fragments (impacts Wireshark measurements etc).\
`net.inet.tcp.tso=0` Send MTU sized frames to NIC (network stack controls all CC and retransmissions etc).\
On wireless networks (lossy networks) net.inet.tcp.tso=0 can perform much better and provide lower latency, as the network stack is more intelligent that the NIC. But will be slower on wired.\
On wired lossless networks, you can reliably let the NIC handle splitting frames

Increases max open file descriptors/handles limit to 524288 (`limit.maxfiles.plist`)

Adds powerline fonts (See https://ohmyz.sh/)

Deletes local timemachine snapshots (does not break real time machine backups), and local caches

Warning; Disables Spotlight (make sure you have alternative like Alfred)
