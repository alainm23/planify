<a href="https://www.patreon.com/alainm23"><img src="https://img.shields.io/badge/patreon-donate-orange.svg?logo=patreon" alt="Planner on Patreon"></a>
<a href="https://hosted.weblate.org/engage/planner/?utm_source=widget"><img src="https://hosted.weblate.org/widgets/planner/-/svg-badge.svg" alt="Estado de la traducción" /></a>
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://github.com/alainm23/planner/blob/master/LICENSE)
[![Build Status](https://travis-ci.com/alainm23/planner.svg?branch=master)](https://travis-ci.com/alainm23/planner)
[![Donate](https://img.shields.io/badge/PayPal-Donate-gray.svg?style=flat&logo=paypal&colorA=0071bb&logoColor=fff)](https://www.paypal.me/alainm23)

<div align="center">
  <span align="center"> <img width="80" height="70" class="center" src="https://github.com/alainm23/planner/blob/master/data/icons/128/com.github.alainm23.planner.svg" alt="Icon"></span>
  <h1 align="center">Planner</h1>
  <h3 align="center">Never worry about forgetting things again</h3>

  <a href="https://appcenter.elementary.io/com.github.alainm23.planner"><img src="https://appcenter.elementary.io/badge.svg?new" alt="Get it on AppCenter" /></a>
</div>

![Planner Screenshot](https://github.com/alainm23/planner/raw/master/data/screenshot/screenshot-01.png)

## Installation

### elementary OS AppCenter
<a href="https://appcenter.elementary.io/com.github.alainm23.planner"><img src="https://appcenter.elementary.io/badge.svg?new" alt="Get it on AppCenter" /></a>

### Flathub
<a href="https://flathub.org/apps/details/com.github.alainm23.planner"><img height="50" alt="Download on Flathub" src="https://flathub.org/assets/badges/flathub-badge-en.png"/></a>

### Arch Linux
[elementary-planner-git](https://aur.archlinux.org/packages/elementary-planner-git) are available in AUR thanks to @yochananmarqos.

## Building

You'll need the following dependencies:

* libgtk-3-dev
* libgee-0.8-dev
* libjson-glib-dev
* libsqlite3-dev
* libsoup2.4-dev
* libgranite-dev (>=0.5)
* libwebkit2gtk-4.0-dev
* libecal1.2-dev || libecal1.2-dev
* libedataserver1.2-dev
* libical-dev
* meson
* valac >= 0.40.3

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `com.github.alainm23.planner`

    sudo ninja install
    com.github.alainm23.planner

## Translate Planner

<a href="https://hosted.weblate.org/engage/planner/?utm_source=widget">
<img src="https://hosted.weblate.org/widgets/planner/-/translations/open-graph.png" alt="Estado de la traducción" />
</a>

## Support
If you like Planner and you want to support its development, consider supporting via [Patreon](https://www.patreon.com/alainm23) or [PayPal](https://www.paypal.me/alainm23)

Made with 💗 in Perú