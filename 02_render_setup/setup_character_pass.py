"""
Historias Nativas - Render Setup Pipeline
Script: setup_character_pass.py

Description:
Mutates the .blend scene headlessly to prepare the "Character Pass".
Enables Motion Blur for the 'Painting with Polygons' effect, disables Anti-Aliasing,
configures Z-Masks, and updates compositor output paths.

Target: Blender 2.75 API (Python 3.4/3.5 compatible)
"""

import bpy

# --- 1. RENDER SETTINGS (Painting with Polygons specific) ---
bpy.context.scene.render.resolution_percentage = 100
bpy.context.scene.render.use_antialiasing = False # Disabled for character pass
bpy.context.scene.render.use_full_sample = False
bpy.context.scene.render.use_motion_blur = True   # Enabled for the displacement effect
bpy.context.scene.render.use_sss = False
bpy.context.scene.render.use_raytrace = False
bpy.context.scene.render.use_simplify = False
bpy.context.scene.render.tile_x = 256
bpy.context.scene.render.tile_y = 256

filename = bpy.path.display_name_from_filepath(bpy.data.filepath)

# Output settings (Relative pipeline paths)
bpy.context.scene.render.filepath = "//../../render/" + filename[0:2] + "/" + filename[0:5] + "/" + filename[0:5] + "_personaje/" + filename[0:5] + "_personaje_"
bpy.data.scenes['Scene'].render.image_settings.file_format = 'PNG'

# --- 2. RENDER LAYERS & Z-MASKS ---
# Mute background layer (layer 0)
bpy.context.scene.render.layers[0].use = False

# Enable and configure other render layers
for n, layer in enumerate(bpy.context.scene.render.layers):
    if n == 0:
        continue
    
    layer.use = True
    for m in range(20):
        if m != 6:
            bpy.context.scene.layers[m] = True
            layer.layers[m] = True
        else:
            bpy.context.scene.layers[m] = False
            layer.layers[m] = False
        
        # Disable existing masks
        layer.layers_zmask[m] = False 
        
    # Activate environment mask (z-mask) on layer 6
    layer.layers_zmask[6] = True 

# --- 3. COMPOSITING NODES ---
bpy.context.scene.use_nodes = True
tree = bpy.context.scene.node_tree

for node in tree.nodes:
    if 'File' in node.name:
        path = node.base_path
        if 'fondo' in path:
            # Mute environment output nodes in character pass
            node.mute = True
        elif 'personaje' in path:
            # Update output path for character sequence
            node.base_path = '//../../render/' + filename[0:2] + '/' + filename[0:5] + '/' + filename[0:5] + '_personaje_'

# --- 4. SAVE MUTATED FILE ---
current_filepath = bpy.data.filepath
idx = current_filepath.find('lib')

# Preserve the original file by appending '_perso'
if idx != -1:
    new_filepath = current_filepath[:idx] + 'perso.blend'
else:
    new_filepath = current_filepath.replace('.blend', '_perso.blend')
    
bpy.ops.wm.save_as_mainfile(filepath=new_filepath)
print("[SUCCESS] Character pass setup saved: " + new_filepath)
