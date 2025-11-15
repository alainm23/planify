/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.Preferences.Pages.InboxPage : Dialogs.Preferences.Pages.BasePage {
    private Gtk.Box group_box;

    public InboxPage (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Inbox Project")
        );
    }

    ~InboxPage () {
        debug ("Destroying Dialogs.Preferences.Pages.InboxPage\n");
    }

    construct {
        var description_label = new Gtk.Label (_("Your Inbox is where new tasks land by default. Based on David Allen's Getting Things Done methodology, it's your capture point for quick ideas and tasks that you'll organize later")) {
            wrap = true,
            xalign = 0,
            margin_bottom = 6,
            margin_start = 3,
            margin_end = 3
        };

        group_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        group_box.append (description_label);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 400,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12,
            margin_bottom = 24,
            child = group_box
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_clamp
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = scrolled_window
        };
        toolbar_view.add_top_bar (new Adw.HeaderBar ());

        child = toolbar_view;
        add_projects ();
    }

    private void add_projects () {
        var fake_radio = new Gtk.CheckButton ();

        foreach (Objects.Source source in Services.Store.instance ().sources) {
            var source_group = new Layouts.HeaderItem (source.display_name) {
                card = true,
                reveal = source.is_visible
            };

            foreach (Objects.Project project in Services.Store.instance ().get_projects_by_source (source.id)) {
                if (project.is_archived) {
                    continue;
                }

                var row = new ProjectRow (project) {
                    active = project.is_inbox_project,
                    group = fake_radio
                };

                signal_map[row.toggled.connect (() => {
                    if (row.active) {
                        Services.Settings.get_default ().settings.set_string ("local-inbox-project-id", project.id);
                    }
                })] = row;

                source_group.add_child (row);
            }

            group_box.append (source_group);
        }
    }

    private Gtk.Widget get_header_box (string title) {
        var header_label = new Gtk.Label (title) {
            css_classes = { "heading" },
            halign = START,
            margin_start = 3
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 6,
            margin_start = 3,
            margin_bottom = 3
        };

        header_box.append (header_label);

        return header_box;
    }

    public class ProjectRow : Gtk.ListBoxRow {
        public Objects.Project project { get; construct; }

        public Gtk.CheckButton radio_button; 

        public Gtk.CheckButton group {
            set {
                radio_button.group = value;
            }
        }

        public bool active {
            set {
                radio_button.active = value;
            }

            get {
                return radio_button.active;
            }
        }

        public signal void toggled ();

        public ProjectRow (Objects.Project project) {
            Object (
                project: project
            );
        }

        ~ProjectRow () {
            debug ("Destroying - ProjectRow\n");
        }

        construct {
            add_css_class ("sidebar-row");
            add_css_class ("transition");
            add_css_class ("no-padding");
            
            radio_button = new Gtk.CheckButton ();

            var action_row = new Adw.ActionRow () {
                title = project.name,
                activatable = true
            };

            action_row.add_prefix (new Widgets.IconColorProject (20) {
                project = project
            });

            action_row.add_suffix (radio_button);

            child = action_row;

            var select_gesture = new Gtk.GestureClick ();
            action_row.add_controller (select_gesture);
            select_gesture.released.connect (() => {
                radio_button.active = !radio_button.active;
                toggled ();
            });
        }
    }
}
