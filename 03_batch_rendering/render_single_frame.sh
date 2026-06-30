#!/bin/bash

# ==============================================================================
# Historias Nativas - Preview Render Manager
# Script: render_single_frame.sh
# 
# Description:
# Extracts a single representative frame (default: 20) for both the Environment 
# and Character passes to verify compositing and lighting setups.
# ==============================================================================

BLENDER_EXE=${BLENDER_PATH:-"blender"}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ENV_SETUP="$SCRIPT_DIR/../02_render_setup/setup_environment_pass.py"
CHAR_SETUP="$SCRIPT_DIR/../02_render_setup/setup_character_pass.py"

TARGET_FRAME=20
processed_count=0

echo "Starting Single Frame Preview (Frame: $TARGET_FRAME)..."

for file in *.blend; do
    [ -e "$file" ] || continue
    SCENE=$(basename "$file" .blend)
    
    echo ">>> Extracting Previews for: $SCENE"

    echo "    -> Environment Pass (Frame $TARGET_FRAME)..."
    $BLENDER_EXE -b "$file" -P "$ENV_SETUP" -f $TARGET_FRAME > "${SCENE}_env_preview.log" 2>&1
    
    echo "    -> Character Pass (Frame $TARGET_FRAME)..."
    $BLENDER_EXE -b "$file" -P "$CHAR_SETUP" -f $TARGET_FRAME > "${SCENE}_char_preview.log" 2>&1
    
    let "processed_count+=1"
done

echo "Preview Generation Finished. Total scenes processed: $processed_count"
exit 0
