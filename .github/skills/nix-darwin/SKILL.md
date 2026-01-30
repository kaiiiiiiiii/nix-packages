---
name: nix-darwin
description: nix-darwin configuration for macOS systems. Use when configuring macOS with Nix, setting system defaults, managing launchd services, integrating Homebrew, configuring keyboard remapping, or working with darwin-specific modules.
---

# nix-darwin for macOS

## Overview

nix-darwin brings NixOS-style declarative configuration to macOS:
- Uses `darwin.lib.darwinSystem` instead of `nixpkgs.lib.nixosSystem`
- Uses launchd instead of systemd
- Integrates with Homebrew for GUI applications
- Manages macOS system defaults declaratively

## Flake Configuration

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs: {
    darwinConfigurations."hostname" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";  # or "x86_64-darwin"
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/macbook
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.username = ./home.nix;
        }
      ];
    };
  };
}
```

## System Defaults

### Dock
```nix
system.defaults.dock = {
  autohide = true;
  autohide-delay = 0.0;
  autohide-time-modifier = 0.2;
  orientation = "bottom";  # "left", "right", "bottom"
  tilesize = 48;
  magnification = false;
  largesize = 64;
  mineffect = "scale";  # "genie", "scale"
  show-recents = false;
  mru-spaces = false;  # Don't reorder spaces based on use
  expose-animation-duration = 0.1;
  expose-group-by-app = false;
  persistent-apps = [
    "/Applications/Arc.app"
    "/System/Applications/Mail.app"
  ];
  persistent-others = [];
};
```

### Finder
```nix
system.defaults.finder = {
  AppleShowAllFiles = true;
  AppleShowAllExtensions = true;
  FXPreferredViewStyle = "clmv";  # "Nlsv" (list), "icnv" (icon), "clmv" (column), "glyv" (gallery)
  FXEnableExtensionChangeWarning = false;
  ShowPathbar = true;
  ShowStatusBar = true;
  _FXShowPosixPathInTitle = true;
  QuitMenuItem = true;  # Allow quitting Finder
};
```

### Global Domain (NSGlobalDomain)
```nix
system.defaults.NSGlobalDomain = {
  AppleShowAllExtensions = true;
  AppleShowAllFiles = true;
  InitialKeyRepeat = 15;      # Delay before key repeat
  KeyRepeat = 2;              # Key repeat rate (lower = faster)
  NSAutomaticCapitalizationEnabled = false;
  NSAutomaticDashSubstitutionEnabled = false;
  NSAutomaticPeriodSubstitutionEnabled = false;
  NSAutomaticQuoteSubstitutionEnabled = false;
  NSAutomaticSpellingCorrectionEnabled = false;
  NSDocumentSaveNewDocumentsToCloud = false;
  NSNavPanelExpandedStateForSaveMode = true;
  NSNavPanelExpandedStateForSaveMode2 = true;
  PMPrintingExpandedStateForPrint = true;
  PMPrintingExpandedStateForPrint2 = true;
  AppleInterfaceStyle = "Dark";
  AppleInterfaceStyleSwitchesAutomatically = false;
  "com.apple.mouse.tapBehavior" = 1;  # Tap to click
  "com.apple.trackpad.enableSecondaryClick" = true;
};
```

### Trackpad
```nix
system.defaults.trackpad = {
  Clicking = true;              # Tap to click
  TrackpadRightClick = true;    # Two-finger right click
  TrackpadThreeFingerDrag = true;
};
```

### Menu Clock
```nix
system.defaults.menuExtraClock = {
  Show24Hour = true;
  ShowAMPM = false;
  ShowDate = 1;  # 0 = when space allows, 1 = always, 2 = never
  ShowDayOfMonth = true;
  ShowDayOfWeek = true;
  ShowSeconds = false;
};
```

### Screenshots
```nix
system.defaults.screencapture = {
  location = "~/Pictures/Screenshots";
  type = "png";  # "jpg", "tiff", "gif", "pdf"
  disable-shadow = true;
};
```

### Spaces & Mission Control
```nix
system.defaults.spaces.spans-displays = false;
system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;
```

## Keyboard Configuration

```nix
system.keyboard = {
  enableKeyMapping = true;
  remapCapsLockToEscape = true;
  # remapCapsLockToControl = true;  # Alternative
  
  # Custom key mappings (HID usage tables)
  userKeyMapping = [
    {
      HIDKeyboardModifierMappingSrc = 30064771129;  # Caps Lock
      HIDKeyboardModifierMappingDst = 30064771113;  # Escape
    }
  ];
};
```

## Security

```nix
security.pam.enableSudoTouchIdAuth = true;  # TouchID for sudo
```

## Launchd Services (instead of systemd)

```nix
# User agent (runs as user)
launchd.user.agents.my-service = {
  serviceConfig = {
    Label = "com.example.my-service";
    Program = "${pkgs.my-package}/bin/my-service";
    ProgramArguments = [
      "${pkgs.my-package}/bin/my-service"
      "--flag"
      "value"
    ];
    KeepAlive = true;
    RunAtLoad = true;
    StandardOutPath = "/tmp/my-service.log";
    StandardErrorPath = "/tmp/my-service.err";
    EnvironmentVariables = {
      PATH = "${pkgs.my-package}/bin";
    };
  };
};

# System daemon (runs as root)
launchd.daemons.my-daemon = {
  serviceConfig = {
    Label = "com.example.my-daemon";
    Program = "${pkgs.my-package}/bin/my-daemon";
    KeepAlive = true;
    RunAtLoad = true;
  };
};
```

## Homebrew Integration

### With nix-homebrew
```nix
# In flake.nix inputs
nix-homebrew = {
  url = "github:zhaofengli-wip/nix-homebrew";
};
homebrew-core = {
  url = "github:homebrew/homebrew-core";
  flake = false;
};
homebrew-cask = {
  url = "github:homebrew/homebrew-cask";
  flake = false;
};

# In configuration
{ inputs, ... }:
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;  # For x86 packages on ARM
    user = "username";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;  # Pin for reproducibility
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";  # Remove unmanaged packages
    };
    
    taps = [];  # Additional taps
    
    brews = [
      "borders"  # CLI tools
    ];
    
    casks = [
      "arc"
      "raycast"
      "discord"
      "1password"
    ];
    
    masApps = {
      "Xcode" = 497799835;
      "Amphetamine" = 937984704;
    };
  };
}
```

## Programs and Services

### Available Darwin Services
```nix
services.aerospace.enable = true;        # Window manager
services.jankyborders.enable = true;     # Window borders
services.sketchybar.enable = true;       # Status bar
services.yabai.enable = true;            # Window manager
services.skhd.enable = true;             # Hotkey daemon
services.spacebar.enable = true;         # Status bar
```

### Nix Configuration
```nix
# Note: If using Determinate Nix, set this to false
nix.enable = false;  # Don't manage nix daemon

# Or if nix-darwin manages the daemon:
nix = {
  enable = true;
  settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@admin" ];
  };
};
```

## Common Commands

```bash
# Build without switching
darwin-rebuild build --flake .#hostname

# Build and switch
darwin-rebuild switch --flake .#hostname

# Check current generation
darwin-rebuild --list-generations

# Rollback
darwin-rebuild switch --rollback
```

## Common Pitfalls

### Homebrew Taps
```nix
# WRONG: Tap not in both places
homebrew.taps = [ "some/tap" ];

# CORRECT: Add to inputs AND nix-homebrew.taps
inputs.some-tap = {
  url = "github:some/tap";
  flake = false;
};
# And in config:
nix-homebrew.taps."some/tap" = inputs.some-tap;
```

### GUI Applications
Keep GUI apps in Homebrew casks for proper macOS integration:
- App Store registration
- Spotlight indexing
- Default app handling
- Gatekeeper validation

### Determinate Nix
If using Determinate Nix installer:
```nix
nix.enable = false;  # Don't let darwin manage daemon
```

### Activation Failures
After failed activation:
```bash
# Check what went wrong
sudo launchctl list | grep nix

# Manual restart if needed
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

### defaults write Commands
Prefer declarative configuration over manual `defaults write`:
```nix
# Instead of: defaults write com.apple.dock autohide -bool true
system.defaults.dock.autohide = true;
```

## Directory Organization

```
hosts/
└── macbook-pro/
    └── default.nix
modules/
└── darwin/
    ├── default.nix
    ├── homebrew.nix
    ├── system-defaults.nix
    └── services/
        ├── aerospace.nix
        ├── jankyborders.nix
        └── sketchybar/
            ├── default.nix
            └── config/
```
