
#### Collection of scripts to speed up MacOS for software development, BigData and scientific research systems

### `Disable-Ventura-Bloatware.sh`
Credit: Original idea and script (Disable bunch of #$!@) by pwnsdx https://gist.github.com/pwnsdx/d87b034c4c0210b988040ad2f85a68d3 and others

This script disables unwanted Apple services on macOS Ventura (13).\
May work with older versions macOS (11, 12) - but not tested (older versions use different agents/daemons).

Running this tool is at your own risk, and no support is provided. Make sure you have backups..\
Never run scripts from the internet without reading the code, and understanding what they are doing.\
Your experience may vary, my machine was much faster, CPU usage was lower, and battery lasted longer :) But at cost of less/unwanted functionality (Mine is a research machine and I want consistent performance between tests - Ie, no unsolicited processes randomly using my resources affecting test results)

#### Overview
Disabling normal mode SIP is not enough, you need to disable Authenticated Root SIP (run `csrutil authenticated-root disable` using Terminal in Recovery mode).\
Using this new process - _you will be able to re-enable SIP (Full Security) and even Lockdown-Mode again after disabling unwanted services_ (strongly recommended).\
But you will need to run this after every MacOS Software Update (OS updates restore the default SSV disk image and the disabled functions).

In versions of Ventura > 13.1 many services remain active despite being correctly disabled with `launchctl`.\
Apple seem to now consider `launchctl` service controls as only "optional requests"!\
This script gives you back control to force it to disable what you ask (use wisely - all actions can be reversed).

You must disable FileVault disk encryption, and Lockdown-Mode, BEFORE starting. You can re-enable them again after the new boot disk snapshot has been created (without unwanted services).\
Copy this script onto a USB stick, to make it easier to access the script while in the Recovery mode Terminal.

Ventura; Service start modifications (via launchctl) are written to `disabled.plist` & `disabled.501.plist` in `/private/var/db/com.apple.xpc.launchd/`\
To revert all launchctl changes, you can delete /private/var/db/com.apple.xpc.launchd/, disabled.plist, disabled.501.plist files, and reboot.
However as many services now ignore the launchctl commands anyway, they also have to be forcefully renamed while in Recovery mode..\
Each of these name changes can be reverted (remove .bak extension) to restore any agents/daemons

#### High Level Process
- Disable FileVault and Lockdown-Mode
- Reboot into Recovery mode, Disable Authenticated Root SIP
- Mount SSV disk image (Signed System Volume),
- Remount SSV image RW mode,
- Make changes to disable and rename unwanted Agents/Daemons,
- Create new disk snapshot (APFS snapshots are conceptually like OpenZFS block-level snapshots),
- Mark new custom snapshot 'bootable',
- Reboot using your new custom base MacOS image :)
- Run after MacOS software Updates (use `launchctl list | grep -v "\-\t0"` to check if required)

#### Full Procedure
0) Take note of Agents and Daemons currently running; `launchctl list | grep -v "\-\t0"`
1) Reboot in Recovery mode (Eg; https://www.lifewire.com/restart-a-mac-into-recovery-mode-5184142)
2) Open 'Terminal' application in Recovery mode
3) Disable SIP; `csrutil authenticated-root disable`
4) List all disk volumes and identifiers; `diskutil list`
5) Identify your system disk identifier - (Eg, 'disk3s3' for Volume 'Macintosh HD') in the diskutil output under the '(synthesized)' set
6) Mount volume; `diskutil mount disk3s3` (replace 'disk3s3' with your own disk identifier if different)
7) Make writable; `mount -uw /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' with your disk volume name)
8) Update `${MYROOTDISK}` variable in the `Disable-Ventura-Bloatware.sh` script (~Line 59), and in the commands below (steps 11, 12), if different from (`/Volumes/Macintosh\ HD`)
9) Make script executable; `chmod 775 ./Disable-Ventura-Bloatware.sh` and execute `./Disable-Ventura-Bloatware.sh` (in Recovery Mode Terminal)
10) Check existing snapshots; `diskutil apfs listSnapshots disk3s3` (change disk and partition to yours)
11) Create new disk snapshot; `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -s "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)
12) Tag new snapshot bootable; `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -r "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)
13) Check snapshots; `diskutil apfs listSnapshots disk3s3` (change disk and partition to yours) - Should show your new customised SSV Volume is the new MacOS Boot image
14) Reboot in Normal mode (first reboot with new snapshot might take upto 10 minutes)
15) Verify LaunchAgents and Daemons are now stopped; `launchctl list | grep -v "\-\t0"`
16) Open MacOS Log Console (`open -a Console`), and use your system for a while (test everything you normally use).
Perform common activities to exercise all needed features, and watch for issues in Console.
If things are not working as desired, you will need to experiment and try restoring Agents and Daemons one by one.
You can also try deleting any related app/user plist files from `~/Library/Preferences/` and rebooting, to restore an Apps defaults settings. (Eg, `rm ~/Library/Preferences/com.apple.AppStore.plist`)

Restoring functionality; follow steps 1,6,7 again, removing `.bak` extension from wanted .plists, restore launchctl loading if Agent, follow steps 11-14 (Increment 'CustomX') to commit the restored plists.
Eg to restore Agents;
```
Steps 1,6,7
mv ${MYROOTDISK}/System/Library/LaunchAgents/<AgentToRestore>.plist.bak ${MYROOTDISK}/System/Library/LaunchAgents/<AgentToRestore>.plist
launchctl enable user/0/<AgentToRestore>    # Root shell user
launchctl enable gui/501/<AgentToRestore>   # UI Login User
launchctl enable user/501/<AgentToRestore>  # Shell Login User
launchctl bootstrap user/0/<AgentToRestore>    # Root shell user
launchctl bootstrap gui/501/<AgentToRestore>   # UI Login User
launchctl bootstrap user/501/<AgentToRestore>  # Shell Login User
launchctl start user/0/<AgentToRestore>     # Root shell user
launchctl start gui/501/<AgentToRestore>    # UI Login User
launchctl start user/501/<AgentToRestore>   # Shell Login User
Steps 11-14 (Using Custom2 etc)
```
Eg to restore Daemons;
```
Steps 1,6,7
mv ${MYROOTDISK}/System/Library/LaunchDaemons/<DaemonToRestore>.plist.bak ${MYROOTDISK}/System/Library/LaunchDaemons/<DaemonToRestore>.plist
Steps 11-14 (Using Custom2 etc)
```
When happy, update the script with your personal changes (for future you), and share fixes for others here..\
17) Once everything is working as desired (and the things you don't use are gone), reboot into Recovery mode again
18) Re-enable SIP `csrutil authenticated-root enable`. Reboot and re-enable disk Encryption/FileVault, and Lockdown mode (if used)

#### Notes/Known Issues;
The script disables Spotlight by default, so make sure you have an alternative Eg, LaunchBar or Alfred etc (or don't disable Spotlight).\
Known issue; Bluetooth is currently broken by default (even though 'com.apple.bluetoothuserd' has been excluded) - TO FIX

APFS Snapshots do NOT create copies of the images, they are byte deltas from the base SSV image. So you can have hundreds, they occupy negligible space and have no detectable performance impact. And there is no need to delete them (you roll them back).\
Many MacOS packages perform multiple actions, so the service groups are only best effort and not guaranteed to be accurate (corrections/improvements welcome).\
This script assumes one user account exists with UID 501. Check yours with `id` command.\
Even if you do not unregister the services/daemons for all user IDs the script renames the plists, so they will be disabled for all users anyway.\
You can get some more information about most Agents/Daemons with;
```
launchctl list
launchctl print gui/$(id -u)/com.foo.http
launchctl print gui/501/com.apple.Safari.History
```

#### Agents not to disable
Disabling `com.apple.speech.speechdatainstallerd` `com.apple.speech.speechsynthesisd` `com.apple.speech.synthesisserver` will freeze Edit menus.\
Disabling `com.apple.bird` will prevent saving prompts from being shown.\
`com.apple.imklaunchagent` is not related to iMessage.\
Disabling `com.apple.WebKit.PluginAgent` can cause video problems in Safari.\
`com.apple.nsurlsessiond` invokes and handles network download requests for many applications and services on macOS (inc iOS and tvOS and watchOS) - Use LittleSnitch to control who it talks to instead.
Disabling Daemon `com.apple.airportd` breaks Wi-Fi connectivity

#### Privacy and Security;
If you are doing this for improved privacy and security, rather than consistency/stability;\
*Checkout https://www.privacyguides.org for an overview of other areas to investigate.*\
Maybe install an outbound firewall like LittleSnitch.
Disable the awdl0 interface if you don't use Handoff/Continuity features like Universal Control, AirDrop and AirPlay etc (https://github.com/jamestut/awdlkiller).
You can also investigate options for full cookie management/cleanup (Eg, SweetPProduction's Cookie App, and web content blockers etc).

-----------------------------------------

### `MacOS_UI_performance.sh`
Applies common MacOS UI performance settings.
Significantly increases keyboard speed. Safe for most use cases.

### `MacOS_other_settings.sh`
Applies common MacOS general optimisation settings.\
Adds powerline fonts (See https://ohmyz.sh/).\
Adds Apple X-Code runtime libraries.\
Deletes local timemachine snapshots (does not impact external disk time machine backups), and local caches\
Deletes local temp caches and application logs\
Warning; Disables Spotlight (make sure you have alternative like Alfred).\
Warning; Disables awdl0 interface (Handoff/Continuity/AirDrop/AirPlay etc).

### `MacOS_sysctl.sh`
('/etc/sysctl.conf' is ignored since MacOS 10.9)\
Seems to sometimes require normal mode SIP (`csrutil disable`) to be disabled (re-enable SIP afterward with `csrutil enable`)

NB; The default MacOS network settings are good for the significant majority of use cases. Networking in Ventura has been significantly improved. Only apply if you understand all the options - customise as needed

Deploys custom sysctl plist settings (`Library_LaunchDaemons_com.startup.sysctl.plist`) for local wired 10Gbps+ networks - useful for local BigData access\
Warning; sysctl `net.inet.tcp.tso` controls the size of packets sent to the NIC.\
`net.inet.tcp.tso=1` (Default) Send massive frames to NIC and let NIC break into MTU fragments (impacts Wireshark measurements etc).\
`net.inet.tcp.tso=0` Send MTU sized frames to NIC (network stack controls all Congestion Control and Retransmissions etc).\
On wireless networks (any lossy network) net.inet.tcp.tso=0 can perform much better and provide lower latency, as the network stack is more intelligent that the NIC. But will be slower on wired.\
On wired networks (lossless network), you can reliably let the NIC handle splitting frames.

Increases max open file descriptors/handles limit to 524288 (`limit.maxfiles.plist`)
