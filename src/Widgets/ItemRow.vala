public class Widgets.ItemRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }
    
    public bool _is_today = false;
    public bool is_today {
        get {
            return _is_today;
        }

        set {
            _is_today = value;
            date_label_revealer.reveal_child = !value;

            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ()); 
            if (Application.utils.is_before_today (datetime)) {
                due_label.get_style_context ().add_class ("duedate-expired");
                date_label_revealer.reveal_child = true;
            }
        }
    }

    public GLib.DateTime? _upcoming = null;
    public GLib.DateTime? upcoming {
        get {
            return _upcoming;
        }

        set {
            _upcoming = value;
            date_label_revealer.reveal_child = false;

            project = Application.database.get_project_by_id (item.project_id);
            project_name_label.label = "<small>%s</small>".printf (project.name);
            project_name_revealer.reveal_child = true;
        }
    }

    private Objects.Project project { get; set; }

    private Gtk.Button hidden_button;
    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;
    private Gtk.Label content_label;
    private Gtk.Stack content_stack;
    
    private Gtk.Box top_box;
    private Gtk.TextView note_textview;
    private Gtk.Label note_placeholder;
    private Gtk.Revealer note_revealer;
    private Gtk.Revealer bottom_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid main_grid;
    private Gtk.Label due_label;
    private Gtk.Label project_name_label;
    private Gtk.Revealer project_name_revealer;

    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer labels_box_revealer;
    private Gtk.Revealer labels_edit_box_revealer;
    private Gtk.Revealer date_label_revealer;
    private Gtk.Box labels_box;
    private Gtk.Box labels_edit_box;
    
    private Widgets.NewCheck new_checklist;
    private Gtk.Revealer checklist_revealer;
    private Gtk.ListBox check_listbox;
    private Gtk.Revealer separator_revealer;

    private Gtk.Menu projects_menu; 
    private Gtk.Menu menu = null;

    private uint checked_timeout = 0;
    private uint timeout_id = 0;
    private bool save_off = false;

    public Gee.HashMap<string, bool> labels_hashmap;
    
    private const Gtk.TargetEntry[] targetEntries = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] targetEntriesMagicButton = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };

    public signal void update_headers ();

    public bool reveal_child {
        set {
            if (value) {
                show_item ();
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
        tooltip_text = item.content;
        can_focus = false;
        get_style_context ().add_class ("item-row");
        labels_hashmap = new Gee.HashMap<string, bool> ();

        hidden_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.margin_start = 6;
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");

        var hidden_revealer = new Gtk.Revealer ();
        hidden_revealer.valign = Gtk.Align.START;
        hidden_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        hidden_revealer.add (hidden_button);
        hidden_revealer.reveal_child = false;

        checked_button = new Gtk.CheckButton ();
        checked_button.can_focus = false;
        checked_button.margin_start = 6;
        checked_button.margin_top = 6;
        checked_button.valign = Gtk.Align.START;
        checked_button.halign = Gtk.Align.BASELINE;
        checked_button.get_style_context ().add_class ("checklist-button");

        if (item.checked == 1) {
            checked_button.active = true;
        } else {
            checked_button.active = false;
        }

        due_label = new Gtk.Label (null);
        due_label.halign = Gtk.Align.START;
        due_label.valign = Gtk.Align.CENTER;
        due_label.margin_end = 6;
        due_label.margin_bottom = 1;

        check_due_style ();
        
        var due_label_revealer = new Gtk.Revealer ();
        due_label_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        due_label_revealer.add (due_label);

        date_label_revealer = new Gtk.Revealer ();
        date_label_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        date_label_revealer.add (due_label_revealer);
        date_label_revealer.reveal_child = true;

        if (item.due_date != "") {
            due_label.label = Application.utils.get_relative_date_from_string (item.due_date);
            due_label_revealer.reveal_child = true;
        }

        content_label = new Gtk.Label (item.content);
        content_label.halign = Gtk.Align.START;
        content_label.valign = Gtk.Align.CENTER;
        content_label.xalign = 0;
        content_label.use_markup = true;
        content_label.margin_bottom = 2;
        content_label.get_style_context ().add_class ("label");
        content_label.ellipsize = Pango.EllipsizeMode.END;

        labels_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        labels_box.height_request = 2;

        labels_box_revealer = new Gtk.Revealer ();
        labels_box_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        labels_box_revealer.add (labels_box);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.valign = Gtk.Align.CENTER;
        content_box.margin_top = 3;
        content_box.pack_start (content_label, false, false, 0);
        content_box.pack_start (labels_box_revealer, false, false, 0);

        var checklist_image = new Gtk.Image ();
        checklist_image.margin_start = 6;
        //checklist_image.margin_end = 9;
        checklist_image.gicon = new ThemedIcon ("planner-checklist-symbolic");
        checklist_image.pixel_size = 16;
        checklist_image.get_style_context ().add_class ("dim-label");

        checklist_revealer = new Gtk.Revealer ();
        checklist_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        checklist_revealer.add (checklist_image);

        var note_image = new Gtk.Image ();
        note_image.gicon = new ThemedIcon ("text-x-generic-symbolic");
        note_image.pixel_size = 13;
        note_image.margin_start = 6;
        note_image.get_style_context ().add_class ("dim-label");

        note_revealer = new Gtk.Revealer ();
        note_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        note_revealer.add (note_image);

        if (item.note != "") {
            note_revealer.reveal_child = true;
        }

        project_name_label = new Gtk.Label (null);
        project_name_label.use_markup = true;

        project_name_revealer = new Gtk.Revealer ();
        project_name_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        project_name_revealer.add (project_name_label);

        var 1_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        1_box.margin_end = 32;
        1_box.pack_start (date_label_revealer, false, false, 0); 
        1_box.pack_start (content_box, false, false, 0);
        1_box.pack_start (checklist_revealer, false, false, 0);
        1_box.pack_start (note_revealer, false, false, 0);
        1_box.pack_end (project_name_revealer, false, false, 0);

        content_entry = new Gtk.Entry ();
        content_entry.margin_bottom = 1;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("label");
        content_entry.get_style_context ().add_class ("content-entry");
        content_entry.text = item.content;
        content_entry.hexpand = true;

        content_stack = new Gtk.Stack ();
        content_stack.margin_start = 6;
        content_stack.hexpand = true;
        content_stack.transition_type = Gtk.StackTransitionType.NONE;
        content_stack.add_named (1_box, "content_label");
        content_stack.add_named (content_entry, "content_entry");

        top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin_start = 0;
        top_box.hexpand = true;
        top_box.pack_start (hidden_revealer, false, false, 0);
        top_box.pack_start (checked_button, false, false, 0);
        top_box.pack_start (content_stack, false, true, 0);

        note_textview = new Gtk.TextView ();
        note_textview.margin_start = 66;
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
        check_listbox.margin_top = 12;
        check_listbox.margin_start = 59;
        check_listbox.get_style_context ().add_class ("check-listbox");

        new_checklist = new Widgets.NewCheck (item.id, item.project_id, item.is_todoist);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 59;
        separator.margin_bottom = 6;

        separator_revealer = new Gtk.Revealer ();
        separator_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        separator_revealer.add (separator);

        /*
            Actions
        */

        var due_button = new Widgets.DueButton ();
        due_button.item = item;

        var label_button = new Widgets.LabelButton (item.id);
        label_button.margin_start = 6;

        var checklist_button = new Gtk.Button.from_icon_name ("planner-checklist-symbolic");
        checklist_button.tooltip_text = _("Add Checklist");
        checklist_button.get_style_context ().add_class ("flat");
        checklist_button.get_style_context ().add_class ("item-action-button");

        var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.MENU);
        delete_button.can_focus = false; 
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.tooltip_text = _("Delete Task");
        delete_button.get_style_context ().add_class ("flat");
        delete_button.get_style_context ().add_class ("item-action-button");

        var settings_button = new Gtk.Button.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU);
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Task settings");
        settings_button.get_style_context ().add_class ("item-action-button");
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_top = 3;
        action_box.margin_start = 60;
        action_box.pack_start (due_button, false, true, 0);
        action_box.pack_start (label_button, false, true, 0);
        action_box.pack_start (checklist_button, false, true, 0);
        action_box.pack_end (settings_button, false, false, 0);
        action_box.pack_end (delete_button, false, false, 0);

        labels_edit_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        labels_edit_box.margin_top = 12;
        labels_edit_box.margin_start = 59;

        labels_edit_box_revealer = new Gtk.Revealer ();
        labels_edit_box_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        labels_edit_box_revealer.add (labels_edit_box);

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.pack_start (note_textview, false, true, 0);
        bottom_box.pack_start (labels_edit_box_revealer, false, false, 0);
        bottom_box.pack_start (check_listbox, false, false, 0);
        bottom_box.pack_start (separator_revealer, false, false, 0);
        bottom_box.pack_start (new_checklist, false, false, 0);
        bottom_box.pack_end (action_box, false, true, 0);

        bottom_revealer = new Gtk.Revealer ();
        bottom_revealer.valign = Gtk.Align.START;
        bottom_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        bottom_revealer.add (bottom_box);

        checklist_button.clicked.connect (() => {
            new_checklist.reveal_child = true;
        });

        /*
            Motion Revealer
        */

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);
        
        main_grid = new Gtk.Grid ();
        main_grid.hexpand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.get_style_context ().add_class ("transition");
        main_grid.add (top_box);
        main_grid.add (bottom_revealer);

        var grid = new Gtk.Grid ();
        grid.margin_bottom = 3;
        grid.hexpand = true;
        grid.orientation = Gtk.Orientation.VERTICAL;

        grid.add (main_grid);
        grid.add (motion_revealer);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_duration = 125;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);

        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntries, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (clear_indicator);

        build_drag_and_drop (false);

        add_all_checks ();
        add_all_labels ();
        
        content_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_item ();
            }

            return false;
        });

        content_entry.activate.connect (() => {
            hide_item ();
        });

        content_entry.changed.connect (() => {
            save ();
        });

        note_textview.buffer.changed.connect (() => {
            save (false);

            if (note_textview.buffer.text == "") {
                note_revealer.reveal_child = false;
            } else {
                note_revealer.reveal_child = true;
            }
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

        Application.utils.drag_magic_button_activated.connect ((value) => {
            build_drag_and_drop (value);
        });

        handle.enter_notify_event.connect ((event) => {
            hidden_revealer.reveal_child = true;
            return true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (bottom_revealer.reveal_child == false) {
                hidden_revealer.reveal_child = false;
            }

            return true;
        });

        hidden_button.clicked.connect (() => {
            if (reveal_child == false) {
                show_item ();
            } else {
                hide_item ();
            }
        });

        Application.database.item_added.connect ((i) => {
            if (item.id == i.parent_id) {
                var row = new Widgets.CheckRow (i);
                
                row.hide_item.connect (hide_item);
   
                check_listbox.add (row);
                check_listbox.show_all ();

                check_checklist_separator ();
            }
        });

        Application.database.item_label_added.connect ((id, item_id, label) => {
            if (item.id == item_id && labels_hashmap.has_key (label.id.to_string ()) == false) {
                var l = new Widgets.LabelPreview (id, item_id, label);
                var g = new Widgets.LabelItem (id, item.id, label);

                labels_box.add (l);
                labels_edit_box.add (g);
                
                labels_box.show_all ();
                labels_edit_box.show_all ();

                labels_box_revealer.reveal_child = true;
                labels_edit_box_revealer.reveal_child = true;
                labels_hashmap.set (label.id.to_string (), true);
            }
        });

        Application.database.item_label_deleted.connect ((id, item_id, label) => {
            if (item.id == item_id) {
                labels_hashmap.unset (label.id.to_string ());
            }
        });

        delete_button.clicked.connect (() => {
            if (Application.database.add_item_to_delete (item)) {
                get_style_context ().remove_class ("item-row-selected");
                main_revealer.reveal_child = false;
            }
        });

        Application.database.item_deleted.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    destroy ();
                }

                return false;
            });
        });

        Application.database.show_undo_item.connect ((id) => {
            if (item.id == id) {
                hide_item ();
                hidden_revealer.reveal_child = false;
                main_revealer.reveal_child = true;
            }
        });

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                if (bottom_revealer.reveal_child == false) {
                    activate_menu ();
                }

                return true;
            }

            return false;
        });

        settings_button.clicked.connect (() => {
            activate_menu ();
        });

        checked_button.toggled.connect (checked_toggled);

        check_listbox.remove.connect (() => {
            check_checklist_separator ();
        });

        Application.todoist.item_completed_completed.connect ((i) => {
            if (item.id == i.id) {
                destroy ();
            }
        });

        Application.database.update_due_item.connect ((i) => {
            if (item.id == i.id) {
                var datetime = new GLib.DateTime.from_iso8601 (i.due_date, new GLib.TimeZone.local ());

                due_label.label = Application.utils.get_relative_date_from_date (datetime);
                due_label_revealer.reveal_child = true;
                
                check_due_style ();

                if (is_today) {
                    date_label_revealer.reveal_child = false;
                    
                    if (Application.utils.is_today (datetime) == false && Application.utils.is_before_today (datetime) == false) {
                        hide_item ();

                        Timeout.add (1000, () => {
                            destroy ();
                
                            return false;
                        });
                    }
                }

                if (upcoming != null) {
                    print ("Entro aqui\n"); 
                    date_label_revealer.reveal_child = false;

                    print ("Nueva fecha: %s\n".printf (datetime.to_string ())); 
                    print ("Upcoming: %s\n".printf (upcoming.to_string ())); 
                    
                    if (Granite.DateTime.is_same_day (datetime, upcoming) == false) {
                        hide_item ();

                        Timeout.add (1000, () => {
                            print ("Se elimino update_due_item\n"); 
                            destroy ();
                
                            return false;
                        });
                    }
                }
            }
        });

        Application.database.add_due_item.connect ((i) => {
            if (item.id == i.id) {
                due_label.label = Application.utils.get_relative_date_from_date (
                    new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ())
                );
                due_label_revealer.reveal_child = true;

                check_due_style ();
            }
        });

        Application.database.remove_due_item.connect ((i) => {
            if (item.id == i.id) {
                due_label.label = "";
                due_label_revealer.reveal_child = false;

                check_due_style ();

                if (is_today || upcoming != null) {
                    hide_item ();

                    Timeout.add (1500, () => {
                        print ("Se elimino update_due_item\n"); 
                        destroy ();
            
                        return false;
                    });
                }
            }
        });

        Application.todoist.item_moved_started.connect ((id) => {
            if (item.id == id) {
                sensitive = false;
            }
        });

        Application.todoist.item_moved_completed.connect ((id) => {
            if (item.id == id) {
                if (upcoming == null) {
                    destroy ();
                } else if (is_today) {
                    destroy ();
                } else {
                    sensitive = true;
                }
            }
        });

        Application.todoist.item_moved_error.connect ((id, error_code, error_message) => {
            if (item.id == id) {
                sensitive = true;
            }
        });

        Application.database.item_updated.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    save_off = true;

                    item.content = i.content;
                    item.note = i.note;

                    content_entry.text = item.content;
                    content_label.label = item.content;
                    note_textview.buffer.text = item.note;
                    
                    if (note_textview.buffer.text == "") {
                        note_placeholder.visible = true;
                        note_placeholder.no_show_all = false;
                    } else {
                        note_placeholder.visible = false;
                        note_placeholder.no_show_all = true;
                    }

                    Timeout.add (250, () => {
                        save_off = false;
        
                        return false;
                    });
                }

                return false;
            });
        });

        Application.database.item_moved.connect ((i) => {
            if (item.id == i.id) {
                item.project_id = i.project_id;

                if (upcoming != null) {
                    project = Application.database.get_project_by_id (item.project_id);
                    project_name_label.label = "<small>%s</small>".printf (project.name);
                    project_name_revealer.reveal_child = true;
                }
            }
        });
    }

    private void checked_toggled () {
        if (checked_button.active) { 
            item.checked = 1;
            item.date_completed = new GLib.DateTime.now_local ().to_string ();
            
            content_label.label = "<s>%s</s>".printf (item.content);

            checked_timeout = Timeout.add (3000, () => {
                if (item.is_todoist == 1) {
                    if (Application.todoist.add_complete_item (item)) {
                        main_revealer.reveal_child = false;
                    }
                } else {
                    if (Application.database.update_item_completed (item)) {
                        main_revealer.reveal_child = false;
                    }
                }

                return false;
            });
        } else {
            if (checked_timeout != 0) {
                item.checked = 1;
                item.date_completed = "";

                content_label.label = item.content;

                Source.remove (checked_timeout);
                checked_timeout = 0;
            }
        }
    }

    private void show_item () {
        bottom_revealer.reveal_child = true;
        main_grid.get_style_context ().add_class ("item-row-selected");

        content_stack.visible_child_name = "content_entry";

        hidden_button.get_style_context ().add_class ("opened");

        activatable = false;
        selectable = false;
        
        content_entry.grab_focus_without_selecting ();

        if (content_entry.cursor_position < content_entry.text.length) {
            content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
        }
    }

    private void hide_item () {
        bottom_revealer.reveal_child = false;

        main_grid.get_style_context ().remove_class ("item-row-selected");
        content_stack.visible_child_name = "content_label";

        hidden_button.get_style_context ().remove_class ("opened");

        timeout_id = Timeout.add (250, () => {
            activatable = true;
            selectable = true;
            
            Source.remove (timeout_id);
            
            return false;
        });
    }

    private void build_drag_and_drop (bool is_magic_button_active) {
        if (is_magic_button_active) {
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targetEntriesMagicButton, Gdk.DragAction.MOVE);
            this.drag_data_received.connect (on_drag_magic_button_received);
        } else {
            this.drag_data_received.disconnect (on_drag_magic_button_received);
            Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, targetEntries, Gdk.DragAction.MOVE);
        }

        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);        
    }

    private void on_drag_magic_button_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        print ("Index: %i\n".printf (this.get_index ()));
        Application.utils.magic_button_activated (
            item.project_id,
            item.section_id,
            item.is_todoist,
            false,
            this.get_index () + 1
        );
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

        row.draw (cr);

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
        Application.utils.drag_item_activated (true);
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (ItemRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("ITEMROW"), 32, data
        );
    }

    public void clear_indicator (Gdk.DragContext context) {
        reveal_drag_motion = false;
        
        main_revealer.reveal_child = true;

        Application.utils.drag_item_activated (false);
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        reveal_drag_motion = true;
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        reveal_drag_motion = false;
    }

    private void save (bool online=true) {
        if (save_off == false) {
            content_label.label = content_entry.text;

            item.content = content_entry.text;
            tooltip_text = item.content;
            item.note = note_textview.buffer.text;

            if (online) {
                item.save ();
            } else {
                item.save_local ();
            }
        }   
    }
    
    private void add_all_checks () {
        foreach (var check in Application.database.get_all_cheks_by_item (item)) {
            var row = new Widgets.CheckRow (check);

            row.hide_item.connect (hide_item);

            check_listbox.add (row);
            check_listbox.show_all ();
        }

        check_checklist_separator ();
    }

    private void add_all_labels () {
        foreach (var label in Application.database.get_labels_by_item (item.id)) {
            var l = new Widgets.LabelPreview (label.item_label_id, item.id, label);
            var g = new Widgets.LabelItem (label.item_label_id, item.id, label);

            labels_box.add (l);
            labels_edit_box.add (g);

            labels_box.show_all ();
            labels_edit_box.show_all ();

            labels_edit_box_revealer.reveal_child = true;
            labels_box_revealer.reveal_child = true;
            labels_hashmap.set (label.id.to_string (), true);
        }
    }

    private void check_due_style () {
        if (item.due_date != "") {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());            
            
            due_label.get_style_context ().remove_class ("duedate-today");
            due_label.get_style_context ().remove_class ("duedate-expired");
            due_label.get_style_context ().remove_class ("duedate-upcoming");
            
            if (Application.utils.is_today (datetime)) {
                due_label.get_style_context ().add_class ("duedate-today");
            } else if (Application.utils.is_before_today (datetime)) {
                due_label.get_style_context ().add_class ("duedate-expired");
            } else {
                due_label.get_style_context ().add_class ("duedate-upcoming");
            }
        }
    }
    private void check_checklist_separator () {
        if (check_listbox.get_children ().length () > 0) {
            checklist_revealer.reveal_child = true;
            separator_revealer.reveal_child = true;
        } else {
            checklist_revealer.reveal_child = false;
            separator_revealer.reveal_child = false;
        }
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (item);
        } 

        foreach (var child in projects_menu.get_children ()) {
            child.destroy ();
        }

        var item_menu = new Widgets.ImageMenuItem (_("Inbox"), "mail-mailbox-symbolic");
        item_menu.activate.connect (() => {
            int64 inbox_id = Application.settings.get_int64 ("inbox-project");

            if (item.is_todoist == 0) {
                if (Application.database.move_item (item, inbox_id)) {
                    destroy ();
                }
            } else {
                Application.todoist.move_item (item, inbox_id);
            }
        });

        projects_menu.add (item_menu);
        
        foreach (var project in Application.database.get_all_projects ()) {
            if (item.is_todoist == project.is_todoist && item.project_id != project.id) {
                item_menu = new Widgets.ImageMenuItem (project.name, "planner-project-symbolic"); 
                item_menu.activate.connect (() => {
                    if (item.is_todoist == 0) {
                        if (Application.database.move_item (item, project.id)) {
                            destroy ();
                        }
                    } else {
                        Application.todoist.move_item (item, project.id);
                    }
                });

                projects_menu.add (item_menu);
            }
        }

        projects_menu.show_all ();

        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Item item) {
        menu = new Gtk.Menu ();
        menu.width_request = 200;
        
        var complete_menu = new Widgets.ImageMenuItem (_("Complete"), "emblem-default-symbolic");   

        var view_edit_menu = new Widgets.ImageMenuItem (_("View / Hide task"), "edit-symbolic");

        var move_project_menu = new Widgets.ImageMenuItem (_("Move to project"), "go-jump-symbolic");
        projects_menu = new Gtk.Menu ();
        move_project_menu.set_submenu (projects_menu);

        var duplicate_menu = new Widgets.ImageMenuItem (_("Duplicate"), "edit-copy-symbolic");

        var convert_menu = new Widgets.ImageMenuItem (_("Convert to project"), "planner-project-symbolic");

        var share_menu = new Widgets.ImageMenuItem (_("Copy link to task"), "insert-link-symbolic");
        
        var delete_menu = new Widgets.ImageMenuItem (_("Delete task"), "user-trash-symbolic");

        menu.add (complete_menu);
        menu.add (view_edit_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (move_project_menu);
        menu.add (convert_menu);
        menu.add (duplicate_menu);
        menu.add (share_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (delete_menu);

        menu.show_all ();

        complete_menu.activate.connect (() => {
            checked_button.active = !checked_button.active;
        });

        view_edit_menu.activate.connect (() => {
            if (bottom_revealer.reveal_child) {
                hide_item ();
            } else {
                show_item ();
            }
        });

        delete_menu.activate.connect (() => {
            if (Application.database.add_item_to_delete (item)) {
                get_style_context ().remove_class ("item-row-selected");
                main_revealer.reveal_child = false;
            }
        });
    }
}