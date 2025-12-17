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

public enum DeadlineButtonType {
    BUTTON,
    BUTTON_DETAIL,
    CARD
}

public class Widgets.DeadlineButton : Adw.Bin {
    public DeadlineButtonType button_type { get; construct; }

    private Widgets.Calendar.Calendar calendar_view;
    private Gtk.Popover calendar_popover;
    private Gtk.MenuButton button;
    private Gtk.Revealer delete_revealer;
    private Gtk.Label deadline_date_label;
    private Gtk.Label deadline_relative_label;
    private Gtk.Revealer main_revealer;
    private Gtk.Image deadline_icon;

    public GLib.DateTime datetime {
        set {
            calendar_view.date = value;
            delete_revealer.reveal_child = value != null;

            if (value == null) {
                calendar_view.reset ();
                if (button_type == DeadlineButtonType.BUTTON_DETAIL) {
                    deadline_icon.remove_css_class ("error");

                    deadline_date_label.label = _("Set Deadline");
                    deadline_date_label.remove_css_class ("error");

                    deadline_relative_label.label = null;
                }
            } else {
                if (button_type == DeadlineButtonType.BUTTON_DETAIL) {
                    deadline_date_label.label = get_date_format (value);
                    deadline_relative_label.label = get_relative_date_format (value);
                    update_error_style (value);
                }
            }
        }
    }

    public bool reveal_content {
        set {
            main_revealer.reveal_child = value;
        }
    }

    public signal void date_selected (GLib.DateTime ? date);

    public DeadlineButton () {
        Object (
            button_type: DeadlineButtonType.BUTTON,
            tooltip_text: _("Set a Deadline")
        );
    }

    public DeadlineButton.with_detail () {
        Object (
            button_type: DeadlineButtonType.BUTTON_DETAIL,
            tooltip_text: _("Set a Deadline")
        );
    }

    public DeadlineButton.card () {
        Object (
            button_type: DeadlineButtonType.CARD,
            tooltip_text: _("Set a Deadline")
        );
    }

    ~DeadlineButton () {
        debug ("Destroying - Widgets.DeadlineButton\n");
    }

    construct {
        calendar_popover = build_popover ();
        build_button_content ();
        build_ui ();
    }

    private void build_button_content () {
        deadline_icon = new Gtk.Image.from_icon_name ("hourglass-symbolic");
        
        Gtk.Widget button_child;

        if (button_type == DeadlineButtonType.BUTTON) {
            button_child = deadline_icon;
        } else if (button_type == DeadlineButtonType.BUTTON_DETAIL) {
            deadline_date_label = new Gtk.Label (_("Set Deadline")) {
                halign = START
            };

            deadline_relative_label = new Gtk.Label (null) {
                halign = START
            };
            deadline_relative_label.add_css_class ("dimmed");
            
            var deadline_box = new Gtk.Box (HORIZONTAL, 6) {
                halign = START
            };
            deadline_box.append (deadline_icon);
            deadline_box.append (deadline_date_label);
            deadline_box.append (deadline_relative_label);
            button_child = deadline_box;
        } else {
            // CARD type
            button_child = deadline_icon;
        }

        button = new Gtk.MenuButton () {
            css_classes = { "flat" },
            valign = Gtk.Align.CENTER,
            child = button_child,
            popover = calendar_popover
        };
    }

    private void build_ui () {
        Gtk.RevealerTransitionType transition_type = button_type == DeadlineButtonType.BUTTON ? Gtk.RevealerTransitionType.SLIDE_LEFT : Gtk.RevealerTransitionType.SLIDE_DOWN;

        main_revealer = new Gtk.Revealer () {
            transition_type = transition_type,
            child = button,
            reveal_child = true
        };

        child = main_revealer;
    }

    public Gtk.Popover build_popover () {
        calendar_view = new Widgets.Calendar.Calendar (true);

        var delete_button = new Gtk.Button.with_label (_("Delete")) {
            margin_top = 12
        };
        delete_button.add_css_class ("destructive-action");

        delete_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = delete_button,
            reveal_child = false
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (calendar_view);
        content_box.append (delete_revealer);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            child = content_box,
            position = Gtk.PositionType.BOTTOM
        };

        calendar_view.day_selected.connect (() => {
            date_selected (calendar_view.date);
            popover.hide ();
        });

        delete_button.clicked.connect (() => {
            date_selected (null);
            calendar_view.reset ();
            delete_revealer.reveal_child = false;
            
            popover.hide ();
        });

        return popover;
    }

    private string get_date_format (GLib.DateTime date) {
        var date_only = Utils.Datetime.get_date_only (date);
        
        var day_name = date_only.format ("%a");
        var day_month = date_only.format ("%e %b");

        return "%s, %s".printf (day_name, day_month);
    }

    private string get_relative_date_format (GLib.DateTime date) {
        var date_only = Utils.Datetime.get_date_only (date);
        var today = Utils.Datetime.get_date_only (new GLib.DateTime.now_local ());
                
        string relative_time;
        if (Utils.Datetime.is_today (date_only)) {
            relative_time = _("Today");
        } else if (Utils.Datetime.is_tomorrow (date_only)) {
            relative_time = _("Tomorrow");
        } else if (Utils.Datetime.is_yesterday (date_only)) {
            relative_time = _("Yesterday");
        } else {
            int days_diff = (int) ((date_only.difference (today)) / GLib.TimeSpan.DAY);
            if (days_diff > 0) {
                relative_time = _("in %d days").printf (days_diff);
            } else {
                relative_time = _("%d days ago").printf (-days_diff);
            }
        }
        
        return relative_time;
    }

    private void update_error_style (GLib.DateTime date) {
        var date_only = Utils.Datetime.get_date_only (date);
        bool is_overdue = Utils.Datetime.is_today (date_only) || 
                          Utils.Datetime.is_yesterday (date_only) || 
                          Utils.Datetime.is_overdue (date_only);
        
        if (is_overdue) {
            deadline_date_label.add_css_class ("error");
            deadline_icon.add_css_class ("error");
        } else {
            deadline_date_label.remove_css_class ("error");
            deadline_icon.remove_css_class ("error");
        }
    }
}