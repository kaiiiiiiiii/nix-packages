---
name: nix-flakes
description: Nix Flakes configuration, inputs, outputs, and project structure. Use when creating flake.nix files, managing inputs, defining outputs (packages, devShells, nixosConfigurations, darwinConfigurations), updating lock files, or troubleshooting flake evaluation.
---

# Nix Flakes

## Flake Structure

```nix
{
  description = "My flake description";

  inputs = {
    # Input declarations
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # Output definitions
  };
}
```

## Input Types

### GitHub Repository
```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
  
  # Specific commit
  specific.url = "github:owner/repo/commit-sha";
  
  # Branch
  branch.url = "github:owner/repo/branch-name";
  
  # Tag
  tagged.url = "github:owner/repo?ref=v1.0.0";
};
```

### Other Sources
```nix
inputs = {
  # GitLab
  gitlab.url = "gitlab:owner/repo";
  
  # Git URL
  git.url = "git+https://example.com/repo.git";
  git-ssh.url = "git+ssh://git@github.com/owner/repo";
  
  # Tarball
  tarball.url = "https://example.com/archive.tar.gz";
  
  # Local path
  local.url = "path:/absolute/path";
  
  # Flake registry
  registry.url = "flake:nixpkgs";
};
```

### Non-Flake Inputs
```nix
inputs = {
  my-source = {
    url = "github:owner/repo";
    flake = false;  # Don't treat as flake
  };
};
```

### Input Follows (Dependency Deduplication)
```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";  # Share nixpkgs
  };
  
  sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

## Output Types

### NixOS Configurations
```nix
outputs = { nixpkgs, ... }: {
  nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/hostname
      ./modules/nixos
    ];
  };
};
```

### Darwin Configurations
```nix
outputs = { nix-darwin, ... }: {
  darwinConfigurations.hostname = nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs; };
    modules = [
      ./hosts/macbook
      ./modules/darwin
    ];
  };
};
```

### Home Manager (Standalone)
```nix
outputs = { home-manager, nixpkgs, ... }: {
  homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = { inherit inputs; };
    modules = [ ./home.nix ];
  };
};
```

### Packages
```nix
outputs = { nixpkgs, ... }: {
  packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.hello;
  packages.x86_64-linux.my-package = derivation;
};
```

### Dev Shells
```nix
outputs = { nixpkgs, ... }: {
  devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
    packages = with nixpkgs.legacyPackages.x86_64-linux; [
      git
      nodejs
    ];
    shellHook = ''
      echo "Entering dev shell"
    '';
  };
};
```

### Overlays
```nix
outputs = { ... }: {
  overlays.default = final: prev: {
    my-package = prev.my-package.override { ... };
  };
};
```

### Modules
```nix
outputs = { ... }: {
  nixosModules.default = import ./modules/nixos;
  darwinModules.default = import ./modules/darwin;
  homeManagerModules.default = import ./modules/home;
};
```

### Checks
```nix
outputs = { nixpkgs, ... }: {
  checks.x86_64-linux = {
    format = nixpkgs.legacyPackages.x86_64-linux.runCommand "check-format" {} ''
      # Check formatting
      touch $out
    '';
  };
};
```

## Multi-System Pattern

```nix
outputs = { nixpkgs, ... }:
let
  systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
  forAllSystems = nixpkgs.lib.genAttrs systems;
  pkgsFor = system: nixpkgs.legacyPackages.${system};
in {
  packages = forAllSystems (system: {
    default = (pkgsFor system).hello;
  });
  
  devShells = forAllSystems (system: {
    default = (pkgsFor system).mkShell {
      packages = with (pkgsFor system); [ git ];
    };
  });
};
```

## Helper Library Pattern

```nix
# lib/default.nix
{ inputs, ... }:
{
  mkDarwinHost = { hostname, system, username, ... }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit inputs username; };
      modules = [
        ../hosts/${hostname}
        ../modules/darwin
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = ../home;
        }
      ];
    };

  mkNixosHost = { hostname, system, username, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs username; };
      modules = [
        ../hosts/${hostname}
        ../modules/nixos
      ];
    };
}
```

## Common Commands

```bash
# Build and switch
darwin-rebuild switch --flake .#hostname
nixos-rebuild switch --flake .#hostname
sudo nixos-rebuild switch --flake .#hostname

# Home Manager
home-manager switch --flake .#user

# Update all inputs
nix flake update

# Update single input
nix flake lock --update-input nixpkgs

# Show outputs
nix flake show

# Check validity
nix flake check

# Build specific output
nix build .#packages.x86_64-linux.my-package

# Enter dev shell
nix develop
nix develop .#other-shell

# Run package
nix run .#my-package

# Evaluate expression
nix eval .#nixosConfigurations.hostname.config.services.nginx.enable
```

## Lock File Management

The `flake.lock` file pins all input versions:
- **Always commit** `flake.lock` to version control
- **Review diffs** before switching to updated inputs
- Update intentionally with `nix flake update`

```bash
# Update everything
nix flake update

# Update specific input
nix flake lock --update-input home-manager

# Pin to specific commit
nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/commit-sha
```

## Common Pitfalls

### Git Tracking Required
```bash
# Files must be tracked by git to be visible
git add flake.nix hosts/ modules/
```

### Pure Evaluation
```nix
# WRONG: No lookup paths in flakes
import <nixpkgs> {}

# CORRECT: Use inputs
inputs.nixpkgs.legacyPackages.${system}
```

### Secrets
Never put unencrypted secrets in flakes. Use:
- sops-nix for encrypted secrets
- agenix for age-encrypted secrets
- Environment variables at runtime

### Experimental Features
Enable in `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

### System Attribute
Always specify `system` explicitly:
```nix
# WRONG: No system specified
packages.default = pkgs.hello;

# CORRECT: System specified
packages.x86_64-linux.default = pkgs.hello;
```

## Debugging

```bash
# Show trace on error
nix build --show-trace

# Evaluate with trace output
nix eval .#path --show-trace

# Debug in repl
nix repl
:lf .  # Load flake
outputs.nixosConfigurations.hostname.config.services

# Check what's in store
nix path-info -rsh .#result
```
