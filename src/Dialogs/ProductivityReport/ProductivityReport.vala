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
        var dynamic_goal_switch = new Adw.SwitchRow () {
            title = _("Use Scheduled Tasks as Goal"),
            subtitle = _("Use today's scheduled tasks as your daily goal")
        };
        dynamic_goal_switch.active = Services.Settings.get_default ().settings.get_boolean ("use-dynamic-goal");

        var daily_spin = new Adw.SpinRow.with_range (0, 100, 1) {
            title = _("Daily Goal"),
            value = Services.Settings.get_default ().settings.get_int ("daily-task-goal")
        };

        var weekly_spin = new Adw.SpinRow.with_range (0, 500, 1) {
            title = _("Weekly Goal"),
            value = Services.Settings.get_default ().settings.get_int ("weekly-task-goal")
        };

        var goals_group = new Adw.PreferencesGroup () {
            title = _("Fixed Goals"),
            sensitive = !dynamic_goal_switch.active
        };
        goals_group.add (daily_spin);
        goals_group.add (weekly_spin);

        var dynamic_group = new Adw.PreferencesGroup ();
        dynamic_group.add (dynamic_goal_switch);

        dynamic_goal_switch.notify["active"].connect (() => {
            goals_group.sensitive = !dynamic_goal_switch.active;
        });

        var save_button = new Gtk.Button.with_label (_("Save")) {
            css_classes = { "suggested-action", "pill" },
            halign = CENTER,
            margin_top = 8
        };

        save_button.clicked.connect (() => {
            int daily_val = (int) daily_spin.value;
            int weekly_val = (int) weekly_spin.value;

            if (!dynamic_goal_switch.active && (daily_val <= 0 || weekly_val <= 0)) {
                daily_spin.add_css_class (daily_val <= 0 ? "error" : "");
                weekly_spin.add_css_class (weekly_val <= 0 ? "error" : "");
                return;
            }

            daily_spin.remove_css_class ("error");
            weekly_spin.remove_css_class ("error");

            Services.Settings.get_default ().settings.set_boolean ("use-dynamic-goal", dynamic_goal_switch.active);
            Services.Settings.get_default ().settings.set_int ("daily-task-goal", daily_val);
            Services.Settings.get_default ().settings.set_int ("weekly-task-goal", weekly_val);

            hide_goals_setup ();
            productivity_section.refresh ();
        });

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_start = 16,
            margin_end = 16,
            margin_top = 16,
            margin_bottom = 16
        };
        content_box.append (dynamic_group);
        content_box.append (goals_group);
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
