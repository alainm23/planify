<div align="center">
  <h1 align="center">Ion Color Generator</h1>
 
  <a href="https://appcenter.elementary.io/com.github.alainm23.ion-color-generator"><img src="https://appcenter.elementary.io/badge.svg?new" alt="Get it on AppCenter" /></a>
</div>

![ion-color-generator](https://raw.githubusercontent.com/alainm23/ion-color-generator/master/data/screenshot-01.png)

## Building and Installation

You'll need the following dependencies:
* glib-2.0
* gobject-2.0
* granite >=0.5
* gtk+-3.0
* gtksourceview-3.0
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

```bash
meson build --prefix=/usr
cd build
ninja
```

To install, use `ninja install`, then execute with `com.github.alainm23.ion-color-generator`

```bash
ninja install
com.github.alainm23.ion-color-generator
```

## Donations
Stripe is not yet available in my country, If you like Ion Color Generator and you want to support its development, consider donating via [PayPal](https://www.paypal.me/alainm23)

Made with ❤ in Perú

