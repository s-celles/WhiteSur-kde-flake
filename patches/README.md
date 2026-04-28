# Patches

Drop `*.patch` files in this directory ; the build picks them up
alphabetically and applies them to the upstream source via
`stdenvNoCC.mkDerivation`'s `patches` attribute.

## Naming

`NN-short-summary.patch` — `NN` is a 2-digit ordinal so the order of
application is explicit (later patches assume earlier ones landed). One
fix per patch ; the ordinal lets you reorder by renaming.

## Generating

```bash
# In a checkout of upstream WhiteSur-kde, after committing your fix :
git format-patch -1 HEAD --stdout > /path/to/this/patches/NN-fix-foo.patch
```

Or hand-write a unified diff against the pinned tree — what matters is
that `patch -p1` applies cleanly from the source root.

## Tracked Plasma 6 issues

Open issues from
[vinceliuice/WhiteSur-kde](https://github.com/vinceliuice/WhiteSur-kde/issues)
worth a patch :

- [#124](https://github.com/vinceliuice/WhiteSur-kde/issues/124) — global theme breaks Plasma 6 desktop after logout
- [#119](https://github.com/vinceliuice/WhiteSur-kde/issues/119) — blurry title font in WhiteSur Light
- [#120](https://github.com/vinceliuice/WhiteSur-kde/issues/120) — inconsistent panel edges (dark variant)
- [#114](https://github.com/vinceliuice/WhiteSur-kde/issues/114) — GTK apps don't pick up window decorations
- [#113](https://github.com/vinceliuice/WhiteSur-kde/issues/113) — overlapping search bar / no global menu
- [#107](https://github.com/vinceliuice/WhiteSur-kde/issues/107) — black backdrop on logout / shutdown / restart confirm dialogs
- [#102](https://github.com/vinceliuice/WhiteSur-kde/issues/102) — menu doesn't work on Plasma 6.0
- [#100](https://github.com/vinceliuice/WhiteSur-kde/issues/100) — icon issues after recent plasma theme update

The flake user is free to skip any patch by deleting the file before
build, or pin to a specific upstream commit via the `whitesur-kde-src`
flake input.
