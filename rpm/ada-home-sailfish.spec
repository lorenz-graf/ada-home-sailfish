# Ada Home for Sailfish OS, packaged as an RPM Patchmanager patch (see Patchmanager's
# README-Patch-Developers.md). Built by ../build-rpm.sh (noarch, only the patch files).
%global patchname ada-home-sailfish
%global patchdir %{_datadir}/patchmanager/patches/%{patchname}

Name:       ada-home-sailfish
Version:    %{ah_version}
Release:    1
Summary:    Minimal text homescreen (Patchmanager patch)
License:    BSD-3-Clause
URL:        https://github.com/lorenz-graf/ada-home-sailfish
BuildArch:  noarch
Requires:   patchmanager >= 3.0
Requires:   lipstick-jolla-home-qt5

%description
A Patchmanager patch for the Sailfish OS homescreen: big clock, apps as text and
swipe apps on Home, notifications in the Top menu, weather, calendar and running
apps on the second page.

After installing or updating, activate "Ada Home" in Settings > Patchmanager and
pull down > Restart preloaded services. Uninstalling deactivates the patch first.

# Patchmanager unapplies with the diff stored in the patch dir, so the patch must be
# deactivated before its files are replaced (update, or a hand-copied install) or
# removed. "patchmanager -u" asks the daemon over D-Bus and waits; for a patch that
# isn't active it does nothing. The homescreen keeps the patched QML until lipstick
# restarts (Patchmanager's "Restart preloaded services" or a reboot).
%pre
export NO_PM_PRELOAD=1
if [ -x /usr/sbin/patchmanager ] && [ -d %{patchdir} ]; then
    /usr/sbin/patchmanager -u %{patchname} >/dev/null 2>&1 || :
fi
exit 0

%preun
export NO_PM_PRELOAD=1
if [ "$1" -eq 0 ] && [ -x /usr/sbin/patchmanager ]; then
    /usr/sbin/patchmanager -u %{patchname} >/dev/null 2>&1 || :
fi
exit 0

%prep
cp %{_sourcedir}/LICENSE .

%build

%install
install -D -m 0644 %{_sourcedir}/patch.json         %{buildroot}%{patchdir}/patch.json
install -D -m 0644 %{_sourcedir}/unified_diff.patch %{buildroot}%{patchdir}/unified_diff.patch

%files
%license LICENSE
%dir %{patchdir}
%{patchdir}/patch.json
%{patchdir}/unified_diff.patch
