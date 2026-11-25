#!/bin/bash
#
# Installs, updates and starts awdlkiller (https://github.com/jamestut/awdlkiller).
# awdlkiller keeps the awdl0 interface down: it waits on a routing socket and takes awdl0
# down the moment macOS brings it up. While it runs, AirDrop, AirPlay, Sidecar, Universal
# Control and some Handoff/Continuity features do not work.
#
# Run it as your normal user from any folder; the install steps use sudo. Run it again to
# update: it installs the newest awdlkiller release, built from source with the Xcode
# command line tools, after showing what changed and asking first.
#
# Undo;
#   sudo launchctl bootout system/jamestut.awdlkiller
#   sudo rm /Library/LaunchDaemons/jamestut.awdlkiller.plist
#   sudo rm /usr/local/libexec/awdlkiller /usr/local/libexec/awdlkiller.version
#   sudo ifconfig awdl0 up

set -euo pipefail

REPO_URL="https://github.com/jamestut/awdlkiller.git"
WEB_URL="${REPO_URL%.git}"
LABEL="jamestut.awdlkiller"
INSTALL_DIR="/usr/local/libexec"
BINARY="${INSTALL_DIR}/awdlkiller"
VERSION_FILE="${INSTALL_DIR}/awdlkiller.version"
PLIST_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Library_LaunchDaemons_${LABEL}.plist"
PLIST_DST="/Library/LaunchDaemons/${LABEL}.plist"
SERVICE="system/${LABEL}"
# awdlkiller's own installer puts a setuid root copy here
OLD_BINARY="/usr/local/bin/awdlkiller"

# Fail instead of asking for a GitHub login when the repository cannot be read
export GIT_TERMINAL_PROMPT=0

WORK=""
cleanup() {
    if [[ -n "${WORK}" && -d "${WORK}" ]]; then
        rm -rf -- "${WORK:?}"
    fi
}
trap cleanup EXIT

die() {
    echo "ERROR: $*" >&2
    exit 1
}

confirm() {
    local answer=""
    read -r -p "$1 [y/n] " answer || true
    [[ "${answer}" == "y" ]]
}

loaded() {
    sudo launchctl print "${SERVICE}" >/dev/null 2>&1
}

# launchd runs the binary as root at every boot, so nobody but root may be able to replace it
check_root_only() {
    local d="$1"
    while [[ -n "${d}" && "${d}" != "/" ]]; do
        if [[ -e "${d}" && -n "$(find -H "${d}" -maxdepth 0 \( ! -user root -o -perm -g+w -o -perm -o+w \) -print)" ]]; then
            die "${d} can be changed by users other than root, and launchd would run what is put there as root. Fix its owner or permissions, or set INSTALL_DIR to a folder only root can write to."
        fi
        d="$(dirname "${d}")"
    done
}

[[ "$(uname -s)" == "Darwin" ]] || die "awdlkiller is for macOS"
[[ -f "${PLIST_SRC}" ]] || die "${PLIST_SRC} not found; keep this script next to its plist"
plutil -lint "${PLIST_SRC}" >/dev/null || die "${PLIST_SRC} is not a valid plist"
plist_program="$(/usr/libexec/PlistBuddy -c 'Print :Program' "${PLIST_SRC}" 2>/dev/null || true)"
[[ "${plist_program}" == "${BINARY}" ]] || die "${PLIST_SRC} runs '${plist_program}', but this script installs ${BINARY}"
xcode-select -p >/dev/null 2>&1 || die "awdlkiller is fetched with git and built from source, which needs the Xcode command line tools. Install them with 'xcode-select --install', then run this script again."
check_root_only "${BINARY}"

# The newest release tag (vX.Y.Z) and the commit it points to, read without cloning
latest_tag=""
latest_commit=""
if tags="$(git ls-remote --tags "${REPO_URL}" 'v*' 2>/dev/null)"; then
    latest_version="$(printf '%s\n' "${tags}" \
        | sed -n 's#^[0-9a-f]*[[:space:]]*refs/tags/v\([0-9][0-9.]*\)$#\1#p' \
        | sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1)"
    if [[ -n "${latest_version}" ]]; then
        latest_tag="v${latest_version}"
        latest_commit="$(printf '%s\n' "${tags}" | awk -v t="refs/tags/${latest_tag}" \
            '$2 == (t "^{}") {peeled = $1} $2 == t {direct = $1} END {print (peeled != "" ? peeled : direct)}')"
    fi
fi

installed_tag=""
installed_commit=""
if [[ -x "${BINARY}" && -f "${VERSION_FILE}" ]]; then
    read -r installed_tag installed_commit < "${VERSION_FILE}" || true
fi

build=0
if [[ ! -x "${BINARY}" ]]; then
    [[ -n "${latest_tag}" ]] || die "could not read awdlkiller's releases from ${REPO_URL}; check the network and run this script again"
    build=1
elif [[ -z "${latest_tag}" ]]; then
    echo "WARNING: could not read awdlkiller's releases from ${REPO_URL}; keeping the installed ${installed_tag:-build}"
elif [[ "${installed_commit}" != "${latest_commit}" ]]; then
    build=1
else
    echo "awdlkiller ${installed_tag} is installed and up to date"
fi

changed=0
if [[ "${build}" -eq 1 ]]; then
    WORK="$(mktemp -d "${TMPDIR:-/tmp}/awdlkiller.XXXXXX")"
    git clone --quiet "${REPO_URL}" "${WORK}/src" || die "could not download ${REPO_URL}"
    git -C "${WORK}/src" -c advice.detachedHead=false checkout --quiet "${latest_commit}"
    echo
    if [[ -n "${installed_commit}" ]] && git -C "${WORK}/src" cat-file -e "${installed_commit}^{commit}" 2>/dev/null; then
        echo "awdlkiller ${installed_tag} -> ${latest_tag}:"
        git -C "${WORK}/src" log --no-decorate --format='  %h %cs %s' "${installed_commit}..${latest_commit}"
        git -C "${WORK}/src" diff --stat "${installed_commit}" "${latest_commit}"
        echo "All changes: ${WEB_URL}/compare/${installed_tag}...${latest_tag}"
    else
        echo "awdlkiller ${latest_tag}: $(git -C "${WORK}/src" log -1 --format='%h %cs %s' "${latest_commit}")"
        echo "Source: ${WEB_URL}/tree/${latest_tag}"
    fi
    echo "It is built from source here and runs as root at every boot."
    if confirm "Build and install awdlkiller ${latest_tag}?"; then
        make -C "${WORK}/src" awdlkiller || die "the awdlkiller build failed"
        [[ -x "${WORK}/src/awdlkiller" ]] || die "the build made no awdlkiller binary"
        printf '%s %s\n' "${latest_tag}" "${latest_commit}" > "${WORK}/version"
        if [[ ! -d "${INSTALL_DIR}" ]]; then
            sudo install -d -o root -g wheel -m 755 "${INSTALL_DIR}"
            check_root_only "${INSTALL_DIR}"
        fi
        sudo install -o root -g wheel -m 755 "${WORK}/src/awdlkiller" "${BINARY}"
        sudo install -o root -g wheel -m 644 "${WORK}/version" "${VERSION_FILE}"
        echo "Installed ${BINARY} (${latest_tag})"
        changed=1
    elif [[ ! -x "${BINARY}" ]]; then
        echo "Nothing installed."
        exit 0
    else
        echo "Keeping awdlkiller ${installed_tag:-as installed}."
    fi
fi

if ! cmp -s "${PLIST_SRC}" "${PLIST_DST}"; then
    sudo install -o root -g wheel -m 644 "${PLIST_SRC}" "${PLIST_DST}"
    echo "Installed ${PLIST_DST}"
    changed=1
fi

if [[ -e "${OLD_BINARY}" ]]; then
    echo
    echo "${OLD_BINARY} is a copy from awdlkiller's own installer, which sets the setuid bit on it."
    echo "The LaunchDaemon now runs ${BINARY}, so the old copy is no longer used."
    if confirm "Remove ${OLD_BINARY}?"; then
        sudo rm -f -- "${OLD_BINARY}"
        echo "Removed ${OLD_BINARY}"
    fi
fi

sudo launchctl enable "${SERVICE}"
if [[ "${changed}" -eq 1 ]] && loaded; then
    echo "Restarting awdlkiller"
    sudo launchctl bootout "${SERVICE}" || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        loaded || break
        sleep 0.5
    done
fi
if ! loaded; then
    sudo launchctl bootstrap system "${PLIST_DST}" || die "launchctl could not start ${LABEL}; see 'sudo launchctl print ${SERVICE}'"
fi

sleep 1
status="$(sudo launchctl print "${SERVICE}" 2>/dev/null || true)"
if [[ "${status}" == *"state = running"* ]]; then
    echo "awdlkiller is running."
else
    echo "WARNING: awdlkiller is not running; see /private/tmp/awdlkiller.err and 'sudo launchctl print ${SERVICE}'"
fi
awdl="$(ifconfig awdl0 2>/dev/null || true)"
if [[ -z "${awdl}" ]]; then
    echo "WARNING: there is no awdl0 interface yet; launchd restarts awdlkiller every 10 seconds until there is."
elif [[ "${awdl%%$'\n'*}" == *"<UP"* ]]; then
    echo "WARNING: awdl0 is still up"
else
    echo "awdl0 is down."
fi
