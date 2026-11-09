#!/bin/sh
# Build the patch and put it live on the phone, without the devel-su password.
# Needs the development helper enabled on the phone (dev-helper/ada-home-dev,
# "enable" gives a time-limited polkit rule). Steps:
#   build + checks -> unapply -> stage -> dry run -> install (helper unit)
#   -> fresh journal recording -> apply -> restart lipstick -> check
# Restarting lipstick closes all open apps.
set -eu
cd "$(dirname "$0")"

PHONE=${PHONE:-defaultuser@phone}
PM='gdbus call --system --dest org.SfietKonstantin.patchmanager --object-path /org/SfietKonstantin/patchmanager --method org.SfietKonstantin.patchmanager'

./build-patch.sh
local_hash=$(sha256sum patch/ada-home-sailfish/unified_diff.patch | cut -d' ' -f1)

ssh -o BatchMode=yes "$PHONE" "$PM.unapplyPatch ada-home-sailfish > /dev/null; mkdir -p ~/ada-home-sailfish"
scp -q -o BatchMode=yes patch/ada-home-sailfish/* "$PHONE:ada-home-sailfish/"

ssh -o BatchMode=yes "$PHONE" "
set -e
# Dry run against the live files. Links left behind by Patchmanager's
# emergency unapply ('not a regular file') are harmless and ignored.
cd / && out=\$(patch -p1 --dry-run -N < ~/ada-home-sailfish/unified_diff.patch 2>&1 || true)
if echo \"\$out\" | grep -E 'FAILED|can.t find|malformed'; then echo 'dry run failed'; exit 1; fi
systemctl start ada-home-dev-install.service
status=\$(cat /run/ada-home-dev/install-status)
case \"\$status\" in OK*$local_hash*) ;; *) echo \"install failed: \$status\"; exit 1 ;; esac
systemctl restart ada-home-dev-log.service
if [ \"\$($PM.getFailure)\" = '(true,)' ]; then $PM.resolveFailure; fi
$PM.applyPatch ada-home-sailfish | grep -o 'SUCCESS\|FAILED'
$PM.restartServices > /dev/null
"
echo "Waiting for lipstick to restart..."
sleep 15
ssh -o BatchMode=yes "$PHONE" "
systemctl --user show lipstick -p ActiveState -p ActiveEnterTimestamp -p NRestarts | tr '\n' ' '; echo
echo \"patch applied: \$($PM.isPatchApplied ada-home-sailfish)  Patchmanager failure: \$($PM.getFailure)\"
echo \"lipstick crashes in log: \$(grep -c 'lipstick.service: Main process exited, code=killed' /run/ada-home-dev/journal.txt)\"
echo 'QML warnings:'
grep -E 'lipstick\[' /run/ada-home-dev/journal.txt | grep -E '\[W\].*qml|unavailable|is not a type|Error' \
    | grep -v 'LauncherGrid.qml:288\|nemothumbnail' | sed 's/.*lipstick\[[0-9]*\]: //' | cut -c1-250 | sort | uniq -c | head -20
"
