# Aerospace OS

A controller-first spatial desktop experiment, with an Ubuntu-based desktop session as the eventual target. This repository currently contains a Godot 4 flight and file-browsing prototype, not a bootable OS.

## Run the prototype

1. Install Godot 4 standard edition (GDScript; no .NET needed).
2. Import `project.godot` in Godot and press F6 with `main.tscn` open, or F5 to run the project.
3. Connect an Xbox-style controller over USB. Keyboard controls work without a controller.

The prototype opens your Documents directory. Folders are blue boxes; files are purple. Aim the center crosshair at an object to highlight it, then open it. Files open using the host operating system's default application. It shows at most 120 non-hidden entries per folder. File changes, application launchers, and live application windows in 3D are not implemented.

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
- Open a folder, return to its parent, and open a harmless text/image file in its associated host application.
- Open controls while moving: flight stops. Remap a key and a button, close and restart the app, and confirm they persist.
- Toggle mouse look, then use Escape to release the pointer and open controls.
- Disconnect/reconnect the controller; keyboard navigation continues to work.

Engine validation: `godot --headless --path . --editor --import`, then `godot --headless --path . --quit-after 120`.

On this Windows checkout, run: `powershell -ExecutionPolicy Bypass -File .\run.ps1`. Add `-Editor` to edit the project. The launcher uses the locally extracted Godot under ignored `build/tools`, or Godot on PATH.
