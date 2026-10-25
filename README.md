# Aerospace OS

A controller-first spatial desktop experiment, with an Ubuntu-based desktop session as the eventual target. This repository currently contains a Godot 4 flight and file-browsing prototype, not a bootable OS.

## Run the prototype

1. Install Godot 4 standard edition (GDScript; no .NET needed).
2. Import `project.godot` in Godot and press F6 with `main.tscn` open, or F5 to run the project.
3. Connect an Xbox-style controller over USB. Keyboard controls work without a controller.

The prototype opens your Documents directory. Folders are animated portals; files are floating crystals spread across orbital shells. Fly through a folder portal to enter its contents, or aim at it and press Y/Enter. Aim at a file and press Y/Enter to open it. Files open using the host operating system's default application. It shows at most 120 non-hidden entries per folder, plus a gold return portal behind the spawn point when a parent exists. File changes, application launchers, and live application windows in 3D are not implemented.

## Folder dimensions and scenery

Every folder has a stable universe seed. Going deeper changes the scene between the Crab Nebula, a stylized black hole with an accretion disk, a spiral galaxy, and the Lagoon Nebula. Sibling folders vary their sky orientation, star distribution, portal colors, planet surfaces, and asteroid placement. Returning to a folder restores the same scenery.

Stars surround the camera in every direction. Ringed planets and asteroid belts are decorative 3D scenery; they have no collision or file actions. The backgrounds are artistic compositions, not scale-accurate astronomical simulations. Crab and Lagoon imagery comes from Hubble; full attribution, source links, and license terms are in [assets/space/CREDITS.md](assets/space/CREDITS.md), with image credits also shown on screen.

The expensive nebula backdrop is baked into a sky cubemap once per folder, while stars stay sharp and portals animate in real time. The Compatibility renderer remains enabled for integrated GPUs. Destination labels stay readable at a fixed screen size within 220 world units; aim at distant objects to see their full path in the HUD.

Portals activate when your flight path crosses the opening, including at high speed. Folder travel fades out/in and stops momentum so you can orient yourself in the new dimension. The gold return portal and Backspace/View both go to the parent folder.

Known validation limitation: on this Windows/Intel Iris Xe setup with Godot 4.7.2, closing the rendered preview logs two OpenGL texture cleanup warnings (about 2.7 MiB total). All four scenes render, and portal/flight checks pass; the cleanup warning remains unresolved. Physical-controller testing is still manual.

## Default controls

| Action | Controller | Keyboard |
| --- | --- | --- |
| Translate left/right/up/down | Left stick or D-pad | A/D/W/S |
| Look (yaw/pitch) | Right stick | Arrow keys |
| Roll left/right | Left/right trigger or bumpers | Q/E |
| Forward thrust | A | Space |
| Reverse thrust | X | Shift |
| Brake to a stop | B | Ctrl |
| Open aimed-at item | Y | Enter |
| Parent folder | View/Back | Backspace |
| Reset position and orientation | Right stick click | Home |
| Controls menu | Click the on-screen button | Esc |
| Toggle mouse look | — | F2 |

Movement is relative to the camera, including after rolling. Thrust accelerates the player; momentum persists until braking. Translation and look have a stick deadzone. The first connected controller is used for analog flight.

The controls menu can replace each action's keyboard key and controller button. Bindings persist in Godot's user data directory (`controls.cfg`). Analog stick and trigger assignments are fixed in this first prototype. Avoid assigning the same key/button to multiple actions; duplicate assignments currently activate both. Escape and F2 are reserved.

## Testing progression

1. **Native Windows:** test flight, controller input, remapping, and file browsing immediately. No VM is needed for this stage.
2. **Ubuntu VM:** test Linux file associations and opening files. Start with 4 GB RAM, 2 virtual CPUs, and a 30 GB dynamically allocated disk. Enable supported 3D acceleration and install guest tools. Connect the controller to the guest through USB passthrough; keyboard input can be used if passthrough is unavailable. VM graphics performance is not representative of native hardware.
3. **Ubuntu on real hardware:** test controller feel and graphics performance using an Ubuntu installation on a spare machine or external SSD.
4. **Desktop session and image:** integrate login/session startup, application launching, recovery to a conventional desktop, then build an installable image.

## Manual acceptance checks

- Left stick translates without rotating; right stick rotates without translating.
- Each trigger rolls in the expected direction. Thrust follows the current facing direction after a roll.
- Release thrust: motion persists. Hold brake: speed reaches zero.
- Reset restores the initial viewpoint and stops motion.
- Fly through a folder portal and confirm its contents and backdrop change. Try crossing from both sides and missing the opening.
- Turn around and cross the gold return portal; confirm the original scenery returns.
- Aim at a portal and press Y/Enter to enter without flying. Backspace/View returns to its parent.
- Open a harmless text/image file in its associated host application.
- Look behind, above, and below you: stars should remain visible in all directions.
- Open controls while moving: flight stops. Remap a key and a button, close and restart the app, and confirm they persist.
- Toggle mouse look, then use Escape to release the pointer and open controls.
- Disconnect/reconnect the controller; keyboard navigation continues to work.

Engine validation: `godot --headless --path . --editor --import`, then `godot --headless --path . --quit-after 120`.

Portal/flight regression checks: `godot --headless --path . --script tests/portal_test.gd`. Tests create fixtures only under Godot's user data directory. Headless checks do not validate visual quality; inspect the rendered app as well.

On this Windows checkout, run: `powershell -ExecutionPolicy Bypass -File .\run.ps1`. Add `-Editor` to edit the project. The launcher uses the locally extracted Godot under ignored `build/tools`, or Godot on PATH.
