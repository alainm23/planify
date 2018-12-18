#!/usr/bin/env python3

import os
import subprocess

prefix = os.environ.get('MESON_INSTALL_PREFIX', '/usr/local')
datadir = os.path.join(prefix, 'share')
schemadir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'glib-2.0', 'schemas')

if not os.environ.get('DESTDIR'):
    print('Updating icon cache...')
    icon_cache_dir = os.path.join(datadir, 'icons', 'hicolor')
    if not os.path.exists(icon_cache_dir):
        os.makedirs(icon_cache_dir)
    subprocess.call(['gtk-update-icon-cache', '-qtf', icon_cache_dir])
    
    print('Updating desktop database...')
    desktop_database_dir = os.path.join(datadir, 'applications')
    if not os.path.exists(desktop_database_dir):
        os.makedirs(desktop_database_dir)
    subprocess.call(['update-desktop-database', '-q', desktop_database_dir])
    
    print('Compiling gsettings schemas...')
    subprocess.call(['glib-compile-schemas', schemadir])
