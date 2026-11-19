#!/usr/bin/env python3
"""Export both desktop releases using the project's pinned Godot version."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time


PROJECT = Path(__file__).resolve().parent.parent
PRESETS = {
    "macos": ("macOS", "macos.zip", "macos/Minimized Dungeon.zip"),
    "windows": ("Windows", "windows_release_x86_64.exe", "windows/Minimized Dungeon.exe"),
}


def template_directory(executable, version):
    engine_dir = Path(executable).resolve().parent
    if any((engine_dir / marker).exists() for marker in ("_sc_", "._sc_")):
        return engine_dir / "editor_data/export_templates" / version
    if sys.platform == "darwin":
        base = Path.home() / "Library/Application Support/Godot"
    elif sys.platform == "win32":
        base = Path(os.environ["APPDATA"]) / "Godot"
    else:
        base = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "godot"
    return base / "export_templates" / version


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT"), help="Godot executable path")
    parser.add_argument("--platform", choices=["both", *PRESETS], default="both")
    parser.add_argument("--check", action="store_true", help="Check prerequisites without exporting")
    args = parser.parse_args()
    executable = args.godot or shutil.which("godot") or shutil.which("godot4")
    if not executable and sys.platform == "darwin":
        executable = "/Applications/Godot.app/Contents/MacOS/Godot"
    if not executable:
        raise RuntimeError("Godot not found. Supply --godot /path/to/Godot.")
    executable = shutil.which(executable) or executable
    result = subprocess.run([executable, "--version"], check=True, capture_output=True, text=True, timeout=15)
    expected = (PROJECT / ".godot-version").read_text().strip() + ".stable"
    actual = ".".join(result.stdout.strip().split(".")[:4])
    if actual != expected:
        raise RuntimeError(f"Expected Godot {expected}; found {result.stdout.strip()}.")
    platforms = list(PRESETS) if args.platform == "both" else [args.platform]
    directory = template_directory(executable, expected)
    missing = [PRESETS[name][1] for name in platforms if not (directory / PRESETS[name][1]).is_file()]
    if missing:
        raise RuntimeError(
            f"Missing export templates in {directory}: {', '.join(missing)}. "
            "Install matching templates through Godot > Editor > Manage Export Templates."
        )
    print(f"Godot {expected}: export prerequisites available.", flush=True)
    if args.check:
        return
    for name in platforms:
        preset, _, relative = PRESETS[name]
        output = PROJECT / "build" / relative
        output.parent.mkdir(parents=True, exist_ok=True)
        started = time.time_ns()
        result = subprocess.run(
            [executable, "--headless", "--path", str(PROJECT), "--export-release", preset, str(output)],
            timeout=180,
        )
        if result.returncode or not output.is_file() or not output.stat().st_size or output.stat().st_mtime_ns < started:
            raise RuntimeError(f"{preset} export failed; review Godot output above.")
        if name == "windows":
            pack = output.with_suffix(".pck")
            if not pack.is_file() or not pack.stat().st_size or pack.stat().st_mtime_ns < started:
                raise RuntimeError("Windows export is missing a fresh .pck file.")
        print(f"Exported {output}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"Export blocked: {error}", file=sys.stderr)
        sys.exit(1)
