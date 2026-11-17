#!/bin/sh
# Writes the Android 13 themed-icon layer (ic_launcher_monochrome) at each
# density from assets/icon/colophon_monochrome.png. Adaptive icon layers are
# 108dp: mdpi 108px, hdpi 162, xhdpi 216, xxhdpi 324, xxxhdpi 432.
set -e
cd "$(dirname "$0")/.."
src=assets/icon/colophon_monochrome.png
for pair in mdpi:108 hdpi:162 xhdpi:216 xxhdpi:324 xxxhdpi:432; do
  d=${pair%%:*}; px=${pair##*:}
  sips -z "$px" "$px" "$src" --out "android/app/src/main/res/mipmap-$d/ic_launcher_monochrome.png" >/dev/null
done
