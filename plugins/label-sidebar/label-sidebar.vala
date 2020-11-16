public class Plugins.LabelSidebar : Peas.ExtensionBase, Peas.Activatable {
    Plugins.Interface plugins;
    public Object object { owned get; construct; }

    // Widgets
    private Widgets.Pane pane = null;
    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.EventBox top_eventbox;
    private Gtk.Grid main_grid;
    private Gtk.Revealer main_revealer;

    private uint timeout_id = 0;
    private uint toggle_timeout = 0;

    public void activate () {
        plugins = (Plugins.Interface) object;
        plugins.hook_pane.connect ((p) => {
            if (pane != null)
                return;
            
            pane = p;
            build_ui ();
        });
    }
    
    public void deactivate () {
        hide_destroy ();
    }

    public void update_state () { }

    private void build_ui () {
        var area_image = new Gtk.Image ();
        area_image.halign = Gtk.Align.CENTER;
        area_image.valign = Gtk.Align.CENTER;
        area_image.gicon = new ThemedIcon ("pricetag-outline-blue");
        area_image.pixel_size = 16;

        var name_label = new Gtk.Label (_("Labels"));
        name_label.margin_start = 9;
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("pane-area");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var menu_image = new Gtk.Image ();
        menu_image.gicon = new ThemedIcon ("edit-symbolic");
        menu_image.pixel_size = 14;

        var menu_button = new Gtk.Button ();
        menu_button.can_focus = false;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.tooltip_text = _("Section Menu");
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
        top_box.margin_start = 5;
        top_box.margin_top = 1;
        top_box.margin_bottom = 1;
        top_box.pack_start (area_image, false, false, 0);
        top_box.pack_start (name_label, false, true, 0);
        top_box.pack_end (menu_stack, false, false, 0);

        top_eventbox = new Gtk.EventBox ();
        top_eventbox.margin_start = 7;
        top_eventbox.margin_end = 5;
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.add (top_box);
        top_eventbox.get_style_context ().add_class ("toogle-box");

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.margin_top = 3;
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

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = false;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (main_grid);

        pane.listbox_grid.add (main_revealer);
        pane.show_all ();

        timeout_id = Timeout.add (150, () => {
            timeout_id = 0;
            main_revealer.reveal_child = true;
            return false;
        });

        get_all_labels ();

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                var label = ((Widgets.LabelPaneRow) row).label;
                pane.label_selected (label);
                pane.project_listbox.unselect_all ();
                pane.listbox.unselect_all ();
                Planner.event_bus.area_unselect_all ();
            }
        });

        Planner.database.label_added.connect_after ((label) => {
            Idle.add (() => {
                var row = new Widgets.LabelPaneRow (label);
                listbox.insert (row, 0);
                listbox.show_all ();
                return false;
            });
        });

        top_eventbox.enter_notify_event.connect ((event) => {
            menu_stack.visible_child_name = "menu_button";
            return true;
        });

        top_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            menu_stack.visible_child_name = "count_label";
            return true;
        });

        menu_button.clicked.connect (() => {
            var dialog = new Dialogs.Preferences.Preferences ("labels");
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
        });

        Planner.utils.pane_project_selected.connect (() => {
            listbox.unselect_all ();
        });

        Planner.utils.pane_action_selected.connect (() => {
            listbox.unselect_all ();
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;

        Timeout.add (500, () => {
            main_grid.destroy ();
            return false;
        });
    }

    private void get_all_labels () {
        foreach (var label in Planner.database.get_all_labels ()) {
            var row = new Widgets.LabelPaneRow (label);
            listbox.add (row);
        }
        listbox.show_all ();
    }
}

public class Widgets.LabelPaneRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;

    public LabelPaneRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {
        margin_start = margin_end = 6;
        margin_top = 2;
        get_style_context ().add_class ("pane-row");

        var color_image = new Gtk.Image.from_icon_name ("tag-symbolic", Gtk.IconSize.MENU);
        color_image.valign = Gtk.Align.CENTER;
        color_image.halign = Gtk.Align.CENTER;
        color_image.can_focus = false;
        color_image.get_style_context ().add_class ("label-%s".printf (label.id.to_string ()));

        var name_label = new Gtk.Label (label.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("font-weight-600");
        name_label.valign = Gtk.Align.CENTER;
        name_label.margin_start = 3;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        count_label = new Gtk.Label (null);
        count_label.label = "<small>%i</small>".printf (8);
        count_label.valign = Gtk.Align.CENTER;
        count_label.opacity = 0.7;
        count_label.use_markup = true;
        count_label.width_chars = 3;

        count_revealer = new Gtk.Revealer ();
        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.add (count_label);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        main_box.margin = 6;
        main_box.margin_end = 3;
        main_box.hexpand = true;
        main_box.pack_start (color_image, false, false, 0);
        main_box.pack_start (name_label, false, true, 0);
        main_box.pack_end (count_revealer, false, true, 0);

        var main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (main_box);

        add (main_revealer);
        update_count ();

        Planner.database.label_updated.connect ((l) => {
            Idle.add (() => {
                if (label.id == l.id) {
                    name_label.label = l.name;
                }

                return false;
            });
        });

        Planner.database.label_deleted.connect ((l) => {
            if (label.id == l.id) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }
        });

        Planner.database.item_label_added.connect ((id, item_id, l) => {
            if (label.id == l.id) {
                update_count ();
            }
        });

        Planner.database.item_label_deleted.connect ((id, item_id, l) => {
            if (label.id == l.id) {
                update_count ();
            }
        });
    }

    private void update_count () {
        var count = Planner.database.get_items_by_label (label.id).size;
        count_label.label = "<small>%i</small>".printf (count);

        if (count <= 0) {
            count_revealer.reveal_child = false;
        } else {
            count_revealer.reveal_child = true;
        }
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (
        typeof (Peas.Activatable),
        typeof (Plugins.LabelSidebar)
    );
}
