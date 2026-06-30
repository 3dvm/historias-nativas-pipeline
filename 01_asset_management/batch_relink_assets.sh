#!/bin/bash

# ==============================================================================
# Historias Nativas - Pipeline Tools
# Script: batch_relink_assets.sh
# 
# Description:
# Batch processor that iterates over all .blend files in the current directory,
# ignores already processed files using an omission list, and executes the 
# relink_paths.py script headlessly.
# ==============================================================================

# Allow overriding the Blender path via Environment Variable, fallback to system 'blender'
BLENDER_EXE=${BLENDER_PATH:-"blender"}

# Resolve the absolute path of the Python script (assuming it's in the same folder as this bash script)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PYTHON_SCRIPT="$SCRIPT_DIR/relink_paths.py"

OMIT_FILE="./omit.list"

echo "=========================================================="
echo " Starting Batch Asset Relink in: $(pwd)"
echo "=========================================================="

processed_count=0

# Loop safely through all .blend files in the current directory
for file in *.blend; do
    # Skip if no .blend files are found
    [ -e "$file" ] || continue

    SCENE_NAME=$(basename "$file" .blend)
    
    # Check if the scene is already marked in the omit list
    if [ -f "$OMIT_FILE" ] && grep -qw "$SCENE_NAME" "$OMIT_FILE"; then
        echo "[SKIP] Scene '$SCENE_NAME' is in the omit list. Moving to next..."
        continue
    fi

    echo ""
    echo ">>> Processing Scene: $SCENE_NAME"
    
    # Execute Blender headlessly (-b), running the python script (-P), and saving the output to a log
    $BLENDER_EXE -b "$file" -y -P "$PYTHON_SCRIPT" > "${SCENE_NAME}_relink.log" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Scene '$SCENE_NAME' relinked successfully."
        # Add to omit list to prevent re-processing in future runs
        echo "$SCENE_NAME" >> "$OMIT_FILE"
        let "processed_count+=1"
    else
        echo "[ERROR] Failed to process '$SCENE_NAME'. Check ${SCENE_NAME}_relink.log for details."
    fi

done

echo ""
echo "=========================================================="
echo " Batch Relink Finished. Total scenes processed: $processed_count"
echo "=========================================================="

exit 0
