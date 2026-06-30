"""
Historias Nativas - Asset Management Pipeline
Script: relink_paths.py

Description:
This script runs headlessly via the Blender Python API. It iterates through all 
linked libraries in a .blend file and forces their filepaths to resolve to the 
correct relative directory structure (e.g., '//../../../libs/'). 
It fixes broken paths for 'props', 'characters' (personajes), and 'environments' (ambientes).

Target: Blender 2.75 API
"""

import bpy
import os

def relink_libraries():
    print("\n--- Starting Library Relink Process ---")
    
    libraries = bpy.data.libraries
    
    for i, lib in enumerate(libraries):
        original_path = lib.filepath
        print(f"[{i}] Inspecting: {original_path}")
        
        # 1. Relink Props
        if 'props' in original_path:
            idx = original_path.find('props')
            new_path = '//../../../libs/' + original_path[idx:]
            bpy.data.libraries[i].filepath = new_path
            print(f"    -> Relinked to: {new_path}")
            
        # 2. Relink Characters (Personajes)
        elif 'personajes' in original_path:
            idx = original_path.find('personajes') + 11  # Offset for 'personajes/'
            sub_str = original_path[idx:]
            n_idx = sub_str.find('/') + 1
            new_path = '//../../../libs/personajes/' + sub_str[n_idx:]
            bpy.data.libraries[i].filepath = new_path
            print(f"    -> Relinked to: {new_path}")
            
        # 3. Relink Environments (Ambientes)
        elif 'ambientes' in original_path:
            idx = original_path.find('ambientes')
            new_path = '//../../../libs/' + original_path[idx:]
            bpy.data.libraries[i].filepath = new_path
            print(f"    -> Relinked to: {new_path}")

    print("--- Relink Process Completed ---\n")

def save_relinked_file():
    """Saves the file with a '-lib.blend' suffix to preserve the original master file."""
    current_filepath = bpy.data.filepath
    if not current_filepath:
        print("Error: The current file has no path.")
        return

    # Extract the name and append the new suffix
    idx = current_filepath.rfind('.blend')
    new_filepath = current_filepath[:idx] + '-lib.blend'
    
    bpy.ops.wm.save_as_mainfile(filepath=new_filepath)
    print(f"[SUCCESS] Relinked scene saved as: {os.path.basename(new_filepath)}")

# Execute pipeline steps
if __name__ == "__main__":
    relink_libraries()
    save_relinked_file()
