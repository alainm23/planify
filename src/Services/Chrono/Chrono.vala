public class Services.Chrono.Chrono : GLib.Object {
    public Services.Chrono.extras extras { get; set; }
    public Services.Chrono.en en { get; set; }
    
    static Chrono _instance = null;
    public static Chrono instance {
        get {
            if (_instance == null) {
                _instance = new Chrono ();
            }
            return _instance;
        }
    }

    construct {
        extras = Services.Chrono.extras.instance;
        en = Services.Chrono.en.instance;
    }

    public Objects.Duedate? parse (string expression, string lang) {
        if (lang == "en") {
            if (extras.parse (expression) != null) {
                return extras.parse (expression);
            }

            return en.parse (expression);
        }

        return null;
    }
}