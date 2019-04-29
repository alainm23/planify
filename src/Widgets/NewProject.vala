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

    private Gtk.Spinner loading_spinner;
    private Gtk.Entry name_entry;
    private Gtk.ToggleButton icon_button;
    
    private Gtk.Stack stack;
    private Gtk.Grid project_grid;
    public const string COLOR_CSS = """
        .icon-preview {
            background-color: %s;
            border-radius: 50px;
            box-shadow: inset 0px 0px 0px 1px rgba(0, 0, 0, 0.2);
        }
    """;
    
    private bool is_todoist = false;

    private int color_selected;

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
        add_grid.column_spacing = 9;
        add_grid.add (add_image);
        add_grid.add (add_label);

        var add_eventbox = new Gtk.EventBox ();
        add_eventbox.margin_start = 7;
        add_eventbox.valign = Gtk.Align.CENTER;
        add_eventbox.add (add_grid);
        
        // New
        loading_spinner = new Gtk.Spinner ();
        loading_spinner.active = true;
        loading_spinner.start ();
        loading_spinner.no_show_all = true;
        loading_spinner.visible = false;

        icon_button = new Gtk.ToggleButton ();
        icon_button.width_request = 16;
        icon_button.height_request = 16;
        icon_button.can_focus = false;
        icon_button.valign = Gtk.Align.CENTER;
        icon_button.halign = Gtk.Align.CENTER;
        icon_button.get_style_context ().add_class ("button-circular");
        icon_button.tooltip_text = _("Select an Icon and Color");
        icon_button.get_style_context ().add_class ("icon-preview");
        icon_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        name_entry = new Gtk.Entry ();
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.hexpand = true;
        name_entry.placeholder_text = _("Project name");

        var icon_picker = new Widgets.Popovers.ColorPicker (icon_button);

        var source_button = new Gtk.ToggleButton ();
        
        var source_image = new Gtk.Image ();
        source_image.gicon = new ThemedIcon ("computer-symbolic");
        source_image.pixel_size = 16;
        
        source_button.add (source_image);

        if (Application.user.is_todoist == false) {
            source_button.no_show_all = true;
            source_button.visible = false;
        }

        var source_popover = new Widgets.Popovers.SourceProject (source_button);

        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        grid.add (name_entry);
        grid.add (source_button);

        project_grid = new Gtk.Grid ();
        project_grid.margin_start = 6;
        project_grid.margin_top = 6;
        project_grid.margin_end = 3;
        project_grid.column_spacing = 9;
        project_grid.add (loading_spinner);
        project_grid.add (icon_button);
        project_grid.add (grid);

        stack = new Gtk.Stack ();
        stack.valign = Gtk.Align.CENTER;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.transition_duration = 120;

        stack.add_named (add_eventbox, "add_eventbox");
        stack.add_named (project_grid, "project_grid");

        add (stack);
        color_selected = GLib.Random.int_range (30, 50);
        apply_styles (Application.utils.get_color (color_selected));
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
                project.color = color_selected;
                project.name = name_entry.text;

                if (is_todoist) {
                    project_grid.sensitive = false;
                    loading_spinner.no_show_all = false;
                    loading_spinner.visible = true;
                    icon_button.visible = false;

                    project.is_todoist = true;
                    Application.todoist.add_project (project);
                } else {
                    project.id = (int64) Application.utils.generate_id ();
                    if (Application.database_v2.add_project (project)) {
                        clear ();
                    }
                }
            }
        });

        Application.todoist.project_added.connect (() => {
            clear ();
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

        icon_picker.color_selected.connect ((color) => {
            color_selected = color;
            apply_styles (Application.utils.get_color (color));
        });

        source_button.toggled.connect (() => {
            if (source_button.active) {
                source_popover.show_all ();
            }
        });
  
        source_popover.closed.connect (() => {
            source_button.active = false;
        });

        source_popover.source_changed.connect ((is_computer) => {
            if (is_computer) {
                is_todoist = false;
                source_image.icon_name = "computer-symbolic";
            } else {
                is_todoist = true;
                source_image.icon_name = "planner-todoist";
            }
        });

        Application.database_v2.user_added.connect ((user) => {
            if (user.is_todoist) {
                source_button.no_show_all = false;
                source_button.visible = true;

                show_all ();
            }
        });
    }  

    private void apply_styles (string color) {
        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
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
        project_grid.sensitive = true;
        icon_button.visible = true;
        loading_spinner.visible = false;

        color_selected = GLib.Random.int_range (30, 50);
        apply_styles (Application.utils.get_color (color_selected));

        stack.visible_child_name = "add_eventbox";
    }
}