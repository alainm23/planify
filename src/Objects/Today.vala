public class Objects.Today : Objects.BaseObject {
    private static Today? _instance;
    public static Today get_default () {
        if (_instance == null) {
            _instance = new Today ();
        }

        return _instance;
    }

    int? _today_count = null;
    public int today_count {
        get {
            if (_today_count == null) {
                _today_count = Services.Database.get_default ().get_items_by_date (
                    new GLib.DateTime.now_local (), false).size;
            }

            return _today_count;
        }

        set {
            _today_count = value;
        }
    }

    int? _overdeue_count = null;
    public int overdeue_count {
        get {
            if (_overdeue_count == null) {
                _overdeue_count = Services.Database.get_default ().get_items_by_overdeue_view (false).size;
            }

            return _overdeue_count;
        }

        set {
            _overdeue_count = value;
        }
    }

    public signal void today_count_updated ();

    construct {
        name = _("Today");

        Services.Database.get_default ().item_added.connect (() => {
            _today_count = Services.Database.get_default ().get_items_by_date (
                new GLib.DateTime.now_local (), false).size;
            _overdeue_count = Services.Database.get_default ().get_items_by_overdeue_view (false).size;
            today_count_updated ();
        });

        Services.Database.get_default ().item_deleted.connect (() => {
            _today_count = Services.Database.get_default ().get_items_by_date (
                new GLib.DateTime.now_local (), false).size;
            _overdeue_count = Services.Database.get_default ().get_items_by_overdeue_view (false).size;
            today_count_updated ();
        });

        Services.Database.get_default ().item_updated.connect (() => {
            _today_count = Services.Database.get_default ().get_items_by_date (
                new GLib.DateTime.now_local (), false).size;
            _overdeue_count = Services.Database.get_default ().get_items_by_overdeue_view (false).size;
            today_count_updated ();
        });
    }
}