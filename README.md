# Ada Home

A Patchmanager patch for **Sailfish OS** that turns the homescreen into a minimal, text-only home:

| | Stock Sailfish | Ada Home |
|---|---|---|
| Home (after leaving an app, unlocking, the home key) | Covers of running apps | Big clock and date, up to 8 apps as plain text |
| Second page (swipe in from the left or right edge) | Events: notifications, weather, calendar | Weather, active Alarms, Calendar and Running apps (section headers, small covers 3 per row, dimmed background) |
| Notifications | Events page | Top menu (pull down from the top), below the toggles |

Tested on the Jolla Phone (2026), Sailfish OS 5.2.0.22.

## Home

- **Clock and date:** tap opens the clock or calendar app. Long-press chooses which app that is ("Default" = the stock Clock / Calendar).
- **Apps:** 0–8 slots (default 4) shown as text. An empty slot shows a grey "App". Long-press a slot to choose its app from a searchable list (ignores case, accents and separators; Enter picks the first match). To rename a slot, long-press it, type the new name into the search field and tap **Rename**.
- **Long-press on empty space:** Settings. While Settings is open, the clock and date stay visible so changes show right away.
- **Swipe left or right** (not from the screen edge, also when it starts on an app or the clock): opens a configurable app (defaults: right to left = Calculator, left to right = Contacts; "Off" switches to the second page). Swipes from the edge still switch pages as before.
- **Double tap on empty space:** turns the display off and locks, like the stock Top menu lock button (off by default).
- **Loading screen:** while an app starts, its icon, name and a spinner show until the app's window appears (tap to hide; hides by itself after 10 s).
- On Home the status bar uses the Home text colour and hides its clock (Home has its own). Optionally it stays hidden until you touch Home. Elsewhere it stays as it is.

## Second page

Swipe in from the left or right screen edge. Each section has a section header and only shows when it has something to show:

- **Weather** (the header is optional: Settings → Layout → Weather header)
- **Alarms:** all alarms that are switched on, with time and name. Tap opens the clock app chosen for the Home clock. This list also shows when the weather widget is off
- **Calendar**
- **Running apps:** the covers, small and 3 per row by default (Settings → Layout → Always small covers; off = stock behaviour). Long-press a cover for **Close all**, as in stock Sailfish

The background is dimmed on this page, not on Home.

## Settings

All values are stored in dconf under `/desktop/lipstick-jolla-home/ada_home/`.

| Section | Setting | Default | Key |
|---|---|---|---|
| Home screen | Apps on home screen | 4 | `slot_count` |
| | Show date time (Off / On / Date only) | On | `date_time` |
| | App alignment (Left / Center / Right) | Left | `alignment` |
| Layout | Apps at the bottom | Off | `bottom` |
| | Side margin, Top margin, Bottom margin (steps of one standard spacing) | 0 | `margin_side`, `margin_top`, `margin_bottom` |
| | Clock to apps distance (Auto = centred) | Auto | `apps_gap` |
| | Always small covers (running apps 3 per row) | On | `small_covers` |
| | Weather header (on the second page) | On | `weather_header` |
| Appearance | Text size | 1.0 | `text_scale` |
| | Bold font | Off | `bold` |
| | Text shadow (Off / Small / Medium / Large) | Small | `shadow_level` |
| | Text color (Ambience / Ambience highlight / White / Black) | Ambience | `text_color` |
| | Hide status bar (on Home; touching Home shows it for a moment) | Off | `hide_status_bar` |
| | Hide alarm bell (in the status bar; alarms stay listed on the second page) | Off | `hide_alarm_bell` |
| | Auto show keyboard (in the app list) | On | `auto_keyboard` |
| Gestures | Swipe left app, Swipe right app | Calculator, Contacts | `swipe_left_app`, `swipe_right_app` |
| | Double tap to lock | Off | `double_tap_lock` |

Chosen apps are stored as `.desktop` file paths: `slot_apps`, `slot_names` (renamed labels, empty = the app's own name), `clock_app`, `date_app`.

"Ambience" colours come from the current ambience, which already picks them to contrast with its background. The shadow adapts too: dark behind light text, a light glow behind dark text.

## The Top menu

- A **Notifications** section below the toggles, with **Clear all**. Notifications can be swiped away directly (stock Sailfish needs a long-press first). Hidden while the device is locked.
- The big lock button at the top is gone (the power key locks). Long-pressing the power key still shows power off / reboot there.
- The gear (Organize, Top menu settings) sits at the right end of the Notifications line instead of its own row.

## Install

Ada Home is a Patchmanager patch packaged as an RPM (it's not in the Patchmanager web catalog). Patchmanager 3 must be installed.

1. Download `ada-home-sailfish-<version>-<release>.noarch.rpm` from the [releases](https://github.com/lorenz-graf/ada-home-sailfish/releases) on the phone and tap it in the file manager to install it (with developer mode on), or install it as root:
   ```
   devel-su pkcon install-local ada-home-sailfish-<version>-<release>.noarch.rpm
   ```
2. Settings → Patchmanager: activate **Ada Home**, then pull down → **Restart preloaded services** (this restarts the homescreen and closes open apps).

**Updating:** install the new RPM the same way. It deactivates Ada Home before replacing the files, so activate it again afterwards (step 2). Your settings stay.

If "Activate enabled patches when booting" is off in Patchmanager (the default), the patch has to be activated again after every reboot.

<details>
<summary>Without the RPM (copy the patch by hand)</summary>

1. Copy `patch/ada-home-sailfish/` to the phone, e.g. to `~/ada-home-sailfish/`.
2. Install it as root:
   ```
   devel-su sh -c 'cp -r ~defaultuser/ada-home-sailfish /usr/share/patchmanager/patches/ && chown -R root:root /usr/share/patchmanager/patches/ada-home-sailfish'
   ```
3. Activate it as in step 2 above.

Remove it with `devel-su rm -rf /usr/share/patchmanager/patches/ada-home-sailfish` after deactivating it. Installing the RPM later replaces a hand-copied patch (it deactivates it first).
</details>

### Other patches

Patchmanager applies the active patches one after another. Two patches can change the same file as long as they change different lines. If they change the same lines, the one applied later fails to activate.

**Active together with Ada Home on my phone:**

| Patch | Version | What it changes |
|---|---|---|
| Launcher Search List (`sfos-patch-launcher-list`) | 0.2.6 | App Grid |
| Compact Battery (`sfos-patch-compact-battery`) | 0.1.2 | Battery icon in the status bar |
| Status Bar in apps + Compact Cellular (`status-bar-compact-cellular`) | 0.2.0-local1 | Status bar; also `compositor.qml` and `HomeLayer.qml`, but other lines than Ada Home. A local merge of the two patches below, not in the catalog |

**Also checked:**

- **Status Bar in apps** (`sfos-patch-status-bar` 0.2.0): used with Ada Home on the phone, works.
- **Compact Cellular Indicator** (`compact-cellular-indicator` 1.0.0) and **Homescreen Running Apps Cover Icons** (`homescreen-cover-icons` 0.2.0): dry run only (both apply cleanly with Ada Home, in both orders), not used on the phone.
- **Status Bar in apps** and **Compact Cellular Indicator** can't be active together, with or without Ada Home: with Status Bar in apps applied, Compact Cellular Indicator fails in `StatusArea.qml`. That's why I use the merged version above.

**What to expect from other patches** (not tested unless listed above):

- **Status bar patches** should work: Ada Home changes no status bar file. On Home it only sets the status bar colour and hides the status bar clock (and optionally the alarm bell) at runtime. A patch that replaces the clock or the alarm icon with its own item may stay visible on Home.
- **App Grid, Silica and app patches** don't touch the files Ada Home changes.
- **Events view patches:** Home replaces the Events list (it stays only on the lock screen), so anything a patch adds to the Events view won't show on Home.
- **Cover patches:** changes to the cover itself (`SwitcherItem.qml`) should work. Patches that change the covers page layout (`Switcher.qml`) may conflict.
- **Notification and Top menu patches** will likely conflict: Ada Home changes `TopMenu.qml`, `TopMenuNotifications.qml`, `NotificationListView.qml` and `NotificationStandardGroupItem.qml`.
- **Patches that change `compositor.qml` or `HomeLayer.qml`** (page switching, edge swipes) may conflict, depending on the lines.

<details>
<summary>Stock files Ada Home changes, and how to check another patch</summary>

All under `/usr/share/lipstick-jolla-home-qt5/`: `compositor.qml`, `layers/HomeLayer.qml`, `eventsview/EventsWindow.qml`, `switcher/Switcher.qml`, `notifications/NotificationListView.qml`, `notifications/NotificationStandardGroupItem.qml`, `topmenu/TopMenu.qml`, `topmenu/TopMenuNotifications.qml`. The other files in the patch are new.

Files another patch changes: `grep '^+++ ' /usr/share/patchmanager/patches/<patch>/unified_diff.patch`. With Ada Home active and the other patch not active, a dry run shows whether the other patch still applies on top (nothing is changed):

```
cd / && patch -p1 --dry-run -N < /usr/share/patchmanager/patches/<patch>/unified_diff.patch
```

`FAILED` means the two patches change the same lines.
</details>

## Undo

- **Deactivate:** Settings → Patchmanager → Ada Home → deactivate, then **Restart preloaded services**. The homescreen is stock again.
- **If the homescreen is broken:** hold the power key to restart. With "Activate enabled patches when booting" off, the phone comes up with the stock homescreen. Patchmanager also turns all patches off by itself when lipstick reports a QML type error or its service fails.
- **Uninstall:** Settings → Patchmanager → long-press **Ada Home** → **Deactivate**, then long-press → **Remove** (Patchmanager removes the RPM; no password needed). Or as root: `devel-su pkcon remove ada-home-sailfish` (deactivates the patch first). The homescreen is stock after the next **Restart preloaded services** or reboot.
- **Remove the settings:** `dconf reset -f /desktop/lipstick-jolla-home/ada_home/`

## How it works

Patchmanager serves patched copies of the homescreen's QML (`/usr/share/lipstick-jolla-home-qt5/`) to lipstick; nothing on disk is changed. The patch:

- changes where navigation lands (`compositor.qml`, `layers/HomeLayer.qml`): the Events page becomes Home, the covers become the second page, and the wallpaper dimming follows the covers page
- adds the Home page (`eventsview/HomeFavourites.qml`, `HomeAppPicker.qml`, `HomeSettings*.qml`, `HomeTextShadow.qml`) to the Events window (`eventsview/EventsWindow.qml`); the stock Events list stays for the lock screen. The loading screen is part of the Home page and follows the covers page's own launch tracking
- adds weather, active alarms and calendar above the covers (`switcher/CoversWidgets.qml`, `switcher/CoversAlarms.qml`, `switcher/Switcher.qml`)
- adds the notifications to the Top menu (`topmenu/TopMenuNotifications.qml`, `topmenu/TopMenu.qml`, `notifications/*`)
- leaves the status bar files alone: the Home page sets the status bar's colour, hides its clock (and optionally the whole bar) while Home is shown, and optionally hides the alarm bell, all at runtime, so status bar patches still apply. If a patch rebuilds the status bar so the clock or the bell can't be found, they just stay visible. The lock screen has its own status bar and isn't changed

## Build

The patch is built from the difference between the stock files and the changed files:

- `stock/`: the unmodified `/usr/share/lipstick-jolla-home-qt5/` from the phone, read-only. Not in git (Jolla's code is proprietary; only the diff is published).
- `work/`: the same tree with the changes. Not in git; recreate it from the patch with `cp -a stock work && patch -p1 -d work < patch/ada-home-sailfish/unified_diff.patch`.

```
./build-patch.sh   # -> patch/ada-home-sailfish/{patch.json,unified_diff.patch}
./build-rpm.sh     # -> build/ada-home-sailfish-<version>-<release>.noarch.rpm
```

The version is `VERSION=` in `build-patch.sh` (written to `patch.json`), the RPM release is `Release:` in `rpm/ada-home-sailfish.spec`. `build-rpm.sh` packages the patch as it is in `patch/` and needs `rpmbuild` (Arch: `pacman -S rpm-tools`); it writes an rpm v4 package with a gzip payload, since Sailfish has rpm 4.16. The package's scriptlets deactivate the patch (`patchmanager -u`) before an update replaces its files and before an uninstall removes them, because Patchmanager reverses a patch with its diff.

Before writing the patch it runs three checks, the last two over SSH on the phone. The phone's address comes from `PHONE=user@host` or from a file `phone.conf` (one line, git-ignored):

1. `qmllint-qt5` on every changed QML file (syntax).
2. `check-imports.py`: asks the phone which installed QML module provides each type a file uses, and fails on a missing import. qmllint doesn't catch these; lipstick only reports "X is not a type" when it starts.
3. `check-compile.py`: creates each changed file with `qmlscene` on the phone (lipstick's own module replaced by a stub) to catch compile errors such as overriding a built-in property.

After a Sailfish OS update, fetch `stock/` again from the phone, rebuild and check that the patch still applies.

### Development on the phone

`deploy.sh` builds the patch and puts it live in one step (deactivate, install, activate, restart the homescreen, report crashes and QML warnings) without the `devel-su` password. It needs the development helper in [`dev-helper/`](dev-helper/): copy that folder to the phone as `~/ada-home-dev/` and install it once as root:

```
devel-su sh -c 'sh ~defaultuser/ada-home-dev/ada-home-dev setup && /usr/libexec/ada-home-dev/ada-home-dev enable 4'
```

After that, once per session (the window expires by itself; `deploy.sh` checks it before changing anything and says so when it has run out):

```
devel-su /usr/libexec/ada-home-dev/ada-home-dev enable 4
```

`enable <hours>` (1–24) writes a polkit rule with an expiry time that lets `defaultuser`, also over SSH, start exactly two units: one copies the staged patch from `~/ada-home-sailfish/` into Patchmanager (it refuses any patch that touches files outside `/usr/share/lipstick-jolla-home-qt5/` or uses `..` in a path), the other records the journal to `/run/ada-home-dev/journal.txt` (stops by itself after 3 hours, since `/run` is in RAM). `disable` removes the rule early, `uninstall` removes the helper completely.

## License

BSD-3-Clause, see [LICENSE](LICENSE): use, modify and redistribute freely (also commercially), keep the copyright notice, and don't use the authors' names to promote derived products.

- Everything written for this project (the new QML files, the changes in the patch, scripts, dev helper, docs): © 2026 Lorenz Graf and contributors
- The patch modifies Jolla's homescreen QML (`lipstick-jolla-home-qt5`), which is proprietary and not covered by this license; the diff contains context lines from those files. Not affiliated with or endorsed by Jolla
