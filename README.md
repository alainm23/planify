[![Please do not theme this app](https://stopthemingmy.app/badge.svg)](https://stopthemingmy.app)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

<div align="center">
  <span align="center"> <img width="128" height="128" class="center" src="data/icons/hicolor/scalable/apps/io.github.alainm23.planify.svg" alt="Planify Icon"></span>
  <h1 align="center">Planify</h1>
  <h3 align="center">Never worry about forgetting things again</h3>
</div>

![Planify Screenshot](https://raw.githubusercontent.com/alainm23/planify/master/data/resources/screenshot/screenshot-03.png)

## Planify is here...

- 🚀️ Neat visual style.
- 🤚️ Drag and Order: Sort your tasks wherever you want.
- 💯️ Progress indicator for each project.
- 💪️ Be more productive and organize your tasks by 'Sections'.
- 📅️ Visualize your events and plan your day better.
- ⏲️ Reminder system, you can create one or more reminders, you decide.
- 🌙️ Better integration with the dark theme.
- 🎉️ and much more.

### ☁️ Support for Todoist & Nextcloud:

- Synchronize your Projects, Tasks and Sections.
- Support for Todoist offline: Work without an internet connection; when everything is reconnected, it will be synchronized.
- Planify is not created by, affiliated with, or supported by Doist

### 💎️ Other features:

- ⏲️ Reminders notifications.
- 🔍️ Quick Find.
- 🌙️ Night mode.
- 🔁️ Recurring due dates.

# Install

## Official

### Release

<a href="https://flathub.org/apps/details/io.github.alainm23.planify" rel="noreferrer noopener" target="_blank"><img loading="lazy" draggable="false" width='240' alt='Download on Flathub' src='https://dl.flathub.org/assets/badges/flathub-badge-en.png' /></a>

<!-- <a href="https://snapcraft.io/planify">
  <img alt="Get it from the Snap Store" src="https://snapcraft.io/static/images/badges/en/snap-store-black.svg"  loading="lazy" width='240' draggable="false"/>
</a> -->

## 🛠 From Source

You'll need the following dependencies:

<details>
<summary>Dependencies</summary>

Package Name | Required Version
:--- |---:|
meson | 0.56
valac | 0.48
gio-2.0 | 2.80.3
glib-2.0 | 2.80.3
gee-0.8 | 0.20.6
gtk4 | 4.14.4
libsoup-3.0 | 3.4.4
sqlite3 | 3.45.1
libadwaita-1 | 1.5.3
webkitgtk-6.0 | 2.44.3
json-glib-1.0 | 1.8.0
libecal-2.0 | 3.52.4
libedataserver-1.2 | 3.52.4
libportal | 0.7.1
libportal-gtk4 | 0.7.1
gxml-0.20 | 0.21.0
libsecret-1 | 0.21.4
libspelling-dev

Fedora installation command:

    sudo dnf install vala meson ninja-build gtk4-devel libadwaita-devel libgee-devel libsoup3-devel webkitgtk6.0-devel libportal-devel libportal-gtk4-devel evolution-devel libspelling-devel

Ubuntu/Debian installation command:

    sudo apt install valac meson ninja-build libgtk-4-dev libadwaita-1-dev libgee-0.8-dev libjson-glib-dev libecal2.0-dev libsoup-3.0-dev libwebkitgtk-6.0-dev libportal-dev libportal-gtk4-dev libspelling-1-dev
</details>

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.github.alainm23.planify`

    sudo ninja install
    io.github.alainm23.planify

### GNOME Builder

- Clone
- Open in GNOME Builder

# Contributing

Take a look at [ARCHITECTURE.md](ARCHITECTURE.md)

## Code of conduct

Planify follows the [GNOME Code of Conduct](https://conduct.gnome.org/).

- **Be friendly.** Use welcoming and inclusive language.
- **Be empathetic.** Be respectful of differing viewpoints and experiences.
- **Be respectful.** When we disagree, we do so politely and constructively.
- **Be considerate.** Remember that decisions are often difficult when competing priorities are involved.
- **Be patient and generous.** If someone asks for help it is because they need
  it.
- **Try to be concise.** Read the discussion before commenting.


## Support
If you like Planify and want to support its development, consider supporting via [Patreon](https://www.patreon.com/alainm23), [PayPal](https://www.paypal.me/alainm23) or [Liberapay](https://liberapay.com/Alain)

Made with 💗 in Perú
