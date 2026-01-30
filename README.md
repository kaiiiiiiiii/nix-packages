# Nix Packages

Custom Nix packages repository.

## Available Packages

| Package | Description | Platforms |
|---------|-------------|-----------|
| `fosrl-pangolin` | Tunneled reverse proxy server with identity and access control | Linux |
| `fosrl-newt` | Tunneling client for Pangolin | Linux, macOS |

## Usage

### Using the Overlay (Recommended)

The overlay is the primary way to consume these packages. It makes the packages available as if they were part of nixpkgs.

#### In a Flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-packages.url = "github:kaiiiiiiiii/nix-packages";
  };

  outputs = { self, nixpkgs, nix-packages, ... }: {
    # Example: NixOS configuration
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Apply the overlay
        { nixpkgs.overlays = [ nix-packages.overlays.default ]; }
        
        # Now you can use the packages
        ({ pkgs, ... }: {
          environment.systemPackages = [
            pkgs.fosrl-pangolin
            pkgs.fosrl-newt
          ];
        })
      ];
    };

    # Example: Home Manager configuration (standalone)
    homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ nix-packages.overlays.default ];
      };
      modules = [
        ({ pkgs, ... }: {
          home.packages = [
            pkgs.fosrl-newt
          ];
        })
      ];
    };
  };
}
```

#### Using the NixOS Module

This repository provides a NixOS module that automatically applies the overlay:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-packages.url = "github:kaiiiiiiiii/nix-packages";
  };

  outputs = { self, nixpkgs, nix-packages, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-packages.nixosModules.default
        
        ({ pkgs, ... }: {
          environment.systemPackages = [
            pkgs.fosrl-pangolin
            pkgs.fosrl-newt
          ];
        })
      ];
    };
  };
}
```

#### Using the Home Manager Module

For Home Manager configurations:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    nix-packages.url = "github:kaiiiiiiiii/nix-packages";
  };

  outputs = { self, nixpkgs, home-manager, nix-packages, ... }: {
    homeConfigurations.myuser = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        nix-packages.homeManagerModules.default
        
        ({ pkgs, ... }: {
          home.packages = [
            pkgs.fosrl-newt
          ];
        })
      ];
    };
  };
}
```

### Direct Package Reference

You can also reference packages directly without using overlays:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-packages.url = "github:kaiiiiiiiii/nix-packages";
  };

  outputs = { self, nixpkgs, nix-packages, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ ... }: {
          environment.systemPackages = [
            nix-packages.packages.x86_64-linux.fosrl-pangolin
            nix-packages.packages.x86_64-linux.fosrl-newt
          ];
        })
      ];
    };
  };
}
```

### Command Line Usage

```bash
# Run a package directly
nix run github:kaiiiiiiiii/nix-packages#fosrl-newt

# Build a package
nix build github:kaiiiiiiiii/nix-packages#fosrl-pangolin

# Enter a shell with the package available
nix shell github:kaiiiiiiiii/nix-packages#fosrl-newt
```

## Package Configuration

### fosrl-pangolin

Pangolin supports configuration options:

```nix
pkgs.fosrl-pangolin.override {
  databaseType = "pg";  # "sqlite" (default) or "pg" (PostgreSQL)
  environmentVariables = {
    # Add custom environment variables
  };
}
```

## Development

```bash
# Check the flake
nix flake check

# Build a specific package
nix build .#fosrl-pangolin
nix build .#fosrl-newt

# Build for a specific system
nix build .#packages.x86_64-linux.fosrl-pangolin
nix build .#packages.aarch64-linux.fosrl-newt
```

## Binary Cache (Cachix)

Pre-built packages are available via Cachix:

```bash
# Add the cache
cachix use kaiiiiiiiii

# Or manually configure in your Nix configuration
nix.settings.substituters = [ "https://kaiiiiiiiii.cachix.org" ];
nix.settings.trusted-public-keys = [ "kaiiiiiiiii.cachix.org-1:73fRzH1WLb8OCC+QGhPa9gEQKbGV6rYi/gOZrlBIXB4=" ];
```

Cache only contains Linux builds!

## License

Individual packages retain their original licenses. See each package for details.
