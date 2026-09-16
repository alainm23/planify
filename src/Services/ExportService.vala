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

public class Services.ExportService : GLib.Object {
    private const double PAGE_WIDTH = 595.0;  // A4 width in points
    private const double PAGE_HEIGHT = 842.0; // A4 height in points
    private const double MARGIN = 50.0;

    private static ExportService ? _instance;
    public static ExportService get_default () {
        if (_instance == null) {
            _instance = new ExportService ();
        }

        return _instance;
    }

    public void export_project_pdf (Objects.Project project, string output_path) {
        var surface = new Cairo.PdfSurface (output_path, PAGE_WIDTH, PAGE_HEIGHT);
        var cr = new Cairo.Context (surface);
        double y = MARGIN;

        // Project name
        y += draw_markup (cr, "<b>%s</b>".printf (escape (project.name)),
                          MARGIN, y, 24, PAGE_WIDTH - MARGIN * 2, "#000000");

        // Description
        if (project.description != "") {
            y += 8;
            y += draw_markup (cr, escape (project.description),
                              MARGIN, y, 11, PAGE_WIDTH - MARGIN * 2, "#666666");
        }

        // Due date
        if (project.due_date != "") {
            var datetime = Utils.Datetime.get_date_from_string (project.due_date);
            if (datetime != null) {
                y += 6;
                string due = "%s: %s".printf (_("Deadline"),
                    Utils.Datetime.get_short_date_format_from_date (datetime));
                y += draw_markup (cr, escape (due), MARGIN, y, 10,
                                  PAGE_WIDTH - MARGIN * 2, "#4d4d4d");
            }
        }

        // Tasks without section
        if (project.items.size > 0) {
            // Give the first task more air when there was no description above it.
            y += project.description != "" ? 12 : 24;
            y = draw_items (cr, surface, project.items, y, MARGIN);
        }

        // Sections
        var sorted_sections = new Gee.ArrayList<Objects.Section> ();
        sorted_sections.add_all (project.sections);
        sorted_sections.sort ((a, b) => {
            return a.section_order - b.section_order;
        });

        bool is_first_section = true;
        foreach (Objects.Section section in sorted_sections) {
            if (y > PAGE_HEIGHT - MARGIN - 30) {
                surface.show_page ();
                y = MARGIN;
            }

            y += (is_first_section && project.items.size <= 0) ? 24 : 12;
            is_first_section = false;

            y += draw_markup (cr, "<b>%s</b>".printf (escape (section.name)),
                              MARGIN, y, 11, PAGE_WIDTH - MARGIN * 2, "#000000");
            y += 8;

            if (section.items.size > 0) {
                y = draw_items (cr, surface, section.items, y, MARGIN);
            }
        }

        surface.show_page ();
        surface.finish ();
    }

    private double draw_items (Cairo.Context cr, Cairo.PdfSurface surface, Gee.ArrayList<Objects.Item> items, double start_y, double x) {
        double y = start_y;

        foreach (Objects.Item item in items) {
            if (y > PAGE_HEIGHT - MARGIN) {
                surface.show_page ();
                y = MARGIN;
            }

            // Build the whole task line as one Pango markup string so emoji,
            // per-span colors and wrapping are all resolved together.
            var markup = new StringBuilder ();

            // Checkbox
            markup.append (item.checked ? "- [x] " : "- [ ] ");

            // Due date prefix
            if (item.has_due) {
                string date_str = "[%s] ".printf (
                    Utils.Datetime.get_relative_date_from_date (item.due.datetime));
                markup.append ("<span size='9000' foreground='#666666'>%s</span>"
                    .printf (escape (date_str)));
            }

            // Title
            string title_color = item.checked ? "#808080" : "#000000";
            markup.append ("<span foreground='%s'>%s</span>"
                .printf (title_color, escape (item.content)));

            // Priority
            if (item.priority != Constants.PRIORITY_4) {
                markup.append ("<span size='9000' foreground='%s'> (P%d)</span>"
                    .printf (priority_hex (item.priority), 4 - item.priority + 1));
            }

            // Deadline
            if (item.has_deadline) {
                string deadline_str = " · %s %s".printf (_("Deadline:"),
                    Utils.Datetime.get_relative_time_from_date (item.deadline_datetime));
                markup.append ("<span size='9000' foreground='#808080'>%s</span>"
                    .printf (escape (deadline_str)));
            }

            // Labels — each in its own color, appended after the title.
            foreach (Objects.Label label in item.labels) {
                markup.append ("<span size='9000' foreground='%s'>  %s</span>"
                    .printf (Util.get_default ().get_color (label.color), escape (label.name)));
            }

            double line_h = draw_markup (cr, markup.str, x, y, 11,
                                         PAGE_WIDTH - MARGIN - x, "#000000");
            y += line_h;

            // Description — indented under the task text.
            if (item.description.strip () != "") {
                y += 3;
                double desc_x = x + 22; // roughly the checkbox width, aligns under the title
                y += draw_markup (cr, escape (item.description), desc_x, y, 9,
                                  PAGE_WIDTH - MARGIN - desc_x, "#808080");
                y += 4;
            } else {
                y += 6;
            }

            // Sub-items
            if (item.items.size > 0) {
                y = draw_items (cr, surface, item.items, y, x + 20);
            }
        }

        return y;
    }

    /**
     * Render Pango markup at (x, y) wrapped to `wrap_width`, using the system
     * font stack (so emoji and missing glyphs fall back correctly). Returns the
     * height consumed so the caller can advance y.
     */
    private double draw_markup (Cairo.Context cr, string markup, double x, double y,
                                int size_pt, double wrap_width, string default_hex) {
        var layout = Pango.cairo_create_layout (cr);

        // Pango defaults to 96 DPI, but a PDF surface works in 72-point units,
        // so sizes came out ~33% too large. Pin the layout's font resolution to
        // 72 DPI so a Pango size in points matches Cairo's user-space points.
        Pango.cairo_context_set_resolution (layout.get_context (), 72.0);

        var font = new Pango.FontDescription ();
        font.set_family ("Sans");
        font.set_size (size_pt * Pango.SCALE);
        layout.set_font_description (font);

        layout.set_width ((int) (wrap_width * Pango.SCALE));
        layout.set_wrap (Pango.WrapMode.WORD_CHAR); // wrap on words, break long words too

        try {
            layout.set_markup (markup, -1);
        } catch (Error e) {
            // Fall back to plain text if the markup is somehow invalid.
            layout.set_text (markup, -1);
        }

        var rgba = Gdk.RGBA ();
        if (!rgba.parse (default_hex)) {
            rgba.parse ("#000000");
        }
        cr.set_source_rgb (rgba.red, rgba.green, rgba.blue);

        cr.move_to (x, y);
        Pango.cairo_show_layout (cr, layout);

        int w, h;
        layout.get_pixel_size (out w, out h);
        return (double) h;
    }

    private string escape (string text) {
        return Markup.escape_text (text);
    }

    private string priority_hex (int priority) {
        switch (priority) {
            case Constants.PRIORITY_1: return "#ff7066"; // red
            case Constants.PRIORITY_2: return "#ff9914"; // orange
            case Constants.PRIORITY_3: return "#5297ff"; // blue
            default: return "#666666";
        }
    }
}
