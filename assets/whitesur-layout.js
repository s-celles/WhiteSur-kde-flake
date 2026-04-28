// WhiteSur top panel + dock — patched to mirror macOS menu-bar behaviour.
//
// Differences from upstream :
//   - `org.kde.plasma.kickoff` (the application launcher button) is replaced
//     by `org.scelles.systemmenu` — a small dropdown of system actions
//     (About / Settings / Force Quit / Lock / Sleep / Restart / Shut Down
//     / Log Out), the equivalent of the macOS Apple menu. Clicking it
//     does NOT browse apps ; that's what KRunner (Alt+Space) and the
//     application dashboard kicker on the dock are for.
//   - `org.scelles.appname` is inserted before `org.kde.plasma.appmenu`.
//     It shows the focused window's application name in bold (Konsole,
//     Brave, Dolphin…) and on click exposes the macOS-style window
//     actions : Hide / Hide Others / Show All / Quit. The upstream
//     appmenu then renders File / Edit / View / … to its right, so the
//     menu bar reads :
//       [systemmenu] [bold app name] | File Edit View …
//
// Both plasmoids are shipped by securix-bureautix's echo-pom-style.nix
// (they live under /run/current-system/sw/share/plasma/plasmoids/), so
// any Plasma session that has that module imported can reference them
// regardless of which LAF is active.

var panel = new Panel
var panelScreen = panel.screen

// No need to set panel.location as ShellCorona::addPanel will automatically pick one available edge

// For an Icons-Only Task Manager on the bottom, *3 is too much, *2 is too little
// Round down to next highest even number since the Panel size widget only displays
// even numbers
panel.height = 2 * Math.floor(gridUnit * 2.5 / 2)
panel.location = "top"

// Restrict horizontal panel to a maximum size of a 21:9 monitor
const maximumAspectRatio = 21/9;
if (panel.formFactor === "horizontal") {
    const geo = screenGeometry(panelScreen);
    const maximumWidth = Math.ceil(geo.height * maximumAspectRatio);

    if (geo.width > maximumWidth) {
        panel.alignment = "center";
        panel.minimumLength = maximumWidth;
        panel.maximumLength = maximumWidth;
    }
}

// macOS-style menu bar : system menu (Apple equivalent), bold active
// app name with window actions, then the global menu (File/Edit/…).
//
// The systemmenu icon is overridden to `start-here`, the standard
// distributor-icon name. WhiteSur-icon-theme-flake patches that name
// to a NixOS snowflake in every variant, with the right colour per
// theme :
//   WhiteSur, WhiteSur-light → dark-fill snowflake (#363636), reads on light
//   WhiteSur-dark            → white-fill snowflake (#FFFFFF), reads on dark
// This way the icon auto-adapts when the user toggles between WhiteSur
// variants — no need to writeConfig a different value per variant.
//
// We don't use pomstyle-launcher-nixos (the hicolor copy shipped by
// echo-pom-style.nix) because hicolor only ships one fill — the
// snowflake would stay readable on the variant matching that fill and
// invisible on the opposite. The icon-theme-resolved start-here gives
// us the per-variant tinting for free.
var sysmenu = panel.addWidget("org.scelles.systemmenu")
sysmenu.currentConfigGroup = ["General"]
sysmenu.writeConfig("iconName", "start-here")
sysmenu.reloadConfig()
panel.addWidget("org.scelles.appname")

var bpanel = new Panel
bpanel.location = "bottom"
bpanel.lengthMode = "fit"
bpanel.hiding = "dodgewindows"
bpanel.height = 64

let taskBar = bpanel.addWidget("org.kde.plasma.icontasks")
taskBar.currentConfigGroup = ["General"]
taskBar.writeConfig("launchers", [
    "preferred://filemanager",
    "preferred://browser",
    "applications:org.kde.konsole.desktop",
    "applications:systemsettings.desktop",
])
// Running-task display : without these, Plasma's defaults can hide
// running apps that aren't pinned launchers (per-desktop filter, per-
// activity filter) or fold them under a single icon (groupingStrategy
// 1 or 2). The macOS dock shows every open app inline regardless of
// desktop/activity, so we mirror that.
taskBar.writeConfig("showOnlyCurrentDesktop", false)
taskBar.writeConfig("showOnlyCurrentActivity", false)
taskBar.writeConfig("groupingStrategy", 0)
// Audio indicator (small speaker icon under apps that play sound),
// matches macOS Sonoma's now-playing dot. The "running" indicator
// (small bar / dot under each open app) is part of the icontasks
// visual style and doesn't need a separate config key.
taskBar.writeConfig("indicateAudioStreams", true)
taskBar.reloadConfig()
panel.addWidget("org.kde.plasma.appmenu")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.showdesktop")
