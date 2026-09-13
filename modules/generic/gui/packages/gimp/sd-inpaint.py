#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GIMP 3 plug-in: prompt-driven inpainting of the current selection.

The heavy lifting is done by ``stable-diffusion.cpp``'s ``sd-cli`` (packaged by
nixpkgs, MIT licensed).  This plug-in is only the bridge between GIMP and that
CLI:

1. export the current image as the img2img "init" image,
2. turn the current selection into a black/white inpainting mask,
3. run ``sd-cli -i init.png --mask mask.png -p <prompt> ...``,
4. load the generated PNG back as a new layer.

It is installed and (optionally) enabled by the nixos-config module
``modules/generic/gui/packages/gimp/default.nix``.  The defaults live in the
adjacent, Nix-generated ``sd-inpaint.json``; ``GIMP_SD_CLI`` and
``GIMP_SD_MODEL`` override the CLI path and the model path at runtime without a
rebuild.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile

import gi

gi.require_version("Gimp", "3.0")
gi.require_version("GimpUi", "3.0")
gi.require_version("Gtk", "3.0")

from gi.repository import Gimp, GimpUi, GLib, Gtk, Gio  # noqa: E402

CONFIG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sd-inpaint.json")

DEFAULT_CONFIG = {
    "sd_cli": "sd-cli",
    "model": "",
    "steps": 25,
    "cfg_scale": 7.0,
    "strength": 0.75,
    "sampler": "euler_a",
    "scheduler": "karras",
    "negative_prompt": "",
    "extra_args": [],
}

SAMPLERS = [
    "euler",
    "euler_a",
    "heun",
    "dpm2",
    "dpm++2s_a",
    "dpm++2m",
    "dpm++2mv2",
    "ipndm",
    "ipndm_v",
    "lcm",
    "ddim_trailing",
    "tcd",
    "res_multistep",
    "res_2s",
    "er_sde",
]

SCHEDULERS = [
    "discrete",
    "karras",
    "exponential",
    "ays",
    "gits",
    "smoothstep",
    "sgm_uniform",
    "simple",
    "kl_optimal",
    "lcm",
]


def load_config() -> dict:
    config = dict(DEFAULT_CONFIG)
    try:
        with open(CONFIG_PATH) as handle:
            config.update(json.load(handle))
    except (OSError, ValueError):
        pass
    for env, key in (("GIMP_SD_CLI", "sd_cli"), ("GIMP_SD_MODEL", "model")):
        if os.environ.get(env):
            config[key] = os.environ[env]
    return config


def _error(message: str) -> None:
    Gimp.message(message)
    # A dialog is nicer interactively, but in `-i` (headless) runs GTK may not
    # be initialised, so never let the notification itself fail the procedure.
    try:
        dialog = Gtk.MessageDialog(
            None,
            0,
            Gtk.MessageType.ERROR,
            Gtk.ButtonsType.CLOSE,
            "Stable Diffusion inpainting failed",
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()
    except Exception:  # noqa: BLE001
        pass


class SdInpaintPlugin(Gimp.PlugIn):
    def __init__(self) -> None:
        super().__init__()
        self.config = load_config()

    def do_query_procedures(self) -> list:
        return ["python-fu-sd-inpaint"]

    def do_set_i18n(self, name: str) -> bool:
        return False

    def do_create_procedure(self, name: str):
        procedure = Gimp.ImageProcedure.new(
            self, name, Gimp.PDBProcType.PLUGIN, self.run, None
        )
        procedure.set_image_types("RGB*, GRAY*")
        procedure.set_menu_label("Transform Selection with Prompt...")
        procedure.add_menu_path("<Image>/Filters/AI/")
        procedure.set_documentation(
            "Inpaint the current selection from a text prompt",
            "Uses stable-diffusion.cpp (sd-cli) img2img inpainting: the current "
            "selection becomes the mask and the prompt describes what should be "
            "drawn inside it. The result is added as a new layer.",
            name,
        )
        procedure.set_attribution("nixos-config", "MIT", "2026")
        return procedure

    # ------------------------------------------------------------------ helpers

    def _settings_dialog(self, defaults: dict) -> dict | None:
        """Small GTK dialog for the per-run parameters."""
        dialog = Gtk.Dialog(title="Stable Diffusion Inpaint", flags=0)
        dialog.add_buttons(
            Gtk.STOCK_CANCEL,
            Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OK,
            Gtk.ResponseType.OK,
        )
        box = dialog.get_content_area()
        box.set_spacing(8)
        box.set_border_width(12)

        def entry_row(label: str, value: str) -> Gtk.Entry:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            caption = Gtk.Label(label=label)
            caption.set_xalign(0.0)
            caption.set_size_request(110, -1)
            entry = Gtk.Entry()
            entry.set_text(value)
            entry.set_hexpand(True)
            row.pack_start(caption, False, False, 0)
            row.pack_start(entry, True, True, 0)
            box.pack_start(row, False, False, 0)
            return entry

        def spin_row(label: str, value: float, lower: float, upper: float,
                     step: float, digits: int) -> Gtk.SpinButton:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            caption = Gtk.Label(label=label)
            caption.set_xalign(0.0)
            caption.set_size_request(110, -1)
            adjustment = Gtk.Adjustment(value, lower, upper, step, step * 10, 0)
            spin = Gtk.SpinButton(adjustment=adjustment, digits=digits)
            spin.set_value(value)
            row.pack_start(caption, False, False, 0)
            row.pack_start(spin, False, False, 0)
            box.pack_start(row, False, False, 0)
            return spin

        def combo_row(label: str, values: list, current: str) -> Gtk.ComboBoxText:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            caption = Gtk.Label(label=label)
            caption.set_xalign(0.0)
            caption.set_size_request(110, -1)
            combo = Gtk.ComboBoxText()
            for item in values:
                combo.append_text(item)
            combo.set_active(values.index(current) if current in values else 0)
            row.pack_start(caption, False, False, 0)
            row.pack_start(combo, True, True, 0)
            box.pack_start(row, False, False, 0)
            return combo

        model_entry = entry_row("Model", str(defaults["model"]))
        prompt_entry = entry_row("Prompt", "")
        negative_entry = entry_row("Negative", str(defaults["negative_prompt"]))
        steps_spin = spin_row("Steps", float(defaults["steps"]), 1, 200, 1, 0)
        cfg_spin = spin_row("CFG scale", float(defaults["cfg_scale"]), 0, 30, 0.5, 1)
        strength_spin = spin_row("Strength", float(defaults["strength"]), 0, 1, 0.05, 2)
        seed_spin = spin_row("Seed (-1 = random)", -1.0, -1, 2**31 - 1, 1, 0)
        sampler_combo = combo_row("Sampler", SAMPLERS, str(defaults["sampler"]))
        scheduler_combo = combo_row("Scheduler", SCHEDULERS, str(defaults["scheduler"]))

        dialog.show_all()
        response = dialog.run()
        if response != Gtk.ResponseType.OK:
            dialog.destroy()
            return None

        result = {
            "model": model_entry.get_text().strip(),
            "prompt": prompt_entry.get_text().strip(),
            "negative_prompt": negative_entry.get_text().strip(),
            "steps": int(steps_spin.get_value()),
            "cfg_scale": float(cfg_spin.get_value()),
            "strength": float(strength_spin.get_value()),
            "seed": int(seed_spin.get_value()),
            "sampler": sampler_combo.get_active_text(),
            "scheduler": scheduler_combo.get_active_text(),
        }
        dialog.destroy()
        return result

    def _export_init_image(self, image, path: str) -> None:
        Gimp.file_save(
            Gimp.RunMode.NONINTERACTIVE, image, Gio.File.new_for_path(path), None
        )

    def _export_selection_mask(self, image, path: str) -> None:
        """Save the current selection as a full-size black/white PNG mask."""
        width = image.get_width()
        height = image.get_height()

        # A throw-away layer whose layer mask is initialised from the selection:
        # white inside the selection, black outside.  That is exactly the
        # convention sd-cli expects for --mask (white = repaint).
        carrier = Gimp.Layer.new(
            image,
            "sd-inpaint-mask",
            width,
            height,
            Gimp.ImageType.RGBA_IMAGE,
            100.0,
            Gimp.LayerMode.NORMAL,
        )
        image.insert_layer(carrier, None, 0)
        try:
            carrier.add_mask(carrier.create_mask(Gimp.AddMaskType.SELECTION))
            mask_image = Gimp.Image.new(width, height, Gimp.ImageBaseType.GRAY)
            try:
                mask_layer = Gimp.Layer.new_from_drawable(carrier.get_mask(), mask_image)
                mask_image.insert_layer(mask_layer, None, -1)
                Gimp.file_save(
                    Gimp.RunMode.NONINTERACTIVE,
                    mask_image,
                    Gio.File.new_for_path(path),
                    None,
                )
            finally:
                mask_image.delete()
        finally:
            carrier.remove()

    def _run_sd_cli(self, run: dict, init_path: str, mask_path: str, out_path: str):
        command = [
            self.config["sd_cli"],
            "-m",
            run["model"],
            "-p",
            run["prompt"],
            "-n",
            run["negative_prompt"],
            "-i",
            init_path,
            "--mask",
            mask_path,
            "--steps",
            str(run["steps"]),
            "--cfg-scale",
            str(run["cfg_scale"]),
            "--strength",
            str(run["strength"]),
            "--seed",
            str(run["seed"]),
            "--sampling-method",
            run["sampler"],
            "--scheduler",
            run["scheduler"],
            "-o",
            out_path,
        ]
        command.extend(str(extra) for extra in (self.config.get("extra_args") or []))
        return subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )

    # --------------------------------------------------------------------- run

    def run(self, procedure, run_mode, image, drawables, config, run_data):
        GimpUi.init(procedure.get_name())

        success, non_empty, _x1, _y1, _x2, _y2 = Gimp.Selection.bounds(image)
        if not non_empty:
            _error(
                "Select the region you want to change first (any selection tool, "
                "then Filters > AI > Transform Selection with Prompt)."
            )
            return procedure.new_return_values(Gimp.PDBStatusType.CALLING_ERROR, None)

        if run_mode == Gimp.RunMode.INTERACTIVE:
            values = self._settings_dialog(self.config)
            if values is None:
                return procedure.new_return_values(Gimp.PDBStatusType.CANCEL, None)
        else:
            values = {
                "model": self.config["model"],
                "prompt": "",
                "negative_prompt": self.config["negative_prompt"],
                "steps": self.config["steps"],
                "cfg_scale": self.config["cfg_scale"],
                "strength": self.config["strength"],
                "seed": -1,
                "sampler": self.config["sampler"],
                "scheduler": self.config["scheduler"],
            }

        model = values["model"]
        if not model or not os.path.exists(model):
            _error(
                "No Stable Diffusion model found.\n\nSet "
                "dobikoConf.gimp.ai.promptInpaint.model to a .safetensors/.gguf "
                "checkpoint (an inpainting checkpoint works best) or export "
                "GIMP_SD_MODEL before starting GIMP."
            )
            return procedure.new_return_values(Gimp.PDBStatusType.CALLING_ERROR, None)
        if not values["prompt"]:
            _error("The prompt must not be empty.")
            return procedure.new_return_values(Gimp.PDBStatusType.CALLING_ERROR, None)

        workdir = tempfile.mkdtemp(prefix="gimp-sd-inpaint-")
        init_path = os.path.join(workdir, "init.png")
        mask_path = os.path.join(workdir, "mask.png")
        out_path = os.path.join(workdir, "result.png")

        image.undo_group_start()
        try:
            Gimp.progress_init("Stable Diffusion inpainting...")
            self._export_init_image(image, init_path)
            self._export_selection_mask(image, mask_path)
            Gimp.progress_update(0.1)

            Gimp.message("Running Stable Diffusion, this can take a while...")
            process = self._run_sd_cli(values, init_path, mask_path, out_path)
            Gimp.progress_update(0.9)

            if process.returncode != 0 or not os.path.exists(out_path):
                tail = "\n".join((process.stdout or "").splitlines()[-12:])
                _error(f"sd-cli exited with {process.returncode}.\n\n{tail}")
                return procedure.new_return_values(Gimp.PDBStatusType.EXECUTION_ERROR, None)

            result_layer = Gimp.file_load_layer(
                Gimp.RunMode.NONINTERACTIVE, image, Gio.File.new_for_path(out_path)
            )
            image.insert_layer(result_layer, None, 0)
            result_layer.set_name("SD inpaint")
            Gimp.displays_flush()
        except Exception as exception:  # noqa: BLE001 - report anything to the user
            _error(f"{type(exception).__name__}: {exception}")
            return procedure.new_return_values(Gimp.PDBStatusType.EXECUTION_ERROR, None)
        finally:
            Gimp.progress_end()
            image.undo_group_end()
            for path in (init_path, mask_path, out_path):
                try:
                    os.remove(path)
                except OSError:
                    pass
            try:
                os.rmdir(workdir)
            except OSError:
                pass

        if run_mode == Gimp.RunMode.INTERACTIVE:
            Gimp.message("Stable Diffusion inpainting complete.")

        return procedure.new_return_values(Gimp.PDBStatusType.SUCCESS, None)


if __name__ == "__main__":
    Gimp.main(SdInpaintPlugin.__gtype__, sys.argv)
