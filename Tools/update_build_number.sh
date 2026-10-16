#!/bin/bash

stamp_build_number() {
    if [ -n "${SCRIPT_OUTPUT_FILE_0:-}" ]; then
        mkdir -p "$(dirname "$SCRIPT_OUTPUT_FILE_0")"
        echo "${1:-skipped}" > "$SCRIPT_OUTPUT_FILE_0"
    fi
}

if [ "$CI" == "true" ]; then
    echo "Skipping build number update script under CI."
    stamp_build_number skipped
    exit 0
fi

# Source: https://gist.github.com/karlvr/c93a98d7000ecb163895

# This script automatically sets the version and short version string of
# an Xcode project from the Git repository containing the project.
#
# To use this script in Xcode, add the script's path to a "Run Script" build
# phase for your application target.

if [ -z "${TARGET_BUILD_DIR:-}" ] || [ -z "${INFOPLIST_PATH:-}" ]; then
    echo "warning: skipping build number update (not running inside an Xcode target)"
    stamp_build_number skipped
    exit 0
fi

pushd "$(dirname "$0")" > /dev/null
# shellcheck disable=SC1091
source "$(pwd -P)/utils.sh"
popd > /dev/null

BUILD_VERSION=$(get_build_version)
SHORT_VERSION=$(get_short_version)
BUNDLE_VERSION=$(get_bundle_version)

INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if [ ! -f "$INFO_PLIST" ]; then
    echo "warning: skipping build number update (missing $INFO_PLIST)"
    stamp_build_number skipped
    exit 0
fi

/usr/libexec/PlistBuddy -c "Add :CFBundleBuildVersion string $BUILD_VERSION" "$INFO_PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleBuildVersion $BUILD_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $SHORT_VERSION" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "$INFO_PLIST"

    stamp_build_number "$BUNDLE_VERSION"
