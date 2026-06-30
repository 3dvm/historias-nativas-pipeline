# Historias Nativas: Art-Driven Render Pipeline (Legacy)

![Blender](https://img.shields.io/badge/Blender-2.75-orange?logo=blender&logoColor=white)
![Python](https://img.shields.io/badge/Python-bpy-blue?logo=python&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-Scripting-4EAA25?logo=gnu-bash&logoColor=white)
![Role](https://img.shields.io/badge/Role-Pipeline_TD-purple)

> **Note:** These scripts were developed for Blender 2.49 - 2.75 during the production of the animated series *["Historias Nativas"](https://www.youtube.com/playlist?list=PLU0PtXQyV9C7PtgiSqsm3QVCUYM68ybqy)*. While the Blender Python API (`bpy`) has evolved significantly since then, this repository serves as a showcase of fundamental pipeline logic, headless scene mutation, and batch render orchestration that remains highly relevant in modern VFX and animation pipelines.

## 🎨 1. The Artistic Challenge: "Painting with Polygons"
The art direction for *"Historias Nativas"* required a visual style that emulated traditional brushstrokes in motion. To achieve this, we implemented a technique called **"Painting with Polygons"**, which relies on displacing character geometry using a rotating Empty object, combined with extremely high sub-frame **Motion Blur**.

While this effect looked beautiful and organic on characters, applying it globally to the environments created an uncontrollable visual mess. We needed to split every scene into two distinct render passes:
* **Character Pass:** High Motion Blur, Anti-Aliasing disabled, Z-Mask enabled.
* **Environment Pass:** No Motion Blur, High Anti-Aliasing, Z-Mask disabled.

## ⚠️ 2. The Technical Bottleneck
Manually opening hundreds of `.blend` files to separate these passes—adjusting Render Layers, turning Compositor nodes on and off, and tweaking engine settings—was highly error-prone and would have brought production to a halt. We needed an automated, headless solution.

## ⚙️ 3. The Pipeline Architecture

To solve this, I developed a hybrid Python/Bash pipeline to automate the render wrangling process across local machines.

```mermaid
flowchart TD```mermaid
    A[📁 Master Scene .blend] --> B{⚙️ render_missing_passes.sh}
    
    subgraph Orchestration [Bash Render Orchestration]
        B <-->|Reads & Updates Status| C[(📄 omitir.list log)]
        B -->|If Env pass missing| D[Blender Engine + setup_environment_pass.py]
        B -->|If Char pass missing| E[Blender Engine + setup_character_pass.py]
    end
    
    subgraph Mutation [Python API Mutation - Headless]
        D -.->|Overrides| F[Anti-Aliasing: ON<br>Motion Blur: OFF<br>Z-Mask: OFF]
        E -.->|Overrides| G[Anti-Aliasing: OFF<br>Motion Blur: ON<br>Z-Mask: ON]
    end
    
    F --> H[🖼️ Environment Sequence]
    G --> I[🖼️ Character Sequence]
    
    H --> J((🎬 Final Compositing))
    I --> J

    classDef bash fill:#4EAA25,stroke:#fff,stroke-width:2px,color:#fff;
    classDef python fill:#3776AB,stroke:#fff,stroke-width:2px,color:#fff;
    classDef file fill:#E26F25,stroke:#fff,stroke-width:2px,color:#fff;
    
    class B bash;
    class D,E python;
    class A file;
```

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

---

**Ernesto Del Valle Macuare** | Pipeline TD & Tools Developer

[🔗 LinkedIn](https://www.linkedin.com/in/ernesto-del-valle-macuare/) | [🔗 GitHub Portfolio](https://github.com/3dvm)




