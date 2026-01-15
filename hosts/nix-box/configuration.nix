{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  # --- Enable Flakes & Standalone Nix Command ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  # --- Boot & Kernel ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- Networking ---
  networking.hostName = "nix-box";
  systemd.network.enable = true;
  networking.useDHCP = false;

  systemd.network.networks."10-lan" = {
    matchConfig.Name = ["enp7s0"];

    networkConfig = {
      DHCP = "yes";
      IPv6PrivacyExtensions = "yes"; 
    };

    ipv6AcceptRAConfig = {
      Token = "::dead:beef";
    };
  };


  # --- Locale & Time ---
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "br-abnt2";

  # --- System Configuration ---
  nix.package = pkgs.lixPackageSets.stable.lix;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.steam.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/guilherme/nixos-config";
  };

  # --- User Configuration ---
  users.users.guilherme = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ]; 
    packages = with pkgs; [
      # Desktop
      hyprshot
      hyprlock
      wlogout
      wofi
      mako

      # Apps
      librewolf
      kitty
      qbittorrent
      keepassxc
      lxqt.pavucontrol-qt
      udiskie
      btop
      discord
      lm_sensors
      fastfetch
      mpv
      
      # Theming & Media
      playerctl
      bibata-cursors
      papirus-icon-theme
      catppuccin-qt5ct
      bibata-cursors
      papirus-icon-theme
      kdePackages.qtstyleplugin-kvantum
      libsForQt5.qtstyleplugin-kvantum
      kdePackages.qt6ct
      libsForQt5.qt5ct
      nwg-look
      (catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "lavender" ];
      })
      (catppuccin-kvantum.override {
        variant = "mocha";
        accent = "lavender";
      })
    ];
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # --- Core Programs & Services ---
  security.sudo-rs.enable = true;
  security.polkit.enable = true;
  programs.dconf.enable = true;
  
  # SSH
  services.openssh = {
    enable = true;
    openFirewall = false;
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      UsePAM = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = false;
      X11Forwarding = false;
      GatewayPorts = "no";
      AllowStreamLocalForwarding = "no";
      ClientAliveInterval = 300;
      LoginGraceTime = 30;
      KexAlgorithms = ["mlkem768x25519-sha256" "sntrup761x25519-sha512@openssh.com" "curve25519-sha256"];
      HostKeyAlgorithms = "ssh-ed25519";
      Ciphers = ["aes256-gcm@openssh.com"];
      Macs = ["hmac-sha2-512-etm@openssh.com"];
      PubkeyAcceptedAlgorithms = "ssh-ed25519,sk-ssh-ed25519@openssh.com";
    };
  };

  programs.ssh.startAgent = true;
  #programs.gnupg.agent.enableSSHSupport = true;

  # Firewall
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "wg0" ];
    allowedTCPPorts = [ 18931 25600 ];
    allowedUDPPorts = [ 18931 25600 25601 ];
    extraCommands= ''
      # Allow SSH (Port 22) from IPv4 LAN
      iptables -A nixos-fw -p tcp --dport 22 -s 192.168.0.0/24 -j nixos-fw-accept 

      # Allow SSH from IPv6 Link Local
      ip6tables -A nixos-fw -p tcp --dport 22 -s fe80::/10 -j nixos-fw-accept
    '';
  };

  # Hyprland
  programs.hyprland.enable = true;
  services.hypridle.enable = true;
  
  # Waybar
  programs.waybar.enable = true;

  # Audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };

  # --- Theming Configuration ---
  qt.style = "kvantum";
  qt.platformTheme = "qt6ct";

  # Fonts
  fonts.packages = with pkgs.nerd-fonts; [ 
    fira-code 
    fira-mono 
  ];

  # Greetd (Login Screen)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --remember --remember-session --time --asterisks --greeting 'Welcome to Nix' --window-padding 2 --container-padding 3"; 
      };
    };
  };

  # --- System Packages ---
  environment.systemPackages = with pkgs; [
    neovim
    git
    wget
  ];

  # --- Polkit Agent (for hyprland) ---
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
    };
  };

  # --- System Maintenance ---
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ]; # This covers all subvols on that partition
  };
  systemd.services.btrfs-balance = {
    description = "Btrfs Periodic Balance";
    serviceConfig = {
      Type = "oneshot";
      IOClass = "idle";
      IOSchedulingClass = "idle";
    };
    path = [ pkgs.btrfs-progs ];
    script = ''
      # We use dusage=10 (which includes 5) to replicate "5 10" in one pass
      btrfs balance start -dusage=10 -musage=5 /
    '';
  };

  systemd.timers.btrfs-balance = {
    description = "Run weekly Btrfs balance";
    wantedBy = [ "timers.target" ];
    partOf = [ "btrfs-balance.service" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h"; # Helps avoid immediate overlap with other jobs
    };
  };

  # --- Unfree ---
  nixpkgs.config.allowUnfree = true;

  # --- System State ---
  system.stateVersion = "25.11"; 
}
