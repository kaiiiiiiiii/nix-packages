---
name: nix-troubleshooting
description: Troubleshooting common Nix, NixOS, and nix-darwin issues. Use when debugging build failures, evaluation errors, garbage collection, disk space issues, channel/flake problems, or activation failures.
---

# Nix Troubleshooting Guide

## Build Failures

### Show Full Error Trace
```bash
nix build --show-trace
nixos-rebuild build --show-trace
darwin-rebuild build --show-trace
```

### Build with Verbose Output
```bash
nix build -L                    # Show build logs
nix build -vvv                  # Very verbose
```

### Check Specific Package
```bash
nix build nixpkgs#packageName
nix log nixpkgs#packageName     # View build log
```

### Hash Mismatch
```bash
# Get correct hash
nix hash to-sri sha256:$(nix-prefetch-url URL)

# For fetchFromGitHub
nix-prefetch-github owner repo --rev REV
```

## Evaluation Errors

### Debug in REPL
```bash
nix repl
:lf .                           # Load current flake
:p outputs.nixosConfigurations.hostname.config.services.nginx
```

### Check Syntax
```bash
nix-instantiate --parse file.nix
```

### Trace Expressions
```nix
# Add to code for debugging
builtins.trace "Debug: ${builtins.toString value}" value
```

### Find Infinite Recursion
```bash
nix eval --show-trace .#path 2>&1 | head -100
```

## Flake Issues

### Git Tracking
```bash
# Files must be tracked
git add flake.nix hosts/ modules/
git status                      # Check for untracked files
```

### Lock File Problems
```bash
# Update all inputs
nix flake update

# Update single input
nix flake lock --update-input nixpkgs

# Clear and regenerate
rm flake.lock
nix flake lock
```

### Flake Won't Evaluate
```bash
# Check flake outputs
nix flake show --allow-import-from-derivation

# Validate flake
nix flake check
```

### Dirty Git Tree
```bash
# Flakes require clean git state for reproducibility
git stash
nix build
git stash pop
```

## Disk Space Issues

### Check Nix Store Size
```bash
nix path-info -Sh /run/current-system
du -sh /nix/store
df -h /nix
```

### Garbage Collection
```bash
# Standard garbage collection
nix-collect-garbage

# Remove old generations
nix-collect-garbage -d
sudo nix-collect-garbage -d     # System generations

# Keep recent generations
nix-env --delete-generations +5 # Keep last 5
nix-env --delete-generations 30d # Delete older than 30 days
```

### Remove Specific Generation
```bash
# List generations
nix-env --list-generations
nixos-rebuild list-generations
darwin-rebuild --list-generations

# Delete specific generation
nix-env --delete-generations 42
```

### Optimize Store
```bash
nix store optimise              # Deduplicate store
```

## Channel vs Flake Confusion

### Check Current Setup
```bash
# Are you using flakes?
cat flake.nix

# Check nix channels (legacy)
nix-channel --list

# Check NIX_PATH
echo $NIX_PATH
```

### Remove Legacy Channels
```bash
nix-channel --remove nixpkgs
unset NIX_PATH
```

## Activation Failures

### NixOS
```bash
# Try boot instead of switch
sudo nixos-rebuild boot --flake .#hostname

# Check what would change
nixos-rebuild dry-activate --flake .#hostname

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

### nix-darwin
```bash
# Check for conflicts
darwin-rebuild check --flake .#hostname

# Build without switching
darwin-rebuild build --flake .#hostname

# Rollback
darwin-rebuild switch --rollback
```

### Home Manager
```bash
# Check for file conflicts
home-manager build --flake .#user

# Remove conflicting files
home-manager switch --flake .#user -b backup
```

## Daemon Issues

### Restart Nix Daemon
```bash
# NixOS
sudo systemctl restart nix-daemon

# macOS
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

### Check Daemon Status
```bash
# NixOS
systemctl status nix-daemon

# macOS
sudo launchctl list | grep nix
```

### Daemon Permission Errors
```bash
# Check trusted users
cat /etc/nix/nix.conf | grep trusted

# Ensure user is in trusted-users
# In configuration:
nix.settings.trusted-users = [ "root" "@wheel" "@admin" ];
```

## Sandbox Issues

### Disable Sandbox (Debugging)
```bash
nix build --option sandbox false
```

### Check Sandbox Status
```bash
nix show-config | grep sandbox
```

## Network Issues

### Substituter Problems
```bash
# Test substituter connectivity
curl -I https://cache.nixos.org

# Check substituter config
nix show-config | grep substituters

# Build without cache
nix build --option substitute false
```

### Firewall/Proxy
```bash
# Use proxy
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port

# Or in nix.conf
http-proxy = http://proxy:port
```

## Common Error Messages

### "collision between" / "same priority"
File conflicts - typically from multiple sources trying to create same file:
```bash
# For Home Manager
home-manager switch -b backup    # Backup existing files

# Check for nix-env installed packages
nix-env -q
nix-env -e packagename          # Remove conflicting package
```

### "cannot open connection to remote store"
Daemon not running:
```bash
# Check daemon
pgrep nix-daemon

# Restart
sudo systemctl restart nix-daemon  # NixOS
sudo launchctl kickstart -k system/org.nixos.nix-daemon  # macOS
```

### "path is not valid"
Store corruption:
```bash
# Verify store
nix-store --verify --check-contents

# Repair store
nix-store --verify --check-contents --repair
```

### "infinite recursion encountered"
Self-referential definition:
```nix
# WRONG
rec {
  a = b;
  b = a;
}

# Check with trace
builtins.trace "checking value" value
```

### "attribute not found"
Typo or missing import:
```bash
# Check available attributes
nix repl
:lf .
:tab outputs.nixosConfigurations.<TAB>
```

## Debug Commands Summary

```bash
# Verbose build
nix build -L --show-trace

# REPL inspection
nix repl --file '<nixpkgs>'
:lf .

# Flake info
nix flake show
nix flake metadata
nix flake info

# Derivation inspection
nix show-derivation /nix/store/...

# Path info
nix path-info -rsh /nix/store/...

# Why is this in store
nix why-depends /run/current-system /nix/store/...

# Build log
nix log /nix/store/...

# Store diff
nix store diff-closures /run/current-system ./result
```

## Performance

### Faster Evaluation
```bash
# Cache evaluation
nix eval --json .#outputs > /dev/null

# Parallel builds
nix build --max-jobs 4
```

### Profile Builds
```bash
# Time build phases
nix build --print-build-logs 2>&1 | tee build.log
```

## Getting Help

```bash
# Man pages
man nix
man nix.conf
man configuration.nix

# Option search
nixos-option services.nginx.enable
man home-configuration.nix

# Online search
# https://search.nixos.org/packages
# https://search.nixos.org/options
```
