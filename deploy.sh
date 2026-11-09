#!/bin/sh
# Build the patch and put it live on the phone, without the devel-su password.
# Needs the development helper enabled on the phone (dev-helper/ada-home-dev,
# "enable" gives a time-limited polkit rule). Steps:
#   build + checks -> unapply -> stage -> dry run -> install (helper unit)
#   -> fresh journal recording -> apply -> restart lipstick -> check
# Restarting lipstick closes all open apps.
set -eu
cd "$(dirname "$0")"

# Phone to check against / deploy to: $PHONE, or the git-ignored file
# phone.conf (one line, e.g. defaultuser@192.168.x.y)
if [ -z "${PHONE:-}" ] && [ -f phone.conf ]; then
    PHONE=$(head -n 1 phone.conf)
fi
if [ -z "${PHONE:-}" ]; then
    echo "Set PHONE=defaultuser@<phone address> or put it in phone.conf" >&2
    exit 1
fi
PM='gdbus call --system --dest org.SfietKonstantin.patchmanager --object-path /org/SfietKonstantin/patchmanager --method org.SfietKonstantin.patchmanager'

./build-patch.sh
local_hash=$(sha256sum patch/ada-home-sailfish/unified_diff.patch | cut -d' ' -f1)

ssh -o BatchMode=yes "$PHONE" "$PM.unapplyPatch ada-home-sailfish > /dev/null; mkdir -p ~/ada-home-sailfish"
scp -q -o BatchMode=yes patch/ada-home-sailfish/* "$PHONE:ada-home-sailfish/"

# lipstick's start time before the restart, to see when it is back
before=$(ssh -o BatchMode=yes "$PHONE" "systemctl --user show lipstick -p ActiveEnterTimestampMonotonic")

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
# Wait until lipstick runs again with a new start time (up to 60 s)
echo "Waiting for lipstick to restart..."
ssh -o BatchMode=yes "$PHONE" "
before='$before'
for i in \$(seq 60); do
    sleep 1
    now=\$(systemctl --user show lipstick -p ActiveEnterTimestampMonotonic -p ActiveState)
    case \"\$now\" in *ActiveState=active*) ;; *) continue ;; esac
    [ \"\$(echo \"\$now\" | grep Monotonic)\" != \"\$before\" ] && break
done
sleep 3
"
ssh -o BatchMode=yes "$PHONE" "
systemctl --user show lipstick -p ActiveState -p ActiveEnterTimestamp -p NRestarts | tr '\n' ' '; echo
echo \"patch applied: \$($PM.isPatchApplied ada-home-sailfish)  Patchmanager failure: \$($PM.getFailure)\"
echo \"lipstick crashes in log: \$(grep -c 'lipstick.service: Main process exited, code=killed' /run/ada-home-dev/journal.txt)\"
echo 'QML warnings:'
grep -E 'lipstick\[' /run/ada-home-dev/journal.txt | grep -E '\[W\].*qml|unavailable|is not a type|Error' \
    | grep -v 'of object LauncherFolderItem\|nemothumbnail' | sed 's/.*lipstick\[[0-9]*\]: //' | cut -c1-250 | sort | uniq -c | head -20
"
