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

public class Views.Scheduled.Scheduled : Adw.Bin {
    private Gtk.ListBox listbox;
    private Gtk.ScrolledWindow scrolled_window;

    public Gee.HashMap <string, Layouts.ItemRow> items;
    
    construct {
        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        var headerbar = new Layouts.HeaderBar ();
        headerbar.title = _("Scheduled");

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 12
        };
        listbox_grid.attach (listbox, 0, 0);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (listbox_grid);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 24,
            margin_end = 24
        };

        content_clamp.child = content;

        scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var magic_button = new Widgets.MagicButton ();

        var content_overlay = new Gtk.Overlay () {
			hexpand = true,
			vexpand = true
		};

		content_overlay.child = scrolled_window;
		content_overlay.add_overlay (magic_button);

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = content_overlay;

        child = toolbar_view;
        add_days ();

        magic_button.clicked.connect (() => {
            prepare_new_item ();
        });
    }

    private void add_days () {
        var date = new GLib.DateTime.now_local ();
        var month_days = Util.get_default ().get_days_of_month (date.get_month (), date.get_year ());
        var remaining_days = month_days - date.add_days (7).get_day_of_month ();
        var days_to_iterate = 7;

        if (remaining_days >= 1 && remaining_days <= 3) {
            days_to_iterate += remaining_days;
        }

        for (int i = 0; i < days_to_iterate; i++) {
            date = date.add_days (1);

            var row = new Views.Scheduled.ScheduledDay (date);
            listbox.append (row);
        }

        month_days = Util.get_default ().get_days_of_month (date.get_month (), date.get_year ());
        remaining_days = month_days - date.get_day_of_month ();

        if (remaining_days > 3) {
            var row = new Views.Scheduled.ScheduledRange (date.add_days (1), date.add_days (remaining_days));
            listbox.append (row);
        }

        for (int i = 0; i < 4; i++) {
            date = date.add_months (1);
            var row = new Views.Scheduled.ScheduledMonth (date);
            listbox.append (row);
        }
    }

    public void prepare_new_item (string content = "") {
        var inbox_project = Services.Database.get_default ().get_project (
            Services.Settings.get_default ().settings.get_string ("inbox-project-id")
        );

        var dialog = new Dialogs.QuickAdd ();
        dialog.update_content (content);
        dialog.set_project (inbox_project);
        dialog.set_due (Util.get_default ().get_format_date (new GLib.DateTime.now_local ().add_days (1)));
        dialog.show ();
    }
}
