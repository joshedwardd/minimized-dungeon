# Dungeon Pixel

Original project bitmap font authored for this interface on 2026-11-17. No external font file or third-party font license is used.

The source glyph drawings are in `scripts/build_pixel_font.py`. The atlas PNG and BMFont descriptor are generated from those drawings. Do not hand-edit generated outputs. Rebuild with:

```sh
python3 scripts/build_pixel_font.py
```

Coverage: printable ASCII (32-126), including distinct uppercase/lowercase, digits, punctuation, and the ellipsis glyph used by Godot. This is the existing English interface's character set, not a localization font.

Native raster size is 8, with a 10-pixel line height. The shared font resource enforces integer bitmap scaling: 16 for body text and 24 for headings. The build also produces an inspection sample in `.godot/pixel-preview/font-sample.png`.
