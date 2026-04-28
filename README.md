# WhiteSur-kde-flake

Nix flake packaging of [vinceliuice/WhiteSur-kde](https://github.com/vinceliuice/WhiteSur-kde) — the macOS-like theme bundle for KDE Plasma — with a place to drop Plasma 6 fix patches that upstream hasn't merged yet.

Ships every variant the theme contains : `WhiteSur`, `WhiteSur-alt`, `WhiteSur-dark` for the Plasma desktop theme and look-and-feel, `WhiteSur` / `WhiteSur-opaque` / `WhiteSur-sharp` Aurorae window decorations, the `WhiteSur` / `WhiteSur-opaque` Kvantum themes, all the colour schemes, the WhiteSurPanel layout template, the splitdigitalclock plasmoid, the wallpapers, and the Plasma-6.2 SDDM theme.

## Why

Upstream is mollement-maintained for Plasma 6 — at the time of writing the latest commit is months old, and several P6 issues have been open for a year+ ([#124](https://github.com/vinceliuice/WhiteSur-kde/issues/124), [#107](https://github.com/vinceliuice/WhiteSur-kde/issues/107), …). This flake :

- pins a known commit so a bad upstream change can't break a rebuild ;
- applies any `*.patch` under `./patches/` automatically (one fix per patch, alpha-ordered) ;
- exposes the result as a regular Nix package and a NixOS module.

## Usage

In your system flake :

```nix
{
  inputs.whitesur-kde.url = "github:s-celles/WhiteSur-kde-flake";

  outputs = { self, nixpkgs, whitesur-kde, ... }: {
    nixosConfigurations.WULFENIX = nixpkgs.lib.nixosSystem {
      modules = [
        whitesur-kde.nixosModules.default
        # …rest of your config
      ];
    };
  };
}
```

After `nixos-rebuild switch`, the theme files land under `/run/current-system/sw/share/{aurorae,plasma,Kvantum,wallpapers,sddm,color-schemes}/` and KCM modules pick them up. Activate the variant you want via :

```bash
plasma-apply-lookandfeel -a com.github.vinceliuice.WhiteSur-dark
plasma-apply-colorscheme WhiteSurDark
plasma-apply-desktoptheme WhiteSur-dark
kvantummanager --set WhiteSur
```

## Adding a patch

See [`patches/README.md`](patches/README.md). Short version : `git format-patch -1` against an upstream checkout, drop the resulting `.patch` in `patches/`, rebuild.

## Bumping upstream

Edit the `whitesur-kde-src.url` SHA in [`flake.nix`](flake.nix), run `nix flake update` to refresh the lock, rebuild. Existing patches are re-applied ; a build failure means a patch needs rebasing.

## License

Theme content : GPL-3.0-or-later (upstream WhiteSur-kde). Flake plumbing : same, by extension.
