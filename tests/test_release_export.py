import contextlib
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import export_release


class ReleaseExportCheck(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.project = Path(self.directory.name)
        (self.project / ".godot-version").write_text("4.7.2\n")
        (self.project / "_sc_").touch()
        self.templates = self.project / "editor_data/export_templates/4.7.2.stable"
        self.templates.mkdir(parents=True)
        for name in ("macos.zip", "windows_release_x86_64.exe"):
            (self.templates / name).touch()
        self.engine = self.project / "Godot"
        self.engine.write_text('''#!/usr/bin/env python3
from pathlib import Path
import sys
folder = Path(__file__).parent
if "--version" in sys.argv:
    print((folder / "version").read_text())
elif (folder / "mode").read_text() == "success":
    output = Path(sys.argv[-1])
    output.write_bytes(b"export fixture")
    if output.suffix == ".exe":
        output.with_suffix(".pck").write_bytes(b"pack fixture")
''')
        self.engine.chmod(0o755)
        (self.project / "version").write_text("4.7.2.stable.official.fixture")
        (self.project / "mode").write_text("success")

    def run_export(self, *arguments):
        with patch.object(export_release, "PROJECT", self.project), patch.object(
            sys, "argv", ["export_release.py", "--godot", str(self.engine), *arguments]
        ), contextlib.redirect_stdout(io.StringIO()):
            export_release.main()

    def test_missing_template_blocks_both_before_export(self):
        (self.templates / "windows_release_x86_64.exe").unlink()
        with self.assertRaisesRegex(RuntimeError, "Missing export templates"):
            self.run_export()
        self.assertFalse((self.project / "build").exists())

    def test_wrong_engine_blocks_export(self):
        (self.project / "version").write_text("4.6.0.stable.official.fixture")
        with self.assertRaisesRegex(RuntimeError, "Expected Godot"):
            self.run_export()
        self.assertFalse((self.project / "build").exists())

    def test_check_does_not_export(self):
        self.run_export("--check")
        self.assertFalse((self.project / "build").exists())

    def test_both_outputs_include_windows_pack(self):
        self.run_export()
        for name in ("macos/Minimized Dungeon.zip", "windows/Minimized Dungeon.exe", "windows/Minimized Dungeon.pck"):
            self.assertGreater((self.project / "build" / name).stat().st_size, 0)

    def test_success_exit_with_stale_output_is_rejected(self):
        import os

        output = self.project / "build/macos/Minimized Dungeon.zip"
        output.parent.mkdir(parents=True)
        output.write_bytes(b"previous release")
        os.utime(output, (1, 1))
        (self.project / "mode").write_text("no-output")
        with self.assertRaisesRegex(RuntimeError, "export failed"):
            self.run_export("--platform", "macos")
        self.assertEqual(output.read_bytes(), b"previous release")


if __name__ == "__main__":
    unittest.main()
