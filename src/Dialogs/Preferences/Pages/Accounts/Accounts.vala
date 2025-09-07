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

    public Accounts (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Accounts")
        );
    }
    
    ~Accounts () {
        print ("Destroying - Dialogs.Preferences.Pages.Accounts\n");
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

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        content_box.append (sources_group);
        content_box.append (new Gtk.Label (_("You can sort your accounts by dragging and dropping")) {
            css_classes = { "caption", "dimmed" },
            halign = START,
            margin_start = 12
        });

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

        Gee.HashMap<string, Widgets.SourceRow> sources_hashmap = new Gee.HashMap<string, Widgets.SourceRow> ();
        foreach (Objects.Source source in Services.Store.instance ().sources) {
            if (!sources_hashmap.has_key (source.id)) {
                sources_hashmap[source.id] = new Widgets.SourceRow (source);
                sources_group.add_child (sources_hashmap[source.id]);
            }
        }

        signal_map[Services.Store.instance ().source_added.connect ((source) => {
            if (!sources_hashmap.has_key (source.id)) {
                sources_hashmap[source.id] = new Widgets.SourceRow (source);
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
            var source = ((Widgets.SourceRow) row).source;
            preferences_dialog.push_subpage (new Dialogs.Preferences.Pages.SourceView (preferences_dialog, source));
        })] = sources_group;

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
            ((Widgets.SourceRow) row).clean_up ();
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
