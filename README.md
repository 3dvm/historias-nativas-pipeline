## ⚙️ 3. The Pipeline Architecture

To solve the production bottlenecks, I developed a hybrid Python/Bash pipeline divided into two main systems: Asset Centralization and Render Orchestration.

### A. Storage Optimization: The Centralized "libs/" Migration (Python)
Initially, the project suffered from massive data duplication, as environment and character libraries were copied locally into every episode's folder. As the show grew, this became a storage and version-control nightmare. 

I redesigned the file topology to use a single, centralized `libs/` repository at the root of the project. To prevent artists from manually relinking hundreds of shots, I wrote the headless Python script inside `01_asset_management/`. It iterates through `bpy.data.libraries` and automatically migrates the relative paths to the new centralized structure:

```text
Historias_Nativas_Root/
├── libs/                          # Centralized Shared Assets
│   ├── ambientes/
│   ├── personajes/
│   └── props/
├── cap_01_nacimiento/
│   └── escenas/                   # Shots linking to ../../../libs/
└── cap_02_vuelo/
    └── escenas/                   # Shots linking to ../../../libs/

```

### B. Headless Scene Mutation (Python)

The scripts in `02_render_setup/` access the `.blend` files headlessly (without opening the GUI) and mutate the scene data for the *Painting with Polygons* effect. They automatically:

* Toggle `bpy.context.scene.render.use_motion_blur` and `use_antialiasing`.
* Reconfigure Render Layers and Z-Masks (`layers_zmask`).
* Re-route the Compositor output nodes (`File Output`) to the correct network directories.

### C. Local Render Farm Orchestration (Bash)

The scripts in `03_batch_rendering/` act as a lightweight render manager. The core script (`render_missing_passes.sh`) features a robust logging system:

* It parses a log file (`omit.list`) to track the status of every frame.
* It dynamically detects if a scene is missing only the background (`f`) or the character pass (`p`).
* It injects the missing frame ranges (`-s` and `-e`) into the Blender command line, ensuring the render queue is idempotent and can be safely interrupted overnight.
