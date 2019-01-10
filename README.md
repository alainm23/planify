[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://github.com/alainm23/planner/blob/master/LICENSE)
[![Build Status](https://travis-ci.com/alainm23/planner.svg?branch=master)](https://travis-ci.com/alainm23/planner)

![Planner Screenshot](https://github.com/alainm23/planner/raw/master/data/screenshot/screenshot-01.png)

![Planner Screenshot](https://github.com/alainm23/planner/raw/master/data/screenshot/screenshot-02.png)

![Planner Screenshot](https://github.com/alainm23/planner/raw/master/data/screenshot/screenshot-03.png)

![Planner Screenshot](https://github.com/alainm23/planner/raw/master/data/screenshot/screenshot-04.png)

[![Donate](https://img.shields.io/badge/PayPal-Donate-gray.svg?style=flat&logo=paypal&colorA=0071bb&logoColor=fff)](https://www.paypal.me/alainm23)

<div align="center">
  <span align="center"> <img width="80" height="70" class="center" src="https://github.com/alainm23/planner/blob/master/data/icons/128/com.github.alainm23.planner.svg" alt="Icon"></span>
  <h1 align="center">Planner</h1>
  <h3 align="center">Never worry about forgetting things again</h3>

  <a href="https://appcenter.elementary.io/com.github.alainm23.planner"><img src="https://appcenter.elementary.io/badge.svg?new" alt="Get it on AppCenter" /></a>
</div>

<br/>

## Building and Installation

You'll need the following dependencies:
* libgtk-3-dev
* libunity-dev
* libecal1.2-dev
* libedataserver1.2-dev
* libedataserverui1.2-dev
* libgtksourceview-3.0-dev >= 3.24
* libical-dev
* libgee-0.8-dev
* libjson-glib-dev
* libgeoclue-2-dev
* libsqlite3-dev
* libsoup2.4-dev
* libgranite-dev (>=0.5)
* libnotify-dev
* meson
* valac >= 0.40.3

## Building

```
meson build && cd build
meson configure -Dprefix=/usr
sudo ninja install
com.github.alainm23.planner
```

## Donations
Stripe is not yet available in my country, If you like Planner and you want to support its development, consider donating via [PayPal](https://www.paypal.me/alainm23)

Made with 💗 in Perú

