[DBus (name = "com.github.alainm23.planner")]
public interface DBusClientInterface : Object {
    public abstract void add_item (int64 id) throws Error;
}

public class DBusClient : Object{
    public DBusClientInterface? interface = null;

    private static GLib.Once<DBusClient> instance;
    public static unowned DBusClient get_default () {
        return instance.once (() => { return new DBusClient (); });
    }

    construct {
        try {
            interface = Bus.get_proxy_sync (
                BusType.SESSION, 
                "com.github.alainm23.planner", 
                "/com/github/alainm23/planner");
        } catch (IOError e) {
            error ("Monitor Indicator DBus: %s\n", e.message);
        }
    }
}