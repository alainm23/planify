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

public class Dialogs.Preferences.Pages.HomeView : Dialogs.Preferences.Pages.BasePage {
    public HomeView (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Home View")
        );
    }

    ~HomeView () {
        debug ("Destroying - Dialogs.Preferences.Pages.HomeView\n");
    }

    construct {
        var filters_group = new Layouts.HeaderItem (_("Filters")) {
            card = true,
            reveal = true
        };

        var group_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 12
        };
        group_box.append (filters_group);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = group_box
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = scrolled_window;

        child = toolbar_view;

        var fake_radio = new Gtk.CheckButton ();

        Objects.BaseObject[] filters = {
            Objects.Filters.Inbox.get_default (),
            Objects.Filters.Today.get_default (),
            Objects.Filters.Scheduled.get_default (),
            Objects.Filters.Pinboard.get_default ()
        };

        foreach (Objects.BaseObject object in filters) {
            var row = new HomeViewRow (object) {
                active = Services.Settings.get_default ().get_string ("home-view") == object.view_id,
                group = fake_radio
            };

            signal_map[row.toggled.connect (() => {
                Services.Settings.get_default ().settings.set_string ("home-view", object.view_id);
            })] = row;

            filters_group.add_child (row);
        }

        foreach (Objects.Source source in Services.Store.instance ().sources) {
            var source_group = new Layouts.HeaderItem (source.display_name) {
                card = true,
                reveal = source.is_visible
            };

            foreach (Objects.Project project in Services.Store.instance ().get_projects_by_source (source.id)) {
                if (project.is_archived) {
                    continue;
                }
                
                var row = new HomeViewRow (project) {
                    active = Services.Settings.get_default ().get_string ("home-view") == project.view_id,
                    group = fake_radio
                };

                signal_map[row.toggled.connect (() => {
                    Services.Settings.get_default ().settings.set_string ("home-view", project.view_id);
                })] = row;

                source_group.add_child (row);
            }

            group_box.append (source_group);
        }

        destroy.connect (() => {
            clean_up ();
        });
    }

    public override void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public class HomeViewRow : Gtk.ListBoxRow {
        public Objects.BaseObject base_object { get; construct; }

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

        public HomeViewRow (Objects.BaseObject base_object) {
            Object (
                base_object: base_object
            );
        }

        ~HomeViewRow () {
            debug ("Destroying - HomeViewRown\n");
        }

        construct {
            add_css_class ("sidebar-row");
            add_css_class ("transition");
            add_css_class ("no-padding");
            
            radio_button = new Gtk.CheckButton ();

            var action_row = new Adw.ActionRow () {
                title = base_object.name,
                activatable = true
            };

            if (base_object is Objects.Project) {
                action_row.add_prefix (new Widgets.IconColorProject (20) {
                    project = (Objects.Project) base_object
                });
            } else {
                action_row.add_prefix (new Gtk.Image.from_icon_name (base_object.icon_name));
            }

            action_row.add_suffix (radio_button);

            child = action_row;

            var select_gesture = new Gtk.GestureClick ();
            action_row.add_controller (select_gesture);
            select_gesture.released.connect (() => {
                radio_button.active = !radio_button.active;
                toggled ();
            });

            radio_button.toggled.connect (() => {
                toggled ();
            });
        }
    }
}