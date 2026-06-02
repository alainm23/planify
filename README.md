[![Please do not theme this app](https://stopthemingmy.app/badge.svg)](https://stopthemingmy.app)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)
<a href="https://hosted.weblate.org/engage/planner/">
<img src="https://hosted.weblate.org/widget/planner/io-github-alainm23-planify/svg-badge.svg" alt="Estado de la traducción" />
</a>

<div align="center">
  <span align="center"> <img width="128" height="128" class="center" src="data/icons/hicolor/scalable/apps/io.github.alainm23.planify.svg" alt="Planify Icon"></span>
  <h1 align="center">Planify</h1>
  <h3 align="center">Never worry about forgetting things again</h3>
</div>

![Planify Screenshot](https://raw.githubusercontent.com/alainm23/planify/main/data/resources/screenshot/screenshot-03.png)

## ✨ Features

### 🎯 Core Functionality
- **🚀 Modern Interface**: Clean, intuitive design that gets out of your way
- **🤚 Drag & Drop**: Effortlessly organize tasks and projects with natural gestures
- **💯 Progress Tracking**: Visual indicators show completion status at a glance
- **📂 Smart Organization**: Group tasks into sections for better workflow management
- **📅 Calendar Integration**: Visualize your schedule and plan your day effectively
- **⏰ Flexible Reminders**: Set multiple reminders per task - never miss a deadline
- **🌙 Dark Mode**: Seamless integration with system themes
- **🔍 Quick Search**: Find anything instantly with powerful search capabilities

### ☁️ Cloud Synchronization
- **Todoist Integration**: Full sync with your existing Todoist account
- **Nextcloud Support**: Keep your data private with self-hosted solutions
- **Offline Mode**: Work without internet - sync when you're back online
- **Cross-Platform**: Access your tasks from anywhere

*Note: Planify is not created by, affiliated with, or supported by Doist*

### 💎 Advanced Features
- **🔔 Smart Notifications**: Never miss important tasks
- **🔁 Recurring Tasks**: Set up repeating schedules with flexible patterns
- **📊 Analytics**: Track your productivity over time
- **🏷️ Labels & Filters**: Organize and find tasks with custom labels
- **📎 Attachments**: Add files and links to your tasks
- **🎨 Customization**: Personalize colors and themes

## 📥 Installation

### 🏪 Official Distribution

<a href="https://flathub.org/apps/details/io.github.alainm23.planify" rel="noreferrer noopener" target="_blank">
  <img loading="lazy" draggable="false" width='240' alt='Download on Flathub' src='https://dl.flathub.org/assets/badges/flathub-badge-en.png' />
</a>

### 🛠 Build from Source

<details>
<summary><strong>System Requirements & Dependencies</strong></summary>

**Minimum Requirements:**
- Linux distribution with GTK4 support
- 2GB RAM
- 500MB disk space

**Build Dependencies:**

| Package | Version |
|---------|---------|
| meson | ≥ 0.56 |
| valac | ≥ 0.48 |
| gio-2.0 | ≥ 2.80.3 |
| glib-2.0 | ≥ 2.80.3 |
| gee-0.8 | ≥ 0.20.6 |
| gtk4 | ≥ 4.14.4 |
| libsoup-3.0 | ≥ 3.4.4 |
| sqlite3 | ≥ 3.45.1 |
| libadwaita-1 | ≥ 1.5.3 |
| json-glib-1.0 | ≥ 1.8.0 |
| libecal-2.0 | ≥ 3.52.4 |
| libedataserver-1.2 | ≥ 3.52.4 |
| libportal | ≥ 0.7.1 |
| libportal-gtk4 | ≥ 0.7.1 |
| gxml-0.20 | ≥ 0.21.0 |
| libsecret-1 | ≥ 0.21.4 |
| libspelling-dev | latest |
| gtksourceview-5 | 5.12.1 |
| libicu-dev | ≥ 76.1 |

**Install Dependencies:**

**Fedora/RHEL:**
```bash
sudo dnf install vala meson ninja-build gtk4-devel libadwaita-devel libgee-devel libsoup3-devel libportal-devel libportal-gtk4-devel evolution-devel libspelling-devel gtksourceview5-devel libicu-devel
```

**Ubuntu/Debian:**
```bash
sudo apt install valac meson ninja-build libgtk-4-dev libadwaita-1-dev libgee-0.8-dev libjson-glib-dev libecal2.0-dev libsoup-3.0-dev libportal-dev libportal-gtk4-dev libspelling-1-dev libgtksourceview-5-dev libicu-dev
```

</details>

**Build Instructions:**

```bash
# Clone the repository
git clone https://github.com/alainm23/planify.git
cd planify

# Configure build
meson build --prefix=/usr

# Compile
cd build
ninja

# Install
sudo ninja install

# Run
io.github.alainm23.planify
```

### 🍏 macOS Build (Experimental)
Planify can be built on macOS (tested on Apple Silicon, macOS 14+) using Homebrew’s GTK4/libadwaita stack. Optional components not available on macOS are disabled (Evolution, WebKit, portals, spell check).

1. Install dependencies:
   ```bash
   brew update
   brew install vala meson ninja gtk4 libadwaita libgee json-glib \
     libsoup sqlite libical gtksourceview5 desktop-file-utils \
     libsecret icu4c pango cairo fontconfig
   ```
2. Make pkg-config find libical/icu:
   ```bash
   export PKG_CONFIG_PATH="/opt/homebrew/opt/libical/lib/pkgconfig:/opt/homebrew/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
   ```
3. Build and run via the helper script:
   ```bash
   chmod +x run-macos.sh
   ./run-macos.sh
   GSETTINGS_SCHEMA_DIR=data ./build/src/io.github.alainm23.planify
   ```
   The script cleans the build dir, configures Meson with macOS-safe flags (`-Devolution=false -Dwebkit=false -Dportal=false -Dspelling=disabled`), compiles, compiles schemas, and launches the app with the needed runtime env vars.

#### DMG Packaging (Experimental)
After building, you can generate a DMG (still relies on Homebrew GTK/libadwaita on the target system; not fully standalone):
```bash
# From repo root, after ./run-macos.sh
./scripts/build-macos-dmg.sh
```
Result: `build/Planify.dmg`.

### 🏗️ Development Setup

**Using GNOME Builder:**
1. Install [GNOME Builder](https://apps.gnome.org/Builder/)
2. Clone this repository
3. Open the project in GNOME Builder
4. Click "Run" to build and test

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### 🐛 Bug Reports & Feature Requests
- Check [existing issues](https://github.com/alainm23/planify/issues) first
- Use our issue templates for better communication
- Include system information and steps to reproduce

### 💻 Code Contributions
- Read our [Architecture Guide](ARCHITECTURE.md)
- Review our [AI Policy](AI_POLICY.md) for guidelines on AI-assisted contributions
- Fork the repository and create a feature branch
- Follow our coding standards and commit message format
- Submit a pull request with a clear description

### 🌍 Translations
Help make Planify available in your language:

- **Weblate (Recommended)**: [Join our translation project](https://hosted.weblate.org/engage/planner/)
- **Manual**: Check our [Translation Guide](po/README.md)

## 📋 Code of Conduct

Planify follows the [GNOME Code of Conduct](https://conduct.gnome.org/). We are committed to providing a welcoming and inclusive environment for all contributors.

**Our Principles:**
- **Be friendly** - Use welcoming and inclusive language
- **Be empathetic** - Respect differing viewpoints and experiences  
- **Be respectful** - Disagree politely and constructively
- **Be considerate** - Remember that decisions often involve competing priorities
- **Be patient** - Help others learn and grow
- **Be concise** - Read discussions before commenting

## 💝 Support the Project

If you find Planify useful, consider supporting its development:

<div align="center">

[![Patreon](https://img.shields.io/badge/Patreon-F96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/alainm23)
[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.me/alainm23)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/alainm23)
[![Liberapay](https://img.shields.io/badge/Liberapay-F6C915?style=for-the-badge&logo=liberapay&logoColor=black)](https://liberapay.com/Alain)

</div>

<div align="center">
  <strong>Made with 💗 in Perú</strong>
  <br><br>
  <img src="https://img.shields.io/github/stars/alainm23/planify?style=social" alt="GitHub stars">
  <img src="https://img.shields.io/github/forks/alainm23/planify?style=social" alt="GitHub forks">
</div>
