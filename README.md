# Kati

A [playtak.com](https://playtak.com) client for PC focusing on delivering a nice 3d board. While it already works very smoothly for playing and observing games, there are still a few open TODOs and some polishing left to be done.

Being a client for PC, the controls are optimized for a mouse (a pointer device with two buttons) or, as a secondary target, a touchpad + keyboard. With a mouse, you click left to place pieces or move stacks, click right to switch the type of piece to place and drag right to move the camera. There is no support for touch (mobile) devices.

You can download a native app from the releases section on [the project's github page](https://github.com/exoticorn/Kati), which is the preferred way to run Kati. However, there is also a web based version to be found at [kati.exoticorn.de](https://kati.exoticorn.de).

There is an overview of the UI and the controls to be found by clicking the '?' button in the top right corner.

## Features

* Play on [playtak.com](https://playtak.com) with an existing account or as a guest.
* Observe multiple games, cycling between them.
* Chat with you opponent or other observers.
* A reasonably nicely rendered 3d board.
* Play offline against a TEI engine (not in the web version)
* Analyse with a TEI engine with MultiPV display if the engine supports it (not in the web version)

## Screenshot

![A game against IntutionBot](https://kati.exoticorn.de/screenshot01.png)

## Development

You can find the source code at [github.com/exoticorn/Kati](https://github.com/exoticorn/Kati).
This repository uses [Git LFS](https://git-lfs.com/), so you need it installed in order to access the binary assets.

Kati is build in the [Godot engine](https://godotengine.org/), currently v4.5.

Models are created in [Blender](https://www.blender.org/), using the [Ucupaint](https://extensions.blender.org/add-ons/ucupaint/) add-on for texture painting. Additional textures are created using [Material Maker](https://www.materialmaker.org/).

Sound effects have been recorded and cut in [Audacity](https://www.audacityteam.org/).

## License

Kati is released as free software under the MIT license. Fonts are under the SIL license, other assets CC0. See LICENSE.txt for details.