#!/bin/zsh
# Emballe une version publiable : compilation Release, signature Developer ID
# (autorité G2) de l'intérieur vers l'extérieur avec runtime renforcé,
# notarisation, agrafage, archive .zip et signature Sparkle (EdDSA).
#
#   scripts/package_release.sh [--no-notarize]
#
# Résultat dans build/release/ : MacDown-<version>.zip et la ligne
# sparkle:edSignature/length à reporter dans appcast.xml.
set -euo pipefail
cd "${0:A:h}/.."
notarize=1
[[ ${1:-} == --no-notarize ]] && notarize=0

profile=TreeLevelMC          # profil notarytool du trousseau (équipe 9LVGAJ594U)
sparkle_account=macdown-arm64
identity=$(scripts/devid_identity.sh)

xcodebuild -workspace MacDown.xcworkspace -scheme MacDown -configuration Release build \
    | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
built=$(xcodebuild -workspace MacDown.xcworkspace -scheme MacDown -configuration Release \
    -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR =/{d=$2} /FULL_PRODUCT_NAME = MacDown.app/{print d; exit}')/MacDown.app

out=build/release
rm -rf $out && mkdir -p $out
app=$out/MacDown.app
ditto "$built" $app
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' $app/Contents/Info.plist)
build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' $app/Contents/Info.plist)

sign() { codesign --force --timestamp --options runtime --sign "$identity" "$@"; }

# Sparkle, dans l'ordre que donne sa documentation.
sp=$app/Contents/Frameworks/Sparkle.framework/Versions/B
sign $sp/XPCServices/Installer.xpc
sign --preserve-metadata=entitlements $sp/XPCServices/Downloader.xpc
sign $sp/Autoupdate
sign $sp/Updater.app
sign $app/Contents/Frameworks/Sparkle.framework
for fw in $app/Contents/Frameworks/*.framework(N) $app/Contents/Frameworks/*.dylib(N); do
    [[ $fw == */Sparkle.framework ]] || sign "$fw"
done

sign $app/Contents/SharedSupport/bin/macdown
for appex in $app/Contents/PlugIns/*.appex; do
    sign --entitlements MacDownQuickLook/MacDownQuickLook.entitlements "$appex"
done
sign --entitlements scripts/MacDown-release.entitlements $app

codesign --verify --strict --deep $app
spctl -a -t exec -vv $app 2>&1 | tail -2 || true

zip=$out/MacDown-$version.zip
ditto -c -k --keepParent $app $zip
if (( notarize )); then
    xcrun notarytool submit $zip --keychain-profile $profile --wait
    xcrun stapler staple $app
    rm $zip && ditto -c -k --keepParent $app $zip
    spctl -a -t exec -vv $app 2>&1 | tail -2
fi

echo "version $version ($build)"
Pods/Sparkle/bin/sign_update --account $sparkle_account $zip
