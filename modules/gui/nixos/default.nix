{ config, pkgs, globalArgs, ... }:
{
  imports = [
    ./gaming.nix
  ];

  # --- Packages ---

  environment.systemPackages = with pkgs; [
    alsa-utils
    sddm-astronaut
    
    # Neovim fonts
    plemoljp-nf
  ];

  # --- Programs ---

  # ༄

  # --- UI ---

  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    settings = {
      Users.HideUsers = "nixbld1,nixbld10,nixbld11,nixbld12,nixbld13,nixbld14,nixbld15,nixbld16,nixbld17,nixbld18,nixbld19,nixbld2,nixbld20,nixbld21,nixbld22,nixbld23,nixbld24,nixbld25,nixbld26,nixbld27,nixbld28,nixbld29,nixbld3,nixbld30,nixbld31,nixbld32,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9,runner";
    };
    theme = "sddm-astronaut-theme";
  };
  services.desktopManager.plasma6.enable = true;

  # --- IO ---

  # Configure keymap
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
  console.keyMap = "de";

  services.printing.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true; #aplay -D hdmi:CARD=NVidia,DEV=1 ./Downloads/Free_Test_Data_1MB_WAV.wav 
  
  #   wireplumber.extraConfig = {
  #     "wh-1000xm3-ldac-hq" = {
  #       "monitor.alsa.rules" = [
  #         {
  #           matches = [
  #             {
  #               "node.name" = "alsa_output.pci0000:00/0000:00:03.1.hdmi-stereo-extra1";
  #               # "node.name" = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
  #               # "node.name" = "alsa_output.pci-0000_01_00.1.hdmi-stereo-extra2";
  #             }
  #           ];
  #           actions = {
  #             update-props = {
  #               "node.description" = "Test1234";
  #               "node.nick" = "Test1234";
  #             };
  #           };
  #         }
  #       ];
  #     };
  #     "50-alsa-config" = {
  #       "alsa.use-ucm" = true;
  #     };
  #     "90-enable-hdmi" = {
  #       "properties" = {
  #         "api.alsa.use-acp" = true;
  #         "api.alsa.card" = "NVidia";
  #         "api.alsa.device" = 1;
  #         "node.name" = "hdmi-output-nvidia";
  #       };
  #     };
  #     "displayport-audio" = {
  #       "context.objects" =  [
  #           {
  #             "factory" = "adapter";
  #             "args" = {
  #               "factory.name"           = "api.alsa.pcm.sink";
  #               "node.name"              = "displayport-audio";
  #               "node.description"       = "Undetected DP Audio";
  #               "media.class"            = "Audio/Sink";
  #               "api.alsa.path"          = "hw:0,1";
  #             };
  #           }
  #         ];
  #     };
  #   };
  };

  # environment.etc."wireplumber/alsa-monitor.conf.d/90-hdmi.conf".text = ''
  #   properties = {
  #     api.alsa.use-acp = true;
  #     api.alsa.card = "NVidia";
  #     api.alsa.device = 1;
  #     node.name = "hdmi-output-nvidia";
  #   }
  # '';

  # environment.etc."wireplumber/alsa-monitor.conf.d/90-displayport-audio.conf".text = ''
  #   context.objects = [
  #     {
  #       factory = adapter;
  #       args = {
  #         factory.name           = api.alsa.pcm.sink;
  #         node.name              = "displayport-audio";
  #         node.description       = "Undetected DP Audio";
  #         media.class            = "Audio/Sink";
  #         api.alsa.path          = "hw:0,1";
  #       }
  #     }
  #   ]
  # '';

  # environment.etc."wireplumber/alsa-monitor.conf.d/50-alsa-config.conf".text = ''
  #   monitor.alsa.properties = {
  #     # Use ALSA-Card-Profile devices. They use UCM or the profile
  #     # configuration to configure the device and mixer settings.
  #     # alsa.use-acp = true
  #     # Use UCM instead of profile when available. Can be disabled
  #     # to skip trying to use the UCM profile.
  #     alsa.use-ucm = true
  #   }
  # '';
}
