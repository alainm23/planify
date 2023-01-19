public class Objects.Pinboard : Objects.BaseObject {
    private static Pinboard? _instance;
    public static Pinboard get_default () {
        if (_instance == null) {
            _instance = new Pinboard ();
        }

        return _instance;
    }

    int? _pinboard_count = null;
    public int pinboard_count {
        get {
            if (_pinboard_count == null) {
                _pinboard_count = Services.Database.get_default ().get_items_pinned (false).size;
            }

            return _pinboard_count;
        }

        set {
            _pinboard_count = value;
        }
    }

    public signal void pinboard_count_updated ();

    construct {
        name = ("Pinboard");
        keywords = _("pinboard");

        Services.Database.get_default ().item_added.connect (() => {
            _pinboard_count = Services.Database.get_default ().get_items_pinned (false).size;
            pinboard_count_updated ();
        });

        Services.Database.get_default ().item_deleted.connect (() => {
            _pinboard_count = Services.Database.get_default ().get_items_pinned (false).size;
            pinboard_count_updated ();
        });

        Services.Database.get_default ().item_updated.connect (() => {
            _pinboard_count = Services.Database.get_default ().get_items_pinned (false).size;
            pinboard_count_updated ();
        });
    }
}