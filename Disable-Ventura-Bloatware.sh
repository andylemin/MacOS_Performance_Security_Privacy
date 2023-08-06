#!/bin/sh
# Credit: Original idea and script (disable.sh) by pwnsdx https://gist.github.com/pwnsdx/d87b034c4c0210b988040ad2f85a68d3 and others

# This script disables unwanted Apple services on macOS Ventura (13)
# May still work with older versions macOS Big Sur (11), macOS Monterey (12) - but not tested (older versions use different agents/daemons)
# Running this tool is entirely at your own risk, and no support is provided. Make sure you have backups..
# Your experience may vary, my machine was much faster, CPU usage was lower, internet was faster, and battery lasted longer :) (A research machine) But these should not be your sole goals

## Requirements;
# Disabling SIP is still required before running this script (run `csrutil disable` using Terminal in Recovery mode)
# In later versions of Ventura from 13.1, disabling SIP is not enough. _Many services (like cloudd etc) still remain active despite being correctly disabled_!
# Apple seem to now consider 'launchctl' service controls as only "requests" rather than "orders"!
# This script gives you back control to demand it disables what you ask (use wisely - all actions can be reversed).

# NB; Using this new process you will also be able to re-enable SIP (Full Security) and even Lockdown-Mode again afterwards (strongly recommended)
# There is no need to leave SIP disabled or run the script every boot like others. But you will need to run this after every MacOS Software Update (OS updates restore the disabled functions)
# You must disable FileVault disk encryption BEFORE starting, you can re-enable it again afterwards (strongly recommended), after the new boot disk snapshot has been created and signed (without unwanted services)
# It is recommended to place this script onto a USB stick, to make it easier to access the script while in the Recovery mode Terminal

# Ventura; Service start modifications (via launchctl) are written to /private/var/db/com.apple.xpc.launchd/, disabled.plist & disabled.501.plist
# To revert all launchctl changes, you can delete /private/var/db/com.apple.xpc.launchd/, disabled.plist, disabled.501.plist files, and reboot
# However many services now ignore the launchctl commands! So they also have to be forcefully renamed while in Recovery mode..
# Each of those name changes can be reverted by renaming back (remove .bak) to restore any agents/daemons

## High Level Overview; After Disabling SIP, FileVault and Lockdown-Mode
# Mount SSV disk image (Signed System Volume),
# Remount SSV image RW mode,
# Make changes to disable ande rename unwanted Agents/Daemons,
# Create new disk snapshot (APFS snapshots are conceptually like OpenZFS block-level snapshots),
# Mark new custom snapshot 'bootable',
# Reboot using your new custom base MacOS image :)
# Repeat after each MacOS software Update

## Full Procedure;
#1) Reboot into Recovery mode (Many guides for this, Eg; https://www.lifewire.com/restart-a-mac-into-recovery-mode-5184142)
#2) Open 'Terminal' application while in Recovery mode
#3) Disable SIP; Run command `csrutil authenticated-root disable`
#4) List all disk volumes and identifiers; Run Command `diskutil list`
#5) Identify your system disk identifier - (Eg, 'disk3s3' for Volume 'Macintosh HD') in the diskutil output under the "(synthesized)" set
#6) Mount the volume; Run Command `diskutil mount disk3s3` (replace 'disk3s3' with your own disk identifier if different)
#7) Make the mounted volume writable; Run Command `mount -uw /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' with your own disk volume name if different)
#8) Update the `${MYROOTDISK}` variable in the Disable-Ventura-Bloatware.sh script (Line 97), and in the commands below (steps 11, 12), if it is different from (`/Volumes/Macintosh\ HD`)
#9) Make the script executable; `chmod 775 ./Disable-Ventura-Bloatware.sh` and execute `./Disable-Ventura-Bloatware.sh` in the Recovery Mode Terminal
#10) Check existing snapshots; Run Command `diskutil apfs listSnapshots disk3s3` (change disk and partition to match yours)
#11) Create new disk snapshot; Run Command `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -s "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)
#12) Tag new snapshot bootable; Run Command `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -r "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)
#13) Check all new snapshots; Run Command `diskutil apfs listSnapshots disk3s3` (change disk and partition to match yours) - Should show your new customised SSV Volume is the new MacOS Boot image
#14) Reboot in Normal mode (first reboot with new snapshot might take upto 10 minutes)
#15) Verify LaunchAgents and Daemons are stopped with command `launchctl list | grep -v "\-\t0"`, and use your system for a while (test everything you use)
#16) If some things are not working as desired, you will need to experiment and try restoring Agents and Daemons one by one.\
#Restoring functionality can be done by following the process manually in reverse and restoring the plists names;\
#Ie, Follow steps 1-8 again, Remove `.bak` extension from .plists names, restore enable launchctl loading.\
#When happy, complete steps 10-17 again. And finally update the script for future you..\
#Eg to restore agents;
#```
#mv ${MYROOTDISK}/System/Library/LaunchAgents/<AgentToRestore>.plist.bak ${MYROOTDISK}/System/Library/LaunchAgents/<AgentToRestore>.plist
#launchctl enable user/0/${agent}    # Root shell user
#launchctl enable gui/501/${agent}   # UI Login User
#launchctl enable user/501/${agent}  # Shell Login User
#launchctl bootstrap user/0/${agent}    # Root shell user
#launchctl bootstrap gui/501/${agent}   # UI Login User
#launchctl bootstrap user/501/${agent}  # Shell Login User
#launchctl start user/0/${agent}     # Root shell user
#launchctl start gui/501/${agent}    # UI Login User
#launchctl start user/501/${agent}   # Shell Login User
#```
#Eg to restore agents;
#```
#mv ${MYROOTDISK}/System/Library/LaunchDaemons/<DaemonToRestore>.plist.bak ${MYROOTDISK}/System/Library/LaunchDaemons/<DaemonToRestore>.plist
#```
#17) Once everything you use is working as desired (and the things you don't use are gone), reboot into Recovery mode again
#18) Finally re-enable SIP `csrutil authenticated-root enable`, enable disk Encryption/FileVault, and Lockdown mode as well if desired

## Notes;
# NB; If you are doing this for improved privacy and security;
# Checkout https://www.privacyguides.org for an overview of other areas to investigate.
# Install an outbound firewall like LittleSnitch (if you are using a script like this, this is highly recommended)
# Disable the awdl0 interface if you dont use Handoff/Continuity features like Universal Control, AirDrop and AirPlay etc (https://github.com/jamestut/awdlkiller)
# Disable your Camera and Microphone if you dont do Video calls
# Replace Spotlight (Spotlight searches sent to Apple). Eg, LaunchBar or Alfred etc
# You should also investigate options for full cookie management/cleanup. Eg, SweetPProduction's Cookie App, and content blockers etc
# Many MacOS packages perform multiple actions, so the following groups are only best effort collections and not guaranteed to be accurate (corrections/improvements welcome)
# This script assumes just one user account exists with UID 501. Check yours with 'id' command. Add extra commands below for any extra UIDs.
# Even if you do not unregister the services/daemons for all user IDs, the script renames the plists so they will be disabled for all users anyway
# You can get detailed information about most Agents/Daemons with;\
# 'launchctl print gui/$(id -u)/com.foo.http'
# 'launchctl print gui/501/com.apple.Safari.History'
# And many other references including; https://gist.github.com/dmattera/883a4457b67534df795cdd0fa1651a26

# Agents not to disable
# Removing 'com.apple.speech.speechdatainstallerd' 'com.apple.speech.speechsynthesisd' 'com.apple.speech.synthesisserver' will freeze Edit menus
# Removing 'com.apple.bird' will prevent saving prompts from being shown
# 'com.apple.imklaunchagent' is not related to iMessage
# Removing 'com.apple.WebKit.PluginAgent' can cause video problems in Safari
# 'com.apple.nsurlsessiond' invokes and handles network download requests for many applications and services on macOS (inc iOS and tvOS and watchOS) - Use LittleSnitch to control who it talks to

MYROOTDISK="/Volumes/Macintosh HD"

read -p "Please confirm; Running in Recovery mode? [y/n]" recmode
if [[ "$recmode" != "y" ]]; then
    echo "This script must be run from within Recovery mode!"
    echo
    exit
fi

# TODO What about the other folders;
#  Currently supports; /System/Library/LaunchAgents, /System/Library/LaunchDaemons
#  ~/Library/LaunchAgents, /Library/LaunchAgents, /Library/LaunchDaemons
#  https://gist.github.com/dmattera/883a4457b67534df795cdd0fa1651a26

# Launch Agents
LA_BLUETOOTH=('com.apple.bluetoothuserd')

LA_QUICKLOOK=('com.apple.quicklook' \
'com.apple.quicklook.ui.helper' \
'com.apple.quicklook.ThumbnailsAgent')

LA_TIMEMACHINE=('com.apple.TMHelperAgent')

LA_CLOUD=('com.apple.icloud.fmfd' \
'com.apple.iCloudNotificationAgent' \
'com.apple.iCloudUserNotifications' \
'com.apple.icloud.searchpartyuseragent' \
'com.apple.icloud.findmydeviced.findmydevice-user-agent' \
'com.apple.cloudd' \
'com.apple.cloudpaird' \
'com.apple.cloudphotod' \
#'com.apple.CloudPhotosConfiguration' \  # No longer in Ventura
'com.apple.CloudSettingsSyncAgent' \
'com.apple.dataaccess.dataaccessd' \
'com.apple.itunescloudd' \
#'com.apple.ManagedClient.cloudconfigurationd' \  # No longer in Ventura
'com.apple.syncdefaultsd' \
'com.apple.followupd' \
'com.apple.amsengagementd' \
'com.apple.sociallayerd' \
'com.apple.protectedcloudstorage.protectedcloudkeysyncing' \
#'com.apple.BTServer.cloudpairing' \  # No longer in Ventura
'com.apple.security.cloudkeychainproxy3')

LA_MDM=('com.apple.ManagedClientAgent.enrollagent' \
'com.apple.ManagedClientAgent.agent')

LA_ADVERTISING=('com.apple.ap.adprivacyd' \
#'com.apple.ap.adservicesd' \  # No longer in Ventura
'com.apple.ap.promotedcontentd')

LA_CONTACTSANDCALENDAR=('com.apple.contactsd' \
'com.apple.AddressBook.AssistantService' \
'com.apple.AddressBook.SourceSync' \
'com.apple.AddressBook.abd' \
#'com.apple.ContactsAgent' \  # No longer in Ventura
#'com.apple.CalendarAgent' \  # No longer in Ventura
'com.apple.calaccessd' \
#'com.apple.AddressBook.ContactsAccountsService' \  # No longer in Ventura
'com.apple.CallHistoryPluginHelper')

LA_FAMILYSYNC=('com.apple.familycircled' \
'com.apple.familycontrols.useragent' \
'com.apple.familynotificationd' \
'com.apple.UsageTrackingAgent')

LA_BLOAT=('com.apple.financed' \
#'com.apple.analyticsd' \  # No longer in Ventura (suspect this is was renamed/hidden to obfuscate)
'com.apple.gamed' \
'com.apple.newsd' \
'com.apple.weatherd' \
'com.apple.macos.studentd' \
'com.apple.progressd' \
'com.apple.remindd' \
'com.apple.helpd' \
'com.apple.tipsd')

LA_DICTATION=('com.apple.assistant_service' \
'com.apple.assistantd')

LA_FACETIME_MESSAGES=('com.apple.imagent' \
'com.apple.imautomatichistorydeletionagent' \
'com.apple.imtransferagent' \
'com.apple.telephonyutilities.callservicesd' \
'com.apple.avconferenced' \
'com.apple.CommCenter-osx' \
'com.apple.rapportd-user' \
'com.apple.transparencyStaticKey')

LA_PHOTOS=('com.apple.mediaanalysisd' \
'com.apple.peopled' \
'com.apple.photoanalysisd' \
'com.apple.photolibraryd' \
'com.apple.mediastream.mstreamd')

LA_SAFARI=('com.apple.Safari.PasswordBreachAgent' \
'com.apple.Safari.SafeBrowsing.Service' \
#'com.apple.SafariCloudHistoryPushAgent' \  # No longer in Ventura
'com.apple.SafariBookmarksSyncAgent')

LA_SIRI=('com.apple.siriactionsd' \
'com.apple.Siri.agent' \
#'com.apple.siri.context.service' \  # No longer in Ventura
'com.apple.proactiveeventtrackerd' \
'com.apple.triald' \
'com.apple.suggestd' \
'com.apple.siriknowledged' \
'com.apple.sirittsd')

LA_HOME=('com.apple.homed')

# com.apple.geod Launch Agent no longer in Ventura (entry used to call extra removal logic)
LA_LOCATION=('com.apple.geodMachServiceBridge' \
'com.apple.geod' \
'com.apple.CoreLocationAgent' \
'com.apple.parsec-fbf' \
'com.apple.parsecd' \
'com.apple.routined')

LA_MAPS=('com.apple.Maps.pushdaemon')
#'com.apple.Maps.mapspushd' \  # No longer in Ventura

# Client access to other shares still work. Stops your mac sharing to others
LA_SHARING=('com.apple.screensharing.agent' \
'com.apple.screensharing.menuextra' \
'com.apple.screensharing.MessagesAgent' \
'com.apple.amp.mediasharingd' \
'com.apple.sharingd' \
'com.apple.sidecar-hid-relay' \
'com.apple.sidecar-relay')

LA_IDENTITYDATA=('com.apple.BiomeAgent' \
'com.apple.biomesyncd' \
'com.apple.intelligenceplatformd' \
'com.apple.knowledge-agent' \
'com.apple.knowledgeconstructiond' \
'com.apple.spotlightknowledged' \
'com.apple.ScreenTimeAgent' \
'com.apple.accessibility.MotionTrackingAgent' \
'com.apple.transparencyd')

LA_MUSIC=('com.apple.AMPArtworkAgent' \
'com.apple.AMPDeviceDiscoveryAgent' \
'com.apple.AMPLibraryAgent' \
'com.apple.ensemble')

LA_APPLETV=('com.apple.videosubscriptionsd')

LA_PAYMENTS=('com.apple.passd')

LA_AUTOMATIONS=('com.apple.FolderActionsDispatcher' \
'com.apple.ScriptMenuApp')

# Make sure you have an alternative. Eg, LaunchBar or Alfred etc
LA_SPOTLIGHT=('com.apple.Spotlight')

LA_AIRPLAY=('com.apple.AirPlayUIAgent')

# Disabling WiFiVelocityAgent does not break wifi, just stop logging your wifi network history
LA_OTHER=('com.apple.networkserviceproxy-osx' \
'com.apple.universalaccessd' \
#'com.apple.CSCSupported' \  # No longer in Ventura
'com.apple.WiFiVelocityAgent')

TODISABLE=()
#TODISABLE+=( "${LA_BLUETOOTH[@]}" )    # Do not disable if you use Bluetooth headphones/keyboards/controllers etc
#TODISABLE+=( "${LA_QUICKLOOK[@]}" )    # Do not disable if you use QuickLook (image/video previews)
#TODISABLE+=( "${LA_TIMEMACHINE[@]}" )  # Do not disable if you use Time Machine backups
TODISABLE+=( "${LA_CLOUD[@]}" )
TODISABLE+=( "${LA_MDM[@]}" )
TODISABLE+=( "${LA_ADVERTISING[@]}" )
TODISABLE+=( "${LA_CONTACTSANDCALENDAR[@]}" )
TODISABLE+=( "${LA_FAMILYSYNC[@]}" )
TODISABLE+=( "${LA_BLOAT[@]}" )
TODISABLE+=( "${LA_DICTATION[@]}" )
TODISABLE+=( "${LA_FACETIME_MESSAGES[@]}" )
TODISABLE+=( "${LA_PHOTOS[@]}" )       # Photos App will still work
TODISABLE+=( "${LA_SAFARI[@]}" )       # Safari will still work
TODISABLE+=( "${LA_SIRI[@]}" )
TODISABLE+=( "${LA_HOME[@]}" )
TODISABLE+=( "${LA_LOCATION[@]}" )
TODISABLE+=( "${LA_MAPS[@]}" )         # Maps will still work
TODISABLE+=( "${LA_SHARING[@]}" )      # Do not disable if you use Screen and file sharing
TODISABLE+=( "${LA_IDENTITYDATA[@]}" )
TODISABLE+=( "${LA_MUSIC[@]}" )
TODISABLE+=( "${LA_APPLETV[@]}" )
TODISABLE+=( "${LA_PAYMENTS[@]}" )
TODISABLE+=( "${LA_AUTOMATIONS[@]}" )
TODISABLE+=( "${LA_SPOTLIGHT[@]}" )    # Make sure you have an alternative like LaunchBar
TODISABLE+=( "${LA_AIRPLAY[@]}" )      # Do not disable if you use AirPlay
TODISABLE+=( "${LA_OTHER[@]}" )

for agent in "${TODISABLE[@]}"
do
    echo "LaunchAgent: Requesting launchctl Disable of ${agent}" | tee -a ./Disable-Ventura-Bloatware.log
    {
        launchctl bootout user/0/${agent}    # Root shell user
        launchctl bootout gui/501/${agent}   # UI Login User
        launchctl bootout user/501/${agent}  # Shell Login User
        launchctl disable user/0/${agent}    # Root shell user
        launchctl disable gui/501/${agent}   # UI Login User
        launchctl disable user/501/${agent}  # Shell Login User
        launchctl remove user/0/${agent}     # Root shell user
        launchctl remove gui/501/${agent}    # UI Login User
        launchctl remove user/501/${agent}   # Shell Login User
    } &> /dev/null

    if [ -e "${MYROOTDISK}/System/Library/LaunchAgents/${agent}.plist" ] || [ -L "${MYROOTDISK}/System/Library/LaunchAgents/${agent}.plist" ]; then
        echo "LaunchAgent: Renaming ${agent}.plist to ${agent}.plist.bak" | tee -a ./Disable-Ventura-Bloatware.log
        mv "${MYROOTDISK}/System/Library/LaunchAgents/${agent}.plist" "${MYROOTDISK}/System/Library/LaunchAgents/${agent}.plist.bak"
    elif [ -e "${MYROOTDISK}/System/Library/LaunchAgents/${agent}.plist.bak" ] || [ -L "${MYROOTDISK}/System/Library/LaunchAgents/${agent}.plist.bak" ]; then
        echo "LaunchAgent: Already Renamed ${agent}.plist to ${agent}.plist.bak" | tee -a ./Disable-Ventura-Bloatware.log
    else
        echo "LaunchAgent: '${agent}.plist' not found in ${MYROOTDISK}/System/Library/LaunchAgents/" | tee -a ./Disable-Ventura-Bloatware.log
    fi

    # Disabling location tracking requires additional effort
    if [ "${agent}" = 'com.apple.geod' ] && [ -e "${MYROOTDISK}/System/Library/PrivateFrameworks/GeoServices.framework/Versions/A/XPCServices/com.apple.geod.xpc/Contents/MacOS/com.apple.geod" ]; then
        echo "Geod LaunchAgent: Disabling com.apple.geod for _locationd user" | tee -a ./Disable-Ventura-Bloatware.log
        # User ID 205 is special builtin _locationd user
        launchctl disable user/205/com.apple.geod
        launchctl bootout user/205/com.apple.geod
        launchctl disable user/501/com.apple.geodMachServiceBridge
        mv "${MYROOTDISK}/System/Library/PrivateFrameworks/GeoServices.framework/Versions/A/XPCServices/com.apple.geod.xpc/Contents/MacOS/com.apple.geod" "${MYROOTDISK}/System/Library/PrivateFrameworks/GeoServices.framework/Versions/A/XPCServices/com.apple.geod.xpc/Contents/MacOS/com.apple.geod.bak"
    elif [ "${agent}" = 'com.apple.geod' ] && [ -e "${MYROOTDISK}/System/Library/PrivateFrameworks/GeoServices.framework/Versions/A/XPCServices/com.apple.geod.xpc/Contents/MacOS/com.apple.geod.bak" ]; then
        echo "Geod LaunchAgent: Already Disabled com.apple.geod for _locationd user" | tee -a ./Disable-Ventura-Bloatware.log
    fi
    echo "" | tee -a ./Disable-Ventura-Bloatware.log

    # ls -lh "/Volumes/Macintosh HD/System/Volumes/Data/Users/$(id -un)/Library/Containers/com.apple.geod/Data/Library/Application Scripts/com.apple.geod"
    # sudo ls -lh "/Volumes/Macintosh HD/System/Volumes/Data/private/var/root/Library/Containers/com.apple.geod/Data/Library/Application Scripts/com.apple.geod"
done

echo "Done Disabling LaunchAgents" | tee -a ./Disable-Ventura-Bloatware.log


# Launch Daemons

LD_TIMEMACHINE=('com.apple.backupd' \
'com.apple.backupd-helper')

LD_CLOUD=('com.apple.cloudd' \
#'com.apple.cloudpaird' \  # No longer in Ventura
#'com.apple.cloudphotod' \  # No longer in Ventura
#'com.apple.CloudPhotosConfiguration' \  # No longer in Ventura
'com.apple.icloud.findmydeviced' \
#'com.apple.icloud.fmfd' \  # No longer in Ventura
#'com.apple.itunescloudd' \  # No longer in Ventura
'com.apple.icloud.searchpartyd')

LD_SHARING=('com.apple.coreduetd' \
'com.apple.screensharing')

LD_MDM=('com.apple.ManagedClient.cloudconfigurationd' \
'com.apple.ManagedClient.enroll' \
'com.apple.ManagedClient.startup' \
'com.apple.ManagedClient' \
'com.apple.ManagedClient.mechanism')

LD_OTHER=('com.apple.analyticsd' \
'com.apple.osanalytics.osanalyticshelper' \
#'com.apple.CoreLocationAgent' \  # No longer in Ventura
'com.apple.dhcp6d' \
'com.apple.familycontrols' \
'com.apple.findmymacmessenger' \
#'com.apple.followupd' \  # No longer in Ventura
#'com.apple.FollowUpUI' \  # No longer in Ventura
'com.apple.ftp-proxy' \
#'com.apple.ftpd' \  # No longer in Ventura
'com.apple.GameController.gamecontrollerd' \
#'com.apple.geod' \  # No longer in Ventura
'com.apple.netbiosd' \
'com.apple.nsurlsessiond' \
#'com.apple.protectedcloudstorage.protectedcloudkeysyncing' \  # No longer in Ventura
'com.apple.rapportd' \
#'com.apple.security.cloudkeychainproxy3' \  # No longer in Ventura
#'com.apple.siri.morphunassetsupdaterd' \  # No longer in Ventura
'com.apple.siriinferenced' \
'com.apple.triald.system' \
'com.apple.wifianalyticsd')

TODISABLE=()
#TODISABLE+=( "${LD_TIMEMACHINE[@]}" )  # Do not disable if you use Time Machine backups
TODISABLE+=( "${LD_CLOUD[@]}" )
TODISABLE+=( "${LD_SHARING[@]}" )
TODISABLE+=( "${LD_MDM[@]}" )
TODISABLE+=( "${LD_OTHER[@]}" )

for daemon in "${TODISABLE[@]}"
do
    echo "LaunchDaemon: Requesting Disable of ${daemon}" | tee -a ./Disable-Ventura-Bloatware.log
    launchctl disable system/${daemon}
    launchctl remove system/${daemon}

    if [ -e "${MYROOTDISK}/System/Library/LaunchDaemons/${daemon}.plist" ]; then
        echo "LaunchDaemon: Renaming ${daemon}.plist to ${daemon}.plist.bak" | tee -a ./Disable-Ventura-Bloatware.log
        mv "${MYROOTDISK}/System/Library/LaunchDaemons/${daemon}.plist" "${MYROOTDISK}/System/Library/LaunchDaemons/${daemon}.plist.bak"
    elif [ -e "${MYROOTDISK}/System/Library/LaunchDaemons/${daemon}.plist.bak" ]; then
        echo "LaunchDaemon: Already Renamed ${daemon}.plist to ${daemon}.plist.bak" | tee -a ./Disable-Ventura-Bloatware.log
    else
        echo "LaunchDaemon: '${daemon}.plist' not found in ${MYROOTDISK}/System/Library/LaunchDaemons/" | tee -a ./Disable-Ventura-Bloatware.log
    fi
    echo "" | tee -a ./Disable-Ventura-Bloatware.log
done

echo "Done Disabling LaunchDaemons" | tee -a ./Disable-Ventura-Bloatware.log

exit 0

