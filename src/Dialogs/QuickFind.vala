/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Dialogs.QuickFind : Gtk.Dialog {
    public QuickFind () {
        Object (
            transient_for: Planner.instance.main_window,
            deletable: false,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: false
        );
    }

    construct {
        get_style_context ().add_class ("planner-dialog");
        width_request = 600;

        int window_x, window_y;
        int window_width, width_height;

        Planner.settings.get ("window-position", "(ii)", out window_x, out window_y);
        Planner.settings.get ("window-size", "(ii)", out window_width, out width_height);

        move (window_x + ((window_width - width_request) / 2), window_y + 64);

        var search_label = new Gtk.Label (_("Search:"));
        search_label.get_style_context ().add_class ("h3");

        var search_entry = new Gtk.SearchEntry ();
        search_entry.hexpand = true;

        var top_grid = new Gtk.Grid ();
        top_grid.column_spacing = 12;
        top_grid.margin_start = 34;
        top_grid.margin_end = 16;
        top_grid.add (search_label);
        top_grid.add (search_entry);

        var listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("background");
        listbox.hexpand = true;

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.height_request = 250;
        listbox_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = 16;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.pack_start (top_grid, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (listbox_scrolled, true, true, 0);

        get_content_area ().add (main_box);

        search_entry.search_changed.connect (() => {
            listbox.foreach ((widget) => {
                widget.destroy ();
            });

            if (search_entry.text != "") {
                foreach (var item in Planner.database.get_items_by_search (search_entry.text)) {
                    var row = new SearchItem (
                        "item",
                        item.content,
                        search_entry.text
                    );
    
                    listbox.add (row);
                    listbox.show_all ();
                }

                foreach (var project in Planner.database.get_all_projects_by_search (search_entry.text)) {
                    var row = new SearchItem (
                        "project",
                        project.name,
                        search_entry.text
                    );

                    listbox.add (row);
                    listbox.show_all ();
                }
            } else {

            }
        });
    }
}

public class SearchItem : Gtk.ListBoxRow {
    public string result_type { get; construct; }
    public string content { get; construct; }
    public string search_text { get; construct; }

    public SearchItem (string result_type, string content, string search_text) {
        Object (
            result_type: result_type,
            content: content,
            search_text: search_text
        );
    }

    construct {
        get_style_context ().add_class ("searchitem-row");
        if (result_type == "item") {
            var header_label = new Gtk.Label (_("Tasks"));
            header_label.get_style_context ().add_class ("h3");
            header_label.width_request = 84;
            header_label.xalign = 1;
            header_label.margin_end  = 12;

            var checked_button = new Gtk.CheckButton ();
            checked_button.valign = Gtk.Align.CENTER;
            //checked_button.margin_top = 1;
            checked_button.get_style_context ().add_class ("checklist-button");

            var content_label = new Gtk.Label (content.replace (search_text, "<b>%s</b>".printf (search_text)));
            content_label.wrap = true;
            content_label.xalign = 0;
            content_label.use_markup = true;
            content_label.get_style_context ().add_class ("label");

            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.column_spacing = 6;
            grid.add (checked_button);
            grid.add (content_label);

            var main_grid = new Gtk.Grid ();
            main_grid.attach (header_label, 0, 0, 1, 1);
            main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 1);
            main_grid.attach (grid, 2, 0, 1, 1);

            add (main_grid);
        } else if (result_type == "project") {
            var header_label = new Gtk.Label (_("Projects"));
            header_label.get_style_context ().add_class ("h3");
            header_label.width_request = 84;
            header_label.xalign = 1;
            header_label.margin_end  = 12;

            var project_progress = new Widgets.ProjectProgress ();
            project_progress.line_cap = Cairo.LineCap.ROUND;
            project_progress.radius_filled = true;
            project_progress.line_width = 2;
            project_progress.valign = Gtk.Align.CENTER;
            project_progress.halign = Gtk.Align.CENTER;
            project_progress.percentage = 0.5;
            //project_progress.progress_fill_color = Planner.utils.get_color (project.color);

            var content_label = new Gtk.Label (content.replace (search_text, "<b>%s</b>".printf (search_text)));
            content_label.wrap = true;
            content_label.xalign = 0;
            content_label.use_markup = true;
            content_label.get_style_context ().add_class ("label");

            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.margin_start = 4;
            grid.column_spacing = 3;
            grid.add (project_progress);
            grid.add (content_label);

            var main_grid = new Gtk.Grid ();
            main_grid.attach (header_label, 0, 0, 1, 1);
            main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 1);
            main_grid.attach (grid, 2, 0, 1, 1);

            add (main_grid);
        }
    }
    //  public string title { get; construct; }
    //  public int64 id { get; construct; }
    //  public int64 project_id { get; construct; }
    //  public string icon { get; construct; }
    //  public string element { get; construct; }

    //  public SearchItem (string title, string icon, string element, int64 id, int64 project_id=0) {
    //      Object (
    //          title: title,
    //          icon: icon,
    //          element: element,
    //          id: id,
    //          project_id: project_id
    //      );
    //  }

    //  construct {
    //      margin_start = margin_end = 6;
    //      get_style_context ().add_class ("pane-row");

    //      var image = new Gtk.Image ();
    //      image.gicon = new ThemedIcon (icon);
    //      image.pixel_size = 16;

    //      var title_label = new Gtk.Label (title);
    //      //title_label.get_style_context ().add_class ("h3");
    //      title_label.ellipsize = Pango.EllipsizeMode.END;
    //      //title_label.use_markup = true;

    //      var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
    //      box.hexpand = true;
    //      box.margin = 6;
    //      box.pack_start (image, false, false, 0);
    //      box.pack_start (title_label, false, false, 0);

    //      add (box);
    //  }
}