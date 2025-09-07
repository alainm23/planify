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

public class Objects.Backup : Object {
    public string version { get; set; default = ""; }
    public string date { get; set; default = new GLib.DateTime.now_local ().to_string (); }

    public string local_inbox_project_id { get; set; default = ""; }

    public Gee.ArrayList<Objects.Project> projects { get; set; default = new Gee.ArrayList<Objects.Project> (); }
    public Gee.ArrayList<Objects.Section> sections { get; set; default = new Gee.ArrayList<Objects.Section> (); }
    public Gee.ArrayList<Objects.Item> items { get; set; default = new Gee.ArrayList<Objects.Item> (); }
    public Gee.ArrayList<Objects.Label> labels { get; set; default = new Gee.ArrayList<Objects.Label> (); }
    public Gee.ArrayList<Objects.Source> sources { get; set; default = new Gee.ArrayList<Objects.Source> (); }

    public string path { get; set; }
    public string error { get; set; default = ""; }

    GLib.DateTime _datetime;
    public GLib.DateTime datetime {
        get {
            _datetime = new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ());
            return _datetime;
        }
    }

    private string _title;
    public string title {
        get {
            _title = datetime.format ("%c");
            return _title;
        }
    }

    public signal void deleted ();

    public Backup.from_file (File file) {
        var parser = new Json.Parser ();

        try {
            parser.load_from_file (file.get_path ());
            path = file.get_path ();

            var node = parser.get_root ().get_object ();

            version = node.get_string_member ("version");
            date = node.get_string_member ("date");

            // Set Settings
            var settings = node.get_object_member ("settings");
            local_inbox_project_id = settings.get_string_member ("local-inbox-project-id");

            // Sources
            sources.clear ();
            unowned Json.Array _sources = node.get_array_member ("sources");
            foreach (unowned Json.Node item in _sources.get_elements ()) {
                sources.add (new Objects.Source.from_import_json (item));
            }

            // Labels
            labels.clear ();
            unowned Json.Array _labels = node.get_array_member ("labels");
            foreach (unowned Json.Node item in _labels.get_elements ()) {
                labels.add (new Objects.Label.from_import_json (item));
            }

            // Projects
            projects.clear ();
            unowned Json.Array _projects = node.get_array_member ("projects");
            foreach (unowned Json.Node item in _projects.get_elements ()) {
                var _project = new Objects.Project.from_import_json (item);

                if (version == "1.0") {
                    if (_project.source_id != SourceType.CALDAV.to_string ()) {
                        projects.add (_project);
                    }
                } else {
                    projects.add (_project);
                }
            }

            // Sections
            sections.clear ();
            unowned Json.Array _sections = node.get_array_member ("sections");
            foreach (unowned Json.Node item in _sections.get_elements ()) {
                sections.add (new Objects.Section.from_import_json (item));
            }

            // Items
            items.clear ();
            unowned Json.Array _items = node.get_array_member ("items");
            foreach (unowned Json.Node item in _items.get_elements ()) {
                items.add (new Objects.Item.from_import_json (item, labels));
            }
        } catch (Error e) {
            error = e.message;
        }
    }

    public bool valid () {
        if (error != "") {
            return false;
        }

        if (version == null || version == "") {
            return false;
        }

        if (date == null || date == "") {
            return false;
        }

        if (projects.is_empty) {
            return false;
        }

        return true;
    }
}
