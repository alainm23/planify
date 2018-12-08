# Planner
Task and project manager for elementary OS

![Planner Screenshot](https://github.com/alainm23/planner/raw/master/data/screenshot/screenshot-01.png)

## Building and Installation

You'll need the following dependencies:
* libgtk-3-dev
* libunity-dev
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
```

### Donations
Stripe is not yet available in my country, If you like Planner and you want to support its development, consider donating via [PayPal](https://www.paypal.me/alainm23)

Made with 💗 in Perú
