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

public class Widgets.WhenSelector : Adw.Bin {
    public bool is_board { get; construct; }
    public string label { get; construct; }

    public WhenSelector (string label = _("When")) {
        Object (
            is_board: false,
            valign: Gtk.Align.CENTER,
            tooltip_text: label,
            label: label
        );
    }

    public WhenSelector.for_board (string label = _("When")) {
        Object (
            is_board: true,
            tooltip_text: label,
            label: label
        );
    }

    ~WhenSelector () {
        debug ("Destroying - Widgets.WhenSelector\n");
    }

    construct {
        var due_image = new Gtk.Image.from_icon_name ("month-symbolic");

        var due_label = new Gtk.Label (label) {
            xalign = 0,
            use_markup = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        var container_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        container_box.append (due_image);
        container_box.append (due_label);

        var datetime_popover = build_popover ();

        var button = new Gtk.MenuButton () {
            child = container_box,
            popover = datetime_popover,
            css_classes = { "flat" }
        };

        child = button;
    }

    private Gtk.Popover build_popover () {
        var chrono = new Chrono.Chrono ();

        var search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Type a date…")
        };

        var suggested_date_box = new Adw.WrapBox () {
            child_spacing = 6,
            line_spacing = 6,
            margin_top = 12
        };

        var date_item = new Widgets.ContextMenu.MenuItem (_("Choose a date"), "month-symbolic");
        date_item.arrow = true;
        date_item.autohide_popover = false;

        var repeat_item = new Widgets.ContextMenu.MenuItem (_("Repeat"), "playlist-repeat-symbolic");
        repeat_item.arrow = true;
        repeat_item.autohide_popover = false;

        var time_icon = new Gtk.Image.from_icon_name ("clock-symbolic");

        var time_label = new Gtk.Label (_("Time")) {
            css_classes = { "font-weight-500" }
        };

        var time_picker = new Widgets.DateTimePicker.TimePicker () {
            hexpand = true,
            halign = Gtk.Align.END
        };

        var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_start = 11
        };

        time_box.append (time_icon);
        time_box.append (time_label);
        time_box.append (time_picker);

        var hidden_box = new Gtk.Box (VERTICAL, 0) {
            margin_top = 6
        };
        hidden_box.append (date_item);
        hidden_box.append (repeat_item);
        hidden_box.append (time_box);

        var hidden_box_revealer = new Gtk.Revealer () {
            child = hidden_box
        };
        
        var more_button_box = new Gtk.Box (HORIZONTAL, 3) {
            hexpand = true,
            halign = CENTER
        };
        more_button_box.add_css_class ("dimmed");

        more_button_box.append (new Gtk.Image.from_icon_name ("down-small-symbolic"));

        more_button_box.append (new Gtk.Label (_("More")) {
            css_classes = { "caption" }
        });

        var more_button = new Gtk.Button () {
            child = more_button_box,
            margin_top = 6
        };
        more_button.add_css_class ("flat");

        var popover_box = new Gtk.Box (VERTICAL, 0) {
            margin_top = 3,
            margin_bottom = 3
        };

        popover_box.append (search_entry);
        popover_box.append (suggested_date_box);
        popover_box.append (hidden_box_revealer);
        popover_box.append (more_button);

        var popover_scrolled = new Gtk.ScrolledWindow () {
            child = popover_box,
            vscrollbar_policy = NEVER,
            hscrollbar_policy = NEVER
        };

        var popover = new Gtk.Popover () {
            has_arrow = false,
            child = popover_scrolled,
            width_request = 275
        };

        add_default_suggestions (suggested_date_box);

        search_entry.search_changed.connect (() => {
            while (suggested_date_box.get_first_child () != null) {
                suggested_date_box.remove (suggested_date_box.get_first_child ());
            }

            var text = search_entry.text.strip ();
            if (text.length == 0) {
                add_default_suggestions (suggested_date_box);
                return;
            }

            var result = chrono.parse (text);
            if (result != null && result.date != null) {
                var parsed_duedate = new Objects.DueDate ();
                parsed_duedate.datetime = result.date;
                suggested_date_box.append (new SuggestedDate (parsed_duedate));
            }
        });

        more_button.clicked.connect (() => {
            hidden_box_revealer.reveal_child = !hidden_box_revealer.reveal_child;
        });

        return popover;
    }

    private void add_default_suggestions (Adw.WrapBox box) {
        box.append (new SuggestedDate (get_duedate (new DateTime.now_local ())) {
            title = _("Today")
        });

        box.append (new SuggestedDate (get_duedate (new DateTime.now_local ().add_days (1))) {
            title = _("Tomorrow")
        });
        
        box.append (new SuggestedDate (get_duedate (new DateTime.now_local ().add_days (7))) {
            title = _("Next week")
        });
    }

    private Objects.DueDate get_duedate (DateTime date) {
        var duedate = new Objects.DueDate ();
        
        duedate.datetime = Utils.Datetime.get_date_only (date);

        return duedate;
    }

    public class SuggestedDate : Adw.Bin {
        public Objects.DueDate due_date { get; construct; }

        private Gtk.Image date_icon;
        private Gtk.Label date_label;

        public string title {
            set {
                date_label.label = value;
            }
        }

        public SuggestedDate (Objects.DueDate due_date) {
            Object (
                due_date: due_date
            );
        }

        construct {
            date_icon = new Gtk.Image ();

            date_label = new Gtk.Label (Utils.Datetime.get_relative_date_from_date (due_date.datetime));

            var date_box = new Gtk.Box (HORIZONTAL, 6);
            date_box.append (date_icon);
            date_box.append (date_label);

            var button = new Gtk.Button () {
                child = date_box
            };

            child = button;

            if (Utils.Datetime.is_today (due_date.datetime)) {
                date_icon.icon_name = "star-outline-thick-symbolic";
            } else if (Utils.Datetime.is_tomorrow (due_date.datetime)) {
                date_icon.icon_name = "today-calendar-symbolic";
            } else if (Utils.Datetime.is_overdue (due_date.datetime)) {
                date_icon.icon_name = "month-symbolic";
            } else {
                date_icon.icon_name = "month-symbolic";
            }
        }
    }
}