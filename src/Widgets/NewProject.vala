/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.NewProject : Gtk.EventBox {
    private Gtk.Image add_image;
    private Gtk.Label add_label;

    private Gtk.Entry name_entry;
    private Gtk.ToggleButton icon_button;
    private Gtk.Image icon_image;

    private Gtk.Stack stack;
    public const string COLOR_CSS = """
        .icon-preview {
            color: %s;
            background-color: @bg_color;
            padding: 3px;
            border: 1px solid shade (%s, 0.9);
            border-radius: 50px;
        }
    """;
    
    private string color_selected;

    public bool reveal_new_project {
        set {
            if (value) {
                stack.visible_child_name = "project_grid";
                name_entry.grab_focus ();
            } else {
                clear ();
            }
        }
        get {
            if (stack.visible_child_name == "project_grid") {
                return true;
            } else {
                return false;
            }
        }
    }

    construct {
        // Add
        add_image = new Gtk.Image ();
        add_image.gicon = new ThemedIcon ("list-add-symbolic");
        add_image.pixel_size = 16;

        add_label = new Gtk.Label ("<b>%s</b>".printf (_("New project")));
        add_label.use_markup = true;

        var add_grid = new Gtk.Grid ();
        add_grid.column_spacing = 11;
        add_grid.add (add_image);
        add_grid.add (add_label);

        var add_eventbox = new Gtk.EventBox ();
        add_eventbox.margin_start = 7;
        add_eventbox.valign = Gtk.Align.CENTER;
        add_eventbox.add (add_grid);
        
        // New
        icon_button = new Gtk.ToggleButton ();
        icon_button.can_focus = false;
        icon_button.valign = Gtk.Align.CENTER;
        icon_button.halign = Gtk.Align.CENTER;
        icon_button.get_style_context ().add_class ("button-circular");
        icon_button.tooltip_text = _("Select an Icon and Color");
        icon_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        icon_button.get_style_context ().add_class ("project-icon-preview");

        var icon_picker = new Widgets.Popovers.IconPicker (icon_button);

        icon_image = new Gtk.Image ();
        icon_image.get_style_context ().add_class ("icon-preview");
        icon_image.gicon = new ThemedIcon ("planner-startup-symbolic");
        icon_image.pixel_size = 10;
        icon_button.add (icon_image);

        name_entry = new Gtk.Entry ();
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.hexpand = true;
        name_entry.placeholder_text = _("Project name");

        var source_button = new Gtk.Button.from_icon_name ("planner-todoist", Gtk.IconSize.MENU);
        
        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        grid.add (name_entry);
        grid.add (source_button);

        var project_grid = new Gtk.Grid ();
        project_grid.margin_start = 3;
        project_grid.margin_top = 6;
        project_grid.margin_end = 6;
        project_grid.column_spacing = 5;
        project_grid.add (icon_button);
        project_grid.add (grid);

        stack = new Gtk.Stack ();
        stack.valign = Gtk.Align.CENTER;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.transition_duration = 120;

        stack.add_named (add_eventbox, "add_eventbox");
        stack.add_named (project_grid, "project_grid");

        add (stack);
        color_selected = "#333333";
        apply_styles (color_selected);
        clear ();

        add_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                stack.visible_child_name = "project_grid";
                name_entry.grab_focus ();
            }
        });

        name_entry.activate.connect (() => {
            if (name_entry.text != "") {
                var project = new Objects.Project ();
                project.id = (int64) Application.utils.generate_id ();
                project.icon = icon_image.icon_name;
                project.color = color_selected;
                project.name = name_entry.text;

                if (Application.database.add_project (project) == Sqlite.DONE) {
                    clear ();
                }
            }
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                clear ();
            }

            return false;
        });

        icon_button.toggled.connect (() => {
            if (icon_button.active) {
                icon_picker.show_all ();
            }
        });
  
        icon_picker.closed.connect (() => {
            icon_button.active = false;
        });

        icon_picker.on_selected.connect ((icon_name, color) => {
            color_selected = color;

            icon_image.icon_name = icon_name;
            apply_styles (color);
        });

        Timeout.add (150, () => {
            if (Application.user.is_todoist == 0) {
                source_button.no_show_all = true;
                source_button.visible = false;
            } else {
                source_button.no_show_all = false;
                source_button.visible = true;
            }

            return false;
        });
    }  

    private void apply_styles (string color) {
        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                color,
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    public void clear () {
        name_entry.text = "";
        icon_image.icon_name = "planner-startup-symbolic";
        color_selected = "#333333";
        apply_styles (color_selected);

        stack.visible_child_name = "add_eventbox";
    }
}