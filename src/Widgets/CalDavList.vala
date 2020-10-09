public class Widgets.CalDavList : Gtk.EventBox {
    private Gee.HashMap<E.Source, Widgets.SourceRow>? source_rows = null;
    private Gtk.ListBox listbox;

    public signal void tasklist_selected (E.Source source);
    construct {
        var caldav_header = new Granite.HeaderLabel (_("CalDav"));
        caldav_header.margin_start = 12;

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        // grid.add (caldav_header);
        grid.add (listbox);

        add (grid);

        Planner.task_store.task_list_added.connect (add_source);
        Planner.task_store.task_list_modified.connect (update_source);
        Planner.task_store.task_list_removed.connect (remove_source);
        Planner.task_store.get_registry.begin ((obj, res) => {
            E.SourceRegistry registry;
            try {
                registry = Planner.task_store.get_registry.end (res);
            } catch (Error e) {
                critical (e.message);
                return;
            }

            listbox.set_header_func (header_update_func);
            
            var task_lists = registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST);
            task_lists.foreach ((source) => {
                E.SourceTaskList list = (E.SourceTaskList)source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
                if (list.selected == true && source.enabled == true) {
                    add_source (source);
                }
            });
        });

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                var source = ((Widgets.SourceRow) row).source;
                tasklist_selected (source);
            }
        });
    }

    private void add_source (E.Source source) {
        if (source_rows == null) {
            source_rows = new Gee.HashMap<E.Source, Widgets.SourceRow> ();
        }

        debug ("Adding row '%s'", source.dup_display_name ());
        if (!source_rows.has_key (source)) {
            source_rows[source] = new Widgets.SourceRow (source);

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

        } else {
            source_rows[source].update_request ();
        }
    }

    private void remove_source (E.Source source) {
        listbox.unselect_row (source_rows[source]);
        source_rows[source].remove_request ();
        source_rows.unset (source);
    }

    private void header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        if (!(lbrow is Widgets.SourceRow)) {
            return;
        }
        var row = (Widgets.SourceRow) lbrow;
        if (lbbefore != null && lbbefore is Widgets.SourceRow) {
            var before = (Widgets.SourceRow) lbbefore;
            if (row.source.parent == before.source.parent) {
                return;
            }
        }

        E.SourceRegistry registry;
        try {
            registry = Planner.task_store.get_registry_sync ();
        } catch (Error e) {
            warning (e.message);
            return;
        }
        string display_name;

        var ancestor = registry.find_extension (row.source, E.SOURCE_EXTENSION_COLLECTION);
        if (ancestor != null) {
            display_name = ancestor.display_name;
        } else {
            display_name = ((E.SourceTaskList?) row.source.get_extension (E.SOURCE_EXTENSION_TASK_LIST)).backend_name;
        }

        var header_label = new Granite.HeaderLabel (display_name);
        header_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
        header_label.margin_start = 6;

        row.set_header (header_label);
    }
}
