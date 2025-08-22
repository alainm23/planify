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

public class Objects.Project : Objects.BaseObject {
    public string parent_id { get; set; default = ""; }
    public string due_date { get; set; default = ""; }
    public string color { get; set; default = ""; }
    public string emoji { get; set; default = ""; }
    public string description { get; set; default = ""; }
    public ProjectIconStyle icon_style { get; set; default = ProjectIconStyle.PROGRESS; }
    public SourceType backend_type { get; set; default = SourceType.NONE; }
    public bool inbox_project { get; set; default = false; }
    public bool team_inbox { get; set; default = false; }
    public bool is_deleted { get; set; default = false; }
    public bool is_archived { get; set; default = false; }
    public bool is_favorite { get; set; default = false; }
    public bool shared { get; set; default = false; }
    public bool collapsed { get; set; default = false; }
    public bool inbox_section_hidded { get; set; default = false; }
    public string sync_id { get; set; default = ""; }
    public string source_id { get; set; default = SourceType.LOCAL.to_string (); }
    public string calendar_url { get; set; default = ""; }

    bool _show_completed = false;
    public bool show_completed {
        get {
            return _show_completed;
        }

        set {
            _show_completed = value;
            show_completed_changed ();
        }
    }

    ProjectViewStyle _view_style = ProjectViewStyle.LIST;
    public ProjectViewStyle view_style {
        get {
            return _view_style;
        }

        set {
            _view_style = value;
            view_style_changed ();
        }
    }

    public SourceType source_type {
        get {
            return source.source_type;
        }
    }

    Objects.Source ? _source;
    public Objects.Source source {
        get {
            _source = Services.Store.instance ().get_source (source_id);
            return _source;
        }
    }

    string _color_hex;
    public string color_hex {
        get {
            _color_hex = Util.get_default ().get_color (color);
            return _color_hex;
        }
    }

    int _sort_order = 0;
    public int sort_order {
        get {
            return _sort_order;
        }

        set {
            _sort_order = value;
            sort_order_changed ();
        }
    }

    public int child_order { get; set; default = 0; }

    string _view_id;
    public string view_id {
        get {
            _view_id = "project-%s".printf (id_string);
            return _view_id;
        }
    }

    string _parent_id_string;
    public string parent_id_string {
        get {
            _parent_id_string = parent_id.to_string ();
            return _parent_id_string;
        }
    }

    string _short_name;
    public string short_name {
        get {
            _short_name = Util.get_default ().get_short_name (name);
            return _short_name;
        }
    }

    public bool is_inbox_project {
        get {
            return id == Services.Settings.get_default ().settings.get_string ("local-inbox-project-id");
        }
    }

    Gee.ArrayList<Objects.Section> _sections = null;
    public Gee.ArrayList<Objects.Section> sections {
        get {
            if (_sections == null) {
                _sections = Services.Store.instance ().get_sections_by_project (this);
            }

            return _sections;
        }
    }

    Gee.ArrayList<Objects.Section> _sections_archived;
    public Gee.ArrayList<Objects.Section> sections_archived {
        get {
            _sections_archived = Services.Store.instance ().get_sections_archived_by_project (this);
            return _sections_archived;
        }
    }

    Gee.ArrayList<Objects.Item> _items;
    public Gee.ArrayList<Objects.Item> items {
        get {
            _items = Services.Store.instance ().get_item_by_baseobject (this);
            _items.sort ((a, b) => {
                if (a.child_order > b.child_order) {
                    return 1;
                }
                if (a.child_order == b.child_order) {
                    return 0;
                }

                return -1;
            });

            return _items;
        }
    }

    Gee.ArrayList<Objects.Item> _items_checked;
    public Gee.ArrayList<Objects.Item> items_checked {
        get {
            _items_checked = Services.Store.instance ().get_items_checked_by_project (this);
            return _items_checked;
        }
    }

    Gee.ArrayList<Objects.Item> _all_items;
    public Gee.ArrayList<Objects.Item> all_items {
        get {
            _all_items = Services.Store.instance ().get_items_by_project (this);
            return _all_items;
        }
    }

    Gee.ArrayList<Objects.Item> _items_pinned;
    public Gee.ArrayList<Objects.Item> items_pinned {
        get {
            _items_pinned = Services.Store.instance ().get_items_by_project_pinned (this);
            return _items_pinned;
        }
    }

    Gee.ArrayList<Objects.Project> _subprojects;
    public Gee.ArrayList<Objects.Project> subprojects {
        get {
            _subprojects = Services.Store.instance ().get_subprojects (this);
            return _subprojects;
        }
    }

    Objects.Project ? _parent;
    public Objects.Project parent {
        get {
            _parent = Services.Store.instance ().get_project (parent_id);
            return _parent;
        }
    }

    public signal void section_added (Objects.Section section);
    public signal void subproject_added (Objects.Project project);
    public signal void item_added (Objects.Item item);
    public signal void item_deleted (Objects.Item item);
    public signal void show_completed_changed ();
    public signal void sort_order_changed ();
    public signal void section_sort_order_changed ();
    public signal void view_style_changed ();

    int ? _project_count = null;
    public int project_count {
        get {
            if (_project_count == null) {
                _project_count = update_project_count ();
            }

            return _project_count;
        }

        set {
            _project_count = value;
        }
    }

    double ? _percentage = null;
    public double percentage {
        get {
            if (_percentage == null) {
                _percentage = update_percentage ();
            }

            return _percentage;
        }
    }

    private bool _show_multi_select = false;
    public bool show_multi_select {
        set {
            _show_multi_select = value;
            show_multi_select_change ();
        }

        get {
            return _show_multi_select;
        }
    }

    // TODO: ID is deprecated, not valid for every caldav implementation
    // TODO: Also check why is_deck is needed
    public bool is_deck {
        get {
            return id.contains ("deck--board");
        }
    }

    public signal void loading_changed (bool value);
    public signal void project_count_updated ();
    public signal void show_multi_select_change ();

    construct {
        Services.EventBus.get_default ().checked_toggled.connect ((item) => {
            if (item.project_id == id) {
                project_count_update ();
            }
        });

        Services.Store.instance ().item_deleted.connect ((item) => {
            if (item.project_id == id) {
                project_count_update ();
            }
        });

        Services.Store.instance ().item_added.connect ((item) => {
            if (item.project_id == id) {
                project_count_update ();
            }
        });

        Services.EventBus.get_default ().item_moved.connect ((item, old_project_id) => {
            if (item.project_id == id || old_project_id == id) {
                project_count_update ();
            }
        });

        Services.Store.instance ().section_moved.connect ((section, old_project_id) => {
            if (section.project_id == id || old_project_id == id) {
                project_count_update ();
            }
        });

        Services.Store.instance ().item_archived.connect ((item) => {
            if (item.project_id == id) {
                project_count_update ();
            }
        });

        Services.Store.instance ().item_unarchived.connect ((item) => {
            if (item.project_id == id) {
                project_count_update ();
            }
        });
    }

    private void project_count_update () {
        _project_count = update_project_count ();
        _percentage = update_percentage ();
        project_count_updated ();
    }

    public Project.from_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        update_from_json (node);
        backend_type = SourceType.TODOIST;
    }

    public Project.from_google_tasklist_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        update_from_google_tasklist_json (node);
        backend_type = SourceType.GOOGLE_TASKS;
    }

    public Project.from_propstat (Services.CalDAV.WebDAVPropStat propstat, string url) {
        var resource_id = propstat.get_first_prop_with_tagname ("resource-id").text_content;
        print ("Project Resource ID is: %s", resource_id); // TODO: Debugging check if this gives us an alternative id, instead of having to generate one ourself

        id = Util.get_default ().generate_id (this); // THIS ID is INTERNAL and no longer used for requests
        calendar_url = url;
        update_from_propstat (propstat);
        backend_type = SourceType.CALDAV;
    }

    // TODO: add extra null checks
    public void update_from_propstat (Services.CalDAV.WebDAVPropStat propstat, bool update_sync_token = true) {
        name = propstat.get_first_prop_with_tagname ("displayname").text_content;
        if (propstat.get_first_prop_with_tagname ("calendar-color") != null) {
            color = propstat.get_first_prop_with_tagname ("calendar-color").text_content;
        }
        if (update_sync_token) {
            sync_id = propstat.get_first_prop_with_tagname ("sync-token").text_content;
        }
    }

    public string get_id_from_url (GXml.DomElement element) {
        if (element.get_elements_by_tag_name ("d:href").length <= 0) {
            return "";
        }

        GXml.DomElement href = element.get_elements_by_tag_name ("d:href").get_element (0);
        string[] parts = href.text_content.split ("/");
        return parts[parts.length - 2];
    }

    public string get_content (GXml.DomElement element) {
        return element.text_content;
    }

    public Project.from_import_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        name = node.get_object ().get_string_member ("name");
        color = node.get_object ().get_string_member ("color");
        backend_type = SourceType.parse (node.get_object ().get_string_member ("backend_type"));
        inbox_project = node.get_object ().get_boolean_member ("inbox_project");
        team_inbox = node.get_object ().get_boolean_member ("team_inbox");
        child_order = (int32) node.get_object ().get_int_member ("child_order");
        is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        is_archived = node.get_object ().get_boolean_member ("is_archived");
        is_favorite = node.get_object ().get_boolean_member ("is_favorite");
        shared = node.get_object ().get_boolean_member ("shared");
        view_style = node.get_object ().get_string_member ("view_style") == "board" ? ProjectViewStyle.BOARD : ProjectViewStyle.LIST;
        sort_order = (int32) node.get_object ().get_int_member ("sort_order");
        parent_id = node.get_object ().get_string_member ("parent_id");
        collapsed = node.get_object ().get_boolean_member ("collapsed");
        icon_style = node.get_object ().get_string_member ("icon_style") == "progress" ? ProjectIconStyle.PROGRESS : ProjectIconStyle.EMOJI;
        emoji = node.get_object ().get_string_member ("emoji");
        show_completed = node.get_object ().get_boolean_member ("show_completed");
        description = node.get_object ().get_string_member ("description");
        due_date = node.get_object ().get_string_member ("due_date");

        if (node.get_object ().has_member ("source_id")) {
            source_id = node.get_object ().get_string_member ("source_id");
        }

        if (node.get_object ().has_member ("calendar_url")) {
            calendar_url = node.get_object ().get_string_member ("calendar_url");
        }
    }

    public void update_from_json (Json.Node node) {
        name = node.get_object ().get_string_member ("name");

        if (!node.get_object ().get_null_member ("color")) {
            color = node.get_object ().get_string_member ("color");
        }

        if (!node.get_object ().get_null_member ("is_deleted")) {
            is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        }

        if (!node.get_object ().get_null_member ("is_archived")) {
            is_archived = node.get_object ().get_boolean_member ("is_archived");
        }

        if (!node.get_object ().get_null_member ("is_favorite")) {
            is_favorite = node.get_object ().get_boolean_member ("is_favorite");
        }

        if (!node.get_object ().get_null_member ("child_order")) {
            child_order = (int32) node.get_object ().get_int_member ("child_order");
        }

        if (!node.get_object ().get_null_member ("parent_id")) {
            parent_id = node.get_object ().get_string_member ("parent_id");
        } else {
            parent_id = "";
        }

        if (node.get_object ().has_member ("team_inbox") && !node.get_object ().get_null_member ("team_inbox")) {
            team_inbox = node.get_object ().get_boolean_member ("team_inbox");
        }

        if (node.get_object ().has_member ("inbox_project") && !node.get_object ().get_null_member ("inbox_project")) {
            inbox_project = node.get_object ().get_boolean_member ("inbox_project");
        }

        shared = node.get_object ().get_boolean_member ("shared");

        view_style = node.get_object ().get_string_member ("view_style") == "board" ?
                     ProjectViewStyle.BOARD : ProjectViewStyle.LIST;
    }

    public void update_from_google_tasklist_json (Json.Node node) {
        name = node.get_object ().get_string_member ("title");
    }

    public void update_local () {
        Services.Store.instance ().update_project (this);
    }

    public void update (bool use_timeout = true, bool show_loading = true) {
        if (update_timeout_id != 0) {
            GLib.Source.remove (update_timeout_id);
        }

        uint timeout = Constants.UPDATE_TIMEOUT;
        if (use_timeout) {
            timeout = 0;
        }

        update_timeout_id = Timeout.add (timeout, () => {
            update_timeout_id = 0;

            if (backend_type == SourceType.LOCAL) {
                Services.Store.instance ().update_project (this);
            } else if (backend_type == SourceType.TODOIST) {
                if (show_loading) {
                    loading = true;
                }

                Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                    Services.Todoist.get_default ().update.end (res);
                    Services.Store.instance ().update_project (this);
                    loading = false;
                });
            } else if (backend_type == SourceType.CALDAV) {
                if (show_loading) {
                    loading = true;
                }

                Services.CalDAV.Core.get_default ().update_tasklist.begin (this, (obj, res) => {
                    Services.CalDAV.Core.get_default ().update_tasklist.end (res);
                    Services.Store.instance ().update_project (this);
                    loading = false;
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public Objects.Project ? add_subproject_if_not_exists (Objects.Project new_project) {
        Objects.Project ? return_value = null;
        lock (subprojects) {
            return_value = get_subproject (new_project.id);
            if (return_value == null) {
                new_project.set_parent (this);
                Services.Store.instance ().insert_project (new_project);
                return_value = new_project;
            }
            return return_value;
        }
    }

    public Objects.Project ? get_subproject (string id) {
        Objects.Project ? return_value = null;
        lock (_subprojects) {
            foreach (var project in subprojects) {
                if (project.id == id) {
                    return_value = project;
                    break;
                }
            }
        }
        return return_value;
    }

    public void set_parent (Objects.Project project) {
        this._parent = project;
    }

    public Objects.Section add_section_if_not_exists (Objects.Section new_section) {
        Objects.Section ? return_value = null;
        lock (_sections) {
            return_value = get_section (new_section.id);
            if (return_value == null) {
                new_section.set_project (this);
                new_section.section_order = new_section.project.sections.size;
                add_section (new_section);
                Services.Store.instance ().insert_section (new_section);
                return_value = new_section;
            }
            return return_value;
        }
    }

    public Objects.Section ? get_section (string id) {
        Objects.Section ? return_value = null;
        lock (_sections) {
            foreach (var section in sections) {
                if (section.id == id) {
                    return_value = section;
                    break;
                }
            }
        }
        return return_value;
    }

    public void add_section (Objects.Section section) {
        this._sections.add (section);
        section.deleted.connect (() => {
            _sections.remove (section);
        });
    }

    public Objects.Item add_item_if_not_exists (Objects.Item new_item, bool insert = true) {
        Objects.Item ? return_value = null;
        lock (_items) {
            return_value = get_item (new_item.id);
            if (return_value == null) {
                new_item.set_project (this);
                add_item (new_item);
                Services.Store.instance ().insert_item (new_item, insert);
                return_value = new_item;
            }
            return return_value;
        }
    }

    public void add_item (Objects.Item item) {
        _items.add (item);
        item_added (item);
    }

    public Objects.Item ? get_item (string id) {
        Objects.Item ? return_value = null;
        lock (_items) {
            foreach (var item in items) {
                if (item.id == id) {
                    return_value = item;
                    break;
                }
            }
        }
        return return_value;
    }

    public override string get_add_json (string temp_id, string uuid) {
        return get_update_json (uuid, temp_id);
    }

    public override string get_update_json (string uuid, string ? temp_id = null) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("commands");
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value (temp_id == null ? "project_update" : "project_add");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        if (temp_id != null) {
            builder.set_member_name ("temp_id");
            builder.add_string_value (temp_id);
        }

        builder.set_member_name ("args");
        builder.begin_object ();

        if (temp_id == null) {
            builder.set_member_name ("id");
            builder.add_string_value (id);
        }

        builder.set_member_name ("name");
        builder.add_string_value (name);

        builder.set_member_name ("color");
        builder.add_string_value (color);

        builder.set_member_name ("collapsed");
        builder.add_boolean_value (collapsed);

        builder.set_member_name ("is_favorite");
        builder.add_boolean_value (is_favorite);

        if (parent_id != "") {
            builder.set_member_name ("parent_id");
            builder.add_string_value (parent_id);
        } else {
            builder.set_member_name ("parent_id");
            builder.add_null_value ();
        }

        builder.end_object ();
        builder.end_object ();
        builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);
        return generator.to_data (null);
    }

    public override string to_json () {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("id");
        builder.add_string_value (id);

        builder.set_member_name ("name");
        builder.add_string_value (Util.get_default ().get_encode_text (name));

        builder.set_member_name ("color");
        builder.add_string_value (color);

        builder.set_member_name ("collapsed");
        builder.add_boolean_value (collapsed);

        builder.set_member_name ("is_favorite");
        builder.add_boolean_value (is_favorite);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public override string get_move_json (string uuid, string new_parent_id) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value ("project_move");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        builder.set_member_name ("args");
        builder.begin_object ();

        builder.set_member_name ("id");
        builder.add_string_value (id);

        if (new_parent_id != "") {
            builder.set_member_name ("parent_id");
            builder.add_string_value (new_parent_id);
        } else {
            builder.set_member_name ("parent_id");
            builder.add_null_value ();
        }

        builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public string to_string () {
        return """
        _________________________________
            ID: %s
            NAME: %s
            DESCRIPTION: %s
            COLOR: %s
            BACKEND TYPE: %s
            INBOX: %s
            TEAM INBOX: %s
            CHILD ORDER: %i
            DELETED: %s
            ARCHIVED: %s
            FAVORITE: %s
            SHARED: %s
            VIEW: %s
            SHOW COMPLETED: %s
            SORT ORDER: %i
            COLLAPSED: %s
            PARENT ID: %s
            SOURCE ID: %s
            Calendar URL: %s
        ---------------------------------
        """.printf (
            id,
            name,
            description,
            color,
            backend_type.to_string (),
            inbox_project.to_string (),
            team_inbox.to_string (),
            child_order,
            is_deleted.to_string (),
            is_archived.to_string (),
            is_favorite.to_string (),
            shared.to_string (),
            view_style.to_string (),
            show_completed.to_string (),
            sort_order,
            collapsed.to_string (),
            parent_id.to_string (),
            source_id,
            calendar_url
        );
    }

    private int update_project_count () {
        int pending_tasks = 0;
        var items = Services.Store.instance ().get_items_by_project (this);
        foreach (Objects.Item item in items) {
            if (!item.checked && !item.was_archived ()) {
                pending_tasks++;
            }
        }

        return pending_tasks;
    }

    public double update_percentage () {
        int items_total = 0;
        int items_checked = 0;

        foreach (Objects.Item item in Services.Store.instance ().get_items_by_project (this)) {
            if (!item.was_archived ()) {
                items_total++;
                if (item.checked) {
                    items_checked++;
                }
            }
        }

        if (items_total == 0) {
            return 0.0;
        }

        return (double) items_checked / (double) items_total;
    }

    public void share_markdown () {
        Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
        clipboard.set_text (to_markdown ());
        Services.EventBus.get_default ().send_toast (
            Util.get_default ().create_toast (_("The project was copied to the Clipboard."), 0)
        );
    }

    public void share_mail () {
        string uri = "";
        uri += "mailto:?subject=%s&body=%s".printf (name, to_markdown ());
        try {
            AppInfo.launch_default_for_uri (uri, null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }

    private string to_markdown () {
        string text = "";
        text += "## %s\n".printf (name);

        foreach (Objects.Item item in items) {
            text += item.to_markdown ();
        }

        foreach (Objects.Section section in sections) {
            text += "\n";
            text += "### %s\n".printf (section.name);

            foreach (Objects.Item item in section.items) {
                text += item.to_markdown ();
            }
        }

        return text;
    }

    public void delete_project (Gtk.Window window) {
        var dialog = new Adw.AlertDialog (
            _("Delete Project %s?".printf (name)),
            _("This can not be undone")
        );

        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("delete", _("Delete"));
        dialog.close_response = "cancel";
        dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.present (window);

        dialog.response.connect ((_response) => {
            if (_response == "delete") {
                loading = true;
                if (source_type == SourceType.LOCAL) {
                    Services.Store.instance ().delete_project (this);
                } else if (source_type == SourceType.TODOIST) {
                    dialog.set_response_enabled ("cancel", false);
                    dialog.set_response_enabled ("delete", false);

                    Services.Todoist.get_default ().delete.begin (this, (obj, res) => {
                        HttpResponse response = Services.Todoist.get_default ().delete.end (res);
                        loading = false;

                        if (response.status) {
                            Services.Store.instance ().delete_project (this);
                        } else {
                            Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                        }
                    });
                } else if (source_type == SourceType.CALDAV) {
                    dialog.set_response_enabled ("cancel", false);
                    dialog.set_response_enabled ("delete", false);

                    Services.CalDAV.Core.get_default ().delete_tasklist.begin (this, (obj, res) => {
                        HttpResponse response = Services.CalDAV.Core.get_default ().delete_tasklist.end (res);
                        loading = false;

                        if (response.status) {
                            Services.Store.instance ().delete_project (this);
                        } else {
                            Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                        }
                    });
                }
            }
        });
    }

    public void archive_project (Gtk.Window window) {
        var dialog = new Adw.AlertDialog (
            _("Archive?"),
            _("This will archive %s and all its tasks.".printf (name))
        );

        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("archive", _("Archive"));
        dialog.close_response = "cancel";
        dialog.set_response_appearance ("archive", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.present (window);

        dialog.response.connect ((response) => {
            if (response == "archive") {
                is_archived = true;
                Services.Store.instance ().archive_project (this);
            }
        });
    }

    public void unarchive_project () {
        is_archived = false;
        Services.Store.instance ().archive_project (this);
    }

    public Objects.Project duplicate () {
        var new_project = new Objects.Project ();
        new_project.name = name;
        new_project.due_date = due_date;
        new_project.color = color;
        new_project.emoji = emoji;
        new_project.description = description;
        new_project.icon_style = icon_style;
        new_project.backend_type = backend_type;
        new_project.source_id = source_id;

        return new_project;
    }
}
