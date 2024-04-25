#!/bin/sh
PS4='\033[1;34m$(date +%H:%M:%S)\033[0m '; set -x

thin_or_copy_library() {
    local src_arch=$1
    local out_arch=$2
    local lib_path=$3
    local lib_tmp_path=$4

    LIB_NAME="$(basename $lib_path)"

    if lipo -info "$lib_path/$src_arch/$LIB_NAME.a" | grep -q "Architectures in the fat file"; then
        # It's a fat library, use lipo to thin it
        lipo -thin "$out_arch" "$lib_path/$src_arch/$LIB_NAME.a" -output "$lib_tmp_path/$out_arch/$LIB_NAME.a"
    else
        # It's not a fat library, just copy it
        cp "$lib_path/$src_arch/$LIB_NAME.a" "$lib_tmp_path/$out_arch/$LIB_NAME.a"
    fi
}

# Usage:
# thin_or_copy_library x86_64 arm64 /path/to/your/library /path/to/temp/library

# Define the path to the libraries and output
LIBS_PATH="./ios/Libraries"
OUTPUT_PATH="./ios/xcframeworks"
TMP_DIR="./tmp"



# Create necessary directories
mkdir -p "$OUTPUT_PATH"
mkdir -p "$TMP_DIR"

# Cleanup: remove any existing .xcframework files in the output directory
for LIB_PATH in "$LIBS_PATH"/*; do
    if [ -d "$LIB_PATH" ]; then
        LIB_NAME="$(basename $LIB_PATH)"
        rm -rf "$OUTPUT_PATH/$LIB_NAME.xcframework"
        mkdir -p "$LIB_PATH/armv7_arm64"
        mkdir -p "$LIB_PATH/x86_64"
    fi
done



# Main loop
for LIB_PATH in "$LIBS_PATH"/*; do
    if [ -d "$LIB_PATH" ]; then
        LIB_NAME="$(basename $LIB_PATH)"
        LIB_TMP_PATH="$TMP_DIR/$LIB_NAME"
        mkdir -p "$LIB_TMP_PATH"
        
        XCFRAMEWORK_PATH="$OUTPUT_PATH/$LIB_NAME.xcframework"
        
        # Ensure the directories exist before thinning libraries
        mkdir -p "$LIB_TMP_PATH/arm64"
        mkdir -p "$LIB_TMP_PATH/x86_64"
        mkdir -p "$LIB_TMP_PATH/arm64_sim"
        
        thin_or_copy_library armv7_arm64 arm64 $LIB_PATH $LIB_TMP_PATH
        thin_or_copy_library x86_64 x86_64 $LIB_PATH $LIB_TMP_PATH

        cp "$LIB_TMP_PATH/arm64/$LIB_NAME.a" "$LIB_TMP_PATH/arm64_sim"
        ./scripts/m1_utils/update_in_place.sh "$LIB_TMP_PATH/arm64_sim/$LIB_NAME.a"

        mkdir -p "$LIB_TMP_PATH/x86_64_arm64_sim"
        lipo -create "$LIB_TMP_PATH/arm64_sim/$LIB_NAME.a" "$LIB_TMP_PATH/x86_64/$LIB_NAME.a" -output "$LIB_TMP_PATH/x86_64_arm64_sim/$LIB_NAME.a"
        
        xcodebuild -create-xcframework \
            -library "$LIB_TMP_PATH/x86_64_arm64_sim/$LIB_NAME.a" \
            -headers "$LIB_PATH/include" \
            -library "$LIB_TMP_PATH/arm64/$LIB_NAME.a" \
            -headers "$LIB_PATH/include" \
            -output $XCFRAMEWORK_PATH
        
    fi
done
