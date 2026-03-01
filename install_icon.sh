#!/bin/bash
ICON_DIR="/Users/aryanrogye/Code/Projects/HexCalculator/HexCalculator/Assets.xcassets/AppIcon.appiconset"
SOURCE_IMAGE="/Users/aryanrogye/.gemini/antigravity/brain/a1736dab-850d-4c2a-b47e-5f7132431238/hex_calc_icon_v2_1772395000451.png"

mkdir -p "$ICON_DIR"

# Generate ICNS/sizes
sips -z 16 16 "$SOURCE_IMAGE" --out "$ICON_DIR/16.png"
sips -z 32 32 "$SOURCE_IMAGE" --out "$ICON_DIR/16@2x.png"
sips -z 32 32 "$SOURCE_IMAGE" --out "$ICON_DIR/32.png"
sips -z 64 64 "$SOURCE_IMAGE" --out "$ICON_DIR/32@2x.png"
sips -z 128 128 "$SOURCE_IMAGE" --out "$ICON_DIR/128.png"
sips -z 256 256 "$SOURCE_IMAGE" --out "$ICON_DIR/128@2x.png"
sips -z 256 256 "$SOURCE_IMAGE" --out "$ICON_DIR/256.png"
sips -z 512 512 "$SOURCE_IMAGE" --out "$ICON_DIR/256@2x.png"
sips -z 512 512 "$SOURCE_IMAGE" --out "$ICON_DIR/512.png"
sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ICON_DIR/512@2x.png"

# Write Contents.json
cat << 'JSON_EOF' > "$ICON_DIR/Contents.json"
{
  "images" : [
    { "size" : "16x16", "idiom" : "mac", "filename" : "16.png", "scale" : "1x" },
    { "size" : "16x16", "idiom" : "mac", "filename" : "16@2x.png", "scale" : "2x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "32.png", "scale" : "1x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "32@2x.png", "scale" : "2x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "128.png", "scale" : "1x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "128@2x.png", "scale" : "2x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "256.png", "scale" : "1x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "256@2x.png", "scale" : "2x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "512.png", "scale" : "1x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "512@2x.png", "scale" : "2x" }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
JSON_EOF

echo "Done"
