---
name: nix-language
description: Core Nix language patterns, syntax, and idioms. Use when writing Nix expressions, understanding evaluation, working with attribute sets, functions, let bindings, or debugging Nix code. Covers data types, operators, string interpolation, imports, and common pitfalls.
---

# Nix Language Fundamentals

## Core Concepts

- **Purely functional**: No side effects during evaluation; builds produce outputs deterministically from inputs
- **Lazy evaluation**: Values computed only when needed; use `--strict` or `:p` in `nix repl` to force
- **Dynamically typed**: Types checked at runtime; use module system `mkOption` for declarations
- **Expression-oriented**: Everything returns a value; files contain single expressions

## Data Types

### Primitives
```nix
"string"           # String
123                # Integer
3.14               # Float
true false         # Booleans
null               # Null
./path             # Path (relative)
/absolute/path     # Path (absolute)
```

### Attribute Sets
```nix
{ key = value; nested.key = value; }    # Basic attrset
{ "with spaces" = 1; ${dynamic} = 2; }  # Quoted/dynamic keys
rec { a = 1; b = a + 1; }               # Self-referential (use sparingly)
```

### Lists
```nix
[ elem1 elem2 elem3 ]     # Whitespace separated, NO commas
```

### Functions
```nix
x: x + 1                          # Single argument
x: y: x + y                       # Curried (multiple args)
{ a, b }: a + b                   # Destructured attrset
{ a, b ? 0 }: a + b               # With defaults
{ a, b, ... }: a + b              # Allow extra attrs
{ a, ... }@args: a + args.c       # Named entire set
```

## Key Language Constructs

### let Bindings
```nix
let
  x = 1;
  y = 2;
in x + y
```

### with Statement
```nix
with pkgs; [ git vim ]   # Import names into scope
```

### inherit
```nix
{ inherit x y; }                    # Equivalent to { x = x; y = y; }
{ inherit (attrset) x y; }          # Inherit from attrset
let inherit (lib) mkIf mkOption; in ...
```

### String Interpolation
```nix
"Hello ${name}"                     # Only strings/paths coerce
"Value: ${builtins.toString 42}"    # Numbers need toString
''
  Multi-line string
  With ${interpolation}
''                                  # Indented strings
```

### Conditionals
```nix
if condition then a else b          # If expression (always needs else)
```

### Attribute Access
```nix
attrset.key                         # Direct access (error if missing)
attrset.key or default              # With fallback
attrset ? key                       # Check existence
```

## Common Operators

| Operator | Description |
|----------|-------------|
| `//` | Attribute set merge (right overrides left) |
| `++` | List concatenation |
| `+` | Addition or string concatenation |
| `==` | Equality |
| `!=` | Inequality |
| `&&` | Logical AND |
| `||` | Logical OR |
| `!` | Logical NOT |
| `->` | Logical implication |

## Imports and Paths

```nix
import ./file.nix                   # Evaluate file
import ./file.nix { arg = val; }    # With arguments (if file is a function)
./relative/path                     # Relative to current file
/absolute/path                      # Absolute path
<nixpkgs>                          # Lookup path (AVOID - impure)
```

## Common Builtins

```nix
builtins.toString x                 # Convert to string
builtins.map f list                 # Map function over list
builtins.filter pred list           # Filter list
builtins.attrNames attrset          # Get keys as list
builtins.attrValues attrset         # Get values as list
builtins.hasAttr "key" attrset      # Check key exists
builtins.getAttr "key" attrset      # Get value by key
builtins.readFile ./path            # Read file contents
builtins.fetchurl { url = "..."; }  # Fetch URL
builtins.trace msg val              # Debug print (returns val)
```

## Common lib Functions

```nix
lib.mkIf condition value            # Conditional config
lib.mkMerge [ config1 config2 ]     # Merge configs
lib.mkDefault value                 # Low priority value
lib.mkForce value                   # High priority value
lib.optionalAttrs condition attrs   # Conditional attrs
lib.optionalString condition str    # Conditional string
lib.concatMapStrings f list         # Map and concat strings
lib.mapAttrs f attrset              # Map over attrset values
lib.filterAttrs pred attrset        # Filter attrset
lib.genAttrs list f                 # Generate attrset from list
```

## Common Pitfalls

### rec Abuse
```nix
# AVOID: Prefer let...in for clarity
rec { a = 1; b = a + 1; }

# PREFER:
let a = 1; in { inherit a; b = a + 1; }
```

### Missing Semicolons
```nix
# WRONG: Missing semicolons
{ a = 1 b = 2 }

# CORRECT:
{ a = 1; b = 2; }
```

### Lookup Paths
```nix
# AVOID: Impure, depends on NIX_PATH
import <nixpkgs> {}

# PREFER: Use flake inputs
inputs.nixpkgs
```

### Interpolation Types
```nix
# WRONG: Numbers don't interpolate
"Count: ${count}"

# CORRECT:
"Count: ${builtins.toString count}"
```

### Multi-line String Escaping
```nix
# To include literal ${, use ''$:
''
  echo "Value: ''${VARIABLE}"
''
```

## Debugging

```nix
# Print during evaluation
builtins.trace "Debug: ${builtins.toString x}" x

# In nix repl
:p expression                       # Force evaluation
:t expression                       # Show type
:l ./file.nix                       # Load file
```

## Idioms

### Pattern: Option Defaults
```nix
{ option ? "default" }:
# Use option, falling back to "default"
```

### Pattern: Conditional Attributes
```nix
{
  inherit (lib) optionalAttrs;
  config = {
    key = "value";
  } // optionalAttrs (condition) {
    optional-key = "value";
  };
}
```

### Pattern: Safe Attribute Access
```nix
attrset.key or attrset.fallback or "ultimate-default"
```
