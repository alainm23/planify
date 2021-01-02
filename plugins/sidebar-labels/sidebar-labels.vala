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
    private Gtk.Button arrow_button;

    private uint timeout_id = 0;
    private uint toggle_timeout = 0;

    public void activate () {
        plugins = (Plugins.Interface) object;
        plugins.hook_widgets.connect ((w, p) => {
            if (pane != null) {
                return;
            }
            
            pane = p;
            build_ui ();
        });
    }
    
    public void deactivate () {
        hide_destroy ();
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

        var name_label = new Gtk.Label (_("Labels"));
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
        listbox_revealer.reveal_child = Planner.settings.get_boolean ("sidebar-labels-collapsed");

        main_grid = new Gtk.Grid ();
        main_grid.margin_top = 6;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_eventbox);
        main_grid.add (listbox_revealer);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = false;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (main_grid);

        pane.listbox_grid.add (main_revealer);
        pane.show_all ();

        if (listbox_revealer.reveal_child) {
            arrow_button.get_style_context ().add_class ("opened");
        } else {
            arrow_button.get_style_context ().remove_class ("opened");
        }
        
        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        get_all_labels ();
        
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

        top_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                toggle_hidden ();
            }
            
            return false;
        });

        menu_button.clicked.connect (() => {
            var dialog = new Dialogs.Preferences.Preferences ("labels");
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
        });

        Planner.utils.pane_action_selected.connect (() => {
            listbox.unselect_all ();
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
        Planner.settings.set_boolean ("sidebar-labels-collapsed", listbox_revealer.reveal_child);

        if (listbox_revealer.reveal_child) {
            arrow_button.get_style_context ().add_class ("opened");
        } else {
            arrow_button.get_style_context ().remove_class ("opened");
        }
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
        margin_start = 6;
        margin_top = 2;
        margin_end = 3;
        get_style_context ().add_class ("label-row");
        get_style_context ().add_class ("transparent");

        var color_image = new Gtk.Image.from_icon_name ("tag-symbolic", Gtk.IconSize.MENU);
        color_image.valign = Gtk.Align.CENTER;
        color_image.halign = Gtk.Align.CENTER;
        color_image.can_focus = false;
        color_image.get_style_context ().add_class ("label-%s".printf (label.id.to_string ()));

        var name_label = new Gtk.Label (label.name);
        name_label.halign = Gtk.Align.START;
        name_label.valign = Gtk.Align.CENTER;
        name_label.margin_start = 1;
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
        main_box.margin_bottom = 5;
        main_box.margin_top = 5;
        main_box.hexpand = true;
        main_box.pack_start (color_image, false, false, 0);
        main_box.pack_start (name_label, false, true, 0);
        main_box.pack_end (count_revealer, false, true, 0);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.hexpand = true;
        handle.above_child = false;
        handle.add (main_box);

        var main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);
        update_count ();

        handle.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Planner.event_bus.pane_selected (PaneType.LABEL, label.id.to_string ());
                return false;
            }

            return false;
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.LABEL && label.id.to_string () == id) {
                handle.get_style_context ().add_class ("project-selected");
            } else {
                handle.get_style_context ().remove_class ("project-selected");
            }
        });

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
