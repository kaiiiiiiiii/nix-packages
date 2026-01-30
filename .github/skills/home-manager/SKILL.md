---
name: home-manager
description: Home Manager configuration for user environments. Use when managing dotfiles, user packages, program configurations, shell setup, or per-user settings. Covers standalone and integrated (NixOS/darwin) usage, program modules, file management, and custom module patterns.
---

# Home Manager

## Integration Methods

### 1. NixOS Module
```nix
# In flake.nix
nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
  modules = [
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users.username = ./home.nix;
    }
  ];
};
```

### 2. nix-darwin Module
```nix
# In flake.nix
darwinConfigurations.hostname = nix-darwin.lib.darwinSystem {
  modules = [
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users.username = ./home.nix;
    }
  ];
};
```

### 3. Standalone
```nix
# In flake.nix
homeConfigurations.username = home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  extraSpecialArgs = { inherit inputs; };
  modules = [ ./home.nix ];
};
```

```bash
# Build and switch
home-manager switch --flake .#username
```

## Basic Configuration

```nix
{ config, lib, pkgs, ... }:
{
  home.username = "username";
  home.homeDirectory = "/home/username";  # or /Users/username on macOS
  home.stateVersion = "24.05";  # Keep at install version

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    htop
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/go/bin"
  ];

  programs.home-manager.enable = true;
}
```

## Program Modules

### Git
```nix
programs.git = {
  enable = true;
  userName = "Your Name";
  userEmail = "you@example.com";
  
  signing = {
    key = "KEYID";
    signByDefault = true;
  };
  
  delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };
  
  extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = true;
    push.autoSetupRemote = true;
    core.autocrlf = "input";
  };
  
  aliases = {
    co = "checkout";
    st = "status";
    lg = "log --oneline --graph --decorate";
  };
  
  ignores = [
    ".DS_Store"
    "*.swp"
    ".direnv"
    ".envrc"
  ];
};
```

### Shell (Fish)
```nix
programs.fish = {
  enable = true;
  
  shellInit = ''
    set -gx EDITOR nvim
  '';
  
  interactiveShellInit = ''
    # Interactive setup
    set fish_greeting  # Disable greeting
  '';
  
  shellAliases = {
    ll = "eza -la";
    cat = "bat";
    ".." = "cd ..";
  };
  
  shellAbbrs = {
    g = "git";
    gc = "git commit";
    gp = "git push";
  };
  
  plugins = [
    { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
    { name = "tide"; src = pkgs.fishPlugins.tide.src; }
  ];
  
  functions = {
    mkcd = "mkdir -p $argv[1] && cd $argv[1]";
  };
};
```

### Starship
```nix
programs.starship = {
  enable = true;
  enableFishIntegration = true;
  
  settings = {
    add_newline = true;
    
    character = {
      success_symbol = "[❯](bold green)";
      error_symbol = "[❯](bold red)";
    };
    
    directory = {
      truncation_length = 3;
      truncate_to_repo = true;
    };
    
    git_branch = {
      symbol = " ";
      format = "on [$symbol$branch]($style) ";
    };
    
    nix_shell = {
      symbol = " ";
      format = "via [$symbol$state]($style) ";
    };
  };
};
```

### Common Tool Configurations
```nix
programs.bat = {
  enable = true;
  config = {
    theme = "Catppuccin-macchiato";
    style = "numbers,changes,header";
  };
};

programs.eza = {
  enable = true;
  enableFishIntegration = true;
  git = true;
  icons = "auto";
  extraOptions = [ "--group-directories-first" ];
};

programs.fzf = {
  enable = true;
  enableFishIntegration = true;
  defaultCommand = "fd --type f --hidden --follow --exclude .git";
  defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
};

programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};

programs.zoxide = {
  enable = true;
  enableFishIntegration = true;
};
```

## File Management

### Static Files
```nix
home.file = {
  ".config/myapp/config.toml".source = ./config/myapp.toml;
  
  ".config/myapp/generated.conf".text = ''
    setting = value
    another = ${toString config.myApp.port}
  '';
  
  ".local/bin/my-script" = {
    source = ./scripts/my-script.sh;
    executable = true;
  };
};
```

### XDG Directories
```nix
xdg.enable = true;

xdg.configFile = {
  "myapp/config.toml".source = ./config.toml;
};

xdg.dataFile = {
  "myapp/data.json".text = builtins.toJSON { key = "value"; };
};
```

### Generated Configuration Files
```nix
xdg.configFile."myapp/config.toml".source = 
  (pkgs.formats.toml {}).generate "config" {
    setting = "value";
    nested = {
      key = "value";
    };
  };
```

## Custom Program Modules

### Module Structure
```nix
# modules/home/programs/myapp.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.myPrograms.myapp;
in
{
  options.myPrograms.myapp = {
    enable = lib.mkEnableOption "myapp configuration";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myapp;
      description = "Package to use";
    };
    
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };
    
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Configuration settings";
    };
    
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration lines";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    
    xdg.configFile."myapp/config.toml".source =
      (pkgs.formats.toml {}).generate "myapp-config" ({
        port = cfg.port;
      } // cfg.settings);
  };
}
```

### Import Pattern
```nix
# modules/home/programs/default.nix
{ ... }:
{
  imports = [
    ./myapp.nix
    ./another-app.nix
  ];
}
```

## Platform-Specific Configuration

### Using osConfig
```nix
{ osConfig, lib, ... }:
{
  # Access system config from home-manager
  programs.fish.enable = osConfig.programs.fish.enable or false;
  
  # Platform-specific packages
  home.packages = lib.optionals pkgs.stdenv.isDarwin [
    pkgs.darwin-specific
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.linux-specific
  ];
}
```

### Separate Platform Modules
```nix
# modules/home/darwin.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    darwin-specific-tool
  ];
  
  # macOS-specific config
}

# modules/home/nixos.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    linux-specific-tool
  ];
  
  # Linux-specific config
}
```

## Common Patterns

### Theming (Catppuccin Example)
```nix
{ inputs, ... }:
{
  imports = [ inputs.catppuccin.homeManagerModules.catppuccin ];
  
  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };
  
  # Individual app theming
  catppuccin.bat.enable = true;
  catppuccin.fish.enable = true;
  catppuccin.starship.enable = true;
  catppuccin.fzf.enable = true;
}
```

### Environment Activation
```nix
home.activation = {
  myActivation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.runtimeShell} -c 'echo "Running activation script"'
  '';
};
```

### Session Variables That Need Shell
```nix
# For variables that need evaluation at shell start
home.sessionVariablesExtra = ''
  export DYNAMIC_VAR=$(some-command)
'';
```

## Common Commands

```bash
# Standalone
home-manager switch --flake .#username
home-manager build --flake .#username
home-manager generations

# With NixOS/darwin (automatic with system switch)
darwin-rebuild switch --flake .#hostname
nixos-rebuild switch --flake .#hostname
```

## Common Pitfalls

### Collision Errors
```bash
# If you see collision errors, remove nix-env packages first
nix-env -q  # List installed
nix-env -e package-name  # Remove
```

### stateVersion
```nix
# Different from system stateVersion!
# Keep at Home Manager install version
home.stateVersion = "24.05";
```

### Session Variables Not Loading
Ensure your shell is managed by Home Manager or source the session file:
```bash
# In shell init
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
```

### useGlobalPkgs
```nix
# Recommended to avoid separate nixpkgs evaluation
home-manager.useGlobalPkgs = true;
home-manager.useUserPackages = true;
```

## Directory Organization

```
modules/
└── home/
    ├── default.nix           # Main imports
    ├── darwin.nix            # macOS-specific
    ├── nixos.nix             # Linux-specific
    ├── options.nix           # Custom options
    ├── programs/
    │   ├── default.nix
    │   ├── git.nix
    │   ├── development.nix
    │   └── ghostty/
    │       ├── default.nix
    │       └── ghostty-config
    └── shell/
        ├── default.nix
        ├── common.nix
        ├── fish.nix
        └── starship.nix
```
