#!/bin/bash

# ==============================================================================
# Historias Nativas - Render Farm Orchestrator
# Script: render_missing_passes.sh
# 
# Description:
# Intelligent render manager. Parses an omission list (omit.list) to determine 
# if a scene is completely finished, or if it's missing specific frame ranges 
# for the Environment ('f') or Character ('p') passes.
# Automatically injects the correct Python mutation script per pass.
# ==============================================================================

BLENDER_EXE=${BLENDER_PATH:-"blender"}

# Resolve dynamic paths for the Python mutation scripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ENV_SETUP="$SCRIPT_DIR/../02_render_setup/setup_environment_pass.py"
CHAR_SETUP="$SCRIPT_DIR/../02_render_setup/setup_character_pass.py"

OMIT_FILE="./omit.list"
processed_count=0

echo "=========================================================="
echo " Starting Intelligent Render Queue in: $(pwd)"
echo "=========================================================="

for file in *.blend; do
    [ -e "$file" ] || continue

    SCENE=$(basename "$file" .blend)
    
    omit_line=""
    rFondo=""
    fondoStart=""
    fondoEnd=""
    rPerso=""
    persoStart=""
    persoEnd=""

    # 1. Parse the omission list for this specific scene
    if [ -e "$OMIT_FILE" ]; then
        omit_line=$(grep -w "$SCENE" "$OMIT_FILE")
        
        if [ -n "$omit_line" ]; then
            # Extract flags based on expected log format: 
            # SCENE_NAME f start end p start end
            rFondo=$(echo "$omit_line" | cut -d" " -f2)
            rPerso=$(echo "$omit_line" | cut -d" " -f5)

            if [ "$rFondo" = "f" ]; then
                fondoStart=$(echo "$omit_line" | cut -d" " -f3)
                fondoEnd=$(echo "$omit_line" | cut -d" " -f4)
            fi

            if [ "$rPerso" = "p" ]; then
                persoStart=$(echo "$omit_line" | cut -d" " -f6)
                persoEnd=$(echo "$omit_line" | cut -d" " -f7)
            fi
        fi
    fi

    echo ""
    echo ">>> Evaluating Scene: $SCENE"

    # 2. Logic Tree: Decide what to render
    if [ -z "$omit_line" ]; then
        echo "    [FULL RENDER] No omission rules found. Rendering both passes completely."
        
        echo "    -> Rendering Environment Pass..."
        $BLENDER_EXE -b "$file" -y -P "$ENV_SETUP" -a > "${SCENE}_env_render.log" 2>&1
        
        echo "    -> Rendering Character Pass..."
        $BLENDER_EXE -b "$file" -y -P "$CHAR_SETUP" -a > "${SCENE}_char_render.log" 2>&1
        
        echo "$SCENE" >> "$OMIT_FILE"
        let "processed_count+=1"

    else
        # Partial Render Logic
        if [ "$rFondo" = "f" ]; then
            echo "    [PARTIAL RENDER] Rendering Environment from frame $fondoStart to $fondoEnd..."
            $BLENDER_EXE -b "$file" -y -P "$ENV_SETUP" -s "$fondoStart" -e "$fondoEnd" -a > "${SCENE}_env_render.log" 2>&1
            let "processed_count+=1"
        fi
        
        if [ "$rPerso" = "p" ]; then
            echo "    [PARTIAL RENDER] Rendering Characters from frame $persoStart to $persoEnd..."
            $BLENDER_EXE -b "$file" -y -P "$CHAR_SETUP" -s "$persoStart" -e "$persoEnd" -a > "${SCENE}_char_render.log" 2>&1
            let "processed_count+=1"
        fi
        
        if [ "$rFondo" != "f" ] && [ "$rPerso" != "p" ]; then
            echo "    [SKIP] Scene fully rendered or correctly omitted."
        fi
    fi

done

echo ""
echo "=========================================================="
echo " Render Queue Finished. Tasks executed: $processed_count"
echo "=========================================================="
exit 0
