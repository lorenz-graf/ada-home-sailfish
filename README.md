# Ada Home

A Patchmanager patch for **Sailfish OS** that turns the homescreen into a minimal, text-only home:

| | Stock Sailfish | Ada Home |
|---|---|---|
| Home (after leaving an app, unlocking, the home key) | Covers of running apps | Big clock and date, up to 8 apps as plain text |
| Second page (swipe in from the left or right edge) | Events: notifications, weather, calendar | Weather and calendar, then the covers of running apps (dimmed background) |
| Notifications | Events page | Top menu (pull down from the top), below the toggles |

Tested on the Jolla Phone (2026), Sailfish OS 5.2.0.22.

## Home

- **Clock and date:** tap opens the clock or calendar app. Long-press chooses which app that is ("Default" = the stock Clock / Calendar).
- **Apps:** 0–8 slots (default 4) shown as text. An empty slot shows a grey "App". Long-press a slot to choose its app from a searchable list (ignores case, accents and separators; Enter picks the first match). To rename a slot, long-press it, type the new name into the search field and tap **Rename**.
- **Long-press on empty space:** Settings. While Settings is open, the clock and date stay visible so changes show right away.
- **Swipe left or right** (not from the screen edge): opens a configurable app (defaults: right to left = Calculator, left to right = Contacts; "Off" switches to the second page). Swipes from the edge still switch pages as before.
- **Double tap on empty space:** turns the display off and locks, like the stock Top menu lock button (off by default).
- The status bar clock is hidden on Home only.

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
| Appearance | Text size | 1.0 | `text_scale` |
| | Bold font | Off | `bold` |
| | Text shadow (Off / Small / Medium / Large) | Small | `shadow_level` |
| | Text color (Ambience / Ambience highlight / White / Black) | Ambience | `text_color` |
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

Ada Home is a local Patchmanager patch (not in the Patchmanager web catalog). Patchmanager must be installed.

1. Copy `patch/ada-home-sailfish/` to the phone, e.g. to `~/ada-home-sailfish/`.
2. Install it as root:
   ```
   devel-su sh -c 'cp -r ~defaultuser/ada-home-sailfish /usr/share/patchmanager/patches/ && chown -R root:root /usr/share/patchmanager/patches/ada-home-sailfish'
   ```
3. Settings → Patchmanager: activate **Ada Home**, then pull down → **Restart preloaded services** (this restarts the homescreen and closes open apps).

If "Activate enabled patches when booting" is off in Patchmanager (the default), the patch has to be activated again after every reboot.

### Conflicts

Patches that change the same homescreen files can't be active at the same time. Known ones: `status-bar-compact-cellular` (`layers/HomeLayer.qml`, `compositor.qml`) and `sfos-patch-launcher-list` (only if Ada Home ever touches the App Grid). `homescreen-cover-icons` (`switcher/SwitcherItem.qml`) works alongside.

## Undo

- **Deactivate:** Settings → Patchmanager → Ada Home → deactivate, then **Restart preloaded services**. The homescreen is stock again.
- **If the homescreen is broken:** hold the power key to restart. With "Activate enabled patches when booting" off, the phone comes up with the stock homescreen. Patchmanager also turns all patches off by itself when lipstick reports a QML type error or its service fails.
- **Remove the patch:** deactivate it, then `devel-su rm -rf /usr/share/patchmanager/patches/ada-home-sailfish`
- **Remove the settings:** `dconf reset -f /desktop/lipstick-jolla-home/ada_home/`

## How it works

Patchmanager serves patched copies of the homescreen's QML (`/usr/share/lipstick-jolla-home-qt5/`) to lipstick; nothing on disk is changed. The patch:

- changes where navigation lands (`compositor.qml`, `layers/HomeLayer.qml`): the Events page becomes Home, the covers become the second page, and the wallpaper dimming follows the covers page
- adds the Home page (`eventsview/HomeFavourites.qml`, `HomeAppPicker.qml`, `HomeSettings*.qml`, `HomeTextShadow.qml`) to the Events window (`eventsview/EventsWindow.qml`); the stock Events list stays for the lock screen
- adds weather and calendar above the covers (`switcher/CoversWidgets.qml`, `switcher/Switcher.qml`)
- adds the notifications to the Top menu (`topmenu/TopMenuNotifications.qml`, `topmenu/TopMenu.qml`, `notifications/*`) and a Home-only switch for the status bar clock (`statusarea/*`)

## Build

The patch is built from the difference between the stock files and the changed files:

- `stock/`: the unmodified `/usr/share/lipstick-jolla-home-qt5/` from the phone, read-only. Not in git (Jolla's code is proprietary; only the diff is published).
- `work/`: the same tree with the changes. Not in git; recreate it from the patch with `cp -a stock work && patch -p1 -d work < patch/ada-home-sailfish/unified_diff.patch`.

```
./build-patch.sh   # -> patch/ada-home-sailfish/{patch.json,unified_diff.patch}
```

Before writing the patch it runs three checks, the last two over SSH on the phone (`PHONE=user@host`, see the script for the default):

1. `qmllint-qt5` on every changed QML file (syntax).
2. `check-imports.py`: asks the phone which installed QML module provides each type a file uses, and fails on a missing import. qmllint doesn't catch these; lipstick only reports "X is not a type" when it starts.
3. `check-compile.py`: creates each changed file with `qmlscene` on the phone (lipstick's own module replaced by a stub) to catch compile errors such as overriding a built-in property.

After a Sailfish OS update, fetch `stock/` again from the phone, rebuild and check that the patch still applies.

### Development on the phone

`deploy.sh` builds the patch and puts it live in one step (deactivate, install, activate, restart the homescreen, report crashes and QML warnings) without the `devel-su` password. It needs the development helper in [`dev-helper/`](dev-helper/): copy that folder to the phone as `~/ada-home-dev/` and install it once as root:

```
devel-su sh -c 'sh ~defaultuser/ada-home-dev/ada-home-dev setup && /usr/libexec/ada-home-dev/ada-home-dev enable 4'
```

`enable <hours>` (1–24) writes a polkit rule with an expiry time that lets `defaultuser`, also over SSH, start exactly two units: one copies the staged patch from `~/ada-home-sailfish/` into Patchmanager (it refuses any patch that touches files outside `/usr/share/lipstick-jolla-home-qt5/` or uses `..` in a path), the other records the journal to `/run/ada-home-dev/journal.txt`. `disable` removes the rule early, `uninstall` removes the helper completely.

## License

BSD-3-Clause, see [LICENSE](LICENSE): use, modify and redistribute freely (also commercially), keep the copyright notice, and don't use the authors' names to promote derived products.

- Everything written for this project (the new QML files, the changes in the patch, scripts, dev helper, docs): © 2026 Lorenz Graf and contributors
- The patch modifies Jolla's homescreen QML (`lipstick-jolla-home-qt5`), which is proprietary and not covered by this license; the diff contains context lines from those files. Not affiliated with or endorsed by Jolla
