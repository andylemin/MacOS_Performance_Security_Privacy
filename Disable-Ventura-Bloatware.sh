#!/bin/sh

## Procedure;
#0) Take note of Agents and Daemons currently running; `launchctl list | grep -v "\-\t0"`
#1) Reboot in Recovery mode (Eg; https://www.lifewire.com/restart-a-mac-into-recovery-mode-5184142)
#2) Open 'Terminal' application in Recovery mode
#3) Disable SIP; `csrutil authenticated-root disable`
#4) List all disk volumes and identifiers; `diskutil list`
#5) Identify your system disk identifier - (Eg, 'disk3s3' for Volume 'Macintosh HD') in the diskutil output under the '(synthesized)' set
#6) Mount volume; `diskutil mount disk3s3` (replace 'disk3s3' with your own disk identifier if different)
#7) Make writable; `mount -uw /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' with your disk volume name)
#8) Update `${MYROOTDISK}` variable in the `Disable-Ventura-Bloatware.sh` script (~Line 32), and in the commands below (steps 11, 12), if different from (`/Volumes/Macintosh\ HD`)
#9) Make script executable; `chmod 775 ./Disable-Ventura-Bloatware.sh` and execute `./Disable-Ventura-Bloatware.sh` (in Recovery Mode Terminal)
#10) Check existing snapshots; `diskutil apfs listSnapshots disk3s3` (change disk and partition to yours)
#11) Create new disk snapshot; `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -s "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)
#12) Tag new snapshot bootable; `/Volumes/Macintosh\ HD/System/Library/Filesystems/apfs.fs/Contents/Resources/apfs_systemsnapshot -r "Custom1" -v /Volumes/Macintosh\ HD` (replace 'Macintosh\ HD' if different)
#OR 11 & 12) `bless --mount /Volumes/Macintosh\ HD --bootefi --create-snapshot` (I have not confirmed if there is any difference between this command and 11+12 - They seem to work the same so far)
#13) Check snapshots; `diskutil apfs listSnapshots disk3s3` (change disk and partition to yours) - Should show your new customised SSV Volume is the new MacOS Boot image
#14) Reboot in Normal mode (first reboot with new snapshot might take upto 10 minutes)
#15) Verify LaunchAgents and Daemons are now stopped; `launchctl list | grep -v "\-\t0"`

# * See README.md for all remaining steps *

# Agents not to disable
#Disabling `com.apple.speech.speechdatainstallerd` `com.apple.speech.speechsynthesisd` `com.apple.speech.synthesisserver` will freeze Edit menus.\
#Disabling `com.apple.bird` will prevent saving prompts from being shown.\
#`com.apple.imklaunchagent` is not related to iMessage.\
#Disabling `com.apple.WebKit.PluginAgent` can cause video problems in Safari.\
#`com.apple.nsurlsessiond` invokes and handles network download requests for many applications and services on macOS (inc iOS and tvOS and watchOS) - Use LittleSnitch to control who it talks to instead.
#Disabling Daemon `com.apple.airportd` breaks Wi-Fi connectivity

MYROOTDISK="/Volumes/Macintosh HD"

read -p "Please confirm; Running in Recovery mode? [y/n]" recmode
if [[ "$recmode" != "y" ]]; then
    echo "This script must be run from within Recovery mode!"
    echo
    exit
fi

# TODO Build launchctl man page extracts for Ventura https://gist.github.com/dmattera/883a4457b67534df795cdd0fa1651a26

# Launch Agents
# TODO Testing - When Bluetooth is excluded (from being disabled by commenting 'TODISABLE+=( "${LA_BLUETOOTH[@]}" )'), you also need to stop com.apple.sharingd from being disabled.
#  Console logs show bluetoothd trying to connect to com.apple.SharingServices which is likely part of com.apple.sharingd
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
#'com.apple.analyticsd' \  # No longer in Ventura
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
LA_SPOTLIGHT=('com.apple.Spotlight' \
'com.apple.corespotlightd')

LA_AIRPLAY=('com.apple.AirPlayUIAgent')

# Disabling WiFiVelocityAgent does not break wifi, just stop logging your wifi network history
LA_OTHER=('com.apple.networkserviceproxy-osx' \
'com.apple.universalaccessd' \
#'com.apple.CSCSupported' \  # No longer in Ventura
'com.apple.WiFiVelocityAgent' \
'com.apple.cmio.ContinuityCaptureAgent')

TODISABLE=()
TODISABLE+=( "${LA_BLUETOOTH[@]}" )    # Do not disable if you use Bluetooth headphones/keyboards/controllers etc
# TODISABLE+=( "${LA_QUICKLOOK[@]}" )    # Do not disable if you use QuickLook (image/video previews)
# TODISABLE+=( "${LA_TIMEMACHINE[@]}" )  # Do not disable if you use Time Machine backups
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
# TODISABLE+=( "${LA_AUTOMATIONS[@]}" )
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
'com.apple.ManagedClient.mechanism' \
'com.apple.remotemanagementd')

LD_NFC=('com.apple.nfcd' \
'com.apple.nearbyd')

LD_OTHER=('com.apple.locationd' \
'com.apple.findmymac' \
'com.apple.analyticsd' \
'com.apple.osanalytics.osanalyticshelper' \
#'com.apple.CoreLocationAgent' \  # No longer in Ventura
'com.apple.AirPlayXPCHelper' \
'com.apple.RemoteDesktop.PrivilegeProxy' \
'com.apple.familycontrols' \
'com.apple.findmymacmessenger' \
#'com.apple.followupd' \  # No longer in Ventura
#'com.apple.FollowUpUI' \  # No longer in Ventura
'com.apple.ftp-proxy' \
#'com.apple.ftpd' \  # No longer in Ventura
'com.apple.GameController.gamecontrollerd' \
#'com.apple.geod' \  # No longer in Ventura
#'com.apple.protectedcloudstorage.protectedcloudkeysyncing' \  # No longer in Ventura
'com.apple.netbiosd' \
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
TODISABLE+=( "${LD_NFC[@]}" )
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

