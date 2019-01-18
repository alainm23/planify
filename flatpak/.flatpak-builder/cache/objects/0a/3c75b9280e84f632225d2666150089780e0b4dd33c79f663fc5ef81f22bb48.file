// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013 Maya Developers (https://launchpad.net/maya)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class Maya.BackendsManager : GLib.Object {
    private static Maya.BackendsManager? backends_manager = null;

    public static BackendsManager get_default () {
        if (backends_manager == null)
            backends_manager = new BackendsManager ();
        return backends_manager;
    }

    [CCode (has_target = false)]
    private delegate Backend RegisterPluginFunction (Module module);

    public Gee.ArrayList<unowned Backend> backends;

    public signal void backend_added (Backend b);
    public signal void backend_removed (Backend b);

    private LocalBackend local_backend;

    private BackendsManager () {
        backends = new Gee.ArrayList<unowned Backend> ();

        // Add default backend for local calendar
        local_backend = new LocalBackend ();
        add_backend (local_backend);
        var base_folder = File.new_for_path (Build.PLUGIN_DIR);
        find_plugins (base_folder);
    }

    private void load (string path) {
        if (Module.supported () == false) {
            error ("Maya plugins are not supported by this system!");
        }

        Module module = Module.open (path, ModuleFlags.BIND_LAZY);
        if (module == null) {
            critical (Module.error ());
            return;
        }

        void* function;
        module.symbol ("get_backend", out function);
        if (function == null) {
            critical ("get_backend () not found in %s", path);
            return;
        }

        RegisterPluginFunction register_plugin = (RegisterPluginFunction) function;
        Maya.Backend plug = register_plugin (module);
        if (plug == null) {
            critical ("Unknown plugin type for %s !", path);
            return;
        }
        module.make_resident ();
        add_backend (plug);
    }

    private void find_plugins (File base_folder) {
        FileInfo file_info = null;
        try {
            var enumerator = base_folder.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE + "," + FileAttribute.STANDARD_CONTENT_TYPE, 0);
            while ((file_info = enumerator.next_file ()) != null) {
                var file = base_folder.get_child (file_info.get_name ());

                if (file_info.get_file_type () == FileType.REGULAR && GLib.ContentType.equals (file_info.get_content_type (), "application/x-sharedlib")) {
                    load (file.get_path ());
                } else if (file_info.get_file_type () == FileType.DIRECTORY) {
                    find_plugins (file);
                }
            }
        } catch (Error err) {
            warning("Unable to scan plugs folder: %s\n", err.message);
        }
    }

    public void add_backend (Backend b) {
        backends.add (b);
        backend_added (b);
    }

    public void remove_backend (Backend b) {
        if (backends.contains (b)) {
            backends.remove (b);
            backend_removed (b);
        }
    }
}
