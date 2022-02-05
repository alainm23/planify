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

public class Dialogs.Project : Hdy.Window {
    public string color_selected { get; set; }
    public Objects.Project project { get; construct; }

    public bool is_creating {
        get {
            return project.id == Constants.INACTIVE;
        }
    }

    public Project.new () {
        var project = new Objects.Project ();
        project.color = Util.get_default ().get_random_color ();
        project.emoji = "🚀️";
        project.id = Constants.INACTIVE;

        Object (
            project: project,
            deletable: true,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true
        );
    }

    public Project (Objects.Project project) {
        Object (
            project: project,
            deletable: true,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true
        );
    }

    construct {
        unowned Gtk.StyleContext dialog_context = get_style_context ();
        dialog_context.add_class (Gtk.STYLE_CLASS_VIEW);
        dialog_context.add_class ("planner-dialog");
        dialog_context.remove_class ("background");

        transient_for = Planner.instance.main_window;

        var headerbar = new Hdy.HeaderBar ();
        headerbar.has_subtitle = false;
        headerbar.show_close_button = false;
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var emoji_entry = new Gtk.Entry () {
            overwrite_mode = true
        };

        var progress = new Widgets.ProjectProgress (48) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            progress_fill_color = Util.get_default ().get_color (project.color),
            percentage = 0.65
        };

        var label = new Gtk.Label (project.emoji);

        var preview_stack = new Gtk.Stack () {
            hexpand = true,
            homogeneous = false,
            halign = Gtk.Align.CENTER
        };

        preview_stack.add_named (progress, "progress");
        preview_stack.add_named (label, "emoji");

        var preview_button = new Gtk.Button () {
            height_request = 64,
            width_request = 64,
            can_focus = true,
            margin = 12
        };
        preview_button.add (preview_stack);
        preview_button.get_style_context ().add_class ("h1");
        preview_button.get_style_context ().add_class ("emoji-button");

        var picker_stack = new Gtk.Stack () {
            hexpand = true,
            homogeneous = false,
            halign = Gtk.Align.CENTER
        };

        picker_stack.add_named (preview_button, "emoji-button");
        picker_stack.add_named (emoji_entry, "emoji-entry");

        var iconstyle_switch = new Granite.ModeSwitch.from_icon_name ("media-record-symbolic", "face-smile-symbolic") {
            halign = Gtk.Align.CENTER
        };
        iconstyle_switch.primary_icon_tooltip_text = _("Progress");
        iconstyle_switch.secondary_icon_tooltip_text = _("Emoji");

        var name_entry = new Gtk.Entry () {
            margin = 12,
            margin_top = 24,
            placeholder_text = _("Project name")
        };
        name_entry.text = project.name;
        name_entry.get_style_context ().add_class ("border-radius-6");
        name_entry.get_style_context ().add_class ("dialog-entry");

        var radio = new Gtk.RadioButton (null);
        var colors_hashmap = new Gee.HashMap <string, Gtk.RadioButton> ();

        var flowbox = new Gtk.FlowBox () {
            column_spacing = 12,
            row_spacing = 12,
            border_width = 6,
            max_children_per_line = 10,
            min_children_per_line = 8,
            expand = true,
            valign = Gtk.Align.START,
        };

        unowned Gtk.StyleContext flowbox_context = flowbox.get_style_context ();
        flowbox_context.add_class ("flowbox-color");

        foreach (var entry in Util.get_default ().get_colors ().entries) {
            Gtk.RadioButton color_radio = new Gtk.RadioButton (radio.get_group ());
            color_radio.valign = Gtk.Align.CENTER;
            color_radio.halign = Gtk.Align.CENTER;
            color_radio.tooltip_text = Util.get_default ().get_color_name (entry.key);
            color_radio.get_style_context ().add_class ("color-radio");
            Util.get_default ().set_widget_color (Util.get_default ().get_color (entry.key), color_radio);
            colors_hashmap [entry.key] = color_radio;
            flowbox.add (colors_hashmap [entry.key]);

            color_radio.toggled.connect (() => {
                color_selected = entry.key;
                progress.progress_fill_color = Util.get_default ().get_color (color_selected);
            });
        }

        color_selected = project.color;
        if (colors_hashmap.has_key (color_selected)) {
            colors_hashmap [color_selected].active = true;
        }

        var flowbox_grid = new Gtk.Grid () {
            margin = 12,
            margin_top = 0,
            valign = Gtk.Align.START,
            vexpand = false
        };
        flowbox_grid.add (flowbox);

        unowned Gtk.StyleContext flowbox_grid_context = flowbox_grid.get_style_context ();
        flowbox_grid_context.add_class ("picker-content");

        var list_radio = new Gtk.RadioButton (null);
        list_radio.image = new Gtk.Image.from_icon_name ("projectview-list-symbolic", Gtk.IconSize.DND);
        list_radio.tooltip_text = _("Grab the whole screen");

        var board_radio = new Gtk.RadioButton.from_widget (list_radio);
        board_radio.image = new Gtk.Image.from_icon_name ("projectview-board-symbolic", Gtk.IconSize.DND);
        board_radio.tooltip_text = _("Grab the current window");

        var radio_grid = new Gtk.Grid () {
            halign = Gtk.Align.CENTER,
            column_spacing = 18,
            hexpand = true
        };
        radio_grid.add (list_radio);
        radio_grid.add (board_radio);

        var main_radio_grid = new Gtk.Grid () {
            margin = 12,
            margin_top = 0,
            valign = Gtk.Align.START,
            vexpand = false
        };
        main_radio_grid.add (radio_grid);

        unowned Gtk.StyleContext main_radio_grid_context = main_radio_grid.get_style_context ();
        main_radio_grid_context.add_class ("picker-content");

        var submit_button = new Widgets.LoadingButton (
            LoadingButtonType.LABEL,
            is_creating ? _("Add project") : _("Update project")) {
            sensitive = !is_creating
        };
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.get_style_context ().add_class ("border-radius-6");

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("border-radius-6");

        var submit_cancel_grid = new Gtk.Grid () {
            column_spacing = 12,
            column_homogeneous = true,
            margin = 12,
            vexpand = true,
            valign = Gtk.Align.END
        };
        submit_cancel_grid.add (cancel_button);
        submit_cancel_grid.add (submit_button);

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        content_grid.add (headerbar);
        content_grid.add (picker_stack);
        content_grid.add (iconstyle_switch);
        content_grid.add (name_entry);
        content_grid.add (flowbox_grid);
        content_grid.add (main_radio_grid);
        content_grid.add (submit_cancel_grid);

        add (content_grid);

        Timeout.add (preview_stack.transition_duration, () => {
            if (project.icon_style == ProjectIconStyle.PROGRESS) {
                preview_stack.visible_child_name = "progress";
                iconstyle_switch.active = false;
            } else {
                preview_stack.visible_child_name = "emoji";
                iconstyle_switch.active = true;
            }
            
            return GLib.Source.REMOVE;
        });

        preview_button.clicked.connect (() => {
            if (preview_stack.visible_child_name == "emoji") {
                emoji_entry.grab_focus ();
                emoji_entry.insert_emoji ();
            }
        });

        emoji_entry.changed.connect (() => {
            label.label = emoji_entry.text;
        });

        name_entry.changed.connect (() => {
            submit_button.sensitive = Util.get_default ().is_input_valid (name_entry);
        });

        submit_button.clicked.connect (() => {
            if (!is_creating) {
                project.color = color_selected;
                project.name = name_entry.text;
                project.icon_style = iconstyle_switch.active ? ProjectIconStyle.EMOJI : ProjectIconStyle.PROGRESS;
                project.emoji = emoji_entry.text;

                submit_button.is_loading = true;
                Planner.database.update_project (project);
                if (project.todoist) {
                    Planner.todoist.update.begin (project, (obj, res) => {
                        Planner.todoist.update.end (res);
                        submit_button.is_loading = false;
                        hide_destroy ();
                    });
                } else {
                    hide_destroy ();
                }
            } else {
                BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");

                project.color = color_selected;
                project.name = name_entry.text;
                project.icon_style = iconstyle_switch.active ? ProjectIconStyle.EMOJI : ProjectIconStyle.PROGRESS;
                project.emoji = emoji_entry.text;

                if (backend_type == BackendType.TODOIST) {
                    project.todoist = true;
                    submit_button.is_loading = true;
                    Planner.todoist.add.begin (project, (obj, res) => {
                        project.id = Planner.todoist.add.end (res);
                        Planner.database.insert_project (project);
                        Planner.event_bus.pane_selected (PaneType.PROJECT, project.id_string);
                        hide_destroy ();
                    });
                } else if (backend_type == BackendType.LOCAL) {
                    project.id = Util.get_default ().generate_id ();
                    Planner.database.insert_project (project);
                    Planner.event_bus.pane_selected (PaneType.PROJECT, project.id_string);
                    hide_destroy ();
                }
            }
        });

        cancel_button.clicked.connect (() => {
            hide_destroy ();
        });

        iconstyle_switch.notify["active"].connect (() => {
            preview_stack.visible_child_name = iconstyle_switch.active ? "emoji" : "progress";
        });
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
