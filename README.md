# Planner
Task and project manager for elementary OS

## Building and Installation

You'll need the following dependencies:
* libunity-dev
* libgee-0.8-dev
* libgtk-3-dev
* libsqlite3-dev
* libgranite-dev (>=0.5)
* libnotify-dev
* meson
* valac >= 0.40.3

## Building

```
meson build && cd build
meson configure -Dprefix=/usr
sudo ninja install
```