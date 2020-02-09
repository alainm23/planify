[DBus (name = "com.github.alainm23.planner")]
public class Services.DBusServer : Object {
    private const string DBUS_NAME = "com.github.alainm23.planner";
    private const string DBUS_PATH = "/com/github/alainm23/planner";

    private static GLib.Once<DBusServer> instance;

    public static unowned DBusServer get_default () {
        return instance.once (() => { return new DBusServer (); });
    }

    public signal void item_added (int64 id);

    construct {
        Bus.own_name (
            BusType.SESSION,
            DBUS_NAME,
            BusNameOwnerFlags.NONE,
            (connection) => on_bus_aquired (connection),
            () => { },
            null
        );
    }

    public void add_item (int64 id) throws IOError, DBusError {
        item_added (id);
    }

    private void on_bus_aquired (DBusConnection conn) {
        try {
            conn.register_object (DBUS_PATH, get_default ());
        } catch (Error e) {
            error (e.message);
        }
    }
}

[DBus (name = "com.github.alainm23.planner")]
public errordomain DBusServerError {
    SOME_ERROR
}
