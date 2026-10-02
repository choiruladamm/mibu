#!/bin/sh
# Regenerates the PNGs from the 00.0 "garis saldo" mark (needs imagemagick + bc).
# render <out> <bg> <offset in 200-space> <scale> <hole color or "none">
cd "$(dirname "$0")" || exit 1

render() {
  out=$1; bg=$2; off=$3; sc=$4; hole=$5
  t=$(echo "$off*5.12" | bc -l); k=$(echo "5.12*$sc" | bc -l)
  tf="translate $t,$t scale $k,$k"
  magick -size 1024x1024 "xc:$bg" \
    -fill none -stroke white -strokewidth 16 \
    -draw "stroke-linecap round $tf path 'M36,118 C58,158 74,50 100,66 C126,82 132,146 158,92'" \
    -fill white -stroke none -draw "$tf circle 158,92 158,108" \
    PNG32:"$out"
  if [ "$hole" != none ]; then
    magick "$out" -fill "$hole" -stroke none -draw "$tf circle 158,92 158,98" PNG32:"$out"
  fi
}

render icon_ios.png '#111111' 0 1 '#111111'
render icon_fg.png none 30 0.7 '#111111'
render icon_mono.png none 30 0.7 none
render splash_mark.png none 45 0.55 '#111111'
# splash with wordmark (ios + android < 12): mark scaled to 320px on a 512 canvas, shown at 4x density
magick splash_mark.png -resize 582x582 -gravity center -crop 512x512+0+0 +repage -background none \
  -extent 512x512 -page +0-70 -flatten tmp_mark.png
magick tmp_mark.png \
  -font ../fonts/Archivo-900.ttf -pointsize 104 -kerning -6 -fill white -gravity center -annotate +0+95 'mibu' \
  PNG32:splash_ios.png
rm tmp_mark.png
magick icon_ios.png -alpha off PNG24:icon_ios.png
