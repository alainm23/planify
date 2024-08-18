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

public class Dialogs.QuickFind.QuickFindItem : Gtk.ListBoxRow {
    public Objects.BaseObject base_object { get; construct; }
    public string pattern { get; construct; }

    public QuickFindItem (Objects.BaseObject base_object, string pattern) {
        Object (
            base_object: base_object,
            pattern: pattern,
            margin_start: 6,
            margin_end: 6
        );
    }

    ~QuickFindItem () {
        print ("Destroying Dialogs.QuickFind.QuickFindItem\n");
    }

    construct {
        add_css_class ("border-radius-6");

        var main_grid = new Gtk.Grid () {
            column_spacing = 9,
            margin_top = 3,
            margin_bottom = 3,
            margin_end = 3,
            margin_start = 3
        };

        if (base_object is Objects.Project) {
            Objects.Project project = ((Objects.Project) base_object);

            var icon_project = new Widgets.IconColorProject (10);
            icon_project.project = project;

            var name_label = new Gtk.Label (markup_string_with_search (project.name, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            main_grid.attach (icon_project, 0, 0);
            main_grid.attach (name_label, 1, 0);
        } else if (base_object is Objects.Section) {
            Objects.Section section = ((Objects.Section) base_object);

            var section_icon = new Gtk.Image.from_icon_name ("carousel-symbolic") {
                valign = Gtk.Align.CENTER
            };

            var name_label = new Gtk.Label (markup_string_with_search (section.name, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            var project_label = new Gtk.Label (section.project.name) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                css_classes = { "dim-label", "caption" }
            };

            main_grid.attach (section_icon, 0, 0, 1, 2);
            main_grid.attach (name_label, 1, 0, 1, 1);
            main_grid.attach (project_label, 1, 1, 1, 1);
        } else if (base_object is Objects.Item) {
            Objects.Item item = ((Objects.Item) base_object);

            var checked_button = new Gtk.CheckButton () {
                valign = Gtk.Align.CENTER,
                sensitive = false
            };
            checked_button.add_css_class ("priority-color");
            Util.get_default ().set_widget_priority (item.priority, checked_button);

            var content_label = new Gtk.Label (markup_string_with_search (item.content, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            var project_label = new Gtk.Label (item.project.name) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                css_classes = { "dim-label", "caption" }
            };

            if (item.has_section) {
                project_label.label += "%s / %s".printf (project_label.label, item.section.name);
            }

            main_grid.attach (checked_button, 0, 0, 1, 2);
            main_grid.attach (content_label, 1, 0, 1, 1);
            main_grid.attach (project_label, 1, 1, 1, 1);
        } else if (base_object is Objects.Label) {
            Objects.Label label = ((Objects.Label) base_object);

            var widget_color = new Gtk.Grid () {
                valign = Gtk.Align.CENTER,
                height_request = 16,
                width_request = 16
            };
    
            widget_color.add_css_class ("circle-color");
            Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);

            var name_label = new Gtk.Label (markup_string_with_search (label.name, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            main_grid.attach (widget_color, 0, 0);
            main_grid.attach (name_label, 1, 0);
        } else if (base_object is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) base_object);

            var priority_icon = Util.get_default ().get_priority_icon (priority.priority);

            var name_label = new Gtk.Label (markup_string_with_search (priority.name, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            main_grid.attach (priority_icon, 0, 0);
            main_grid.attach (name_label, 1, 0);
        } else if (base_object is Objects.Filters.Today || base_object is Objects.Filters.Scheduled ||
            base_object is Objects.Filters.Completed || base_object is Objects.Filters.Tomorrow ||
            base_object is Objects.Filters.Labels || base_object is Objects.Filters.Scheduled ||
            base_object is Objects.Filters.Pinboard || base_object is Objects.Filters.Anytime ||
            base_object is Objects.Filters.Repeating || base_object is Objects.Filters.Unlabeled ||
            base_object is Objects.Filters.AllItems) {
            var filter_icon = new Gtk.Image.from_icon_name (base_object.icon_name) {
                valign = Gtk.Align.CENTER,
                pixel_size = 16
            };

            var name_label = new Gtk.Label (markup_string_with_search (base_object.name, pattern)) {
                ellipsize = Pango.EllipsizeMode.END,
                xalign = 0,
                use_markup = true
            };

            main_grid.attach (filter_icon, 0, 0);
            main_grid.attach (name_label, 1, 0);
        }
        
        child = main_grid;
    }

    private static string markup_string_with_search (string text, string pattern) {
        const string MARKUP = "%s";

        if (pattern == "") {
            return MARKUP.printf (Markup.escape_text (text));
        }

        // if no text found, use pattern
        if (text == "") {
            return MARKUP.printf (Markup.escape_text (pattern));
        }

        var matchers = Synapse.Query.get_matchers_for_query (
            pattern,
            0,
            RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS
        );

        string? highlighted = null;
        foreach (var matcher in matchers) {
            MatchInfo mi;
            if (matcher.key.match (text, 0, out mi)) {
                int start_pos;
                int end_pos;
                int last_pos = 0;
                int cnt = mi.get_match_count ();
                StringBuilder res = new StringBuilder ();
                for (int i = 1; i < cnt; i++) {
                    mi.fetch_pos (i, out start_pos, out end_pos);
                    warn_if_fail (start_pos >= 0 && end_pos >= 0);
                    res.append (Markup.escape_text (text.substring (last_pos, start_pos - last_pos)));
                    last_pos = end_pos;
                    res.append (Markup.printf_escaped ("<b>%s</b>", mi.fetch (i)));
                    if (i == cnt - 1) {
                        res.append (Markup.escape_text (text.substring (last_pos)));
                    }
                }
                highlighted = res.str;
                break;
            }
        }

        if (highlighted != null) {
            return MARKUP.printf (highlighted);
        } else {
            return MARKUP.printf (Markup.escape_text (text));
        }
    }

    public void hide_destroy () {
        ((Gtk.ListBox) parent).remove (this);
    }
}
