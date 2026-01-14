#!/bin/bash

SYSLOG_TAG="NordVPN.app Installer"

clog () {
    message="${SYSLOG_TAG}: $@"
    logger -t "${SYSLOG_TAG}" "${message}"
    echo "${message}"
}

cerr () {
    message="${SYSLOG_TAG}: $@"
    logger -s -p user.error -t "${SYSLOG_TAG}" "${message}"
    echo -e "\033[0;31m${message}\033[0m"
}

stopApplication() {
    
    APP_PID=`ps -e -o pid,args \
        | grep "${1}/Contents/MacOS/NordVPN" \
        | grep -v "grep" \
        | awk '{print $1}'`
    
    if [ -n "${APP_PID}" ]; then
        clog "Stopping application"
        kill -9 $APP_PID
    fi
    
}

stopOVPNHelperDaemon() {
    
    OVPN_PID=`ps -e -o pid,args \
        | grep "${1}/Contents/Resources/Bin/\(openvpn\|ovpn\).*${2}/" \
        | grep -v "grep" \
        | awk '{print $1}'`
    
    if [ -n "${OVPN_PID}" ]; then
        clog "Stopping daemon"
        kill -9 $OVPN_PID
    fi
    
}

killProcess() {

    HELPER_BUNDLE_ID=$1

    HELPER_PID=$(ps -e -o pid,args | grep -i ${HELPER_BUNDLE_ID} | grep -v "grep" | grep -v "plutil" | awk '{print $1}')

    if [ ! -z "${HELPER_PID}" ]; then
        sudo kill -9 $HELPER_PID
    fi

}

removeOVPNHelperDaemon() {

    APP_BUNDLE_ID=$1
    
    clog "Removing ${APP_BUNDLE_ID}.helper daemon"
    launchctl remove "${APP_BUNDLE_ID}.helper"

    LAUNCH_DAEMONS_PLIST="/Library/LaunchDaemons/${APP_BUNDLE_ID}.helper.plist"
    if [ -e "${LAUNCH_DAEMONS_PLIST}" ]; then
        clog "Removing ${LAUNCH_DAEMONS_PLIST} file"
        rm "${LAUNCH_DAEMONS_PLIST}"
    fi
    
    PRIVILEGED_TOOL="/Library/PrivilegedHelperTools/${APP_BUNDLE_ID}.helper"
    if [ -e "${PRIVILEGED_TOOL}" ]; then
        clog "Removing ${PRIVILEGED_TOOL} file"
        rm "${PRIVILEGED_TOOL}"
    fi

    DNS_TOOL_PATH="/Library/PrivilegedHelperTools/${APP_BUNDLE_ID}.ovpnDnsManager"
    if [ -e "${DNS_TOOL_PATH}" ]; then
        clog "Removing ${DNS_TOOL_PATH} file"
        rm "${DNS_TOOL_PATH}"
    fi

}

removeApp() {
    
    APP_PATH=$1
    ESCAPE_STR='-install.app'

    if [[ $APP_PATH == *"$ESCAPE_STR" ]]; then
        echo "Skipping removal of installer app"
        return
    fi
    clog "Removing ${APP_PATH}"
    
    if [ -e $APP_PATH ]; then
        PREVIOUS_VERSION=$(/usr/bin/mdls -raw -name kMDItemVersion "${APP_PATH}")
        PREVIOUS_MAJOR_VERSION=$(echo $PREVIOUS_VERSION | awk -F. '{print $1}')
        
        clog "Previous version: $PREVIOUS_VERSION"
        clog "Previous major version: $PREVIOUS_MAJOR_VERSION"
    else
        clog "Couldn't find previous application version"
    fi
    
    stopApplication "${APP_PATH}"
    
    # Remove v3 files
    if [ -n "${PREVIOUS_MAJOR_VERSION}" ] && [ $PREVIOUS_MAJOR_VERSION -lt 4 ]; then
        clog "Removing v3 daemon"
        removeOVPNHelperDaemon com.nordvpn.NordVPN
        stopOVPNHelperDaemon ${APP_PATH} com.nordvpn.NordVPN
        
        clog "Removing old login item"
        osascript -e 'tell application "System Events" to delete login item "NordVPN"' || true
    fi
    
    rm -rf "${APP_PATH}"
    
}

removeApplicationsWithBundleID() {
    
    APP_BUNDLE_ID=$1
    PURGE_HELPERS=$2
    
    if [ -n "$PURGE_HELPERS" ]; then
        clog "Removing ${APP_BUNDLE_ID} helpers"
        removeOVPNHelperDaemon $APP_BUNDLE_ID
    fi

    clog "Searching for ${APP_BUNDLE_ID}"
    
    APPS_LIST=()
    IFS=$'\n' 
    read -r -d '' -a APPS_LIST < <( (mdfind kMDItemCFBundleIdentifier = "${APP_BUNDLE_ID}") )

    if [ -z "${APPS_LIST}" ]; then
        clog "No apps with bundle id '${APP_BUNDLE_ID}' was found"
    else
        for INSTALLED_APP_PATH in "${APPS_LIST[@]}"; do

            clog "Located ${APP_BUNDLE_ID} at '${INSTALLED_APP_PATH}'"
            if [ -z "${INSTALLED_APP_PATH}" ]; then
                clog "Skipping ${APP_BUNDLE_ID} at '${INSTALLED_APP_PATH}', because path is empty"
                continue
            fi

            if [ -n "$PURGE_HELPERS" ]; then
                clog "Stopping ovpn process from ${APP_BUNDLE_ID} at '${INSTALLED_APP_PATH}'"
                stopOVPNHelperDaemon $INSTALLED_APP_PATH $APP_BUNDLE_ID
            fi

            clog "Removing ${APP_BUNDLE_ID} at '${INSTALLED_APP_PATH}'"
            removeApp $INSTALLED_APP_PATH
 
        done
    fi
    
    if [ -n "$PURGE_HELPERS" ]; then
        clog "stopping $APP_BUNDLE_ID.helper process"
        killProcess "$APP_BUNDLE_ID.helper"
    fi
    
}

removeUserFiles() {
    clog "Removing user files"

    # Preferences
    for plist in ~/Library/Preferences/com.nordvpn.*.plist ~/Library/Preferences/group.com.nordvpn.*.plist; do
        if [ -e "$plist" ]; then
            clog "Removing $plist"
            rm -f "$plist"
        fi
    done

    # Caches
    for cache in ~/Library/Caches/com.nordvpn.*; do
        if [ -e "$cache" ]; then
            clog "Removing $cache"
            rm -rf "$cache"
        fi
    done

    # HTTP Storages
    for storage in ~/Library/HTTPStorages/com.nordvpn.*; do
        if [ -e "$storage" ]; then
            clog "Removing $storage"
            rm -rf "$storage"
        fi
    done

    # Application Support
    if [ -d ~/Library/Application\ Support/NordVPN ]; then
        clog "Removing ~/Library/Application Support/NordVPN"
        rm -rf ~/Library/Application\ Support/NordVPN
    fi

    # Logs
    if [ -d ~/Library/Logs/NordVPN ]; then
        clog "Removing ~/Library/Logs/NordVPN"
        rm -rf ~/Library/Logs/NordVPN
    fi

    # Saved Application State
    for state in ~/Library/Saved\ Application\ State/com.nordvpn.*; do
        if [ -e "$state" ]; then
            clog "Removing $state"
            rm -rf "$state"
        fi
    done

    # Group Containers
    for container in ~/Library/Group\ Containers/*nordvpn*; do
        if [ -e "$container" ]; then
            clog "Removing $container"
            rm -rf "$container"
        fi
    done
}

removeApplicationsWithBundleID "com.nordvpn.NordVPN" 1
removeApplicationsWithBundleID "com.nordvpn.osx" 1
removeApplicationsWithBundleID "com.nordvpn.macos" 1
removeApp "/Applications/NordVPN.app"
removeUserFiles

clog "Done"
exit 0
