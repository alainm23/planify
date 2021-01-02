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

        var menu_image = new Gtk.Image ();
        menu_image.gicon = new ThemedIcon ("list-add-symbolic");
        menu_image.pixel_size = 14;

        var menu_button = new Gtk.Button ();
        menu_button.can_focus = false;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.tooltip_text = _("Add Label");
        menu_button.image = menu_image;
        menu_button.get_style_context ().remove_class ("button");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("hidden-button");

        var count_label = new Gtk.Label (null);
        count_label.valign = Gtk.Align.CENTER;
        count_label.opacity = 0;
        count_label.use_markup = true;
        count_label.width_chars = 3;

        var menu_stack = new Gtk.Stack ();
        menu_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        menu_stack.add_named (count_label, "count_label");
        menu_stack.add_named (menu_button, "menu_button");

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin_top = 3;
        top_box.margin_bottom = 3;
        top_box.pack_start (arrow_button, false, false, 0);
        top_box.pack_start (name_label, false, true, 0);
        top_box.pack_end (menu_stack, false, false, 0);

        top_eventbox = new Gtk.EventBox ();
        top_eventbox.margin_start = 4;
        top_eventbox.margin_end = 3;
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.add (top_box);
        top_eventbox.get_style_context ().add_class ("toogle-box");

        task_store = Services.Tasks.Store.get_default ();
        tasklists_loaded = new Gee.HashMap <string, bool> ();

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.margin_bottom = 6;
        listbox.margin_start = 20;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        listbox_revealer = new Gtk.Revealer ();
        listbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        listbox_revealer.add (listbox);

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

        top_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                toggle_hidden ();
            }
            
            return false;
        });

        arrow_button.clicked.connect (() => {
            toggle_hidden ();
        });
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
