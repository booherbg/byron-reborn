#!/bin/sh
# Static preview gallery: renders/index.html
set -e
out=renders/index.html
{
  echo '<!doctype html><meta charset="utf-8"><title>Byron Reborn previews</title>'
  echo '<style>body{font-family:system-ui;background:#111;color:#eee;margin:2rem}'
  echo 'figure{display:inline-block;margin:1rem;text-align:center}img{max-width:340px;border-radius:8px;background:#fff}</style>'
  echo "<h1>Byron Reborn — $(git rev-parse --short HEAD 2>/dev/null || echo dev)</h1>"
  for f in renders/*.png; do
    b=$(basename "$f")
    echo "<figure><img src=\"$b\" alt=\"$b\"><figcaption>$b</figcaption></figure>"
  done
} > "$out"
echo "gallery: $out"
