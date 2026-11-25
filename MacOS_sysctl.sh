#!/bin/bash

echo "From MacOS Catalina 10.15.3, /etc/sysctl.conf values are no longer respected. You need to set sysctls via plists instead (this script does this)"
echo
echo "Updating sysctl values on Ventura is generally not required anymore as Apple have already provided sane defaults to achieve 10Gbps performance"
echo "Make sure you have read the changes in 'Library_LaunchDaemons_com.startup.sysctl.plist'"
echo "In particular make sure you understand 'net.inet.tcp.tso', 'net.inet.tcp.delayed_ack' and the network buffer pool (the 'ncl' boot argument), and configure for your use case (info in README.md). These have the most impact."
echo
echo "NB; Installing plists into /Library/LaunchDaemons does NOT require disabling SIP."
echo "Some individual sysctl keys may still refuse to change on some configurations - check /tmp/sysctl.err after reboot, and only then investigate SIP."
read -r -p "Are you sure you want to increase sysctl values? [y/n]" iamsure
if [[ "$iamsure" != "y" ]]; then
    exit
fi

# Needs further testing (requires machine with at least 32 or 64 GB RAM);
#             <string>kern.sysv.shmmax=4194304</string>
#             <string>kern.sysv.shmmin=1</string>
#             <string>kern.sysv.shmmni=32</string>
#             <string>kern.sysv.shmseg=8</string>
#             <string>kern.sysv.shmall=1024</string>

# kern.maxvnodes (old macs default 66560, Ventura default 263168, serverperfmode default 300000)
#   Kernel default is RAM/64KB + 1024, capped at 263168; both plists set 524288 for large source trees
# kern.maxproc (old macs default 1064, Ventura default 16000, serverperfmode default 5000)
# kern.maxfilesperproc (old macs default 10240, Ventura default 245760, serverperfmode default 150000)
# kern.maxprocperuid (old macs default 709, Ventura default 10666, serverperfmode default 3750)
# kern.ipc.maxsockbuf (old macs default 4194304, Ventura default 8388608, serverperfmode default 8388608)
#   The kernel rejects values above kern.ipc.nmbclusters x 128 bytes, so 32MB needs 262144 clusters;
#   both plists keep maxsockbuf = autorcvbufmax + autosndbufmax
# kern.ipc.somaxconn (old macs default 128, Ventura default 128, serverperfmode default 1024)
#   listen() clamps every backlog to it; both plists set 2048 for local server load tests
# kern.ipc.nmbclusters is read-only; the kernel sizes it at boot from RAM (65536 at 8-16GB, 131072 at
#   16-32GB, 262144 at 32GB+) or from the ncl= boot argument, which this script offers to set below
#   (to 1/16 of RAM, up to the kernel's maximum of 1048576)
# kern.timer.coalescing_enabled (default 1); both plists set 0, so the kernel stops adding coalescing
#   slack to timers (timers fire closer to their deadlines, at the cost of more CPU wake-ups)

# Two profile variants ship with this repo (same Label, deploy one only);
#   Library_LaunchDaemons_com.startup.sysctl.plist          - current default (delayed_ack=0, win_scale=8, 16MB autobufs, 32MB maxsockbuf)
#   Library_LaunchDaemons_com.startup.sysctl_ventura.plist  - earlier variant (delayed_ack=1, win_scale=6, 8MB autobufs, 16MB maxsockbuf)
SYSCTL_PLIST="./Library_LaunchDaemons_com.startup.sysctl.plist"

echo "Updating /Library/LaunchDaemons/com.startup.sysctl.plist (from ${SYSCTL_PLIST})"
sudo cp -f "${SYSCTL_PLIST}" /Library/LaunchDaemons/com.startup.sysctl.plist
sudo chown root:wheel /Library/LaunchDaemons/com.startup.sysctl.plist
# validate key-value pairs
plutil /Library/LaunchDaemons/com.startup.sysctl.plist
# load plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.startup.sysctl.plist
# check logs
tail /tmp/sysctl.out
tail /tmp/sysctl.err

echo "Updating /Library/LaunchDaemons/limit.maxfiles.plist"
sudo cp -f ./Library_LaunchDaemons_limit.maxfiles.plist /Library/LaunchDaemons/limit.maxfiles.plist
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
plutil /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/limit.maxfiles.plist
echo

# Network buffer pool; sysctl cannot change kern.ipc.nmbclusters, the kernel reads the ncl= boot argument at boot.
# Target: the kernel's maximum (1048576 2KB clusters, a 2GB pool), but never more than 1/16 of RAM, the largest
# share in Apple's own table (64MB on a 1GB Mac). Under load TCP drops out-of-order segments once the pool is
# nearly full, so a bigger pool keeps them during loss recovery ('netstat -s -p tcp': "dropped due to low memory").
# The pool must also cover kern.ipc.maxsockbuf (the kernel rejects it above nmbclusters x 128 bytes), and
# maxsockbuf = autorcvbufmax + autosndbufmax.
NCL_MAX=1048576
NCL_RAM_SHARE=16
is_number() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
    esac
}
plist_value() {
    sed -n "s#.*<string>$1=\([0-9]*\)</string>.*#\1#p" "${SYSCTL_PLIST}"
}
mem_bytes="$(sysctl -n hw.memsize 2>/dev/null)"
current_ncl="$(sysctl -n kern.ipc.nmbclusters 2>/dev/null)"
rcv_max="$(plist_value net.inet.tcp.autorcvbufmax)"
snd_max="$(plist_value net.inet.tcp.autosndbufmax)"
sockbuf_max="$(plist_value kern.ipc.maxsockbuf)"
if ! is_number "${mem_bytes}" || ! is_number "${current_ncl}" || ! is_number "${rcv_max}" \
    || ! is_number "${snd_max}" || ! is_number "${sockbuf_max}"; then
    echo "Could not read hw.memsize, kern.ipc.nmbclusters or the plist's buffer sizes - skipping the network buffer pool"
else
    if [[ "${sockbuf_max}" -ne $((rcv_max + snd_max)) ]]; then
        echo "WARNING; ${SYSCTL_PLIST} sets kern.ipc.maxsockbuf=${sockbuf_max}, but autorcvbufmax + autosndbufmax is $((rcv_max + snd_max))"
    fi
    # In whole 16KB pages (8 clusters), as the kernel rounds the pool down to pages
    ncl_target=$((mem_bytes / NCL_RAM_SHARE / 2048))
    ncl_target=$((ncl_target - ncl_target % 8))
    if [[ "${ncl_target}" -gt "${NCL_MAX}" ]]; then
        ncl_target="${NCL_MAX}"
    fi
    ncl_needed=$(((sockbuf_max + 127) / 128))
    ncl_needed=$((ncl_needed + (8 - ncl_needed % 8) % 8))
    echo "Network buffer pool; RAM $((mem_bytes >> 30))GB, kern.ipc.nmbclusters=${current_ncl}, target ${ncl_target} ($((ncl_target >> 9))MB pool); maxsockbuf=${sockbuf_max} needs ${ncl_needed}"
    if [[ "${ncl_target}" -lt "${ncl_needed}" ]]; then
        echo "WARNING; 1/${NCL_RAM_SHARE} of this Mac's RAM is too small a pool for maxsockbuf=${sockbuf_max}, so the kernel will reject it - lower autorcvbufmax and autosndbufmax for this Mac"
    fi
    if [[ "${current_ncl}" -lt "${ncl_target}" ]]; then
        old_args="$(nvram boot-args 2>/dev/null | cut -f 2-)"
        new_args=""
        # Split the current boot-args into words without expanding * or ? in them
        set -f
        # shellcheck disable=SC2086
        for arg in ${old_args}; do
            case "${arg}" in
                ncl=*) ;;
                *) new_args="${new_args}${arg} " ;;
            esac
        done
        set +f
        new_args="${new_args}ncl=${ncl_target}"
        echo "boot-args now; '${old_args}'"
        echo "boot-args new; '${new_args}'"
        if [[ "$(uname -m)" == "arm64" ]]; then
            echo "NB; Apple Silicon may filter ncl= out of boot-args (iBoot applies its allow list unless the LocalPolicy sip3 field is set) - check the read-only 'sysctl kern.ipc.nmbclusters' after the reboot"
        fi
        read -r -p "Set boot-args (takes effect at the next reboot)? [y/n]" setncl
        if [[ "$setncl" == "y" ]]; then
            if sudo nvram boot-args="${new_args}"; then
                echo "Set. After the reboot, check the read-only 'sysctl kern.ipc.nmbclusters'; it shows ${ncl_target} if the kernel received ncl="
                if [[ -n "${old_args}" ]]; then
                    echo "To undo; sudo nvram boot-args='${old_args}'"
                else
                    echo "To undo; sudo nvram -d boot-args"
                fi
            else
                echo "Could not set boot-args"
            fi
        fi
    else
        echo "kern.ipc.nmbclusters is already at or above the target"
    fi
fi
echo

echo "Current System Limits"
ulimit -a
launchctl limit maxfiles
