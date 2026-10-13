# Project Z: Open World Prototype

An early Godot 4.x scaffold for an original third-person open-world Android game concept.

## Included in the current prototype scaffold
- A 5.5 km x 5.5 km world footprint
- Placeholder Rajasthan-inspired village/dunes, city blocks, industrial area, railway yard and bridge
- Basic dark road strips with centre markings
- Third-person capsule character and follow camera
- Keyboard movement, sprint, jump and mouse-look
- Basic Android touch controls for movement, RUN, JUMP, FIRE and right-side camera look
- A small target-practice area; FIRE uses a camera raycast and targets can be hit
- A starter placeholder car with keyboard/mobile throttle, brake and steering controls
- 12 simple wandering NPCs in the starting area
- Three glowing objective rings that complete a basic explore objective and update the HUD
- Placeholder hospital, garage and police station locations with an interaction message (F key or mobile INTERACT button)
- Basic enter/exit interaction using E or the on-screen ENTER / EXIT button
- GitHub Actions workflow that imports/validates the project in headless Godot

## Honest status
This is **not a finished game or APK**. World structures and the character are placeholder geometry, not production-quality 3D art. The vehicle is an early placeholder controller, not a realistic driving simulation. The objectives are simple location triggers, not a full mission framework; NPCs only wander randomly and have no dialogue or schedules. There are no developed missions, detailed NPC routines, police/gang AI, dialogue/memory system, save system, polished animations, or Android export package yet. Touch layout and gameplay have not been manually tested on a phone. A passing automated Godot import check only confirms the project can be imported; it does not prove all gameplay works.

## Run
Open this repository as a project in Godot 4.x and run the main scene. Desktop: WASD/arrows to move, Shift to sprint, Space to jump, mouse to look, left-click to fire, and E near the car to enter/exit, and F near a service location to interact. While driving, use W/S and A/D. Android: use the on-screen movement/RUN/JUMP/FIRE/ENTER-EXIT buttons and drag the right side to look; driving adds GAS/BRAKE/steering controls.

## Next development targets
1. Validate and improve controls after an actual Android build.
2. Add a drivable vehicle and enter/exit interaction.
3. Add mission objectives and interactable world locations.
4. Add nearby NPC behaviours before attempting expensive full-world AI.
5. Replace placeholder geometry with optimized art assets and improve mobile performance.
