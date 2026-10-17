#!/bin/zsh
# Compile MacDown (Release) et l'installe dans ~/Applications, extensions
# Quick Look comprises. Rouvre les documents Markdown qui étaient ouverts.
set -e
cd "${0:A:h}/.."
xcodebuild -workspace MacDown.xcworkspace -scheme MacDown -configuration Release build \
    | grep -E 'error:|BUILD (SUCCEEDED|FAILED)'
built=$(xcodebuild -workspace MacDown.xcworkspace -scheme MacDown -configuration Release \
    -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR =/{d=$2} /FULL_PRODUCT_NAME = MacDown.app/{print d; exit}')/MacDown.app

docs=()
if pgrep -qf 'MacDown.app/Contents/MacOS/MacDown$'; then
    if osascript -e 'tell application id "com.uranusjr.macdown" to get modified of every document' | grep -q true; then
        echo "MacDown a des documents non enregistrés : rien n'est remplacé." >&2
        exit 1
    fi
    docs=("${(@f)$(osascript -e 'tell application id "com.uranusjr.macdown" to set fs to file of every document' \
        -e 'set r to {}' -e 'repeat with f in fs' \
        -e 'try' -e 'set end of r to POSIX path of f' -e 'end try' \
        -e 'end repeat' -e 'set AppleScript'"'"'s text item delimiters to linefeed' \
        -e 'return r as text')}")
    osascript -e 'tell application id "com.uranusjr.macdown" to quit'
    while pgrep -qf 'MacDown.app/Contents/MacOS/MacDown$'; do sleep 0.5; done
fi

rm -rf ~/Applications/MacDown.app
ditto "$built" ~/Applications/MacDown.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/Applications/MacDown.app
for appex in ~/Applications/MacDown.app/Contents/PlugIns/*.appex; do pluginkit -a "$appex"; done
qlmanage -r >/dev/null 2>&1 || true

for d in $docs; do [[ -n $d ]] && open -a ~/Applications/MacDown.app "$d"; done
echo "Déployé : ~/Applications/MacDown.app"
