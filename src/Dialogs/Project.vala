/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.Project : Adw.Dialog {
    public Objects.Project project { get; construct; }
    public bool backend_picker { get; construct; }

    private Adw.EntryRow name_entry;
    private Widgets.ColorPickerRow color_picker_row;
    private Widgets.LoadingButton submit_button;
    private Gtk.Switch emoji_switch;
    private Gtk.Label emoji_label;

    public bool is_creating {
        get {
            return project.id == "";
        }
    }

    public Project.new (string source_id, bool backend_picker = false, string parent_id = "") {
        var project = new Objects.Project ();
        project.color = "blue";
        project.emoji = "🚀️";
        project.id = "";
        project.parent_id = parent_id;
        project.source_id = source_id;

        Object (
            project: project,
            backend_picker: backend_picker,
            title: project.parent_id == "" ? _("New Project") : project.parent.name + " → " + _("New Project")
        );
    }

    public Project (Objects.Project project) {
        Object (
            project: project,
            backend_picker: false,
            title: _("Edit Project")
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        emoji_label = new Gtk.Label (project.emoji);

        var progress_bar = new Widgets.CircularProgressBar (32);
        progress_bar.percentage = 0.64;

        var emoji_color_stack = new Gtk.Stack () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        emoji_color_stack.add_named (progress_bar, "color");
        emoji_color_stack.add_named (emoji_label, "emoji");
        
        var emoji_picker_button = new Gtk.Button () {
            hexpand = true,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            height_request = 64,
            width_request = 64,
            margin_top = 6
        };

        var emoji_chooser = new Gtk.EmojiChooser () {
            has_arrow = false
        };

        emoji_chooser.set_parent (emoji_picker_button);

        emoji_picker_button.child = emoji_color_stack;
        
        emoji_picker_button.add_css_class ("title-2");
        emoji_picker_button.add_css_class ("button-emoji-picker");

        name_entry = new Adw.EntryRow ();
        name_entry.title = _("Give your project a name");
        name_entry.text = project.name;

        var emoji_icon = new Gtk.Image.from_icon_name ("reaction-add2-symbolic");

        emoji_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER
        };
        emoji_switch.active = project.icon_style == ProjectIconStyle.EMOJI;

        var emoji_switch_row = new Adw.ActionRow ();
        emoji_switch_row.title = _("Use Emoji");
        emoji_switch_row.set_activatable_widget (emoji_switch);
        emoji_switch_row.add_prefix (emoji_icon);
        emoji_switch_row.add_suffix (emoji_switch);

        var name_group = new Adw.PreferencesGroup () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 24
        };

        name_group.add (name_entry);
        name_group.add (emoji_switch_row);

        var backend_model = new Gtk.StringList (null);
        foreach (Objects.Source source in Services.Database.get_default ().sources) {
            backend_model.append (source.header_text);
        }

        var backend_row = new Adw.ComboRow ();
        backend_row.title = _("Source");
        backend_row.model = backend_model;

        var backend_group = new Adw.PreferencesGroup () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 24,
            margin_bottom = 1
        };

        backend_group.add (backend_row);

        var backend_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = backend_picker
        };

        backend_revealer.child = backend_group;

        color_picker_row = new Widgets.ColorPickerRow ();

        var color_group = new Adw.Bin () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 24,
            margin_bottom = 1,
            valign = Gtk.Align.START,
            css_classes = { "card" },
            child = color_picker_row
        };

        var color_box_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = project.icon_style == ProjectIconStyle.PROGRESS
        };

        color_box_revealer.child = color_group;

        submit_button = new Widgets.LoadingButton.with_label (is_creating ? _("Add Project") : _("Update Project")) {
            vexpand = true,
            hexpand = true,
            margin_bottom = 12,
            margin_end = 12,
            margin_start = 12,
            margin_top = 24,
            valign = Gtk.Align.END
        };

        submit_button.add_css_class ("suggested-action");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (emoji_picker_button);
        content_box.append (name_group);
        content_box.append (backend_revealer);
        content_box.append (color_box_revealer);
        content_box.append (submit_button);

        var content_clamp = new Adw.Clamp () {
			maximum_size = 600,
			margin_start = 12,
			margin_end = 12,
			margin_bottom = 12,
            margin_top = 6
		};

		content_clamp.child = content_box;

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = content_clamp;

        child = toolbar_view;
        Services.EventBus.get_default ().disconnect_typing_accel ();
        
        Timeout.add (emoji_color_stack.transition_duration, () => {
            if (project.icon_style == ProjectIconStyle.PROGRESS) {
                emoji_color_stack.visible_child_name = "color";
            } else {
                emoji_color_stack.visible_child_name = "emoji";
            }

            progress_bar.color = project.color;
            color_picker_row.color = project.color;

            if (project.source_type == BackendType.LOCAL || project.source_type == BackendType.NONE) {
                backend_row.selected = 0;
            } else if (project.source_type == BackendType.TODOIST) {
                backend_row.selected = 1;
            }

            if (is_creating) {
                name_entry.grab_focus ();
            }
            
            return GLib.Source.REMOVE;
        });

        name_entry.entry_activated.connect (add_update_project);
        submit_button.clicked.connect (add_update_project);

        emoji_chooser.emoji_picked.connect ((emoji) => {
            emoji_label.label = emoji;
        });

        emoji_switch.notify["active"].connect (() => {
            if (emoji_switch.active) {
                color_box_revealer.reveal_child = false;
                emoji_color_stack.visible_child_name = "emoji";

                if (emoji_label.label.strip () == "") {
                    emoji_label.label = "🚀️";
                }

                emoji_chooser.popup ();
            } else {
                color_box_revealer.reveal_child = true;
                emoji_color_stack.visible_child_name = "color";
            }
        });

        color_picker_row.color_changed.connect (() => {
            progress_bar.color = color_picker_row.color;
        });

        emoji_picker_button.clicked.connect (() => {
            if (emoji_switch.active) {
                emoji_chooser.popup ();
            }
        });

        backend_row.notify["selected"].connect (() => {
            if (backend_row.selected == 0) {
                project.backend_type = BackendType.LOCAL;
            } else if (backend_row.selected == 1) {
                project.backend_type = BackendType.TODOIST;
            }
        });

        closed.connect (() => {
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private void add_update_project () {
        if (name_entry.text.length <= 0) {
            hide_destroy ();
            return;
        }

        project.name = name_entry.text;
        project.color = color_picker_row.color;
        project.icon_style = emoji_switch.active ? ProjectIconStyle.EMOJI : ProjectIconStyle.PROGRESS;
        project.emoji = emoji_label.label;

        submit_button.is_loading = true;

        if (!is_creating) {
            update_project ();
        } else {
            add_project ();
        }
    }


    private void update_project () {
        if (project.source_type == BackendType.LOCAL) {
            Services.Database.get_default ().update_project (project);
            hide_destroy ();
        } else if (project.source_type == BackendType.TODOIST) {
            Services.Todoist.get_default ().update.begin (project, (obj, res) => {
                Services.Todoist.get_default ().update.end (res);
                Services.Database.get_default ().update_project (project);
                hide_destroy ();
            });
        } else if (project.source_type == BackendType.CALDAV) {
            Services.CalDAV.Core.get_default ().update_tasklist.begin (project, (obj, res) => {
                if (Services.CalDAV.Core.get_default ().update_tasklist.end (res)) {
                    Services.Database.get_default ().update_project (project);
                    hide_destroy ();
                }
            });
        }
    }

    private void add_project () {
        project.child_order = Services.Database.get_default ().get_projects_by_backend_type (project.backend_type).size;
        
        if (project.source_type == BackendType.LOCAL || project.source_type == BackendType.NONE) {
            project.id = Util.get_default ().generate_id (project);
            Services.Database.get_default ().insert_project (project);
            go_project (project.id_string);
        } else if (project.source_type == BackendType.TODOIST) {
            Services.Todoist.get_default ().add.begin (project, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);

                if (response.status) {
                    project.id = response.data;
                    Services.Database.get_default ().insert_project (project);
                    go_project (project.id_string);
                }
            });
        } else if (project.source_type == BackendType.CALDAV) {
            project.id = Util.get_default ().generate_id (project);
            Services.CalDAV.Core.get_default ().add_tasklist.begin (project, (obj, res) => {
                if (Services.CalDAV.Core.get_default ().add_tasklist.end (res)) {
                    Services.CalDAV.Core.get_default ().get_sync_token.begin (project, (obj, res) => {
                        HttpResponse response = Services.CalDAV.Core.get_default ().get_sync_token.end (res);

                        if (response.status) {
                            project.sync_id = response.data;
                        }

                        Services.Database.get_default ().insert_project (project);
                        go_project (project.id_string);
                    });
                }
            });
        }
    }

    public void go_project (string id_string) {
        Timeout.add (250, () => {
            Services.EventBus.get_default ().send_notification (
                Util.get_default ().create_toast (_("Project added successfully!"))
            );    
            Services.EventBus.get_default ().pane_selected (PaneType.PROJECT, id_string);
            hide_destroy ();   
            return GLib.Source.REMOVE;
        });
    }

    public void hide_destroy () {
        close ();
    }
}
