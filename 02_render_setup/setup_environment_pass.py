"""
Historias Nativas - Render Setup Pipeline
Script: setup_environment_pass.py

Description:
Mutates the .blend scene headlessly to prepare the "Environment Pass".
Disables Motion Blur to avoid artifacting, enables Anti-Aliasing,
and routes the compositor output correctly.

Target: Blender 2.75 API (Python 3.4/3.5 compatible)
"""

import bpy

# --- 1. RENDER SETTINGS (Standard rendering) ---
bpy.context.scene.render.resolution_percentage = 100
bpy.context.scene.render.use_antialiasing = True  # Enabled for crisp environments
bpy.context.scene.render.use_motion_blur = False  # Disabled to avoid displacement artifacts
bpy.context.scene.render.use_sss = False
bpy.context.scene.render.use_raytrace = True
bpy.context.scene.render.use_simplify = False
bpy.context.scene.render.tile_x = 256
bpy.context.scene.render.tile_y = 256

filename = bpy.path.display_name_from_filepath(bpy.data.filepath)

# Output settings (Relative pipeline paths)
bpy.context.scene.render.filepath = "//../../render/" + filename[0:2] + "/" + filename[0:5] + "/" + filename[0:5] + "_fondo/" + filename[0:5] + "_fondo_"
bpy.data.scenes['Scene'].render.image_settings.file_format = 'PNG'

# --- 2. RENDER LAYERS & Z-MASKS ---
# Background layer (layer 0) is active
bpy.context.scene.render.layers[0].use = True

for n in range(20):
    # Only layer 6 and 15 are active for the environment pass
    if n != 6 and n != 15:
        bpy.context.scene.render.layers[0].layers[n] = False
        bpy.context.scene.layers[n] = False
    else:
        bpy.context.scene.render.layers[0].layers[n] = True
        bpy.context.scene.layers[n] = True

# Disable all other render layers
for n, layer in enumerate(bpy.context.scene.render.layers):
    if n > 0:
        layer.use = False

# --- 3. COMPOSITING NODES ---
bpy.context.scene.use_nodes = True
tree = bpy.context.scene.node_tree

for node in tree.nodes:
    if 'File' in node.name:
        path = node.base_path
        if 'personaje' in path:
            # Mute character output nodes in environment pass
            node.mute = True
        elif 'fondo' in path:
            # Update output path for environment sequence
            node.base_path = '//../../render/' + filename[0:2] + '/' + filename[0:5] + '/' + filename[0:5] + '_fondo_'

# Custom node adjustment for environment composite
try:
    bpy.data.node_groups['pintura_fondo'].nodes['Dilate/Erode'].distance = 1
except KeyError:
    pass # Failsafe in case the node group is missing in older files

# --- 4. SAVE MUTATED FILE ---
current_filepath = bpy.data.filepath
idx = current_filepath.find('lib')

# Preserve the original file by appending '_fondo'
if idx != -1:
    new_filepath = current_filepath[:idx] + 'fondo.blend'
else:
    new_filepath = current_filepath.replace('.blend', '_fondo.blend')
    
bpy.ops.wm.save_as_mainfile(filepath=new_filepath)
print("[SUCCESS] Environment pass setup saved: " + new_filepath)
