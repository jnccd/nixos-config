{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dobikoConf.gimp;
  ai = cfg.ai;
in
{
  options.dobikoConf.gimp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install GIMP with the plug-ins selected below.

        This replaces the plain `gimp` package from nixpkgs: a plain GIMP does
        not see plug-ins installed through `environment.systemPackages`, so the
        plug-ins have to be wrapped around the GIMP binary.
      '';
    };

    resynthesizer.enabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Add the Resynthesizer plug-in suite: *Filters > Enhance > Heal
        selection* and *Heal transparency*, plus Uncrop, texture synthesis and
        the style/texture renderers.

        Pure C, no GPU or model downloads, so this is enabled everywhere.
      '';
    };

    ai = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Master switch for the heavyweight, model-based GIMP plug-ins (rembg
          background removal and prompt-driven inpainting). Meant for machines
          with enough CPU/GPU headroom, i.e. the gaming hosts; it is off by
          default and enabled per host.
        '';
      };

      rembg = {
        enabled = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Install the AI "Remove Background" plug-in (rembg).  Works on CPU,
            but downloads a ~176 MB u2net model the first time it runs.
          '';
        };
      };

      promptInpaint = {
        enabled = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Install *Filters > AI > Transform Selection with Prompt...*: select
            a region, type a prompt and the selection is regenerated with
            Stable Diffusion (via stable-diffusion.cpp's `sd-cli`).
          '';
        };

        model = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "/home/dobiko/models/sd-v1-5-inpainting.ckpt";
          description = ''
            Path to the checkpoint `sd-cli` loads.  Quote it (it is a string,
            not a path literal, so the model is not copied into the Nix
            store).  An inpainting checkpoint gives the best results, but any
            Stable Diffusion 1.5/SDXL `.ckpt`, `.safetensors` or `.gguf` file
            works: stable-diffusion.cpp detects the format from the file
            contents, so the extension does not matter.

            Leave empty to keep the plug-in installed but report a friendly
            error until a model is chosen.  Can also be overridden at runtime
            with the `GIMP_SD_MODEL` environment variable.

            Download examples (pick one; `~` is the main user's home):

              mkdir -p ~/models

              # Official SD 1.5 inpainting checkpoint (4.3 GB):
              curl -L -o ~/models/sd-v1-5-inpainting.ckpt \
                https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-inpainting/resolve/main/sd-v1-5-inpainting.ckpt

              # Same weights as a single safetensors file (4.3 GB):
              curl -L -o ~/models/sd-v1-5-inpainting.safetensors \
                https://huggingface.co/webui/stable-diffusion-inpainting/resolve/main/sd-v1-5-inpainting.safetensors

              # Smaller fp16 safetensors (2.1 GB):
              curl -L -o ~/models/sd-v1-5-inpainting.safetensors \
                https://huggingface.co/DmitrMakeev/Models-coll/resolve/main/models/sd-v1-5-inpainting.safetensors

              # Quantized GGUF, smallest (1.8 GB) and loads directly:
              curl -L -o ~/models/sd-v1-5-inpainting-Q8_0.gguf \
                https://huggingface.co/gpustack/stable-diffusion-v1-5-inpainting-GGUF/resolve/main/stable-diffusion-v1-5-inpainting-Q8_0.gguf

            Or with the Hugging Face CLI:

              nix shell nixpkgs#huggingface-hub -c huggingface-cli download \
                stable-diffusion-v1-5/stable-diffusion-inpainting \
                sd-v1-5-inpainting.ckpt --local-dir ~/models

            SDXL inpainting (more VRAM; pair it with
            `extraArgs = [ "--vae-tiling" "--offload-to-cpu" ]`):
            `gpustack/stable-diffusion-xl-inpainting-1.0-GGUF`.
          '';
        };

        backend = lib.mkOption {
          type = lib.types.enum [
            "cpu"
            "cuda"
            "rocm"
            "vulkan"
          ];
          default = "cpu";
          description = ''
            Which stable-diffusion.cpp build to wrap: "cuda" for NVIDIA,
            "rocm" for AMD, "vulkan" for the portable GPU path, "cpu" for the
            smallest closure.
          '';
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "--vae-tiling"
            "--offload-to-cpu"
          ];
          description = "Extra sd-cli flags appended to every run.";
        };

        negativePrompt = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Default negative prompt shown in the plug-in dialog.";
        };

        steps = lib.mkOption {
          type = lib.types.ints.between 1 200;
          default = 25;
          description = "Default number of sampling steps.";
        };

        cfgScale = lib.mkOption {
          type = lib.types.float;
          default = 7.0;
          description = "Default classifier-free guidance scale.";
        };

        strength = lib.mkOption {
          type = lib.types.float;
          default = 0.75;
          description = "Default img2img denoising strength (0..1).";
        };

        sampler = lib.mkOption {
          type = lib.types.str;
          default = "euler_a";
          description = "Default sampling method passed to sd-cli.";
        };

        scheduler = lib.mkOption {
          type = lib.types.str;
          default = "karras";
          description = "Default sigma scheduler passed to sd-cli.";
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && config.dobikoConf.nonEssentialGuiPkgs.enabled) {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs lib;
        resynthesizer = cfg.resynthesizer.enabled;
        rembg = ai.enable && ai.rembg.enabled;
        promptInpaint = ai.enable && ai.promptInpaint.enabled;
        promptInpaintModel = ai.promptInpaint.model;
        promptInpaintBackend = ai.promptInpaint.backend;
        promptInpaintExtraArgs = ai.promptInpaint.extraArgs;
        promptInpaintNegativePrompt = ai.promptInpaint.negativePrompt;
        promptInpaintSteps = ai.promptInpaint.steps;
        promptInpaintCfgScale = ai.promptInpaint.cfgScale;
        promptInpaintStrength = ai.promptInpaint.strength;
        promptInpaintSampler = ai.promptInpaint.sampler;
        promptInpaintScheduler = ai.promptInpaint.scheduler;
      })
    ];
  };
}
