---
name: nixos-modules
description: NixOS module system patterns, option declarations, configuration, and best practices. Use when writing NixOS modules, declaring options with mkOption, implementing config blocks, using mkIf/mkMerge, creating services, or structuring NixOS configurations.
---

# NixOS Module System

## Module Structure

```nix
{ config, lib, pkgs, ... }:
{
  imports = [ ./other-module.nix ];  # Import other modules

  options.myService = {              # Declare options
    # Option declarations
  };

  config = {                         # Define configuration
    # Configuration implementation
  };
}
```

## Option Declarations

### Basic Options
```nix
{ lib, ... }:
{
  options.services.myService = {
    enable = lib.mkEnableOption "my service description";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "myservice";
      description = "User to run the service as";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myservice;
      defaultText = lib.literalExpression "pkgs.myservice";
      description = "Package to use";
    };
  };
}
```

### Common Option Types
```nix
lib.types.str                           # String
lib.types.bool                          # Boolean
lib.types.int                           # Integer
lib.types.port                          # Port number (0-65535)
lib.types.path                          # File path
lib.types.package                       # Derivation/package
lib.types.lines                         # Multi-line string
lib.types.attrs                         # Any attribute set
lib.types.raw                           # Unmerged value

# Compound types
lib.types.listOf lib.types.str          # List of strings
lib.types.attrsOf lib.types.int         # Attrset with int values
lib.types.enum [ "a" "b" "c" ]          # Enumeration
lib.types.nullOr lib.types.str          # Nullable string
lib.types.oneOf [ types.str types.int ] # Union type
lib.types.either types.str types.int    # Either type

# Submodules
lib.types.submodule {
  options = {
    name = lib.mkOption { type = lib.types.str; };
    value = lib.mkOption { type = lib.types.int; };
  };
}
lib.types.listOf (lib.types.submodule { ... })
```

### mkOption Parameters
```nix
lib.mkOption {
  type = lib.types.str;                 # Required: option type
  default = "value";                    # Optional: default value
  defaultText = lib.literalExpression "pkgs.foo";  # For docs
  example = "example value";            # For documentation
  description = "What this option does";
  apply = value: transform value;       # Transform before use
  visible = true;                       # Show in docs
  readOnly = false;                     # Prevent setting
  internal = false;                     # Hide from docs
}
```

## Configuration Implementation

### Basic Config with mkIf
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.myService;
in
{
  options.services.myService = { ... };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = {};

    systemd.services.myService = {
      description = "My Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/myservice --port ${toString cfg.port}";
        User = cfg.user;
        Restart = "on-failure";
      };
    };
  };
}
```

### mkMerge for Multiple Conditions
```nix
config = lib.mkMerge [
  (lib.mkIf cfg.enable {
    # Base configuration when enabled
    environment.systemPackages = [ cfg.package ];
  })
  
  (lib.mkIf (cfg.enable && cfg.enableNginx) {
    # Additional configuration when nginx integration enabled
    services.nginx.virtualHosts.${cfg.domain} = { ... };
  })
  
  (lib.mkIf (cfg.enable && cfg.database == "postgresql") {
    # PostgreSQL-specific configuration
    services.postgresql.ensureDatabases = [ cfg.databaseName ];
  })
];
```

### Priority Functions
```nix
# Low priority (can be overridden)
lib.mkDefault value

# High priority (overrides others)
lib.mkForce value

# Explicit priority (lower = higher priority)
lib.mkOverride 100 value   # Same as mkDefault
lib.mkOverride 50 value    # Higher than default
lib.mkOverride 1000 value  # Very low priority
```

## Common Patterns

### cfg Shorthand
```nix
let
  cfg = config.services.myService;
in
# Use cfg.enable, cfg.port, etc.
```

### specialArgs for Custom Arguments
```nix
# In flake.nix
nixosSystem {
  specialArgs = { inherit inputs username; };
  modules = [ ./configuration.nix ];
}

# In module
{ inputs, username, ... }:
{
  # Access inputs and username
}
```

### imports vs import
```nix
# Module system imports (processed by module system)
imports = [ ./module.nix ./other.nix ];

# Nix builtin import (simple file inclusion)
myValue = import ./data.nix;
```

### Conditional Imports
```nix
imports = [
  ./base.nix
] ++ lib.optionals (hostname == "server") [
  ./server.nix
];
```

### Systemd Service Pattern
```nix
systemd.services.myapp = {
  description = "My Application";
  wantedBy = [ "multi-user.target" ];
  after = [ "network.target" ];
  wants = [ "network-online.target" ];
  
  environment = {
    HOME = "/var/lib/myapp";
  };
  
  serviceConfig = {
    Type = "simple";
    ExecStart = "${cfg.package}/bin/myapp";
    ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
    
    User = cfg.user;
    Group = cfg.group;
    WorkingDirectory = "/var/lib/myapp";
    StateDirectory = "myapp";
    
    Restart = "on-failure";
    RestartSec = "5s";
    
    # Hardening
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    ReadWritePaths = [ "/var/lib/myapp" ];
  };
};
```

### Networking Patterns
```nix
networking = {
  hostName = "server";
  firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ ];
  };
};
```

### User Creation
```nix
users.users.myuser = {
  isNormalUser = true;
  description = "My User";
  extraGroups = [ "wheel" "networkmanager" "docker" ];
  shell = pkgs.fish;
  openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
};
```

### Package Installation
```nix
# System-wide packages
environment.systemPackages = with pkgs; [
  vim
  git
  htop
];

# Per-user via Home Manager
home-manager.users.myuser = {
  home.packages = with pkgs; [ ripgrep fd ];
};
```

## Directory Organization

```
modules/
├── nixos/
│   ├── default.nix           # Imports all sub-modules
│   ├── boot.nix
│   ├── networking.nix
│   ├── users.nix
│   └── services/
│       ├── nginx.nix
│       └── postgresql.nix
```

```nix
# modules/nixos/default.nix
{ ... }:
{
  imports = [
    ./boot.nix
    ./networking.nix
    ./users.nix
    ./services/nginx.nix
    ./services/postgresql.nix
  ];
}
```

## Common Pitfalls

### config vs options Confusion
```nix
# WRONG: Mixing option declaration with config
{
  services.nginx.enable = true;  # This is config, not options!
  options.myOption = ...;
}

# CORRECT: Separate options and config
{
  options.myOption = lib.mkOption { ... };
  config.services.nginx.enable = true;
}

# CORRECT: Implicit config block (most common)
{
  options.myOption = lib.mkOption { ... };
  services.nginx.enable = true;  # Implicitly in config
}
```

### stateVersion
```nix
# KEEP at original install version - don't update!
system.stateVersion = "24.05";
```

### Missing lib.mkIf
```nix
# WRONG: Config always applied
config = {
  services.nginx.enable = cfg.enable;  # Still creates nginx config
};

# CORRECT: Guard entire block
config = lib.mkIf cfg.enable {
  services.nginx.enable = true;
};
```

### Type Mismatches
```nix
# WRONG: String when expecting port
port = "8080";

# CORRECT: Integer for port type
port = 8080;
```

## Testing Modules

```bash
# Check syntax
nix-instantiate --parse module.nix

# Evaluate option
nix eval .#nixosConfigurations.host.config.services.myService.port

# Build configuration (without switching)
nixos-rebuild build --flake .#host

# Test in VM
nixos-rebuild build-vm --flake .#host
./result/bin/run-*-vm
```
