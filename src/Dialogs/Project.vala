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
    public string header_title { get; construct; }

    private Gtk.Stack emoji_color_stack;
    private Widgets.CircularProgressBar progress_bar;
    private Adw.EntryRow name_entry;
    private Widgets.ColorPickerRow color_picker_row;
    private Widgets.LoadingButton submit_button;
    private Gtk.Switch emoji_switch;
    private Gtk.Label emoji_label;
    private Gtk.Label source_selected_label;

    private Adw.NavigationView navigation_view;
    private Adw.NavigationPage sources_page;

    public bool is_creating {
        get {
            return project.id == "";
        }
    }

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

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
            header_title: project.parent_id == "" ? _("New Project") : project.parent.name + " → " + _("New Project")
        );
    }

    public Project (Objects.Project project) {
        Object (
            project: project,
            backend_picker: false,
            header_title: _("Edit Project")
        );
    }

    ~Project () {
        print ("Destroying - Dialogs.Project\n");
    }

    construct {
        sources_page = get_sources_page ();

        navigation_view = new Adw.NavigationView ();
        navigation_view.add (get_main_page ());

        child = navigation_view;
        Services.EventBus.get_default ().disconnect_typing_accel ();

        closed.connect (() => {
            clean_up ();
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private Adw.NavigationPage get_main_page () {
        emoji_label = new Gtk.Label (project.emoji);

        progress_bar = new Widgets.CircularProgressBar (32);
        progress_bar.percentage = 0.64;

        emoji_color_stack = new Gtk.Stack () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        emoji_color_stack.add_named (progress_bar, "color");
        emoji_color_stack.add_named (emoji_label, "emoji");
        emoji_color_stack.visible_child_name = project.icon_style == ProjectIconStyle.PROGRESS ? "color" : "emoji";

        var emoji_picker_button = new Gtk.Button () {
            hexpand = true,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            height_request = 64,
            width_request = 64,
            margin_top = 6,
            child = emoji_color_stack,
            css_classes = { "title-2", "button-emoji-picker" }
        };

        var emoji_chooser = new Gtk.EmojiChooser () {
            has_arrow = false
        };

        emoji_chooser.set_parent (emoji_picker_button);

        name_entry = new Adw.EntryRow ();
        name_entry.title = _("Give your project a name");
        name_entry.text = project.name;

        var emoji_icon = new Gtk.Image.from_icon_name ("reaction-add2-symbolic");

        emoji_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = project.icon_style == ProjectIconStyle.EMOJI
        };

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

        source_selected_label = new Gtk.Label (project.source.display_name) {
            css_classes = { "dimmed" },
            tooltip_text = project.source.subheader_text
        };
        var pan_icon = new Gtk.Image.from_icon_name ("go-next-symbolic") {
            pixel_size = 16
        };

        var source_selected_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        source_selected_box.append (source_selected_label);
        source_selected_box.append (pan_icon);

        var source_row = new Adw.ActionRow () {
            activatable = true,
            title = _("Source")
        };

        source_row.add_suffix (source_selected_box);

        var source_group = new Adw.PreferencesGroup () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 24,
            margin_bottom = 1
        };

        source_group.add (source_row);

        var source_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = backend_picker,
            child = source_group
        };

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
        content_box.append (source_revealer);
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
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = content_clamp;

        var navigation_page = new Adw.NavigationPage (toolbar_view, header_title);

        Timeout.add (emoji_color_stack.transition_duration, () => {
            progress_bar.color = project.color;
            color_picker_row.color = project.color;

            if (is_creating) {
                name_entry.grab_focus ();
            }

            return GLib.Source.REMOVE;
        });

        signal_map[name_entry.entry_activated.connect (add_update_project)] = name_entry;
        signal_map[submit_button.clicked.connect (add_update_project)] = submit_button;

        signal_map[emoji_chooser.emoji_picked.connect ((emoji) => {
            emoji_label.label = emoji;
        })] = emoji_chooser;

        signal_map[emoji_switch.notify["active"].connect (() => {
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
        })] = emoji_switch;

        signal_map[color_picker_row.color_changed.connect (() => {
            progress_bar.color = color_picker_row.color;
        })] = color_picker_row;

        signal_map[emoji_picker_button.clicked.connect (() => {
            if (emoji_switch.active) {
                emoji_chooser.popup ();
            }
        })] = emoji_picker_button;

        signal_map[source_row.activated.connect (() => {
            navigation_view.push (sources_page);
        })] = source_row;

        return navigation_page;
    }

    private Adw.NavigationPage get_sources_page () {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        var sources_group = new Adw.PreferencesGroup () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 6,
        };

        var none_radio = new Gtk.CheckButton ();

        foreach (Objects.Source source in Services.Store.instance ().sources) {
            var radio_button = new Gtk.CheckButton () {
                group = none_radio,
                active = project.source_id == source.id
            };

            var source_row = new Adw.ActionRow () {
                activatable = true,
                title = source.display_name,
                subtitle = source.subheader_text
            };

            source_row.add_suffix (radio_button);
            source_row.set_activatable_widget (radio_button);

            signal_map[source_row.activated.connect (() => {
                project.source_id = source.id;

                source_selected_label.label = source.display_name;
                source_selected_label.tooltip_text = source.subheader_text;

                navigation_view.pop ();
            })] = source_row;

            signal_map[radio_button.toggled.connect (() => {
                project.source_id = source.id;

                source_selected_label.label = source.display_name;
                source_selected_label.tooltip_text = source.subheader_text;

                navigation_view.pop ();
            })] = radio_button;

            sources_group.add (source_row);
        }

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 6,
            child = sources_group
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.content = content_clamp;

        var navigation_page = new Adw.NavigationPage (toolbar_view, _("Sources"));

        return navigation_page;
    }

    private void add_update_project () {
        if (name_entry.text.length <= 0) {
            close ();
            return;
        }

        project.name = name_entry.text;
        project.color = color_picker_row.color;
        project.icon_style = emoji_switch.active ? ProjectIconStyle.EMOJI : ProjectIconStyle.PROGRESS;
        project.emoji = emoji_label.label;

        submit_button.is_loading = true;

        if (!is_creating) {
            update_project.begin ();
        } else {
            add_project ();
        }
    }

    private async void update_project () {
        if (project.source_type == SourceType.LOCAL) {
            Services.Store.instance ().update_project (project);
            close ();
            return;
        }

        HttpResponse ? response;

        if (project.source_type == SourceType.TODOIST) {
            response = yield Services.Todoist.get_default ().update (project);
        } else if (project.source_type == SourceType.CALDAV) {
            var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
            response = yield caldav_client.update_project (project);
        } else {
            close ();
            return;
        }

        if (response.status) {
            Services.Store.instance ().update_project (project);
            close ();
        } else {
            Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
            close ();
        }
    }

    private void add_project () {
        project.child_order = Services.Store.instance ().get_projects_by_source (project.source_id).size;

        if (project.source_type == SourceType.LOCAL || project.source_type == SourceType.NONE) {
            project.id = Util.get_default ().generate_id (project);
            Services.Store.instance ().insert_project (project);
            go_project (project.id);
        } else if (project.source_type == SourceType.TODOIST) {
            Services.Todoist.get_default ().add.begin (project, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);

                if (response.status) {
                    project.id = response.data;
                    Services.Store.instance ().insert_project (project);
                    go_project (project.id);
                } else {
                    Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                    close ();
                }
            });
        } else if (project.source_type == SourceType.CALDAV) {
            project.id = Util.get_default ().generate_id (project);
            var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
            caldav_client.create_project.begin (project, (obj, res) => {
                HttpResponse response = caldav_client.create_project.end (res);

                if (response.status) {
                    Services.Store.instance ().insert_project (project);
                    caldav_client.update_sync_token.begin (project, new GLib.Cancellable ());
                    go_project (project.id);
                } else {
                    Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                    close ();
                }
            });
        }
    }

    public void go_project (string id) {
        Timeout.add (250, () => {
            Services.EventBus.get_default ().send_toast (
                Util.get_default ().create_toast (_("Project added successfully!"))
            );
            Services.EventBus.get_default ().pane_selected (PaneType.PROJECT, id);
            close ();
            return GLib.Source.REMOVE;
        });
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        if (color_picker_row != null) {
            color_picker_row.clean_up ();
        }
    }
}
