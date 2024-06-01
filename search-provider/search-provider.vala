// This file is part of Highscore. License: GPL-3.0+.

[DBus (name = "org.gnome.Shell.SearchProvider2")]
public class Planify.SearchProvider : Gtk.Application {
    internal SearchProvider () {
        Object (
            application_id: Build.APPLICATION_ID + ".SearchProvider",
            flags: ApplicationFlags.IS_SERVICE,
            inactivity_timeout: 10000
        );
    }

    construct {

    }

    protected override bool dbus_register (DBusConnection connection, string object_path) {
        try {
            connection.register_object (object_path, this);
        } catch (IOError e) {
            warning ("Could not register search provider: %s", e.message);
            quit ();
        }

        return true;
    }
}
