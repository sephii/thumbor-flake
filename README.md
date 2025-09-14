# Thumbor flake

This is a Nix flake for Thumbor, an open source photo thumbnail service.

## Usage

Add to your `flake.nix` file:

```
inputs.thumbor.url = "github:sephii/thumbor-flake";
inputs.thumbor.inputs.nixpkgs.follows = "nixpkgs";
```

And then use `thumbor.packages.${system}.default`. You can also use the NixOS
module by using `imports = [ thumbor.nixosModules.default ]`. Check the
`module.nix` file for information on the options.
