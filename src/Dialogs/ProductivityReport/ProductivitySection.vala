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

public class Dialogs.ProductivityReport.ProductivitySection : Adw.Bin {
    public signal void see_more_clicked ();
    public signal void setup_goals_clicked ();

    private Gtk.Stack content_stack;
    private Gtk.Revealer see_more_revealer;

    private Dialogs.ProductivityReport.HeatMap heatmap;
    private Gtk.Label goal_value_label;
    private Gtk.LevelBar goal_bar;
    private Gtk.Label weekly_value_label;
    private Gtk.LevelBar weekly_bar;
    private Gtk.Label motivation_label;
    private Gtk.Revealer motivation_revealer;

    construct {
        var title_label = new Gtk.Label (_("Productivity")) {
            halign = START,
            css_classes = { "font-bold" }
        };

        var see_more_button = new Gtk.Button.with_label (_("See More")) {
            halign = END,
            valign = CENTER,
            hexpand = true,
            css_classes = { "flat", "caption" }
        };

        see_more_button.clicked.connect (() => {
            see_more_clicked ();
        });

        see_more_revealer = new Gtk.Revealer () {
            child = see_more_button,
            transition_type = CROSSFADE,
            reveal_child = false,
            visible = false
        };

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true
        };
        header_box.append (title_label);
        header_box.append (see_more_revealer);

        content_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            vhomogeneous = false,
            hhomogeneous = false
        };

        content_stack.add_named (build_setup_view (), "setup");
        content_stack.add_named (build_stats_view (), "stats");

        var section_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        section_box.append (header_box);
        section_box.append (content_stack);

        child = section_box;

        update_view ();

        map.connect (() => {
            if (content_stack.visible_child_name == "stats") {
                Timeout.add (200, () => {
                    load_stats ();
                    return GLib.Source.REMOVE;
                });
            }
        });
    }

    public void refresh () {
        update_view ();
        if (content_stack.visible_child_name == "stats") {
            load_stats ();
        }
    }

    private void update_view () {
        if (!Services.ProductivityService.instance ().has_goals ()) {
            content_stack.visible_child_name = "setup";
            see_more_revealer.reveal_child = false;
        } else {
            content_stack.visible_child_name = "stats";
            see_more_revealer.reveal_child = true;
        }
    }

    private void load_stats () {
        var svc = Services.ProductivityService.instance ();

        heatmap.refresh ();

        goal_value_label.label = svc.use_dynamic
            ? "%d / %d %s".printf (svc.completed_today, svc.daily_goal, _("(scheduled)"))
            : "%d / %d".printf (svc.completed_today, svc.daily_goal);

        weekly_value_label.label = svc.use_dynamic
            ? "%d / %d %s".printf (svc.completed_week, svc.weekly_goal, _("(scheduled)"))
            : "%d / %d".printf (svc.completed_week, svc.weekly_goal);

        double daily_progress = svc.use_dynamic
            ? svc.daily_progress
            : double.min (1.0, svc.daily_progress);

        double weekly_progress = svc.use_dynamic
            ? svc.weekly_progress
            : double.min (1.0, svc.weekly_progress);

        var daily_target = new Adw.CallbackAnimationTarget ((val) => {
            goal_bar.value = val;
        });
        var daily_animation = new Adw.TimedAnimation (
            goal_bar, 0, double.min (1.0, daily_progress), 800, daily_target
        ) { easing = Adw.Easing.EASE_OUT_CUBIC };
        daily_animation.play ();

        var weekly_target = new Adw.CallbackAnimationTarget ((val) => {
            weekly_bar.value = val;
        });
        var weekly_animation = new Adw.TimedAnimation (
            weekly_bar, 0, double.min (1.0, weekly_progress), 800, weekly_target
        ) { easing = Adw.Easing.EASE_OUT_CUBIC };
        weekly_animation.play ();

        motivation_label.label = get_motivation_message (
            svc.completed_today, svc.daily_goal,
            svc.completed_week, svc.weekly_goal
        );
        motivation_revealer.reveal_child = false;

        Timeout.add (900, () => {
            motivation_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });
    }

    private string get_motivation_message (int today, int daily_goal, int week, int weekly_goal) {
        double daily_ratio = daily_goal > 0 ? (double) today / daily_goal : 0;
        double weekly_ratio = weekly_goal > 0 ? (double) week / weekly_goal : 0;

        if (daily_ratio >= 1.0 && weekly_ratio >= 1.0) {
            return "🏆 " + _("All goals achieved! You're unstoppable");
        }

        if (daily_ratio >= 1.0) {
            return "🔥 " + _("Daily goal crushed! Keep the momentum going");
        }

        if (weekly_ratio >= 1.0) {
            return "🎉 " + _("Weekly goal achieved! Enjoy the rest of your week");
        }

        if (today == 0) {
            return "🚀 " + _("Start your day, your first task awaits");
        }

        if (daily_ratio >= 0.75) {
            return "💪 " + _("Almost there! Just a few more tasks today");
        }

        if (weekly_ratio >= 0.75) {
            return "📈 " + _("Great pace this week, you're almost at your goal");
        }

        if (daily_ratio >= 0.5) {
            return "👍 " + _("Halfway through your daily goal, nice progress");
        }

        if (weekly_ratio >= 0.5) {
            return "✨ " + _("Solid week so far, keep it up");
        }

        return "📝 " + _("Every task completed is a step forward");
    }

    private Gtk.Widget build_setup_view () {
        var description_label = new Gtk.Label (_("Set your daily and weekly goals to start tracking your productivity")) {
            wrap = true,
            justify = CENTER,
            css_classes = { "title-2" },
            max_width_chars = 40
        };

        var setup_button = new Gtk.Button.with_label (_("Set Up Goals")) {
            halign = CENTER,
            css_classes = { "suggested-action", "pill" }
        };

        setup_button.clicked.connect (() => {
            setup_goals_clicked ();
        });

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24) {
            halign = CENTER,
            valign = CENTER,
            margin_top = 24,
            margin_bottom = 24
        };

        box.append (description_label);
        box.append (setup_button);

        return new Adw.Bin () {
            child = box
        };
    }

    private Gtk.Widget build_stats_view () {
        heatmap = new Dialogs.ProductivityReport.HeatMap ();

        // Daily goal progress
        var goal_label = new Gtk.Label (_("Daily Goal")) {
            halign = START,
            css_classes = { "caption" }
        };

        goal_value_label = new Gtk.Label ("0 / 0") {
            halign = END,
            hexpand = true,
            css_classes = { "caption", "dimmed" }
        };

        var goal_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        goal_header.append (goal_label);
        goal_header.append (goal_value_label);

        goal_bar = new Gtk.LevelBar () {
            min_value = 0.0,
            max_value = 1.0,
            value = 0.0
        };

        var goal_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 4
        };
        goal_box.append (goal_header);
        goal_box.append (goal_bar);

        // Weekly goal progress
        var weekly_label = new Gtk.Label (_("Weekly Goal")) {
            halign = START,
            css_classes = { "caption" }
        };

        weekly_value_label = new Gtk.Label ("0 / 0") {
            halign = END,
            hexpand = true,
            css_classes = { "caption", "dimmed" }
        };

        var weekly_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        weekly_header.append (weekly_label);
        weekly_header.append (weekly_value_label);

        weekly_bar = new Gtk.LevelBar () {
            min_value = 0.0,
            max_value = 1.0,
            value = 0.0
        };

        var weekly_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 4
        };
        weekly_box.append (weekly_header);
        weekly_box.append (weekly_bar);

        // Goals card
        var goals_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        goals_content.append (goal_box);
        goals_content.append (weekly_box);

        var goals_card = new Adw.Bin () {
            css_classes = { "card" },
            child = goals_content
        };

        var stats_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_top = 1,
            margin_bottom = 1,
            margin_start = 1,
            margin_end = 1,
        };
        stats_box.append (heatmap);

        var goals_title = new Gtk.Label (_("Goals")) {
            halign = START,
            css_classes = { "font-bold" }
        };
        stats_box.append (goals_title);
        stats_box.append (goals_card);
        stats_box.append (build_motivation_card ());

        var edit_goals_button = new Gtk.Button.with_label (_("Edit Goals")) {
            halign = CENTER,
            css_classes = { "flat", "caption", "accent" }
        };

        edit_goals_button.clicked.connect (() => {
            setup_goals_clicked ();
        });

        stats_box.append (edit_goals_button);

        return stats_box;
    }

    private Gtk.Widget build_motivation_card () {
        motivation_label = new Gtk.Label (null) {
            wrap = true,
            halign = CENTER,
            justify = CENTER,
            css_classes = { "caption" },
            opacity = 0
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        box.append (motivation_label);

        var card = new Adw.Bin () {
            css_classes = { "card" },
            child = box,
            margin_top = 2,
            margin_bottom = 2,
            margin_start = 2,
            margin_end = 2,
        };

        motivation_revealer = new Gtk.Revealer () {
            child = card,
            transition_type = SLIDE_DOWN,
            transition_duration = 400,
            reveal_child = false
        };

        motivation_revealer.notify["reveal-child"].connect (() => {
            if (motivation_revealer.reveal_child) {
                var fade_target = new Adw.CallbackAnimationTarget ((val) => {
                    motivation_label.opacity = val;
                });

                var fade_animation = new Adw.TimedAnimation (
                    motivation_label, 0, 1, 500,
                    fade_target
                ) {
                    easing = Adw.Easing.EASE_IN_QUAD
                };
                fade_animation.play ();
            }
        });

        return motivation_revealer;
    }
}
