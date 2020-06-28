/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Widgets.New : Gtk.Revealer {
    public Widgets.Entry name_entry;
    private Gtk.Button project_button;
    private Gtk.Button area_button;
    private Widgets.TextView description_textview;
    private Gtk.ToggleButton source_button;
    private Gtk.Image source_image;
    private Gtk.Popover source_popover = null;

    public Gtk.Stack stack;

    private Gtk.ComboBox area_combobox;
    private Gtk.ListStore area_liststore;
    private Gtk.Revealer area_revealer;

    private Gtk.ListStore color_liststore;
    private Gtk.ComboBox color_combobox;

    private bool area_change_activated { get; set; default = false; }

    private Gtk.ModelButton online_button;
    private Gtk.Label online_label;

    public bool reveal {
        get {
            return reveal_child;
        }
        set {
            reveal_child = value;

            if (value) {
                build_area_liststore (Planner.settings.get_int64 ("area-selected"));
            }
        }
    }

    construct {
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        reveal_child = false;
        valign = Gtk.Align.END;
        halign = Gtk.Align.CENTER;

        var name_header = new Granite.HeaderLabel (_("Name:"));
        name_header.margin_start = 6;

        name_entry = new Widgets.Entry ();
        name_entry.get_style_context ().add_class ("name-entry");
        name_entry.hexpand = true;

        source_image = new Gtk.Image ();
        source_image.pixel_size = 16;
        if (Planner.settings.get_int ("source-selected") == 0) {
            source_image.icon_name = "planner-offline-symbolic";
        } else {
            source_image.icon_name = "planner-online-symbolic";
        }

        source_button = new Gtk.ToggleButton ();
        source_button.add (source_image);
        source_button.get_style_context ().add_class ("source-button");

        var top_grid = new Gtk.Grid ();
        top_grid.margin_start = top_grid.margin_end = 6;
        top_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        top_grid.add (name_entry);
        top_grid.add (source_button);

        var description_header = new Granite.HeaderLabel (_("Description:"));
        description_header.margin_start = 6;

        description_textview = new Widgets.TextView ();
        description_textview.get_style_context ().add_class ("description");
        description_textview.margin = 3;
        description_textview.wrap_mode = Gtk.WrapMode.WORD_CHAR;

        var description_scrolled = new Gtk.ScrolledWindow (null, null);
        description_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        description_scrolled.hexpand = true;
        description_scrolled.add (description_textview);

        var description_frame = new Gtk.Frame (null);
        description_frame.get_style_context ().add_class ("border-radius-4");
        description_frame.margin_start = description_frame.margin_end = 6;
        description_frame.add (description_scrolled);

        var area_header = new Granite.HeaderLabel (_("Folder:"));

        area_liststore = new Gtk.ListStore (3, typeof (Objects.Area?), typeof (unowned string), typeof (string));
        area_combobox = new Gtk.ComboBox.with_model (area_liststore);

        var area_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        area_box.margin_start = area_box.margin_end = 6;
        area_box.pack_start (area_header, false, false, 0);
        area_box.pack_start (area_combobox, false, false, 0);

        area_revealer = new Gtk.Revealer ();
        area_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        area_revealer.add (area_box);
        area_revealer.reveal_child = true;

        var color_header = new Granite.HeaderLabel (_("Color:"));
        color_header.margin_start = 6;

        color_liststore = new Gtk.ListStore (3, typeof (int), typeof (unowned string), typeof (string));
        color_combobox = new Gtk.ComboBox.with_model (color_liststore);
        color_combobox.margin_start = color_combobox.margin_end = 6;

        Gtk.TreeIter iter;
        foreach (var color in Planner.utils.get_color_list ()) {
            color_liststore.append (out iter);
            color_liststore.@set (iter,
                0, color,
                1, " " + Planner.utils.get_color_name (color),
                2, "color-%i".printf (color)
            );

            if (color == 42) {
                color_combobox.set_active_iter (iter);
            }
        }

        var pixbuf_cell = new Gtk.CellRendererPixbuf ();
        color_combobox.pack_start (pixbuf_cell, false);
        color_combobox.add_attribute (pixbuf_cell, "icon-name", 2);

        var text_cell = new Gtk.CellRendererText ();
        color_combobox.pack_start (text_cell, true);
        color_combobox.add_attribute (text_cell, "text", 1);

        var submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack ();
        submit_stack.expand = true;
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        submit_stack.add_named (new Gtk.Label (_("Add")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.margin = 3;
        action_grid.column_spacing = 3;
        action_grid.hexpand = true;
        action_grid.valign = Gtk.Align.END;
        action_grid.column_homogeneous = true;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var action_bar = new Gtk.ActionBar ();
        action_bar.valign = Gtk.Align.END;
        action_bar.expand = false;
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.add (action_grid);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;
        box.pack_start (name_header, false, false, 0);
        box.pack_start (top_grid, false, false, 0);
        box.pack_start (description_header, false, false, 0);
        box.pack_start (description_frame, false, false, 0);
        box.pack_start (color_header, false, false, 0);
        box.pack_start (color_combobox, false, false, 0);
        box.pack_start (area_revealer, false, false, 0);
        box.pack_end (action_bar, false, false, 0);

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add_named (create_chooser_widget (), "chooser");
        stack.add_named (box, "box");

        var main_grid = new Gtk.Grid ();
        main_grid.margin = 8;
        main_grid.height_request = 275;
        main_grid.expand = false;
        main_grid.get_style_context ().add_class ("add-project-widget");
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (stack);

        add (main_grid);

        submit_button.clicked.connect (() => {
            create_project ();
        });

        name_entry.activate.connect (() => {
            create_project ();
        });

        name_entry.changed.connect (() => {
            if (name_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        cancel_button.clicked.connect (cancel);

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                cancel ();
            }

            return false;
        });
        
        Planner.todoist.project_added_started.connect (() => {
            submit_button.sensitive = false;
            submit_stack.visible_child_name = "spinner";
        });

        Planner.todoist.project_added_completed.connect (() => {
            submit_button.sensitive = true;
            submit_stack.visible_child_name = "label";

            cancel ();
        });

        Planner.todoist.project_added_error.connect ((error_code, error_message) => {
            submit_button.sensitive = true;
            submit_stack.visible_child_name = "label";

            print ("error_code: %i\n".printf (error_code));
            print ("error_message: %s\n".printf (error_message));
        });

        source_button.toggled.connect (() => {
            if (source_popover == null) {
                create_source_popover ();
            }

            if (Planner.settings.get_boolean ("todoist-account") == false) {
                online_button.visible = false;
                online_button.no_show_all = true;
            } else {
                online_button.visible = true;
                online_button.no_show_all = false;
                online_label.label = Planner.settings.get_string ("todoist-user-email");
            }

            source_popover.show_all ();
        });

        area_combobox.changed.connect (() => {
            if (area_change_activated) {
                var area = get_area_selected ();
                if (area == null) {
                    Planner.settings.set_int64 ("area-selected", 0);
                } else {
                    Planner.settings.set_int64 ("area-selected", area.id);
                }
            }
        });

        Planner.utils.insert_project_to_area.connect ((area_id) => {
            reveal_child = true;
            stack.visible_child_name = "box";
            build_area_liststore (area_id);
            name_entry.grab_focus ();
        });
    }

    private void create_source_popover () {
        source_popover = new Gtk.Popover (source_button);
        source_popover.position = Gtk.PositionType.BOTTOM;

        var offline_radio = new Gtk.RadioButton (null);
        var online_radio = new Gtk.RadioButton.from_widget (offline_radio);

        if (Planner.settings.get_int ("source-selected") == 0) {
            offline_radio.active = true;
        } else {
            online_radio.active = true;
        }

        var offline_image = new Gtk.Image ();
        offline_image.gicon = new ThemedIcon ("planner-offline-symbolic");
        offline_image.valign = Gtk.Align.START;
        offline_image.pixel_size = 16;

        var offline_label = new Gtk.Label (_("Local"));
        offline_label.hexpand = true;
        offline_label.valign = Gtk.Align.START;
        offline_label.xalign = 0;

        var offline_grid = new Gtk.Grid ();
        offline_grid.column_spacing = 6;
        offline_grid.add (offline_radio);
        offline_grid.add (offline_image);
        offline_grid.add (offline_label);

        var offline_button = new Gtk.ModelButton ();
        offline_button.get_style_context ().add_class ("popover-model-button");
        offline_button.get_child ().destroy ();
        offline_button.add (offline_grid);

        // Online Button
        var online_image = new Gtk.Image ();
        online_image.gicon = new ThemedIcon ("planner-online-symbolic");
        online_image.valign = Gtk.Align.START;
        online_image.pixel_size = 16;

        online_label = new Gtk.Label (null);
        online_label.hexpand = true;
        online_label.valign = Gtk.Align.START;
        online_label.xalign = 0;

        var online_grid = new Gtk.Grid ();
        online_grid.column_spacing = 6;
        online_grid.add (online_radio);
        online_grid.add (online_image);
        online_grid.add (online_label);

        online_button = new Gtk.ModelButton ();
        online_button.get_style_context ().add_class ("popover-model-button");
        online_button.get_child ().destroy ();
        online_button.add (online_grid);

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 200;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 3;
        popover_grid.margin_bottom = 3;
        popover_grid.add (offline_button);
        popover_grid.add (online_button);

        source_popover.add (popover_grid);

        source_popover.closed.connect (() => {
            source_button.active = false;
        });

        offline_button.clicked.connect (() => {
            source_image.icon_name = "planner-offline-symbolic";
            Planner.settings.set_int ("source-selected", 0);
            offline_radio.active = true;
        });

        online_button.clicked.connect (() => {
            source_image.icon_name = "planner-online-symbolic";
            Planner.settings.set_int ("source-selected", 1);
            online_radio.active = true;
        });
    }

    private void build_area_liststore (int64 area_id) {
        area_change_activated = false;
        area_liststore.clear ();
        area_combobox.clear ();
        area_change_activated = true;

        Gtk.TreeIter iter;
        area_liststore.append (out iter);
        area_liststore.@set (iter,
            0, null,
            1, " " + _("No Folder"),
            2, "window-close-symbolic"
        );

        if (area_id == 0) {
            area_combobox.set_active_iter (iter);
        } else {
            if (Planner.database.area_exists (area_id) == false) {
                area_combobox.set_active_iter (iter);
            }
        }

        var areas = Planner.database.get_all_areas ();
        foreach (var area in areas) {
            area_liststore.append (out iter);
            area_liststore.@set (iter,
                0, area,
                1, " " + area.name,
                2, "folder-outline"
            );

            if (area.id == area_id && area_id != 0) {
                area_combobox.set_active_iter (iter);
            }
        }

        if (areas.size > 0) {
            area_revealer.reveal_child = true;
        } else {
            area_revealer.reveal_child = false;
        }

        var pixbuf_cell = new Gtk.CellRendererPixbuf ();
        area_combobox.pack_start (pixbuf_cell, false);
        area_combobox.add_attribute (pixbuf_cell, "icon-name", 2);

        var text_cell = new Gtk.CellRendererText ();
        area_combobox.pack_start (text_cell, true);
        area_combobox.add_attribute (text_cell, "text", 1);
    }

    public Objects.Area? get_area_selected () {
        Gtk.TreeIter iter;
        if (!area_combobox.get_active_iter (out iter)) {
            return null;
        }

        Value item;
        area_liststore.get_value (iter, 0, out item);

        return (Objects.Area) item;
    }

    public int? get_color_selected () {
        Gtk.TreeIter iter;
        if (!color_combobox.get_active_iter (out iter)) {
            return null;
        }

        Value item;
        color_liststore.get_value (iter, 0, out item);

        return (int) item;
    }

    private Gtk.Box create_chooser_widget () {
        var project_image = new Gtk.Image ();
        project_image.halign = Gtk.Align.START;
        project_image.valign = Gtk.Align.CENTER;
        project_image.gicon = new ThemedIcon ("planner-project-symbolic");
        project_image.pixel_size = 14;
        project_image.get_style_context ().add_class ("area-icon");

        var project_label = new Gtk.Label (_("Project"));
        project_label.get_style_context ().add_class ("h3");
        project_label.get_style_context ().add_class ("font-bold");
        project_label.halign = Gtk.Align.START;

        var project_detail_label = new Gtk.Label (_("Start a new project, create a to do list, organize your notes."));
        project_detail_label.wrap = true;
        project_detail_label.xalign = 0;

        var project_grid = new Gtk.Grid ();
        project_grid.margin_start = 6;
        project_grid.column_spacing = 3;
        project_grid.attach (project_image, 0, 0, 1, 1);
        project_grid.attach (project_label, 1, 0, 1, 1);
        project_grid.attach (project_detail_label, 1, 1, 1, 1);

        project_button = new Gtk.Button ();
        project_button.margin_top = 6;
        project_button.add (project_grid);
        project_button.tooltip_markup = Granite.markup_accel_tooltip ({"p"}, _("Add Project"));
        project_button.get_style_context ().add_class ("fancy-turn-animation");
        project_button.get_style_context ().remove_class ("button");
        project_button.get_style_context ().add_class ("flat");
        project_button.get_style_context ().add_class ("menuitem");

        var area_image = new Gtk.Image ();
        area_image.halign = Gtk.Align.START;
        area_image.valign = Gtk.Align.CENTER;
        area_image.gicon = new ThemedIcon ("folder-symbolic");
        area_image.pixel_size = 14;
        area_image.get_style_context ().add_class ("project-icon");

        var source_label = new Gtk.Label (_("Folder"));
        source_label.get_style_context ().add_class ("h3");
        source_label.get_style_context ().add_class ("font-bold");
        source_label.halign = Gtk.Align.START;

        var area_detail_label = new Gtk.Label (_("Organize your projects in groups and keep your panel clean."));
        area_detail_label.wrap = true;
        area_detail_label.xalign = 0;

        var area_grid = new Gtk.Grid ();
        area_grid.margin_start = 6;
        area_grid.column_spacing = 3;
        area_grid.attach (area_image, 0, 0, 1, 1);
        area_grid.attach (source_label, 1, 0, 1, 1);
        area_grid.attach (area_detail_label, 1, 1, 1, 1);

        area_button = new Gtk.Button ();
        area_button.add (area_grid);
        area_button.tooltip_markup = Granite.markup_accel_tooltip ({"f"}, _("Add Folder"));
        area_button.get_style_context ().add_class ("fancy-turn-animation");
        area_button.get_style_context ().remove_class ("button");
        area_button.get_style_context ().add_class ("flat");
        area_button.get_style_context ().add_class ("menuitem");

        var cancel_button = new Gtk.Button.with_label (_("Close"));
        cancel_button.get_style_context ().add_class ("planner-button");
        cancel_button.margin = 3;
        cancel_button.hexpand = true;

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.pack_start (cancel_button);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.pack_start (project_button, false, false, 0);
        box.pack_start (area_button, false, false, 0);
        box.pack_end (action_bar, false, false, 0);

        cancel_button.clicked.connect (cancel);

        project_button.clicked.connect (() => {
            stack.visible_child_name = "box";
            name_entry.grab_focus ();
        });

        area_button.clicked.connect (create_area);

        return box;
    }

    private void cancel () {
        reveal_child = false;

        name_entry.text = "";
        description_textview.buffer.text = "";

        stack.visible_child_name = "chooser";
    }

    private void create_project () {
        if (name_entry.text != "") {
            var area = get_area_selected ();

            var project = new Objects.Project ();
            project.name = name_entry.text;
            project.color = get_color_selected ();
            project.note = description_textview.buffer.text;

            if (area == null) {
                project.area_id = 0;
            } else {
                project.area_id = area.id;
            }

            if (source_image.icon_name == "planner-offline-symbolic") {
                project.id = Planner.utils.generate_id ();
                if (Planner.database.insert_project (project)) {
                    cancel ();
                }
            } else {
                project.is_todoist = 1;
                Planner.todoist.add_project (project);
            }
        }
    }

    private void create_area () {
        var area = new Objects.Area ();
        area.name = _("New folder");

        if (Planner.database.insert_area (area)) {
            cancel ();
        }
    }
}
