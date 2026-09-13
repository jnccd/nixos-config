# Builds the GIMP package used by this configuration.  This is deliberately a
# plain function and not a module: the NixOS side lives in ./default.nix.
{
  pkgs,
  lib,
  resynthesizer ? true,
  rembg ? false,
  promptInpaint ? false,
  promptInpaintModel ? "",
  promptInpaintBackend ? "cpu",
  promptInpaintExtraArgs ? [ ],
  promptInpaintNegativePrompt ? "",
  promptInpaintSteps ? 25,
  promptInpaintCfgScale ? 7.0,
  promptInpaintStrength ? 0.75,
  promptInpaintSampler ? "euler_a",
  promptInpaintScheduler ? "karras",
}:

let
  inherit (pkgs) gimp;

  # Python GIMP runs its Python plug-ins with.  Only PyGObject is needed: GIMP
  # exports GI_TYPELIB_PATH/LD_LIBRARY_PATH to its children, so `Gimp-3.0` is
  # found at runtime.
  gimpPython = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);

  # Separate interpreter that can run `rembg`.  Keeping it out of gimpPython
  # avoids pulling onnxruntime into every Python plug-in GIMP spawns.
  rembgPython = pkgs.python3.withPackages (
    ps: [ (ps.rembg.override { withCli = true; }) ]
  );

  # gvardi/gimp-rembg-plugin -- GIMP 3 background removal on top of rembg.
  removeBgPlugin = pkgs.stdenv.mkDerivation {
    pname = "gimp-plugin-remove-bg";
    version = "unstable-2025-07-27";

    src = pkgs.fetchFromGitHub {
      owner = "gvardi";
      repo = "gimp-rembg-plugin";
      rev = "1a8a0dc71d4135b638e703df315139357a2e4529";
      hash = "sha256-L8GJXHcprNtBdiQTe/Cwx1HGJ/gK4yqdUsKFWP37cZ0=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      pluginDir="$out/${gimp.targetPluginDir}/remove-bg"
      install -Dm755 RemoveBG.py "$pluginDir/remove-bg.py"
      # Upstream shells out to `python -m rembg.cli`, which no longer runs
      # anything with rembg 2.x (there is no __main__ guard in rembg/cli.py).
      # Use the packaged rembg console script and GIMP's Python as the plug-in
      # interpreter.
      substituteInPlace "$pluginDir/remove-bg.py" \
        --replace-fail "#!/usr/bin/env python3" "#!${gimpPython}/bin/python3" \
        --replace-fail "str(python_exe), '-m', 'rembg.cli', 'i'" "'${rembgPython}/bin/rembg', 'i'"
      install -Dm644 ${removeBgConfig} "$pluginDir/config.ini"
      runHook postInstall
    '';
  };

  removeBgConfig = pkgs.writeText "remove-bg-config.ini" ''
    [Paths]
    python_executable = ${rembgPython}/bin/python3

    [Settings]
    default_alpha_matting_value = 15
    default_model = 0
    default_as_mask = False
    default_alpha_matting = False
    default_make_square = False
    default_process_all_images = False

    [Debug]
    debug_enabled = False
  '';

  # stable-diffusion.cpp build used by the prompt-inpainting plug-in.  The
  # CUDA/ROCm/Vulkan variants are only referenced for the selected backend, so
  # a CPU host never evaluates the CUDA package set.
  stableDiffusionCpp =
    {
      cpu = pkgs.stable-diffusion-cpp;
      cuda = pkgs.stable-diffusion-cpp-cuda;
      rocm = pkgs.stable-diffusion-cpp-rocm;
      vulkan = pkgs.stable-diffusion-cpp-vulkan;
    }
    .${promptInpaintBackend};

  # The "select a region and transform it with a prompt" plug-in.  It is our
  # own (MIT) bridge between GIMP and sd-cli, so no external server is needed.
  sdInpaintPlugin = pkgs.stdenv.mkDerivation {
    pname = "gimp-plugin-sd-inpaint";
    version = "1.0.0";

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      pluginDir="$out/${gimp.targetPluginDir}/sd-inpaint"
      install -Dm755 ${./sd-inpaint.py} "$pluginDir/sd-inpaint.py"
      substituteInPlace "$pluginDir/sd-inpaint.py" \
        --replace-fail "#!/usr/bin/env python3" "#!${gimpPython}/bin/python3"
      install -Dm644 ${sdInpaintConfig} "$pluginDir/sd-inpaint.json"
      runHook postInstall
    '';
  };

  sdInpaintConfig = pkgs.writeText "sd-inpaint.json" (
    builtins.toJSON {
      sd_cli = "${stableDiffusionCpp}/bin/sd-cli";
      model = promptInpaintModel;
      steps = promptInpaintSteps;
      cfg_scale = promptInpaintCfgScale;
      strength = promptInpaintStrength;
      sampler = promptInpaintSampler;
      scheduler = promptInpaintScheduler;
      negative_prompt = promptInpaintNegativePrompt;
      extra_args = promptInpaintExtraArgs;
    }
  );

  plugins =
    lib.optionals resynthesizer [ pkgs.gimpPlugins.resynthesizer ]
    ++ lib.optionals rembg [ removeBgPlugin ]
    ++ lib.optionals promptInpaint [ sdInpaintPlugin ];
in
if plugins == [ ] then gimp else pkgs.gimp-with-plugins.override { inherit plugins; }
