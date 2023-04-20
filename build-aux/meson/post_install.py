#!/usr/bin/env python3

import os
import subprocess

prefix = os.environ.get('MESON_INSTALL_PREFIX', '/usr/local')
datadir = os.path.join(prefix, 'share')

# Packaging tools define DESTDIR and this isn't needed for them
if 'DESTDIR' not in os.environ:
    print('Updating package icon cache...')
    subprocess.call(['gtk-update-icon-cache', '-qtf',
                     os.path.join(datadir, 'gnome-builder', 'icons', 'hicolor')])