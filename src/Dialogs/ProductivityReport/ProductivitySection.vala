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

    private Dialogs.ProductivityReport.StatCard today_card;
    private Dialogs.ProductivityReport.StatCard week_card;
    private Dialogs.ProductivityReport.StatCard month_card;
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
            transition_type = Gtk.StackTransitionType.CROSSFADE
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
        int daily = Services.Settings.get_default ().settings.get_int ("daily-task-goal");
        int weekly = Services.Settings.get_default ().settings.get_int ("weekly-task-goal");

        if (daily <= 0 && weekly <= 0) {
            content_stack.visible_child_name = "setup";
            see_more_revealer.reveal_child = false;
        } else {
            content_stack.visible_child_name = "stats";
            see_more_revealer.reveal_child = true;
        }
    }

    private void load_stats () {
        var now = new GLib.DateTime.now_local ();
        var today = Utils.Datetime.get_date_only (now);

        int start_of_week_day = Services.Settings.get_default ().settings.get_enum ("start-week");
        var week_start = get_week_start (today, start_of_week_day);
        var month_start = new GLib.DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);

        int completed_today = 0;
        int completed_week = 0;
        int completed_month = 0;

        foreach (Objects.Item item in Services.Store.instance ().items) {
            if (!item.checked || item.completed_at == "" || item.was_archived ()) {
                continue;
            }

            var completed_date = Utils.Datetime.get_date_from_string (item.completed_at);
            if (completed_date == null) {
                continue;
            }

            var completed_date_only = Utils.Datetime.get_date_only (completed_date);

            if (completed_date_only.compare (today) == 0) {
                completed_today++;
            }

            if (completed_date_only.compare (week_start) >= 0 && completed_date_only.compare (today) <= 0) {
                completed_week++;
            }

            if (completed_date_only.compare (month_start) >= 0 && completed_date_only.compare (today) <= 0) {
                completed_month++;
            }
        }

        today_card.animate_to (completed_today);
        week_card.animate_to (completed_week);
        month_card.animate_to (completed_month);

        // Goals
        int daily_goal = Services.Settings.get_default ().settings.get_int ("daily-task-goal");
        int weekly_goal = Services.Settings.get_default ().settings.get_int ("weekly-task-goal");

        double daily_progress = daily_goal > 0 ? double.min (1.0, (double) completed_today / daily_goal) : 0.0;
        double weekly_progress = weekly_goal > 0 ? double.min (1.0, (double) completed_week / weekly_goal) : 0.0;

        goal_value_label.label = "%d / %d".printf (completed_today, daily_goal);
        weekly_value_label.label = "%d / %d".printf (completed_week, weekly_goal);

        var daily_target = new Adw.CallbackAnimationTarget ((val) => {
            goal_bar.value = val;
        });

        var daily_animation = new Adw.TimedAnimation (
            goal_bar, 0, daily_progress, 800,
            daily_target
        ) {
            easing = Adw.Easing.EASE_OUT_CUBIC
        };
        daily_animation.play ();

        var weekly_target = new Adw.CallbackAnimationTarget ((val) => {
            weekly_bar.value = val;
        });

        var weekly_animation = new Adw.TimedAnimation (
            weekly_bar, 0, weekly_progress, 800,
            weekly_target
        ) {
            easing = Adw.Easing.EASE_OUT_CUBIC
        };
        weekly_animation.play ();

        // Motivational message
        motivation_label.label = get_motivation_message (completed_today, daily_goal, completed_week, weekly_goal);
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

    private GLib.DateTime get_week_start (GLib.DateTime date, int start_day) {
        // start_day: 0=Sunday, 1=Monday, ..., 6=Saturday
        // GLib day_of_week: 1=Monday, ..., 7=Sunday
        int current_dow = date.get_day_of_week (); // 1-7
        int target_dow = start_day == 0 ? 7 : start_day; // convert to 1-7

        int diff = current_dow - target_dow;
        if (diff < 0) {
            diff += 7;
        }

        return Utils.Datetime.get_date_only (date.add_days (-diff));
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
        today_card = new Dialogs.ProductivityReport.StatCard ("0", _("Today"));
        week_card = new Dialogs.ProductivityReport.StatCard ("0", _("This Week"));
        month_card = new Dialogs.ProductivityReport.StatCard ("0", _("This Month"));

        var cards_grid = new Gtk.Grid () {
            column_spacing = 12,
            column_homogeneous = true,
            hexpand = true
        };

        cards_grid.attach (today_card, 0, 0);
        cards_grid.attach (week_card, 1, 0);
        cards_grid.attach (month_card, 2, 0);

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

        var stats_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        stats_box.append (cards_grid);
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
            child = box
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
