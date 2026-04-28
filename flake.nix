{
  description = "WhiteSur-kde theme bundle, packaged as a Nix flake with patches for Plasma 6 issues";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pinned upstream commit. Bumping here is the only entry point —
    # locally-applied patches in ./patches/ rebase on top of whatever
    # tree this commit points to. Track upstream master cautiously :
    # vinceliuice/WhiteSur-kde merges Plasma 6 PRs slowly, and a fresh
    # commit can re-introduce bugs we patched out (see ./patches/README).
    whitesur-kde-src = {
      url = "github:vinceliuice/WhiteSur-kde/1e4d960945572d05a3d96bec5253dd83971239f2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, whitesur-kde-src }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems
        (system: f system (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (system: pkgs: {
        whitesur-kde = pkgs.callPackage ./package.nix {
          src = whitesur-kde-src;
          patchesDir = ./patches;
        };
        default = self.packages.${system}.whitesur-kde;
      });

      # Convenience NixOS module: `imports = [ inputs.whitesur-kde-flake.nixosModules.default ]`
      # in your system config drops the theme into environment.systemPackages so the
      # files land under /run/current-system/sw/share/{aurorae,plasma,Kvantum,...}.
      # Users still pick the WhiteSur variant they want via plasma-apply-lookandfeel,
      # plasma-apply-colorscheme, kvantummanager, etc. — the module installs every
      # variant; it does not enforce one.
      nixosModules.default = { pkgs, ... }: {
        environment.systemPackages = [
          self.packages.${pkgs.system}.whitesur-kde
        ];
      };
    };
}
