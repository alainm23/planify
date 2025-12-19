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
    private Gtk.Label deadline_label;
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
                    deadline_label.remove_css_class ("error");
                } else if (button_type == DeadlineButtonType.CARD) {
                    deadline_label.label = _("Set a Deadline");
                    deadline_label.tooltip_text = null;
                    deadline_icon.remove_css_class ("error");
                }
            } else {
                if (button_type == DeadlineButtonType.BUTTON_DETAIL) {
                    deadline_date_label.label = get_date_format (value);
                    deadline_relative_label.label = get_relative_date_format (value);
                    update_error_style (value);
                } else if (button_type == DeadlineButtonType.CARD) {
                    deadline_label.label = "%s, %s".printf (get_date_format (value), get_relative_date_format (value));
                    deadline_label.tooltip_text = deadline_label.label;
                    update_card_error_style (value);
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
    public signal void picker_opened (bool active);

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

        calendar_popover.closed.connect (() => {
            picker_opened (false);
        });

        calendar_popover.show.connect (() => {
            picker_opened (true);
        });
    }

    private void build_button_content () {
        deadline_icon = new Gtk.Image.from_icon_name ("delay-long-small-symbolic");
        
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
            var title_label = new Gtk.Label (_("Deadline")) {
                halign = START,
                css_classes = { "title-4", "caption", "font-bold" }
            };

            deadline_label = new Gtk.Label (_("Set a Deadline")) {
                xalign = 0,
                use_markup = true,
                halign = START,
                ellipsize = Pango.EllipsizeMode.END,
                css_classes = { "caption" }
            };

            var card_grid = new Gtk.Grid () {
                column_spacing = 12,
                margin_start = 12,
                margin_end = 6,
                margin_top = 6,
                margin_bottom = 6,
                vexpand = true,
                hexpand = true
            };
            card_grid.attach (deadline_icon, 0, 0, 1, 2);
            card_grid.attach (title_label, 1, 0, 1, 1);
            card_grid.attach (deadline_label, 1, 1, 1, 1);

            button_child = card_grid;
        }

        button = new Gtk.MenuButton () {
            css_classes = { "flat" },
            valign = Gtk.Align.CENTER,
            child = button_child,
            popover = calendar_popover
        };

        if (button_type == DeadlineButtonType.CARD) {
            add_css_class ("card");
            add_css_class ("activatable");
            button.add_css_class ("menu-button-no-padding");
            button.hexpand = true;
        }
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
        return Utils.Datetime.get_short_date_format_from_date (date);
    }

    private string get_relative_date_format (GLib.DateTime date) {
        return Utils.Datetime.get_relative_time_from_date (date);
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

    private void update_card_error_style (GLib.DateTime date) {
        var date_only = Utils.Datetime.get_date_only (date);
        bool is_overdue = Utils.Datetime.is_today (date_only) || 
                          Utils.Datetime.is_yesterday (date_only) || 
                          Utils.Datetime.is_overdue (date_only);
        
        if (is_overdue) {
            deadline_label.add_css_class ("error");
            deadline_icon.add_css_class ("error");
        } else {
            deadline_label.remove_css_class ("error");
            deadline_icon.remove_css_class ("error");
        }
    }

    public void remove_error_style () {
        if (button_type == DeadlineButtonType.BUTTON_DETAIL) {
            deadline_date_label.remove_css_class ("error");
            deadline_icon.remove_css_class ("error");
        } else if (button_type == DeadlineButtonType.CARD) {
            deadline_label.remove_css_class ("error");
            deadline_icon.remove_css_class ("error");
        }
    }
}