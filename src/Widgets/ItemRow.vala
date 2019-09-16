public class Widgets.ItemRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    private Gtk.Revealer bottom_revealer;
    private Gtk.Box top_box;
    private Gtk.Image view_image;

    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;
    private Gtk.Label content_label;
    private Gtk.Stack content_stack;
    private Gtk.TextView note_textview;
    private Gtk.Label note_placeholder;

    private Gtk.ListBox check_listbox;
    private Gtk.Revealer checklist_separator_revealer;

    private Gtk.Revealer motion_revealer;
    private bool is_item_open;

    private const Gtk.TargetEntry[] targetEntries = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool reveal_child {
        set {
            if (value) {
                bottom_revealer.reveal_child = true;

                get_style_context ().add_class ("item-row-selected");

                content_stack.visible_child_name = "content_entry";

                view_image.get_style_context ().add_class ("opened");

                activatable = false;
                selectable = false;
                
                content_entry.grab_focus_without_selecting ();
                //content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
            }
        }
        get {
            return bottom_revealer.reveal_child;
        }
    }

    public bool reveal_drag_motion {
        set {   
            motion_revealer.reveal_child = value;
        }
        get {
            return motion_revealer.reveal_child;
        }
    }

    public ItemRow (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        is_item_open = false;
        var HAND_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.HAND1);
        var ARROW_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.ARROW);
        var window = Gdk.Screen.get_default ().get_root_window ();

        can_focus = false;
        get_style_context ().add_class ("item-row");

        view_image = new Gtk.Image ();
        view_image.valign = Gtk.Align.CENTER;
        //view_image.get_style_context ().add_class ("dim-label");
        view_image.get_style_context ().add_class ("view-button");
        view_image.pixel_size = 16;
        view_image.icon_name = "pan-end-symbolic";

        var view_eventbox = new Gtk.EventBox ();
        view_eventbox.add (view_image);

        var view_revealer = new Gtk.Revealer ();
        view_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        view_revealer.add (view_eventbox);
        view_revealer.reveal_child = false;

        checked_button = new Gtk.CheckButton ();
        checked_button.valign = Gtk.Align.BASELINE;
        checked_button.halign = Gtk.Align.BASELINE;

        if (item.checked == 1) {
            checked_button.active = true;
        } else {
            checked_button.active = false;
        }

        content_label = new Gtk.Label (item.content);
        content_label.halign = Gtk.Align.START;
        content_label.valign = Gtk.Align.CENTER;
        content_label.use_markup = true;
        content_label.margin_bottom = 1;
        content_label.ellipsize = Pango.EllipsizeMode.END;

        content_entry = new Gtk.Entry ();
        content_entry.margin_bottom = 1;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("content-entry");
        //content_entry.get_style_context ().add_class ("h3");
        content_entry.text = item.content;
        content_entry.hexpand = true;

        content_stack = new Gtk.Stack ();
        content_stack.hexpand = true;
        content_stack.transition_type = Gtk.StackTransitionType.NONE;
        content_stack.add_named (content_label, "content_label");
        content_stack.add_named (content_entry, "content_entry");

        top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 7);
        top_box.margin_start = 0;
        top_box.hexpand = true;
        top_box.margin_start = 12;
        top_box.pack_start (view_revealer, false, false, 0);
        top_box.pack_start (checked_button, false, false, 2);
        top_box.pack_start (content_stack, false, true, 0);

        note_textview = new Gtk.TextView ();
        note_textview.margin_start = 64;
        note_textview.buffer.text = item.note;
        note_textview.wrap_mode = Gtk.WrapMode.WORD;
        note_textview.get_style_context ().add_class ("textview");
        note_textview.height_request = 42;

        note_placeholder = new Gtk.Label (_("Add note"));
        note_placeholder.opacity = 0.7;
        note_textview.add (note_placeholder);

        if (item.note != "") {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;
        }
            
        check_listbox = new Gtk.ListBox  ();
        check_listbox.margin_top = 6;
        check_listbox.margin_start = 65;
        check_listbox.margin_end = 12;
        check_listbox.get_style_context ().add_class ("check-listbox");

        var new_checklist = new Widgets.NewCheck (item.id);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 65;
        separator.margin_end = 12;

        checklist_separator_revealer = new Gtk.Revealer ();
        checklist_separator_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        checklist_separator_revealer.add (separator);

        var due_button = new Gtk.Button.from_icon_name ("office-calendar-symbolic");
        due_button.always_show_image = true;
        due_button.label = _("Due");
        due_button.halign = Gtk.Align.START;
        due_button.get_style_context ().add_class ("flat");
        due_button.get_style_context ().add_class ("due-button");

        var label_button = new Gtk.Button.from_icon_name ("tag-symbolic");
        label_button.always_show_image = true;
        label_button.label = _("Label");
        label_button.halign = Gtk.Align.START;
        label_button.get_style_context ().add_class ("flat");
        label_button.get_style_context ().add_class ("label-button");

        var delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic");
        delete_button.halign = Gtk.Align.START;
        delete_button.get_style_context ().add_class ("flat");
        delete_button.get_style_context ().add_class ("check-button");

        var settings_button = new Gtk.MenuButton ();
        settings_button.valign = Gtk.Align.CENTER;
        //settings_button.tooltip_text = _("Edit Name and Appearance");
        //settings_button.popover = list_settings_popover;
        settings_button.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_start = 57;
        action_box.pack_start (due_button, false, false, 0);
        action_box.pack_start (label_button, false, false, 0);
        action_box.pack_end (settings_button, false, false, 0);
        action_box.pack_end (delete_button, false, false, 0);

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.margin_bottom = 6;
        bottom_box.pack_start (note_textview, false, true, 0);
        bottom_box.pack_start (check_listbox, false, true, 0);
        bottom_box.pack_start (checklist_separator_revealer, false, true, 0);
        bottom_box.pack_start (new_checklist, false, true, 0);
        bottom_box.pack_end (action_box, false, false, 0);
        
        bottom_revealer = new Gtk.Revealer ();
        bottom_revealer.valign = Gtk.Align.START;
        bottom_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        bottom_revealer.add (bottom_box);

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var main_grid = new Gtk.Grid ();
        main_grid.hexpand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (motion_revealer);
        main_grid.add (top_box);
        main_grid.add (bottom_revealer);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (main_grid);

        add (handle);
        add_all_checks ();
        
        build_drag_and_drop ();

        view_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                if (bottom_revealer.reveal_child) {
                    hide_item ();
                }
            }

            return false;
        });
        
        handle.enter_notify_event.connect ((event) => {
            view_revealer.reveal_child = true;
            window.cursor = HAND_cursor;

            return true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (bottom_revealer.reveal_child == false) {
                view_revealer.reveal_child = false;
            }

            window.cursor = ARROW_cursor;
            
            return true;
        });

        content_entry.activate.connect (() => {
            hide_item ();
        });

        content_entry.changed.connect (() => {
            save ();
        });

        note_textview.buffer.changed.connect (() => {
            save ();
        });

        checked_button.toggled.connect (() => {
            if (checked_button.active) {
                item.checked = 1;
                item.date_completed = new GLib.DateTime.now_local ().to_string ();
            } else {
                item.checked = 0;
                item.date_completed = "";
            }

            save ();
        });

        content_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_item ();
            }

            return false;
        });

        note_textview.focus_in_event.connect (() => {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;

            return false;
        });

        note_textview.focus_out_event.connect (() => {
            if (note_textview.buffer.text == "") {
                note_placeholder.visible = true;
                note_placeholder.no_show_all = false;
            }

            return false;
        });

        note_textview.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_item ();
            }

            return false;
        });

        check_listbox.remove.connect (() => {
            check_checklist_separator ();
        });

        delete_button.clicked.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Are you sure you want to delete this task?"),
                "",
                "dialog-warning",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete Task"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                Application.database.delete_item (item);
            }

            message_dialog.destroy ();
        });

        Application.database.check_added.connect ((check) => {
            if (item.id == check.item_id) {
                var row = new Widgets.CheckRow (check);
                check_listbox.add (row);
                check_listbox.show_all ();

                check_checklist_separator ();
            }
        });

        Application.database.item_deleted.connect ((i) => {
            if (item.id == i.id) {
                destroy ();
            }
        });
    }
  
    private void add_all_checks () {
        var all_checks = Application.database.get_all_cheks_by_item (item.id);

        foreach (var check in all_checks) {
            var row = new Widgets.CheckRow (check);
            check_listbox.add (row);
            check_listbox.show_all ();
        }

        check_checklist_separator ();
    }

    private void check_checklist_separator () {
        if (check_listbox.get_children ().length () > 0) {
            checklist_separator_revealer.reveal_child = true;
        } else {
            checklist_separator_revealer.reveal_child = false;
        }
    }

    private void hide_item () {
        bottom_revealer.reveal_child = false;

        get_style_context ().remove_class ("item-row-selected");
        top_box.margin_top = 3;

        content_stack.visible_child_name = "content_label";

        view_image.get_style_context ().remove_class ("opened");

        Timeout.add (250, () => {
            activatable = true;
            selectable = true;
                
            return false;
        });
    }

    private void save () {
        content_label.label = content_entry.text;

        item.content = content_entry.text;
        item.note = note_textview.buffer.text;

        item.save ();
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntries, Gdk.DragAction.MOVE);

        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        
        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, targetEntries, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);

        drag_end.connect (clear_indicator);
    }
    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (ItemRow) widget;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.3);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();
  
        cr.set_source_rgba (255, 255, 255, 0.5);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.top_box.draw (cr);

        Gtk.drag_set_icon_surface (context, surface);

        row.visible = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (ItemRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("ITEMROW"), 32, data
        );
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        reveal_drag_motion = true;   

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        reveal_drag_motion = false;
    }

    public void clear_indicator (Gdk.DragContext context) {
        reveal_drag_motion = false;
        
        visible = true;
        show_all ();
    }
}