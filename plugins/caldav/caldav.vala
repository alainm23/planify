public class Plugins.CalDAV : Peas.ExtensionBase, Peas.Activatable {
    Plugins.Interface plugins;
    public Object object { owned get; construct; }
    
    private Widgets.Pane pane = null;
    private MainWindow window = null;

    private Gee.HashMap<E.Source, Widgets.SourceRow>? source_rows = null;
    private Gee.HashMap<string, E.Source>? source_uids = null;
    private Gee.HashMap <string, bool> tasklists_loaded;
    private static Services.Tasks.Store task_store;
    private Gtk.ListBox listbox;
    private Gtk.Grid main_grid;
    public void activate () {
        plugins = (Plugins.Interface) object;
        plugins.hook_widgets.connect ((w, p) => {
            if (pane != null && window != null) {
                return;
            }
            
            window = w;
            pane = p;
            
            build_ui ();
        });
    }
    
    public void deactivate () {
        task_store.task_list_added.disconnect (add_source);
        task_store.task_list_modified.disconnect (update_source);
        task_store.task_list_removed.disconnect (remove_source);

        main_grid.destroy ();
    }

    public void update_state () { }

    private void build_ui () {
        task_store = Services.Tasks.Store.get_default ();
        tasklists_loaded = new Gee.HashMap <string, bool> ();

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.margin_top = 3;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (listbox);

        pane.listbox_grid.add (main_grid);
        pane.show_all ();

        task_store.task_list_added.connect (add_source);
        task_store.task_list_modified.connect (update_source);
        task_store.task_list_removed.connect (remove_source);

        task_store.get_registry.begin ((obj, res) => {
            E.SourceRegistry registry;
            try {
                registry = task_store.get_registry.end (res);
            } catch (Error e) {
                critical (e.message);
                return;
            }

            // listbox.set_header_func (header_update_func);
            
            var task_lists = registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST);
            task_lists.foreach ((source) => {
                E.SourceTaskList list = (E.SourceTaskList) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
                if (list.selected == true && source.enabled == true) {
                    add_source (source);
                }
            });
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            Planner.event_bus.unselect_all ();

            if (pane_type == PaneType.TASKLIST && source_uids.has_key (id)) {
                tasklist_selected (source_uids.get (id));
            }
        });
    }

    public void tasklist_selected (E.Source source) {
        if (tasklists_loaded.has_key (source.uid)) {
            window.stack.visible_child_name = "tasklist-%s".printf (source.uid);
        } else {
            tasklists_loaded.set (source.uid, true);
            var tasklist_view = new Views.TaskList (source);
            window.stack.add_named (tasklist_view, "tasklist-%s".printf (source.uid));
            window.stack.visible_child_name = "tasklist-%s".printf (source.uid);
        }
    }   

    private void add_source (E.Source source) {
        if (source_rows == null) {
            source_rows = new Gee.HashMap<E.Source, Widgets.SourceRow> ();
        }

        if (source_uids == null) {
            source_uids = new Gee.HashMap<string, E.Source> ();
        }

        debug ("Adding row '%s'", source.dup_display_name ());
        if (!source_rows.has_key (source)) {
            source_rows[source] = new Widgets.SourceRow (source);
            source_uids[source.uid] = source;

            listbox.add (source_rows[source]);
            listbox.show_all ();
        }
    }

    private void update_source (E.Source source) {
        E.SourceTaskList list = (E.SourceTaskList)source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

        if (list.selected != true || source.enabled != true) {
            remove_source (source);

        } else if (!source_rows.has_key (source)) {
            add_source (source);
        }
    }

    private void remove_source (E.Source source) {
        listbox.unselect_row (source_rows[source]);
        source_rows[source].remove_request ();
        source_rows.unset (source);
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (
        typeof (Peas.Activatable),
        typeof (Plugins.CalDAV)
    );
}
