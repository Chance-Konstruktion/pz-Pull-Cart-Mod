# Holzwagen - Pull Cart for Project Zomboid (Build 42)

A realistic **pullable one-axle wooden cart** inspired by Valheim. Finally stop carrying everything on your back!

> **Status:** working & loads cleanly on B42 42.19 · actively developed
> 🇩🇪 Deutsche Version: [README.md](README.md)

### Features

- **Two-handed pulling mechanic** – realistic movement speed while dragging the cart
- **Two upgrade tiers**:
  - **Tier 1**: Basic wooden cart (cheap & easy to craft)
  - **Tier 2**: Upgraded version with spoked wheels (faster movement)
- **Side bag slots** for extra storage (T1: 2 slots | T2: 4 slots)
- **Barrel Cart (Fasswagen) variant** – large built-in fluid container (450 units) + 3 bag slots
- Fully reversible recipes (you can break items back down)
- Clean, performant Lua code with proper modData handling
- Balanced for long-distance looting and base building

### Features Overview

| Feature              | Tier 1     | Tier 2     | Barrel Cart |
|----------------------|------------|------------|-------------|
| Base Speed           | 80%        | 100%       | like wheels |
| Bag Slots            | 2          | 4          | 3           |
| Fluid Capacity       | -          | -          | 450 units   |
| Crafting Cost        | Low        | Medium     | High        |

### Installation

1. Download the latest release and extract the `HolzwagenMod` folder.
2. Place it in your Project Zomboid mods directory:
   - Windows: `C:\Users\YourName\Zomboid\mods\HolzwagenMod`
3. Move the model files (`.fbx`) into:
   `HolzwagenMod/42/media/models_X/`
4. Enable the mod in the game launcher and start a new game or load an existing save.

### Important Notes

- The cart occupies **both hands** while pulling.
- Movement speed is dynamically adjusted based on installed wheels.
- Barrel Cart: The barrel is a fixed component and can be filled/emptied using funnels and hoses.
- Works with Build 42 (tested with recent versions).

### Recipes

All recipes are available under **Carpentry**:
- Holzwagen T1
- Wheel Upgrade (T1 → T2)
- Barrel Cart conversion + reverse recipe

### Contributing

Feedback and contributions are welcome! Especially looking for:
- Balance feedback
- Improved models / textures
- Additional variants (covered wagon, wheelbarrow, animal-pulled versions, etc.)

Feel free to open Issues or Pull Requests.

---

**Made for players who are tired of slow looting trips.**  
Happy hauling!
