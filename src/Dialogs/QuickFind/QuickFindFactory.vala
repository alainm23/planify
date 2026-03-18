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

public class Dialogs.QuickFind.QuickFindFactory : GLib.Object {
    public static Gtk.SignalListItemFactory create_list_item_factory () {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (on_list_item_setup);
        factory.bind.connect (on_list_item_bind);
        factory.unbind.connect (on_list_item_unbind);
        factory.teardown.connect (on_list_item_teardown);
        return factory;
    }

    public static Gtk.SignalListItemFactory create_header_factory () {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (on_header_setup);
        factory.bind.connect (on_header_bind);
        return factory;
    }

    private static void on_list_item_setup (Gtk.SignalListItemFactory factory, GLib.Object list_item_obj) {
        var list_item = (Gtk.ListItem) list_item_obj;

        var main_grid = new Gtk.Grid () {
            column_spacing = 9,
            margin_top = 3,
            margin_bottom = 3,
            margin_end = 3,
            margin_start = 3
        };

        list_item.child = main_grid;
    }

    private static void on_list_item_unbind (Gtk.SignalListItemFactory factory, GLib.Object list_item_obj) {
        var list_item = (Gtk.ListItem) list_item_obj;
        var main_grid = (Gtk.Grid) list_item.child;

        var child = main_grid.get_first_child ();
        while (child != null) {
            var next = child.get_next_sibling ();
            main_grid.remove (child);
            child = next;
        }
    }

    private static void on_list_item_teardown (Gtk.SignalListItemFactory factory, GLib.Object list_item_obj) {
        var list_item = (Gtk.ListItem) list_item_obj;
        // TODO: Signals?
    }

    private static void on_list_item_bind (Gtk.SignalListItemFactory factory, GLib.Object list_item_obj) {
        var list_item = (Gtk.ListItem) list_item_obj;
        var item = (QuickFindItem) list_item.item;
        var main_grid = (Gtk.Grid) list_item.child;

        if (item.base_object is Objects.Project) {
            bind_project (item, main_grid);
        } else if (item.base_object is Objects.Section) {
            bind_section (item, main_grid);
        } else if (item.base_object is Objects.Item) {
            bind_item (item, main_grid);
        } else if (item.base_object is Objects.Label) {
            bind_label (item, main_grid);
        } else if (item.base_object is Objects.Filters.Priority) {
            bind_priority (item, main_grid);
        } else if (is_filter_type (item.base_object)) {
            bind_filter (item, main_grid);
        }
    }

    private static void bind_project (QuickFindItem item, Gtk.Grid main_grid) {
        Objects.Project project = (Objects.Project) item.base_object;

        var icon_project = new Widgets.IconColorProject (18);
        icon_project.project = project;

        var name_label = new Gtk.Label (markup_string_with_search (project.name, item.pattern)) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            use_markup = true
        };

        main_grid.column_spacing = 6;
        main_grid.margin_start = 6;
        main_grid.margin_end = 3;
        main_grid.margin_top = 3;
        main_grid.margin_bottom = 3;
        main_grid.attach (icon_project, 0, 0);
        main_grid.attach (name_label, 1, 0);
    }

    private static void bind_section (QuickFindItem item, Gtk.Grid main_grid) {
        Objects.Section section = (Objects.Section) item.base_object;

        var section_icon = new Gtk.Image.from_icon_name ("carousel-symbolic") {
            valign = Gtk.Align.CENTER
        };

        var name_label = new Gtk.Label (markup_string_with_search (section.name, item.pattern)) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            use_markup = true
        };

        var project_label = new Gtk.Label (section.project.name) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            css_classes = { "dimmed", "caption" }
        };  

        main_grid.margin_start = 6;
        main_grid.margin_end = 6;
        main_grid.margin_top = 3;
        main_grid.margin_bottom = 3;
        main_grid.attach (section_icon, 0, 0, 1, 2);
        main_grid.attach (name_label, 1, 0, 1, 1);
        main_grid.attach (project_label, 1, 1, 1, 1);
    }

    private static void bind_item (QuickFindItem item, Gtk.Grid main_grid) {
        Objects.Item item_obj = (Objects.Item) item.base_object;

        var checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER,
            sensitive = false
        };
        checked_button.add_css_class ("priority-color");
        Util.get_default ().set_widget_priority (item_obj.priority, checked_button);

        var content_label = new Gtk.Label (markup_string_with_search (item_obj.content, item.pattern)) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            use_markup = true
        };

        var project_label = new Gtk.Label (item_obj.project.name) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            css_classes = { "dimmed", "caption" }
        };

        if (item_obj.has_section) {
            project_label.label += "%s / %s".printf (project_label.label, item_obj.section.name);
        }

        main_grid.margin_start = 6;
        main_grid.margin_end = 6;
        main_grid.margin_top = 3;
        main_grid.margin_bottom = 3;
        main_grid.attach (checked_button, 0, 0, 1, 2);
        main_grid.attach (content_label, 1, 0, 1, 1);
        main_grid.attach (project_label, 1, 1, 1, 1);
    }

    private static void bind_label (QuickFindItem item, Gtk.Grid main_grid) {
        Objects.Label label = (Objects.Label) item.base_object;

        var widget_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            height_request = 16,
            width_request = 16
        };

        widget_color.add_css_class ("circle-color");
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);

        var name_label = new Gtk.Label (markup_string_with_search (label.name, item.pattern)) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            use_markup = true
        };

        main_grid.margin_start = 6;
        main_grid.margin_end = 6;
        main_grid.margin_top = 3;
        main_grid.margin_bottom = 3;
        main_grid.attach (widget_color, 0, 0);
        main_grid.attach (name_label, 1, 0);
    }

    private static void bind_priority (QuickFindItem item, Gtk.Grid main_grid) {
        Objects.Filters.Priority priority = (Objects.Filters.Priority) item.base_object;

        var priority_icon = new Gtk.Image.from_icon_name (priority.icon);
        priority_icon.add_css_class ("view-icon");
        Util.get_default ().set_widget_color (priority.color, priority_icon);

        var name_label = new Gtk.Label (markup_string_with_search (priority.title, item.pattern)) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            use_markup = true
        };

        main_grid.margin_start = 6;
        main_grid.margin_end = 6;
        main_grid.margin_top = 3;
        main_grid.margin_bottom = 3;
        main_grid.attach (priority_icon, 0, 0);
        main_grid.attach (name_label, 1, 0);
    }

    private static void bind_filter (QuickFindItem item, Gtk.Grid main_grid) {
        var filter_icon = new Gtk.Image.from_icon_name (item.base_object.icon_name) {
            valign = Gtk.Align.CENTER,
            pixel_size = 16
        };

        var name_label = new Gtk.Label (markup_string_with_search (item.base_object.name, item.pattern)) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0,
            use_markup = true
        };

        main_grid.margin_start = 6;
        main_grid.margin_end = 6;
        main_grid.margin_top = 3;
        main_grid.margin_bottom = 3;
        main_grid.attach (filter_icon, 0, 0);
        main_grid.attach (name_label, 1, 0);
    }

    private static bool is_filter_type (Objects.BaseObject base_object) {
        return base_object is Objects.Filters.Today ||
        base_object is Objects.Filters.Scheduled ||
        base_object is Objects.Filters.Completed ||
        base_object is Objects.Filters.Tomorrow ||
        base_object is Objects.Filters.Labels ||
        base_object is Objects.Filters.Pinboard ||
        base_object is Objects.Filters.Anytime ||
        base_object is Objects.Filters.Repeating ||
        base_object is Objects.Filters.Unlabeled ||
        base_object is Objects.Filters.AllItems ||
        base_object is Objects.Filters.Inbox;
    }

    private static void on_header_setup (Object object) {
        var header = (Gtk.ListHeader) object;

        var header_label = new Gtk.Label (null) {
            css_classes = { "caption", "font-bold" },
            halign = Gtk.Align.START,
            margin_start = 9,
        };

        header.child = header_label;
    }

    private static void on_header_bind (Object object) {
        var header = (Gtk.ListHeader) object;
        var label = (Gtk.Label) header.child;
        var item = (QuickFindItem) header.item;

        label.label = item.base_object.object_type.get_header ();
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

        string ? highlighted = null;
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

}
