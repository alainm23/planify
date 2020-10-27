public class Plugins.Interface : GLib.Object {
    public Services.PluginsManager manager;

    // Signals
    public signal void hook_pane (Widgets.Pane pane);

    public Interface (Services.PluginsManager manager) {
        this.manager = manager;
    }
}

public class Services.PluginsManager : GLib.Object {
    Peas.Engine engine;
    Peas.ExtensionSet exts;
    Peas.Engine engine_core;
    Peas.ExtensionSet exts_core;

    string settings_field;

    public Plugins.Interface plugin_iface { private set; public get; }

    // Signals
    public signal void hook_pane (Widgets.Pane pane);

    public signal void extension_added (Peas.PluginInfo info);
    public signal void extension_removed (Peas.PluginInfo info);

    public PluginsManager () {
        settings_field = "plugins-enabled";

        plugin_iface = new Plugins.Interface (this);

        engine = Peas.Engine.get_default ();
        engine.enable_loader ("python");
        engine.add_search_path (Constants.PLUGINDIR, null);
        Planner.settings.bind ("plugins-enabled", engine, "loaded-plugins", SettingsBindFlags.DEFAULT);

        /* Our extension set */
        exts = new Peas.ExtensionSet (engine, typeof (Peas.Activatable), "object", plugin_iface, null);

        exts.extension_added.connect ((info, ext) => {
            ((Peas.Activatable)ext).activate ();
            extension_added (info);
        });
        
        exts.extension_removed.connect ((info, ext) => {
            ((Peas.Activatable)ext).deactivate ();
            extension_removed (info);
        });

        exts.foreach (on_extension_foreach);

        // Connect managers signals to interface's signals
        this.hook_pane.connect ((w) => {
            plugin_iface.hook_pane (w);
        });
   }

    void on_extension_foreach (Peas.ExtensionSet set, Peas.PluginInfo info, Peas.Extension extension) {
        ((Peas.Activatable)extension).activate ();
    }

    public Gtk.Widget get_view () {
        var view = new PeasGtk.PluginManager (engine);
        view.expand = true;
        view.margin = 12;
        var bottom_box = view.get_children ().nth_data (1);
        bottom_box.no_show_all = true;
        return view;
    }
}
