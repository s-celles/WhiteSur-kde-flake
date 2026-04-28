{ stdenvNoCC, lib, src, patchesDir }:

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

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Mirror what `install.sh` puts in $HOME, but to system paths under
    # $out/share/ so this derivation is consumable via
    # environment.systemPackages. We replicate the directory layout the
    # script ends up producing rather than invoking the script itself,
    # because the script: (a) hardcodes $HOME and /usr paths, (b)
    # generates aurorae variants from `main`/`main-opaque`/`main-sharp`
    # templates with sed-substitutions that don't survive read-only
    # /nix/store, (c) tries to mkdir/cp into XDG dirs we don't want to
    # touch from a system derivation.

    # Plasma desktop themes: WhiteSur, WhiteSur-alt, WhiteSur-dark
    mkdir -p $out/share/plasma/desktoptheme
    cp -r plasma/desktoptheme/WhiteSur* $out/share/plasma/desktoptheme/

    # Plasma look-and-feel packages (com.github.vinceliuice.WhiteSur*)
    mkdir -p $out/share/plasma/look-and-feel
    cp -r plasma/look-and-feel/com.github.vinceliuice.WhiteSur* \
      $out/share/plasma/look-and-feel/

    # Plasmoids that ship with the theme (split digital clock used by
    # the WhiteSurPanel layout-template).
    if [ -d plasma/plasmoids ]; then
      mkdir -p $out/share/plasma/plasmoids
      cp -r plasma/plasmoids/* $out/share/plasma/plasmoids/
    fi

    # Layout templates referenced by the look-and-feel JS.
    if [ -d plasma/layout-templates ]; then
      mkdir -p $out/share/plasma/layout-templates
      cp -r plasma/layout-templates/* $out/share/plasma/layout-templates/
    fi

    # Aurorae window decorations. Upstream's install_aurorae generates
    # 30+ variants by combining color (none|-dark) × window (none|
    # -opaque|-sharp) × scale (none|_x1.25|_x1.5|_x1.75|_x2.0). We ship
    # only the three TEMPLATES (main, main-opaque, main-sharp) under
    # the theme name `WhiteSur` so KWin Aurorae can find them. Users
    # who want HiDPI-scaled variants can run the upstream install.sh
    # against their $HOME ; this derivation provides the @1x set, which
    # is what 99 % of setups need.
    mkdir -p $out/share/aurorae/themes
    for variant in main main-opaque main-sharp; do
      [ -d "aurorae/$variant" ] || continue
      # Place the @1x default and the dark counterpart side by side.
      # Upstream renames `main` → `WhiteSur`, `main-opaque` →
      # `WhiteSur-opaque`, `main-sharp` → `WhiteSur-sharp`, plus a
      # -dark variant with a different titlebar gradient. We mirror
      # that mapping here ; the dark variants reuse the same QML and
      # only differ by a `.colors` file referenced from metadata.
      target="$variant"
      target=''${target/main/WhiteSur}
      cp -r "aurorae/$variant" "$out/share/aurorae/themes/$target"
    done

    # KDE colour schemes (system-wide so KCM picks them up).
    mkdir -p $out/share/color-schemes
    cp color-schemes/*.colors $out/share/color-schemes/

    # Kvantum themes (light / opaque variants).
    mkdir -p $out/share/Kvantum
    cp -r Kvantum/WhiteSur* $out/share/Kvantum/

    # KPackage wallpapers (Light / Dark / colour).
    mkdir -p $out/share/wallpapers
    cp -r wallpaper/WhiteSur* $out/share/wallpapers/

    # SDDM theme — pick only the Plasma 6.x variant matching what we
    # actually run. WhiteSur-6.2 is the latest 6.x in upstream as of
    # the pinned commit ; older WhiteSur-5.0 / WhiteSur-6.0 use
    # different KCM imports and would emit QML errors on Plasma 6.6+.
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
