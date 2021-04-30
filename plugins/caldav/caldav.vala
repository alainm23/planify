public class Plugins.CalDAV : Peas.ExtensionBase, Peas.Activatable {
    Plugins.Interface plugins;
    public Object object { owned get; construct; }
    
    private Widgets.Pane pane = null;
    private MainWindow window = null;

    private Gee.HashMap<E.Source, Widgets.SourceRow>? source_rows = null;
    private Gee.HashMap<string, E.Source>? source_uids = null;
    private Gee.Collection<E.Source>? collection_sources;
    private static Services.Tasks.Store task_store;
    private Views.TaskList listview = null;
    private Gtk.ListBox listbox;
    private Gtk.Grid main_grid;
    private Gtk.Button arrow_button;
    private Gtk.EventBox top_eventbox;
    private Gtk.Revealer listbox_revealer;

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
        var arrow_icon = new Gtk.Image ();
        arrow_icon.gicon = new ThemedIcon ("pan-end-symbolic");
        arrow_icon.pixel_size = 14;

        arrow_button = new Gtk.Button ();
        arrow_button.valign = Gtk.Align.CENTER;
        arrow_button.halign = Gtk.Align.CENTER;
        arrow_button.can_focus = false;
        arrow_button.image = arrow_icon;
        arrow_button.tooltip_text = _("Project Menu");
        arrow_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        arrow_button.get_style_context ().add_class ("dim-label");
        arrow_button.get_style_context ().add_class ("transparent");
        arrow_button.get_style_context ().add_class ("hidden-button");

        var name_label = new Gtk.Label (_("CalDAV"));
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("pane-area");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin_top = 3;
        top_box.margin_bottom = 3;
        top_box.margin_start = 5;
        top_box.pack_start (name_label, false, true, 0);
        top_box.pack_end (arrow_button, false, false, 0);

        top_eventbox = new Gtk.EventBox ();
        top_eventbox.margin_start = 4;
        top_eventbox.margin_end = 3;
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.add (top_box);
        top_eventbox.get_style_context ().add_class ("toogle-box");

        task_store = Services.Tasks.Store.get_default ();

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.margin_bottom = 6;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        listbox_revealer = new Gtk.Revealer ();
        listbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        listbox_revealer.add (listbox);
        listbox_revealer.reveal_child = true;

        main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_eventbox);
        main_grid.add (listbox_revealer);

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

            var task_lists = registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST);
            task_lists.foreach ((source) => {
                E.SourceTaskList list = (E.SourceTaskList) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
                if (list.selected == true && source.enabled == true) {
                    add_source (source);
                }
            });

            add_collection_source (registry.ref_builtin_task_list ());

            var task_list_collections = registry.list_sources (E.SOURCE_EXTENSION_COLLECTION);
            task_list_collections.foreach ((collection_source) => {
                add_collection_source (collection_source);
            });
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            Planner.event_bus.unselect_all ();

            if (pane_type == PaneType.TASKLIST && source_uids.has_key (id)) {
                tasklist_selected (source_uids.get (id));
            }
        });

        top_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                toggle_hidden ();
            }
            
            return false;
        });

        arrow_button.clicked.connect (() => {
            toggle_hidden ();
        });

        Planner.event_bus.sync.connect (() => {
            action_refresh_all_lists ();
        });
    }

    private void action_refresh_all_lists () {
        task_store.get_registry.begin ((obj, res) => {
            try {
                var registry = task_store.get_registry.end (res);

                if (collection_sources != null) {
                    lock (collection_sources) {
                        foreach (var collection_source in collection_sources) {
                            var backend_name = task_store.get_collection_backend_name (collection_source, registry);

                            if (backend_name.down () != "local") {
                                try {
                                    registry.refresh_backend_sync (collection_source.dup_uid ());
                                } catch (Error e) {
                                    // dialog_refresh_backend_error (e, collection_source, registry);
                                }
                            }
                        }
                    }
                }

                if (source_rows != null) {
                    lock (source_rows) {
                        source_rows.foreach (source_row => {
                            source_row.key.set_connection_status (E.SourceConnectionStatus.CONNECTING);
                            source_row.value.update_request ();

                            task_store.refresh_task_list.begin (source_row.key, null, (obj, res) => {
                                try {
                                    task_store.refresh_task_list.end (res);
                                    source_row.key.set_connection_status (E.SourceConnectionStatus.CONNECTED);
                                } catch (Error e) {
                                    source_row.key.set_connection_status (E.SourceConnectionStatus.DISCONNECTED);
                                    // dialog_refresh_task_list_error (e, source_row.key, registry);
                                }
                                source_row.value.update_request ();
                            });
                            return true;
                        });
                    }
                }

            } catch (Error e) {
                // dialog_get_registry_error (e);
            }
        });
    }

    private void add_collection_source (E.Source collection_source) {
        if (collection_sources == null) {
            collection_sources = new Gee.HashSet<E.Source> (CalDAVUtil.esource_hash_func, CalDAVUtil.esource_equal_func);
        }
        E.SourceTaskList collection_source_tasklist_extension = (E.SourceTaskList)collection_source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

        if (collection_sources.contains (collection_source) || !collection_source.enabled || !collection_source_tasklist_extension.selected) {
            return;
        }
        collection_sources.add (collection_source);

        var backend_name = task_store.get_collection_backend_name (collection_source, task_store.get_registry_sync ());
        if (backend_name == "local") {
            var source_button = new Widgets.SourceButton (
                _("Task List"),
                CalDAVUtil.get_esource_collection_display_name (collection_source),
                get_source_icon (backend_name),
                collection_source.uid
            );
            source_button.sensitive = task_store.is_add_task_list_supported (collection_source);
            source_button.clicked.connect (() => {
                add_new_list (collection_source);
            });
    
            pane.add_project_buttonbox.add (source_button);
            pane.add_project_buttonbox.show_all ();
            pane.buttonbox_scrolled.show_all ();
        }
    }

    private string get_source_icon (string source) {
        if (source == "local") {
            return "planner-offline-symbolic";
        }

        return "planner-online-symbolic";
    }

    private void add_new_list (E.Source collection_source) {
        var error_dialog_primary_text = _("Creating a new task list failed");
        var error_dialog_secondary_text = _("The task list registry may be unavailable or unable to be written to.");

        try {
            var new_source = new E.Source (null, null);
            var new_source_tasklist_extension = (E.SourceTaskList) new_source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
            new_source.display_name = _("New list");
            new_source_tasklist_extension.color = "#0e9a83";

            task_store.add_task_list.begin (new_source, collection_source, (obj, res) => {
                try {
                    task_store.add_task_list.end (res);
                    Timeout.add (250, () => {
                        Planner.event_bus.pane_selected (PaneType.TASKLIST, new_source.uid);
                        Timeout.add (250, () => {
                            Planner.event_bus.edit_tasklist (new_source.uid);
                            return GLib.Source.REMOVE;
                        });
                        return GLib.Source.REMOVE;
                    });
                } catch (Error e) {
                    critical (e.message);
                    show_error_dialog (error_dialog_primary_text, error_dialog_secondary_text, e);
                }
            });

        } catch (Error e) {
            critical (e.message);
            show_error_dialog (error_dialog_primary_text, error_dialog_secondary_text, e);
        }
    }

    private void show_error_dialog (string primary_text, string secondary_text, Error e) {
        string error_message = e.message;

        GLib.Idle.add (() => {
            var error_dialog = new Granite.MessageDialog (
                primary_text,
                secondary_text,
                new ThemedIcon ("dialog-error"),
                Gtk.ButtonsType.CLOSE
            );
            error_dialog.show_error_details (error_message);
            error_dialog.run ();
            error_dialog.destroy ();

            return GLib.Source.REMOVE;
        });
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

        var header_label = new Granite.HeaderLabel (get_esource_collection_display_name (row.source)) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            margin_start = 6
        };

        row.set_header (header_label);
    }

    public string get_esource_collection_display_name (E.Source source) {
        var display_name = "";

        try {
            var registry = task_store.get_registry_sync ();
            var collection_source = registry.find_extension (source, E.SOURCE_EXTENSION_COLLECTION);

            if (collection_source != null) {
                display_name = collection_source.display_name;
            } else if (source.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
                display_name = ((E.SourceTaskList) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST)).backend_name;
            }

        } catch (Error e) {
            warning (e.message);
        }

        return display_name;
    }

    private void toggle_hidden () {
        top_eventbox.get_style_context ().add_class ("active");
        Timeout.add (750, () => {
            top_eventbox.get_style_context ().remove_class ("active");
            return GLib.Source.REMOVE;
        });

        listbox_revealer.reveal_child = !listbox_revealer.reveal_child;
        // Planner.settings.set_boolean ("sidebar-labels-collapsed", listbox_revealer.reveal_child);

        if (listbox_revealer.reveal_child) {
            arrow_button.get_style_context ().add_class ("opened");
        } else {
            arrow_button.get_style_context ().remove_class ("opened");
        }
    }

    public void tasklist_selected (E.Source source) {
        if (listview == null) {
            listview = new Views.TaskList ();
            window.project_stack.add_named (listview, "tasklist");
        }

        listview.source = source;

        window.project_stack.visible_child_name = "tasklist";
    }   

    private void add_source (E.Source source) {
        if (source_rows == null) {
            source_rows = new Gee.HashMap<E.Source, Widgets.SourceRow> ();
        }

        if (source_uids == null) {
            source_uids = new Gee.HashMap<string, E.Source> ();
        }

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
