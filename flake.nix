{
  description = "Custom Nix packages repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      # Systems to support
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Import nixpkgs for each system with our overlay applied
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };

      # The overlay - primary way to consume custom packages
      overlay = final: prev: {
        fosrl-pangolin = final.callPackage ./pkgs/fosrl-pangolin { };
        fosrl-newt = final.callPackage ./pkgs/fosrl-newt { };
      };
    in
    {
      # === OVERLAYS (Primary consumption method) ===
      overlays = {
        default = overlay;
      };

      # === PACKAGES (For nix run/build/shell) ===
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          fosrl-newt = pkgs.fosrl-newt;
        }
        // nixpkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          # pangolin is Linux-only
          fosrl-pangolin = pkgs.fosrl-pangolin;
          default = pkgs.fosrl-pangolin;
        }
        // nixpkgs.lib.optionalAttrs (!pkgs.stdenv.isLinux) {
          default = pkgs.fosrl-newt;
        }
      );

      # === NixOS Module ===
      nixosModules.default =
        { ... }:
        {
          nixpkgs.overlays = [ self.overlays.default ];
        };

      # === Home Manager Module ===
      homeManagerModules.default =
        { ... }:
        {
          nixpkgs.overlays = [ self.overlays.default ];
        };
    };
}
