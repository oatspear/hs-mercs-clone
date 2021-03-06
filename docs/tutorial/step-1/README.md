# Project Structure

For any new project, it is a good idea to start by laying out its structure ahead of time.
For this type of game, we will create the following files and directories.

- `assets`: a directory to hold images, music and so on.
- `data`: a directory to hold data files (not required for the tutorial, but recommended to develop the game further).
- `scenes`: the root directory where scenes will be stored.
- `scenes/battle`: a sub-directory to hold scenes related to battle only.
- `scripts`: a directory to hold general-purpose scripts, or scripts that are not tied to a particular scene (not required for this tutorial).
- `Test.tscn`: a test scene that will act as our main scene.

![Directory Structure](./step-1-dir-structure.PNG)

This is the same structure that you can see at the root of this repository.

Before moving on, open the *Project Settings* menu.
Set `Test.tscn` as the main scene and change the window resolution to 640x360 (for a 16:9 aspect ratio).

![Project Settings](./step-1-project-settings.PNG)
