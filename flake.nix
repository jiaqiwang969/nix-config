{
  description = "EmergentMind's Nix-Config";

  inputs = {
    #################### Official NixOS and HM Package Sources ####################

    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable"; # also see 'unstable-packages' overlay at 'overlays/default.nix"

    hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #################### Utilities ####################

    # Declarative partitioning and formatting
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management. See ./docs/secretsmgmt.md
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # vim4LMFQR!
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      #url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Windows management
    # for now trying to avoid this one because I want stability for my wm
    # this is the hyprland development flake package / unstable
    # hyprland = {
    #   url = "github:hyprwm/hyprland";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    #   hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins";
    #   inputs.hyprland.follows = "hyprland";
    # };

    #################### Personal Repositories ####################

  };

  outputs = { self, disko, nixpkgs, home-manager, ... } @ inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        #"x86_64-linux"
        "aarch64-darwin"
      ];
      inherit (nixpkgs) lib;
      configVars = import ./vars { inherit inputs lib; };
      configLib = import ./lib { inherit lib; };
      specialArgs = { inherit inputs outputs configVars configLib nixpkgs; };
      nix-secrets = configLib.relativeToRoot ./nix-secrets;
    in
    {
      # Custom modules to enable special functionality for nixos or home-manager oriented configs.
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      # Custom modifications/overrides to upstream packages.
      overlays = import ./overlays { inherit inputs outputs; };

      # Custom packages to be shared or upstreamed.
      packages = forAllSystems
        (system:
          let pkgs = nixpkgs.legacyPackages.${system};
          in import ./pkgs { inherit pkgs; }
        );

      # TODO change this to something that has better looking output rules
      # Nix formatter available through 'nix fmt' https://nix-community.github.io/nixpkgs-fmt
      formatter = forAllSystems
        (system:
          nixpkgs.legacyPackages.${system}.nixpkgs-fmt
        );

      # Shell configured with packages that are typically only needed when working on or with nix-config.
      devShells = forAllSystems
        (system:
          let pkgs = nixpkgs.legacyPackages.${system};
          in import ./shell.nix { inherit pkgs; }
        );

      #################### NixOS Configurations ####################
      #
      # Building configurations available through `just rebuild` or `nixos-rebuild --flake .#hostname`

      nixosConfigurations = {
        # Qemu VM dev lab
        grief = lib.nixosSystem {
          inherit specialArgs;
          modules = [
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = specialArgs;
            }
            ./hosts/grief
          ];
        };
        # Qemu VM deployment test lab
        guppy = lib.nixosSystem {
          inherit specialArgs;
          modules = [
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = specialArgs;
            }
            ./hosts/guppy
          ];
        };
        # Theatre - ASUS VivoPC VM40B-S081M
        gusto = lib.nixosSystem {
          inherit specialArgs;
          modules = [
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = specialArgs;
            }
            ./hosts/gusto
          ];
        };
      };
    };
}
