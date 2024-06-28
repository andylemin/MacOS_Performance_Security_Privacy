
#### Collection of scripts to speed up MacOS for software development, Network protocol performance testing, and scientific research systems

### `Disable-Ventura-Bloatware.sh`
Credit: Original process disable script (Disable bunch of #$!@) by pwnsdx https://gist.github.com/pwnsdx/d87b034c4c0210b988040ad2f85a68d3 and others

This process disables unwanted Apple services on macOS Ventura (13) to improve performance and stability - Make it more Unix-like again..\
Required experience level; Advanced users (only tested on Apple M2 so far).\
It may work with older versions macOS (11, 12) - but not tested (older versions also use different agents/daemons).

Running this tool is at your own risk, and no support is provided. Make sure you have backups.. Never run scripts from the internet without reading the code, and understanding what they are doing.\
Your experience may vary, my machine was much faster, CPU usage was lower, and battery lasted longer :D But at the cost of less/unwanted functionality (Mine is a research machine and I need consistent performance - Ie, no unsolicited junk processes randomly using resources and affecting test results)

#### Overview

##### Security
You only need to disable Authenticated Root SIP, you don't need to disable all of SIP.\
Ie, run `csrutil authenticated-root disable` using Terminal in Recovery mode to disable.
and run `csrutil authenticated-root status` using Terminal to confirm.

There are multiple levels to SIP, these have been condensed in Ventura. See `csrutil` (https://khronokernel.github.io/macos/2022/12/09/SIP.html).

NB; You will NOT be able to re-enable Authenticated Root SIP afterward, as this process creates a new APFS snapshot on
the MacOS boot disk (after disabling unwanted stuff), and it is not possible to sign/seal this user-made custom snapshot without Apple's secret keys.\
'Authenticated Root SIP' (SSV - Signed System Volume) means MacOS will only boot from an official signed & sealed OS snapshot.
NB; This is the same setting used to allow booting other operating systems on your Mac hardware..\
Sadly this also means you will also NOT be able to use FileVault (Apple provide a very poor justification for why you cannot 
enable FileVault security without their signed SSV - they basically want to force/coerce you to only use their spam/junk-filled OS by taking away features).\
However, do not worry, and read on..

SSV and FileVault; In the past you could encrypt your entire disk with Full Disk Encryption to provide
'Integrity', 'Privacy' and 'Confidentiality' of the entire system.
(which was great and actually secure - maybe too secure for three letter agencies).
Apple did not like this.. Instead, they decided to create SSV, which ONLY provides 'Integrity' - So anyone can view but
not change OS data (https://support.apple.com/guide/security/signed-system-volume-security-secd698747c9/web) (Integrity-only).\
SSV achieves this by hashing your data in a chain, such that changing any single byte, will invalidate every subsequent
byte in the chain below it (https://developer.apple.com/news/?id=3xpv8r2m) - similar to blockchains.

SSV provides NO Privacy or Confidentiality. Apple's reasoning is that no user data exists on the OS partition, and
FileVault is used to encrypt the user partition.
Hence, the 'Macintosh HD' OS partition (SSV) and the recent introduction of the 'Macintosh HD - Data' user partition (FileVault) for user data.

WARNING; With the official Apple setup (SSV, SIP & FileVault enabled) anyone with physical access can create a new admin
user using recovery mode (or the default 'root' account), and admin users can decrypt the whole 'Macintosh HD - Data'
partition (all user accounts are on the same single partition), and easily access other user's home folders -
so the default install of MacOS Ventura with SSV, SIP & FileVault may be impressive in terms of the modern encryption,
but there are so many back doors you don't actually need to break the encryption..! The attack surface of this design is just too large..\
NB; You can change the password on the default hidden 'root' account with 'sudo passwd root'.

Further enabling FileVault does not actually encrypt data on the disk anymore. Data on disk is _always_ encrypted on Apple Silicon
Macs using hardware keys specific to your Mac (so you cannot remove the SSD and read it in another machine).
"Enabling FileVault" simply adds a user key to the hardware key. This is why enabling FileVault is now instant, and why
other users can also decrypt the 'Macintosh HD - Data' user partition
(https://support.apple.com/guide/security/volume-encryption-with-filevault-sec4c6dc1b6e/web).

An advanced individual/organisation with physical access to the drive, can still remove the controller from the SSD,
and have full access to the data (not confirmed if still true since Apple Silicon).
Eg, examples of attacks on this type of "Encryption" https://www.ieee-security.org/TC/SP2019/papers/310.pdf

This guide is intended for increasing system performance, stability and reducing latency/process jitter by removing
junk/bloat unneeded by professionals. It is not primarily focused on security.
However, as part of the process, because we are disabling SSV to create a modified boot image with all the Apple bloatware disabled,
there are some things we need to do afterward to secure the system - which can actually be more secure and reduce the attack
surface of a default Ventura install, even if someone gains physical access to the machine! :) \

After we have created the custom boot image with only the processes we want, we can create a dedicated per-user encrypted
volume/partition (there is an inconvenience with this discussed later), move the entire users' home folder and all user
data onto this per-user volume, and finally set a hardware firmware password (Intel only) so the system will not boot from
anything other than your custom image.\
NB; For Apple Silicon macs, the process of disabling Authenticated Root SIP, automatically enables password access for
Recovery Mode (closing a back door, and increasing security) - this is roughly equivalent to the firmware password.\
Ie, An attacker will not be able to access recovery mode to create admin accounts (I hope you changed the 'root' password),
and will not be able to remove the SSD to run in another machine, and will not be able to log in to any existing accounts
(unless they have your passwords), and most importantly will not be able to decrypt your dedicated user volume even if
they did access another admin account - much more secure.

Further reading; https://github.com/drduh/macOS-Security-and-Privacy-Guide

##### Launch Control
In Ventura many services remain active even when correctly disabled with `launchctl` commands.
Apple seem to now consider `launchctl` service controls as only "optional requests"! (I have not investigated what
this means for MDM policy managed machines, I would assume they respect MDM controls else they would lose their enterprise customers).

This script gives you back control to force MacOS to disable what you want (use wisely, start small and test, disabling more as you go - all actions can be reversed).

NB; You must disable FileVault, and Lockdown-Mode, BEFORE starting (you can create and encrypt a new dedicated user partition later).\
Copy this script onto a USB stick to make it easier to access the script while in the Recovery mode Terminal.

Ventura; Service start modifications (via launchctl) are written to files `disabled.plist` & `disabled.501.plist` in `/private/var/db/com.apple.xpc.launchd/`.

To revert all launchctl service changes, you can simply delete the `disabled.plist` & `disabled.501.plist` files, and reboot.
However, as many services now ignore the launchctl commands anyway, they also have to be forcefully renamed (what this script does) while in Recovery mode..\
Each of these name changes can be reverted (remove .bak extension) to restore any agents/daemons.

#### High Level Process
- Disable FileVault and Lockdown-Mode
- Reboot into Recovery mode, Disable Authenticated Root SIP
- Mount SSV disk image (Signed System Volume),
- Remount SSV image RW mode,
- Make changes to disable and rename unwanted Agents/Daemons (run `Disable-Ventura-Bloatware.sh`),
- Create new disk snapshot (APFS snapshots are conceptually like OpenZFS block-level snapshots),
- Mark new custom snapshot 'bootable',
- Reboot using your new custom base MacOS image :)
- Validate processes are stopped (use `launchctl list | grep -v "\-\t0"`)
- Create a new Encrypted, Case-sensitive volume for each admin user (each user can have their own password, mitigating local admin attacks).
- Move the user's "home" to the Encrypted partition
- Set a Hardware Firmware password (Intel machines only)

#### Full Procedure
0) Take note of Agents and Daemons currently running; `launchctl list | grep -v "\-\t0" > ~/before-disable.txt`
1) Reboot in Recovery mode (Eg; https://www.lifewire.com/restart-a-mac-into-recovery-mode-5184142)
2) Open 'Terminal' application in Recovery mode
3) Disable SIP; `csrutil authenticated-root disable`
4) List all disk volumes and identifiers; `diskutil list`
5) Identify your system disk identifier and partition/slice for the OS - (Eg, 'disk3s3' for Volume 'Macintosh HD') in the diskutil output under the '(synthesized)' set (The one without '- Data')
6) Mount volume; `diskutil mount disk3s3` (replace 'disk3s3' with your own disk identifier if different)
7) Make writable; `mount -uw /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' with your disk volume name)
8) Update `${MYROOTDISK}` variable in the `Disable-Ventura-Bloatware.sh` script (~Line 32) if you are not using 'Macintosh HD'
9) Make script executable; `chmod 775 ./Disable-Ventura-Bloatware.sh` and execute `./Disable-Ventura-Bloatware.sh` (in Recovery Mode Terminal)
10) Check existing snapshots; `diskutil apfs listSnapshots disk3s3` (change disk and partition to yours)
11) Create new disk snapshot; `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -s "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)
12) Tag new snapshot bootable; `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -r "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)\
**OR 11 & 12** single command) `bless --mount /Volumes/Macintosh\ HD --bootefi --create-snapshot` (I have not confirmed if there is any difference between this command and 11+12 - They both seem to work the same so far)
13) Check snapshots; `diskutil apfs listSnapshots disk3s3` (change disk and partition to yours) - Should show your new customised SSV Volume is the new MacOS Boot image
14) Reboot in Normal mode (first reboot with new snapshot might take upto 10 minutes)
15) Verify LaunchAgents and Daemons are now stopped; `launchctl list | grep -v "\-\t0" > ~/after-disable.txt`\
`cat ./before-disable.txt| wc -l`, `cat ./after-disable.txt| wc -l`\
`cat ./before-disable.txt | tr -d 0-9 | tr -d "[:blank:]" | sort > ~/before-disable-clean.txt`\
`cat ./after-disable.txt | tr -d 0-9 | tr -d "[:blank:]" | sort > ~/after-disable-clean.txt`\
`diff ~/before-disable-clean.txt ~/after-disable-clean.txt` <- This should make you happy ;)
16) Open MacOS Log Console (`open -a Console`), and use your system for a while (test everything you normally use).
Perform common activities to exercise all needed features, and watch for issues in Console. If things are not working as desired (maybe you wanted Remote Desktop sharing), you will need to experiment and try restoring Agents and Daemons one by one using the steps below.\
You can also try deleting any related app/user plist files from `~/Library/Preferences/` and rebooting, to restore an App's defaults settings. (Eg, `rm ~/Library/Preferences/com.apple.AppStore.plist`)

Restoring functionality; follow steps 1,6,7 again, removing `.bak` extension from individual .plists, restore launchctl loading if Agent, and follow steps 11-14 again (Increment 'CustomX') to commit the restored plists.
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

##### Post customisation changes (Secure your system)
17) Once everything is working as desired (and the things you don't use are gone), reboot into Recovery mode again, and set a 'Firmware password' (Intel Macs only). Apple Silicon Macs already ask for your password to access Recovery mode / change boot disk. Reboot back into main OS.
* WARNING; Before the next steps, make sure you have created a secondary admin account (required for this to work)
19) Create per-User secure volume; Open Disk Utility (Ensure View -> 'Show All Devices' is enabled), Select 'Macintosh HD' (under Container disk), right-click 'Add APFS Volume', Select APFS (Case-senstiive, Encrypted). Mount the new volume.
NB; If you really need _true_ security of your home disk at rest, you will need to investigate tools like OpenZFS/VeraCrypt which encrypt volume data before being sent to the SSD hardware (userland encryption rather than hardware encryption).
20) Setup per-User secure volume; Create a folder in your new volume, and restrict the permissions; Eg `mkdir /Volumes/<Per-User Volume name>/<username> && chmod 700 /Volumes/<Per-User Volume name>/<username>`.
* NOTE There is a current limitation; now you have created a dedicated per-User encrypted volume(s), when you boot your machine the volume(s) with your home folder(s) will be locked/encrypted (so login will fail), and they will NOT automatically unlock (which can be a good thing, but a small problem as well). 
* You will need to login to another secondary account (with the Home folder unchanged), just to unlock the per-user volume first. You can then log out, and log in as your intended target user, now its home is unlocked and mounted.
TODO - Write optional launchctl script to prompt user for unlock password at user login, so no temporary account login is required to pre-unlock the per-user volume.
21) Move user home mount point (*read all steps first*); Open 'System Settings', 'Users & Groups' (wait around 5 minutes while the now disabled iCloud stuff times out - Apple/iCloud really wants to know about your accounts), Ctrl+click on user, click 'Advanced options', change Home directory to `/Volumes/<Volume_name>/<username>`\
OR, if you don't want to wait 5 minutes..\
Move user mount point; `dscl . -change /Users/<username> NFSHomeDirectory /Users/<username> /Volumes/<Per-User Volume name>/<username>`
22) reboot, login with temporary user/admin account (with unchanged home directory), mount the per-User volume for the target user, logout (not reboot), and login as your target user.

Congratulations, this process is getting harder with each release of MacOS. But you now have a fully customised, de-junked MacOS, which is also secure at rest. This is the closest I have got Ventura to being Unix-like again..

This has been tested on Intel Macbook Pro, M2 Macbook Pro, and Hackintosh (all Ventura)

#### Rollback Procedure
Rollback to the original Apple MacOS Signed/sealed snapshot; `bless --mount / --last-sealed-snapshot`

#### Notes/Known Issues;
The script disables Spotlight by default, so make sure you have an alternative Eg, LaunchBar or Alfred etc (or don't disable Spotlight).\
The 'Users & Groups' section in 'System Settings' appears not to work! It does.. You just have to click 'Users & Groups' and wait around 5 minutes, then it will eventually appear.. User management is tied into iCloud, and you have to wait for a timeout now we have disabled all the Cloud stuff. Or Manage your users with the Terminal :)

APFS Snapshots do NOT create copies of the images, they are byte deltas from the base SSV image. So you can have hundreds, they occupy negligible space and have no detectable performance impact. And there is no need to delete them (you roll them back).\
Many MacOS packages perform multiple actions, so the groups in the script are only best effort and not guaranteed to be accurate (corrections/improvements welcome).\
This script assumes one user account exists with UID 501. Check yours with `id` command.\
Even if you do not unregister the services/daemons for all user IDs the script renames the plists, so they will be disabled for all users anyway - but you may have errors in Console logs.\
You can get more information about most Agents/Daemons with;
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

NB; The default MacOS network settings are good for the significant majority of use cases.
Networking in Ventura has been significantly improved. Only apply this script you understand all the options - customise as needed first

Deploys custom sysctl plist settings (`Library_LaunchDaemons_com.startup.sysctl.plist`) for local wired 10Gbps+ networks - useful for local BigData access\

TSO) sysctl `net.inet.tcp.tso` controls the size of packets sent to the NIC.\
`net.inet.tcp.tso=1` (Default) Send massive frames to NIC and let NIC break into MTU fragments (impacts Wireshark measurements etc).\
`net.inet.tcp.tso=0` Send MTU sized frames to NIC (network stack controls all Congestion Control and Retransmissions etc).\
On wireless networks (any lossy network) net.inet.tcp.tso=0 can perform much better and provide lower latency, as the network stack is more intelligent that the NIC. But will be slower on wired.\
On wired networks (lossless network), you can reliably let the NIC handle splitting frames.

Clusters) sysctl `kern.ipc.nmbclusters` controls the size/number of buffers available for networking.\
Increasing this value can significantly improve performance, but increases memory usage. Try 262144 first and increase conservatively.
Many guides on the internet suggest to increase this to very large numbers, this is wrong. 262144 will provide 10Gbps easily.

Delayed ACK) sysctl `net.inet.tcp.delayed_ack` controls how ACKs are sent.\
http://www.stuartcheshire.org/papers/NagleDelayedAck/ \
`delayed_ack=0` Responds after every packet (OFF)\
`delayed_ack=1` Always employs delayed_ack; 6 packets can get 1 ack\
`delayed_ack=2` Immediate ack after 2nd packet; 2 packets per ack (Compatibility Mode)\
`delayed_ack=3` (Default) Should auto-detect when to employ delayed ack; 3 packets per ack\

Delayed ACKs have a similar challenge to TSO (what is good for 10Gbps wired is bad for Wifi and Internet).
Wifi is a half duplex medium, so every ACK has to wait for an air-time slot. This slot could have been used for sending
data instead. Therefore, on wireless network delayed_ack=1 or 3 is preferred (we want to avoid interupting the data stream).\
For high speed wired networks however, this ACK delay can restrict upper performance, and so delayed_ack=0 or 2 is preferred.

I have not been able to confirm if 3 (auto) is able to apply the correct ACK delay mode depending on the network interface being used. It would be great if it could.
