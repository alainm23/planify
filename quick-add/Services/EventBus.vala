public class Services.EventBus : Object {
    private static EventBus? _instance;
    public static EventBus get_default () {
        if (_instance == null) {
            _instance = new EventBus ();
        }

        return _instance;
    }

    public signal void theme_changed ();
}