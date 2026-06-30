#!/bin/bash

# ==============================================================================
# Historias Nativas - Simple Render Queue
# Script: render_queue_manager.sh
# 
# Description:
# Iterates through all .blend files in a directory and renders their full 
# animation range. Skips completed scenes logged in omit.list.
# ==============================================================================

BLENDER_EXE=${BLENDER_PATH:-"blender"}
OMIT_FILE="./omit.list"
processed_count=0

echo "Starting Standard Render Queue..."

for file in *.blend; do
    [ -e "$file" ] || continue

    SCENE=$(basename "$file" .blend)
    
    if [ -e "$OMIT_FILE" ] && grep -qw "$SCENE" "$OMIT_FILE"; then
        echo "[SKIP] $SCENE is in omit.list."
        continue
    fi

    echo ">>> Rendering Full Animation: $SCENE"
    $BLENDER_EXE -b "$file" --render-anim > "${SCENE}_render.log" 2>&1
    
    echo "[SUCCESS] Finished $SCENE."
    echo "$SCENE" >> "$OMIT_FILE"
    let "processed_count+=1"
done

echo "Render Queue Finished. Total scenes processed: $processed_count"
exit 0
