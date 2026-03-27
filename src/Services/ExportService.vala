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
        cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
        cr.set_font_size (24);
        cr.set_source_rgb (0, 0, 0);
        y += 24;
        cr.move_to (MARGIN, y);
        cr.show_text (project.name);

        // Description
        if (project.description != "") {
            y += 24;
            cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
            cr.set_font_size (11);
            cr.set_source_rgb (0.4, 0.4, 0.4);

            foreach (string line in wrap_text (cr, project.description, PAGE_WIDTH - MARGIN * 2)) {
                cr.move_to (MARGIN, y);
                cr.show_text (line);
                y += 16;
            }
        }

        // Due date
        if (project.due_date != "") {
            y += 6;
            cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
            cr.set_font_size (10);
            cr.set_source_rgb (0.3, 0.3, 0.3);
            cr.move_to (MARGIN, y);

            var datetime = Utils.Datetime.get_date_from_string (project.due_date);
            if (datetime != null) {
                cr.show_text ("%s: %s".printf (_("Deadline"), Utils.Datetime.get_short_date_format_from_date (datetime)));
            }
        }

        // Tasks without section
        if (project.items.size > 0) {
            y += 12;
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

            if (is_first_section && project.items.size <= 0) {
                y += 24;
            } else {
                y += 12;
            }

            is_first_section = false;
            cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size (11);
            cr.set_source_rgb (0, 0, 0);
            cr.move_to (MARGIN, y);
            cr.show_text (section.name);
            y += 24;

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

            string checkbox = item.checked ? "- [x]" : "- [ ]";

            cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
            cr.set_font_size (11);
            cr.set_source_rgb (0.3, 0.3, 0.3);
            cr.move_to (x, y);
            cr.show_text (checkbox);

            Cairo.TextExtents extents;
            cr.text_extents (checkbox + " ", out extents);
            double text_x = x + extents.x_advance;

            // Due date
            if (item.has_due) {
                string date_str = "[%s] ".printf (Utils.Datetime.get_relative_date_from_date (item.due.datetime));
                cr.set_source_rgb (0.4, 0.4, 0.4);
                cr.set_font_size (9);
                cr.move_to (text_x, y);
                cr.show_text (date_str);

                Cairo.TextExtents date_extents;
                cr.text_extents (date_str, out date_extents);
                text_x += date_extents.x_advance;
            }

            // Title
            cr.set_font_size (11);
            if (item.checked) {
                cr.set_source_rgb (0.5, 0.5, 0.5);
            } else {
                cr.set_source_rgb (0, 0, 0);
            }

            cr.move_to (text_x, y);
            cr.show_text (item.content);

            // Priority
            if (item.priority != Constants.PRIORITY_4) {
                string priority_str = " (P%d)".printf (4 - item.priority + 1);
                Cairo.TextExtents content_extents;
                cr.text_extents (item.content, out content_extents);

                cr.set_font_size (9);
                set_priority_color (cr, item.priority);
                cr.move_to (text_x + content_extents.x_advance, y);
                cr.show_text (priority_str);

                Cairo.TextExtents priority_extents;
                cr.text_extents (priority_str, out priority_extents);
                text_x += content_extents.x_advance + priority_extents.x_advance;
            } else {
                Cairo.TextExtents content_extents;
                cr.text_extents (item.content, out content_extents);
                text_x += content_extents.x_advance;
            }

            // Deadline
            if (item.has_deadline) {
                string deadline_str = " · %s %s".printf (_("Deadline:"), Utils.Datetime.get_relative_time_from_date (item.deadline_datetime));
                cr.set_font_size (9);
                cr.set_source_rgb (0.5, 0.5, 0.5);
                cr.move_to (text_x, y);
                cr.show_text (deadline_str);
            }

            y += 20;

            // Sub-items
            if (item.items.size > 0) {
                y = draw_items (cr, surface, item.items, y, x + 20);
            }
        }

        return y;
    }

    private Gee.ArrayList<string> wrap_text (Cairo.Context cr, string text, double max_width) {
        var lines = new Gee.ArrayList<string> ();
        string[] paragraphs = text.split ("\n");

        foreach (string paragraph in paragraphs) {
            if (paragraph.strip () == "") {
                lines.add ("");
                continue;
            }

            string[] words = paragraph.split (" ");
            string current_line = "";

            foreach (string word in words) {
                string test_line = current_line == "" ? word : current_line + " " + word;
                Cairo.TextExtents extents;
                cr.text_extents (test_line, out extents);

                if (extents.width > max_width && current_line != "") {
                    lines.add (current_line);
                    current_line = word;
                } else {
                    current_line = test_line;
                }
            }

            if (current_line != "") {
                lines.add (current_line);
            }
        }

        return lines;
    }

    private void set_priority_color (Cairo.Context cr, int priority) {
        switch (priority) {
            case Constants.PRIORITY_1: // P1 - red
                cr.set_source_rgb (1.0, 0.44, 0.40);
                break;
            case Constants.PRIORITY_2: // P2 - orange
                cr.set_source_rgb (1.0, 0.60, 0.08);
                break;
            case Constants.PRIORITY_3: // P3 - blue
                cr.set_source_rgb (0.32, 0.59, 1.0);
                break;
            default:
                cr.set_source_rgb (0.4, 0.4, 0.4);
                break;
        }
    }
}
