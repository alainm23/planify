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

public class Dialogs.ProductivityReport.ProductivityReportDialog : Adw.Dialog {
    private Adw.NavigationView navigation_view;
    private Adw.Bin dimming_widget;
    private Gtk.Revealer goals_revealer;
    private Dialogs.ProductivityReport.ProductivitySection productivity_section;

    public ProductivityReportDialog () {
        Object (
            title: _("Summary & Productivity"),
            content_width: 450,
            content_height: 600
        );
    }

    construct {
        navigation_view = new Adw.NavigationView ();
        navigation_view.add (build_main_page ());

        dimming_widget = new Adw.Bin () {
            visible = false,
            css_classes = { "dimming-bg" }
        };

        var dimming_gesture = new Gtk.GestureClick ();
        dimming_widget.add_controller (dimming_gesture);
        dimming_gesture.pressed.connect (() => {
            hide_goals_setup ();
        });

        goals_revealer = new Gtk.Revealer () {
            child = build_goals_setup (),
            valign = END,
            transition_type = SLIDE_UP,
            reveal_child = false
        };

        goals_revealer.notify["reveal-child"].connect (() => {
            dimming_widget.visible = goals_revealer.reveal_child;
        });

        var main_overlay = new Gtk.Overlay () {
            child = navigation_view
        };
        main_overlay.add_overlay (dimming_widget);
        main_overlay.add_overlay (goals_revealer);

        child = main_overlay;

        closed.connect (() => {
            Services.EventBus.get_default ().connect_typing_accel ();
        });

        Services.EventBus.get_default ().disconnect_typing_accel ();
    }

    private void show_goals_setup () {
        goals_revealer.reveal_child = true;
    }

    private void hide_goals_setup () {
        goals_revealer.reveal_child = false;
    }

    private Gtk.Widget build_goals_setup () {
        var title_label = new Gtk.Label (_("Set Up Goals")) {
            css_classes = { "font-bold" },
            halign = START
        };

        var description_label = new Gtk.Label (_("Define how many tasks you want to complete per day and week")) {
            css_classes = { "caption", "dimmed" },
            halign = START,
            wrap = true
        };

        var title_box = new Gtk.Box (VERTICAL, 3);
        title_box.append (title_label);
        title_box.append (description_label);

        // Daily goal
        var daily_label = new Gtk.Label (_("Daily")) {
            halign = START,
            hexpand = true
        };

        var daily_spin = new Gtk.SpinButton.with_range (0, 100, 1) {
            value = 5
        };

        var daily_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8) {
            hexpand = true
        };
        daily_box.append (daily_label);
        daily_box.append (daily_spin);

        // Weekly goal
        var weekly_label = new Gtk.Label (_("Weekly")) {
            halign = START,
            hexpand = true
        };

        var weekly_spin = new Gtk.SpinButton.with_range (0, 500, 1) {
            value = 25
        };

        var weekly_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8) {
            hexpand = true
        };
        weekly_box.append (weekly_label);
        weekly_box.append (weekly_spin);

        var goals_row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 16) {
            homogeneous = true,
            hexpand = true
        };
        goals_row.append (daily_box);
        goals_row.append (weekly_box);

        // Load saved values
        int saved_daily = Services.Settings.get_default ().settings.get_int ("daily-task-goal");
        int saved_weekly = Services.Settings.get_default ().settings.get_int ("weekly-task-goal");
        if (saved_daily > 0) {
            daily_spin.value = saved_daily;
        }
        if (saved_weekly > 0) {
            weekly_spin.value = saved_weekly;
        }

        // Save button
        var save_button = new Gtk.Button.with_label (_("Save")) {
            css_classes = { "suggested-action" },
            hexpand = true,
            margin_top = 6
        };

        save_button.clicked.connect (() => {
            int daily_val = (int) daily_spin.value;
            int weekly_val = (int) weekly_spin.value;

            if (daily_val <= 0 || weekly_val <= 0) {
                daily_spin.add_css_class (daily_val <= 0 ? "error" : "");
                weekly_spin.add_css_class (weekly_val <= 0 ? "error" : "");
                return;
            }

            daily_spin.remove_css_class ("error");
            weekly_spin.remove_css_class ("error");

            Services.Settings.get_default ().settings.set_int ("daily-task-goal", daily_val);
            Services.Settings.get_default ().settings.set_int ("weekly-task-goal", weekly_val);

            hide_goals_setup ();
            productivity_section.refresh ();
        });

        daily_spin.value_changed.connect (() => {
            daily_spin.remove_css_class ("error");
        });

        weekly_spin.value_changed.connect (() => {
            weekly_spin.remove_css_class ("error");
        });

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_start = 16,
            margin_end = 16,
            margin_top = 16,
            margin_bottom = 16
        };

        content_box.append (title_box);
        content_box.append (goals_row);
        content_box.append (save_button);

        return new Adw.Bin () {
            css_classes = { "card" },
            child = content_box
        };
    }

    private Adw.NavigationPage build_main_page () {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        var summary_section = new Dialogs.ProductivityReport.SummarySection ();
        summary_section.see_more_clicked.connect (() => {
            navigation_view.push (build_summary_detail_page ());
        });

        productivity_section = new Dialogs.ProductivityReport.ProductivitySection ();
        productivity_section.see_more_clicked.connect (() => {
            navigation_view.push (build_productivity_detail_page ());
        });

        productivity_section.setup_goals_clicked.connect (() => {
            show_goals_setup ();
        });

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24) {
            margin_start = 16,
            margin_end = 16,
            margin_top = 8,
            margin_bottom = 24
        };

        content_box.append (summary_section);
        content_box.append (productivity_section);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_box
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = scrolled_window
        };
        toolbar_view.add_top_bar (headerbar);

        return new Adw.NavigationPage (toolbar_view, _("Summary & Productivity"));
    }

    private Adw.NavigationPage build_summary_detail_page () {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        var status_page = new Adw.StatusPage () {
            title = _("Summary Details"),
            description = _("Detailed summary will appear here")
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = status_page
        };
        toolbar_view.add_top_bar (headerbar);

        return new Adw.NavigationPage (toolbar_view, _("Summary"));
    }

    private Adw.NavigationPage build_productivity_detail_page () {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        var status_page = new Adw.StatusPage () {
            title = _("Productivity Details"),
            description = _("Detailed productivity stats will appear here")
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = status_page
        };
        toolbar_view.add_top_bar (headerbar);

        return new Adw.NavigationPage (toolbar_view, _("Productivity"));
    }
}
