# Run every recipe with colmena available
set shell := ["nix", "shell", "github:zhaofengli/colmena", "--command", "sh", "-c"]

# Deploy to all VMs
all:
  colmena apply --experimental-flake-eval

# Deploy to specific VMs
vm vms:
  colmena apply --experimental-flake-eval --on {{vms}}
