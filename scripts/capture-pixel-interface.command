#!/bin/zsh
set -eu
project_dir="$(cd -- "$(dirname -- "$0")/.." && pwd)"
godot_executable='/Applications/Godot.app/Contents/MacOS/Godot'
if [[ ! -x "$godot_executable" ]]; then
  print -u2 -- 'Godot was not found in /Applications/Godot.app.'
  exit 1
fi
capture_dir="$project_dir/.godot/pixel-preview"
mkdir -p "$capture_dir"
touch "$capture_dir/.capture-start"
"$godot_executable" --path "$project_dir" --script tests/render_pixel_preview.gd --quit-after 1200 --log-file "$capture_dir/capture.log"
if [[ ! -f "$capture_dir/manifest.json" || ! "$capture_dir/manifest.json" -nt "$capture_dir/.capture-start" ]]; then
  print -u2 -- "Capture did not finish. See $capture_dir/capture.log"
  exit 1
fi
print -- "Capture finished. Review images in $capture_dir"
open "$capture_dir"
