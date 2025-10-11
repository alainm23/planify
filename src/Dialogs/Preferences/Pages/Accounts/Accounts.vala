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

public class Dialogs.Preferences.Pages.Accounts : Dialogs.Preferences.Pages.BasePage {
    private Layouts.HeaderItem sources_group;
    private Gtk.Label inbox_page_name;

    public Accounts (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Accounts")
        );
    }
    
    ~Accounts () {
        debug ("Destroying - Dialogs.Preferences.Pages.Accounts\n");
    }

    construct {
        var todoist_item = new Widgets.ContextMenu.MenuItem (_("Todoist"));
        var nextcloud_item = new Widgets.ContextMenu.MenuItem (_("Nextcloud"));
        var caldav_item = new Widgets.ContextMenu.MenuItem (_("CalDAV"));

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (todoist_item);
        menu_box.append (nextcloud_item);
        menu_box.append (caldav_item);

        var popover = new Gtk.Popover () {
            has_arrow = true,
            child = menu_box,
            width_request = 250,
            position = Gtk.PositionType.BOTTOM
        };

        var add_source_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            icon_name = "plus-large-symbolic",
            css_classes = { "flat" },
            tooltip_markup = _("Add Source"),
            popover = popover
        };

        sources_group = new Layouts.HeaderItem (_("Accounts")) {
            card = true,
            reveal = true,
            listbox_margin_top = 6
        };

        sources_group.add_widget_end (add_source_button);

        inbox_page_name = new Gtk.Label (null) {
            ellipsize = END,
            max_width_chars = 24
        };
        inbox_page_name.add_css_class ("caption");
        inbox_page_name.add_css_class ("dimmed");

        var arrow_icon = new Gtk.Image.from_icon_name ("go-next-symbolic");

        var inbox_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = END,
            valign = CENTER,
            hexpand = true
        };
        inbox_box.append (inbox_page_name);
        inbox_box.append (arrow_icon);

        var inbox_page_row = new Adw.ActionRow () {
            activatable = true,
            title = _("Inbox Page")
        };
        inbox_page_row.add_prefix (new Gtk.Image.from_icon_name ("mailbox-symbolic"));
        inbox_page_row.add_suffix (inbox_box);

        var inbox_group = new Adw.PreferencesGroup () {
            margin_top = 12
        };
        inbox_group.add (inbox_page_row);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        content_box.append (sources_group);
        content_box.append (new Gtk.Label (_("You can sort your accounts by dragging and dropping")) {
            css_classes = { "caption", "dimmed" },
            halign = START,
            margin_start = 12
        });
        content_box.append (inbox_group);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_start = 24,
            margin_end = 24
        };

        content_clamp.child = content_box;

        var toolbar_view = new Adw.ToolbarView () {
            content = content_clamp
        };
        toolbar_view.add_top_bar (new Adw.HeaderBar ());

        child = toolbar_view;
        update_inbox_page_name ();

        Gee.HashMap<string, SourceRow> sources_hashmap = new Gee.HashMap<string, SourceRow> ();
        foreach (Objects.Source source in Services.Store.instance ().sources) {
            if (!sources_hashmap.has_key (source.id)) {
                sources_hashmap[source.id] = new SourceRow (source, preferences_dialog);
                sources_group.add_child (sources_hashmap[source.id]);
            }
        }

        signal_map[Services.Store.instance ().source_added.connect ((source) => {
            if (!sources_hashmap.has_key (source.id)) {
                sources_hashmap[source.id] = new SourceRow (source, preferences_dialog);
                sources_group.add_child (sources_hashmap[source.id]);
            }
        })] = Services.Store.instance ();

        signal_map[Services.Store.instance ().source_deleted.connect ((source) => {
            if (sources_hashmap.has_key (source.id)) {
                sources_hashmap[source.id].hide_destroy ();
                sources_hashmap.unset (source.id);
            }
        })] = Services.Store.instance ();

        signal_map[todoist_item.clicked.connect (() => {
            #if USE_WEBKITGTK
            preferences_dialog.push_subpage (new TodoistSetup.with_webkit (preferences_dialog, this));
            #else
            preferences_dialog.push_subpage (new TodoistSetup (preferences_dialog, this));
            #endif
        })] = todoist_item;

        signal_map[nextcloud_item.clicked.connect (() => {
            preferences_dialog.push_subpage (new NextcloudSetup (preferences_dialog, this));
        })] = nextcloud_item;

        signal_map[caldav_item.clicked.connect (() => {
            preferences_dialog.push_subpage (new CalDAVSetup (preferences_dialog, this));
        })] = caldav_item;

        signal_map[sources_group.row_activated.connect ((row) => {
            var source = ((SourceRow) row).source;
            preferences_dialog.push_subpage (new Dialogs.Preferences.Pages.SourceView (preferences_dialog, source));
        })] = sources_group;

        inbox_page_row.activated.connect (() => {
            preferences_dialog.push_subpage (new Dialogs.Preferences.Pages.InboxPage (preferences_dialog));
        });
        
        Services.Settings.get_default ().settings.changed["local-inbox-project-id"].connect (() => {
            update_inbox_page_name ();
        });

        destroy.connect (() => {
            clean_up ();
        });
    }

    public void show_message_error (int error_code, string error_message, bool visible_issue_button = true) {
        var error_view = new Widgets.ErrorView () {
            error_code = error_code,
            error_message = error_message,
            visible_issue_button = visible_issue_button
        };

        var page = new Adw.NavigationPage (error_view, "");

        preferences_dialog.push_subpage (page);
    }

    public override void clean_up () {
        sources_group.set_sort_func (null);
        foreach (var row in sources_group.get_children ()) {
            ((SourceRow) row).clean_up ();
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    private void update_inbox_page_name () {
        Objects.Project ? inbox_project = Services.Store.instance ().get_project (
            Services.Settings.get_default ().settings.get_string ("local-inbox-project-id")
        );

        if (inbox_project == null) {
            return;
        }
        
        string label = "%s (%s)".printf (inbox_project.name, inbox_project.source.display_name);
        inbox_page_name.label = label;
        inbox_page_name.tooltip_text = label;
    }

    public Gtk.Widget build_sync_page () {
        var image = new Adw.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            height_request = 64,
            width_request = 64
        };

        var label = new Gtk.Label (_("Planify is syncing your tasks, this may take a few minutes")) {
            wrap = true,
            halign = Gtk.Align.CENTER,
            justify = Gtk.Justification.CENTER,
            margin_start = 12,
            margin_end = 12,
        };
        label.add_css_class ("dimmed");

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24) {
            margin_top = 128,
            margin_start = 64,
            margin_end = 64
        };
        box.append (image);
        box.append (label);

        return box;
    }

    public class SourceRow : Gtk.ListBoxRow {
        public Objects.Source source { get; construct; }
        public Adw.PreferencesDialog preferences_dialog { get; construct; }

        private Widgets.ReorderChild reorder;
        private Gtk.Revealer main_revealer;
        private Gtk.Switch visible_checkbutton;
        private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

        public SourceRow (Objects.Source source, Adw.PreferencesDialog preferences_dialog) {
            Object (
                source: source,
                preferences_dialog: preferences_dialog
            );
        }

        ~SourceRow () {
            debug ("Destroying - SourceRow\n");
        }

        construct {
            add_css_class ("no-selectable");

            var title_label = new Gtk.Label (source.display_name) {
                halign = Gtk.Align.START
            };

            var subtitle_label = new Gtk.Label (source.subheader_text) {
                halign = Gtk.Align.START,
                css_classes = { "caption", "dimmed" }
            };

            var subtitle_revealer = new Gtk.Revealer () {
                child = subtitle_label,
                reveal_child = source.source_type != SourceType.LOCAL
            };

            var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                valign = Gtk.Align.CENTER
            };
            title_box.append (title_label);
            title_box.append (subtitle_revealer);

            visible_checkbutton = new Gtk.Switch () {
                active = source.is_visible,
                valign = CENTER
            };

            Gtk.Image ? warning_image = null;
            if (source.source_type == SourceType.CALDAV && source.caldav_data.ignore_ssl) {
                warning_image = new Gtk.Image.from_icon_name ("dialog-warning-symbolic");
                warning_image.set_tooltip_text ("SSL verification is disabled");
            }

            var end_box = new Gtk.Box (HORIZONTAL, 12) {
                hexpand = true,
                halign = END
            };
            if (warning_image != null) {
                end_box.append (warning_image);
            }
            end_box.append (visible_checkbutton);
            end_box.append (new Gtk.Image.from_icon_name ("go-next-symbolic"));

            var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                margin_top = 6,
                margin_bottom = 6,
                margin_start = 6,
                margin_end = 6,
                height_request = 32
            };

            content_box.append (new Gtk.Image.from_icon_name ("list-drag-handle-symbolic") {
                css_classes = { "dimmed" },
                pixel_size = 12
            });
            content_box.append (title_box);
            content_box.append (end_box);

            var card = new Adw.Bin () {
                child = content_box,
                margin_top = 3,
                margin_bottom = 3,
                margin_start = 3,
                margin_end = 3
            };

            reorder = new Widgets.ReorderChild (card, this);

            main_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
                child = reorder
            };

            child = main_revealer;
            reorder.build_drag_and_drop ();
            update_switch_sensitivity ();

            Timeout.add (main_revealer.transition_duration, () => {
                main_revealer.reveal_child = true;
                return GLib.Source.REMOVE;
            });

            signal_map[source.updated.connect (() => {
                title_label.label = source.display_name;
            })] = source;

            signal_map[visible_checkbutton.notify["active"].connect (() => {
                if (!visible_checkbutton.active) {
                    int visible_count = 0;
                    foreach (Objects.Source s in Services.Store.instance ().sources) {
                        if (s.is_visible) {
                            visible_count++;
                        }
                    }
                    
                    if (visible_count <= 1) {
                        visible_checkbutton.active = true;
                        return;
                    }

                    string current_inbox_id = Services.Settings.get_default ().settings.get_string ("local-inbox-project-id");
                    var inbox_project = Services.Store.instance ().get_project (current_inbox_id);
                    
                    if (inbox_project != null && inbox_project.source_id == source.id) {
                        visible_checkbutton.active = true;
                        show_inbox_warning_dialog ();
                        return;
                    }
                }
                
                source.is_visible = visible_checkbutton.active;
                source.save ();
                update_all_switches ();
            })] = visible_checkbutton;

            signal_map[Services.Store.instance ().source_added.connect (() => {
                update_switch_sensitivity ();
            })] = Services.Store.instance ();

            signal_map[Services.Store.instance ().source_deleted.connect (() => {
                update_switch_sensitivity ();
            })] = Services.Store.instance ();

            signal_map[reorder.on_drop_end.connect ((listbox) => {
                update_views_order (listbox);
            })] = reorder;

            signal_map[main_revealer.notify["child-revealed"].connect (() => {
                reorder.draw_motion_widgets ();
            })] = main_revealer;
        }

        private void show_inbox_warning_dialog () {
            var dialog = new Adw.AlertDialog (
                _("Cannot Hide This Account"),
                _("This account contains your current Inbox project. Please change your Inbox project first.")
            );

            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("change", _("Change Inbox"));
            dialog.set_response_appearance ("change", Adw.ResponseAppearance.SUGGESTED);
            dialog.set_default_response ("change");
            dialog.set_close_response ("cancel");

            dialog.choose.begin (Planify._instance.main_window, null, (obj, res) => {
                string response = dialog.choose.end (res);
                if (response == "change") {
                    preferences_dialog.push_subpage (new Dialogs.Preferences.Pages.InboxPage (preferences_dialog));
                }
            });
        }

        private void update_views_order (Gtk.ListBox listbox) {
            unowned SourceRow ? row = null;
            var row_index = 0;

            do {
                row = (SourceRow) listbox.get_row_at_index (row_index);

                if (row != null) {
                    row.source.child_order = row_index;
                    row.source.save ();
                }

                row_index++;
            } while (row != null);

            Services.EventBus.get_default ().update_sources_position ();
        }

        private void update_switch_sensitivity () {
            int visible_count = 0;
            foreach (Objects.Source s in Services.Store.instance ().sources) {
                if (s.is_visible) {
                    visible_count++;
                }
            }
            visible_checkbutton.sensitive = visible_count > 1 || !source.is_visible;
        }

        private void update_all_switches () {
            var listbox = (Gtk.ListBox) parent;
            if (listbox == null) return;
            
            unowned SourceRow ? row = null;
            var row_index = 0;
            do {
                row = (SourceRow) listbox.get_row_at_index (row_index);
                if (row != null) {
                    row.update_switch_sensitivity ();
                }
                row_index++;
            } while (row != null);
        }

        public void hide_destroy () {
            main_revealer.reveal_child = false;
            clean_up ();
            Timeout.add (main_revealer.transition_duration, () => {
                ((Gtk.ListBox) parent).remove (this);
                return GLib.Source.REMOVE;
            });
        }

        public void clean_up () {
            if (reorder != null) {
                reorder.clean_up ();
                reorder = null;
            }

            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signal_map.clear ();
            
            main_revealer = null;
        }
    }

    public class LoadingPage : Adw.Bin {
        private Gtk.Label secondary_label;
        private Gtk.ProgressBar progress_bar;
        private Adw.Spinner spinner;
        private bool _show_progress = false;

        public string sync_label {
            set {
                secondary_label.label = value;
            }
        }

        public bool show_progress {
            get { return _show_progress; }
            set {
                _show_progress = value;
                spinner.visible = !value;
                progress_bar.visible = value;
            }
        }

        public double progress {
            set {
                progress_bar.fraction = value;
            }
        }

        construct {
            var title_label = new Gtk.Label (_("Syncing…")) {
                wrap = true,
                halign = CENTER,
                justify = CENTER,
                margin_bottom = 24
            };
            title_label.add_css_class ("title-1");
        
            spinner = new Adw.Spinner () {
                valign = CENTER,
                halign = CENTER,
                height_request = 64,
                width_request = 64
            };

            progress_bar = new Gtk.ProgressBar () {
                valign = CENTER,
                halign = CENTER,
                width_request = 300,
                visible = false
            };

            secondary_label = new Gtk.Label (null) {
                wrap = true,
                halign = CENTER,
                justify = CENTER
            };
            secondary_label.add_css_class ("dimmed");
            secondary_label.add_css_class ("caption");

            var primary_label = new Gtk.Label (_("Planify is syncing your tasks, this may take a few minutes")) {
                wrap = true,
                halign = CENTER,
                justify = CENTER,
                margin_start = 12,
                margin_end = 12,
            };
            primary_label.add_css_class ("dimmed");

            var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24) {
                margin_top = 128,
                margin_start = 64,
                margin_end = 64
            };

            content_box.append (title_label);
            content_box.append (spinner);
            content_box.append (progress_bar);
            content_box.append (secondary_label);
            content_box.append (primary_label);

            child = content_box;
        }
    }
}
