{ stdenvNoCC, lib, bash, coreutils, gnused, src, patchesDir }:

let
  # Apply every *.patch under ./patches/ in alpha order. Files at the
  # top level of patchesDir count ; subdirectories are ignored so the
  # tree can hold notes / READMEs / staging areas without surprising
  # the build.
  patchFiles = builtins.attrNames (
    lib.filterAttrs
      (name: type: type == "regular" && lib.hasSuffix ".patch" name)
      (builtins.readDir patchesDir)
  );
in
stdenvNoCC.mkDerivation {
  pname = "whitesur-kde";
  # The upstream repo has no tags ; we version-stamp by the short SHA
  # of the pinned commit (see flake.nix `whitesur-kde-src.url`).
  version = "1e4d960";

  inherit src;
  patches = map (name: patchesDir + "/${name}") patchFiles;

  nativeBuildInputs = [ bash coreutils gnused ];

  dontConfigure = true;
  dontBuild = true;

  # Replace upstream's Apple-logo `start.svg` (the Plasma desktoptheme
  # kicker icon used by org.kde.plasma.kickoff and friends) with the
  # NixOS snowflake from ./assets/. Same `fill="currentColor"` contract,
  # so KDE's panel theme keeps tinting it in line with light/dark mode.
  # Override BOTH copies upstream ships : `icons/` (the canonical one)
  # and `icons-old/` (kept for backwards-compat). Each desktop theme
  # variant (WhiteSur, WhiteSur-alt, WhiteSur-dark) inherits from this
  # shared `icons/` dir via the desktoptheme fallback chain — no need
  # to override the per-variant copies.
  postPatch = ''
    cp ${./assets/start-nixos.svg} plasma/desktoptheme/icons/start.svg
    if [ -f plasma/desktoptheme/icons-old/start.svg ]; then
      cp ${./assets/start-nixos.svg} plasma/desktoptheme/icons-old/start.svg
    fi
  '';

  installPhase = ''
    runHook preInstall

    # Run upstream's install.sh in the sandbox with HOME pointing at
    # $out, so its non-root branch puts everything under $out/.local/
    # share and $out/.config. We then relocate to the standard system
    # paths $out/share/{aurorae,plasma,Kvantum,wallpapers,color-schemes}/.
    #
    # Why we run the script rather than copy by hand : install.sh's
    # install_aurorae function generates 10+ variants from the three
    # `main`/`main-opaque`/`main-sharp` templates by sed-substituting
    # placeholders for color (none|-dark) and HiDPI scale (1.0|1.25|
    # 1.5|1.75|2.0). Reproducing those substitutions in shell here
    # would be a big chunk of duplicated logic that drifts every time
    # upstream tweaks them ; just running the script keeps us in sync.
    export HOME=$PWD/fake-home
    mkdir -p "$HOME"
    # `name` is already set by stdenv to "$pname-$version" in the build
    # environment ; install.sh reads ''${name:-''${THEME_NAME}} and would
    # use that derivation name as the theme name (cp/sed targets like
    # `whitesur-kde-1e4d960-dark_x1.5` instead of `WhiteSur-dark_x1.5`).
    # Unset it so install.sh falls back to its hardcoded THEME_NAME.
    unset name
    bash install.sh

    # Relocate user-side install paths to system-side ones. install.sh
    # writes Kvantum to $HOME/.config/Kvantum and the rest to
    # $HOME/.local/share/<group>/, so we move both into $out/share/.
    mkdir -p $out/share
    if [ -d "$HOME/.local/share/aurorae" ]; then
      mv "$HOME/.local/share/aurorae" $out/share/aurorae
    fi
    if [ -d "$HOME/.local/share/color-schemes" ]; then
      mv "$HOME/.local/share/color-schemes" $out/share/color-schemes
    fi
    if [ -d "$HOME/.local/share/plasma" ]; then
      mv "$HOME/.local/share/plasma" $out/share/plasma
    fi
    if [ -d "$HOME/.local/share/wallpapers" ]; then
      mv "$HOME/.local/share/wallpapers" $out/share/wallpapers
    fi
    if [ -d "$HOME/.config/Kvantum" ]; then
      mv "$HOME/.config/Kvantum" $out/share/Kvantum
    fi

    # Layout templates and plasmoids — install.sh doesn't touch these
    # but they ship with the upstream tree and the LAF layout JS
    # references them. Copy the bare directories from the source.
    if [ -d plasma/plasmoids ]; then
      mkdir -p $out/share/plasma/plasmoids
      cp -r plasma/plasmoids/* $out/share/plasma/plasmoids/
    fi
    if [ -d plasma/layout-templates ]; then
      mkdir -p $out/share/plasma/layout-templates
      cp -r plasma/layout-templates/* $out/share/plasma/layout-templates/
    fi

    # SDDM theme — install.sh in the repo root doesn't handle SDDM
    # (sddm/install.sh does, but we'd rather pin the Plasma 6.2 variant
    # explicitly). Older WhiteSur-5.0 / WhiteSur-6.0 use different
    # KCM imports that emit QML errors on Plasma 6.6+, so we ship only
    # 6.2 under the canonical name `WhiteSur`.
    if [ -d sddm/WhiteSur-6.2 ]; then
      mkdir -p $out/share/sddm/themes
      cp -r sddm/WhiteSur-6.2 $out/share/sddm/themes/WhiteSur
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "WhiteSur (macOS-like) theme bundle for KDE Plasma 6 — Aurorae, Plasma desktop theme, Kvantum, look-and-feel, color schemes, wallpapers, SDDM";
    homepage = "https://github.com/vinceliuice/WhiteSur-kde";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
