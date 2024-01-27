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

public class Objects.Item : Objects.BaseObject {
    public string content { get; set; default = ""; }
    public string description { get; set; default = ""; }
    public string added_at { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string completed_at { get; set; default = ""; }
    public string updated_at { get; set; default = ""; }
    public string section_id { get; set; default = ""; }
    public string project_id { get; set; default = ""; }
    public string parent_id { get; set; default = ""; }
    public string extra_data { get; set; default = ""; }

    public Objects.DueDate due { get; set; default = new Objects.DueDate (); }
    public Gee.ArrayList<Objects.Label> labels { get; set; default = new Gee.ArrayList<Objects.Label> (); }

    public Gee.ArrayList<Objects.Label> _get_labels () {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();

        foreach (Objects.Label label in labels) {
            return_value.add (label);
        }

        return return_value;
    }

    public int priority { get; set; default = Constants.PRIORITY_4; }

    public bool activate_name_editable { get; set; default = false; }

    public string priority_icon {
        get {
            if (priority == Constants.PRIORITY_1) {
                return "planner-priority-1";
            } else if (priority == Constants.PRIORITY_2) {
                return "planner-priority-2";
            } else if (priority == Constants.PRIORITY_3) {
                return "planner-priority-3";
            } else {
                return "planner-flag";
            }
        }
    }

    public string priority_color {
        get {
            if (priority == Constants.PRIORITY_1) {
                return "#ff7066";
            } else if (priority == Constants.PRIORITY_2) {
                return "#ff9914";
            } else if (priority == Constants.PRIORITY_3) {
                return "#5297ff";
            } else {
                return "@text_color";
            }
        }
    }

    public string priority_text {
        get {
            if (priority == Constants.PRIORITY_1) {
                return _("Priority 1: high");
            } else if (priority == Constants.PRIORITY_2) {
                return _("Priority 2: medium");
            } else if (priority == Constants.PRIORITY_3) {
                return _("Priority 3: low");
            } else {
                return _("Priority 4: none");
            }
        }
    }

    public int child_order { get; set; default = 0; }
    public bool custom_order { get; set; default = false; }
    public int day_order { get; set; default = 0; }
    public bool checked { get; set; default = false; }
    public bool is_deleted { get; set; default = false; }

    private bool _collapsed = false;
    public bool collapsed {
        get {
            return _collapsed;
        }

        set {
            _collapsed = value;
            collapsed_change ();
        }
    }

    public bool pinned { get; set; default = false; }
    public string pinned_icon {
        get {
            return pinned ? "planner-pin-tack" : "planner-pinned";
        }
    }

    public bool completed {
        get {
            return checked;
        }
    }

    public bool has_due {
        get {
            return due.datetime != null;
        }
    }

    public bool has_section {
        get {
            return section_id != "";
        }
    }

    bool _loading = false;
    public bool loading {
        set {
            _loading = value;
            loading_changed (_loading);
        }

        get {
            return _loading;
        }
    }

    string _ics = "";
    public string ics {
        get {
            _ics = Services.Todoist.get_default ().get_string_member_by_object (extra_data, "ics");
            return _ics;
        }
    }

    string _calendar_data = "";
    public string calendar_data {
        get {
            _calendar_data = Services.Todoist.get_default ().get_string_member_by_object (extra_data, "calendar-data");
            return _calendar_data;
        }
    }

    GLib.DateTime _added_datetime;
    public GLib.DateTime added_datetime {
        get {
            _added_datetime = new GLib.DateTime.from_iso8601 (added_at, new GLib.TimeZone.local ());
            return _added_datetime;
        }
    }

    GLib.DateTime _updated_datetime;
    public GLib.DateTime updated_datetime {
        get {
            _updated_datetime = new GLib.DateTime.from_iso8601 (updated_at, new GLib.TimeZone.local ());
            return _updated_datetime;
        }
    }

    Json.Builder _builder;
    public Json.Builder builder {
        get {
            if (_builder == null) {
                _builder = new Json.Builder ();
            }

            return _builder;
        }
    }

    Objects.Item? _parent;
    public Objects.Item parent {
        get {
            _parent = Services.Database.get_default ().get_item (parent_id);
            return _parent;
        }
    }

    Objects.Project? _project;
    public Objects.Project project {
        get {
            _project = Services.Database.get_default ().get_project (project_id);
            return _project;
        }
    }

    Objects.Section? _section;
    public Objects.Section section {
        get {
            _section = Services.Database.get_default ().get_section (section_id);
            return _section;
        }
    }

    Gee.ArrayList<Objects.Item> _items;
    public Gee.ArrayList<Objects.Item> items {
        get {
            _items = Services.Database.get_default ().get_subitems (this);
            _items.sort ((a, b) => {
                if (a.child_order > b.child_order) {
                    return 1;
                } if (a.child_order == b.child_order) {
                    return 0;
                }
                
                return -1;
            });
            return _items;
        }
    }

    Gee.ArrayList<Objects.Reminder> _reminders;
    public Gee.ArrayList<Objects.Reminder> reminders {
        get {
            _reminders = Services.Database.get_default ().get_reminders_by_item (this);
            return _reminders;
        }
    }

    public signal void item_label_added (Objects.Label label);
    public signal void item_label_deleted (Objects.Label label);
    public signal void item_added (Objects.Item item);
    public signal void reminder_added (Objects.Reminder reminder);
    public signal void reminder_deleted (Objects.Reminder reminder);
    public signal void loading_changed (bool value);
    public signal void collapsed_change ();
    
    construct {
        deleted.connect (() => {
            Idle.add (() => {
                Services.Database.get_default ().item_deleted (this);
                return false;
            });
        });
    }

    public Item.from_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        project_id = node.get_object ().get_string_member ("project_id");
        content = node.get_object ().get_string_member ("content");
        description = node.get_object ().get_string_member ("description");
        checked = node.get_object ().get_boolean_member ("checked");
        priority = (int32) node.get_object ().get_int_member ("priority");
        is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        added_at = node.get_object ().get_string_member ("added_at");
        labels = get_labels_from_json (node);

        if (!node.get_object ().get_null_member ("section_id")) {
            section_id = node.get_object ().get_string_member ("section_id");
        } else {
            section_id = "";
        }

        if (!node.get_object ().get_null_member ("parent_id")) {
            parent_id = node.get_object ().get_string_member ("parent_id");
        } else {
            parent_id = "";
        }

        if (!node.get_object ().get_null_member ("completed_at")) {
            completed_at = node.get_object ().get_string_member ("completed_at");
        } else {
            completed_at = "";
        }

        if (!node.get_object ().get_null_member ("due")) {
            due.update_from_todoist_json (node.get_object ().get_object_member ("due"));
        } else {
            due.reset ();
        }
    }

    public void update_from_json (Json.Node node) {
        project_id = node.get_object ().get_string_member ("project_id");
        content = node.get_object ().get_string_member ("content");
        description = node.get_object ().get_string_member ("description");
        checked = node.get_object ().get_boolean_member ("checked");
        priority = (int32) node.get_object ().get_int_member ("priority");
        is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        added_at = node.get_object ().get_string_member ("added_at");
        check_labels (get_labels_maps_from_json (node));

        if (!node.get_object ().get_null_member ("section_id")) {
            section_id = node.get_object ().get_string_member ("section_id");
        } else {
            section_id = "";
        }

        if (!node.get_object ().get_null_member ("parent_id")) {
            parent_id = node.get_object ().get_string_member ("parent_id");
        } else {
            parent_id = "";
        }

        if (!node.get_object ().get_null_member ("completed_at")) {
            completed_at = node.get_object ().get_string_member ("completed_at");
        } else {
            completed_at = "";
        }

        if (!node.get_object ().get_null_member ("due")) {
            due.update_from_json (node.get_object ().get_object_member ("due"));
        } else {
            due.reset ();
        }
    }

    public Item.from_import_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        content = node.get_object ().get_string_member ("content");
        description = node.get_object ().get_string_member ("description");
        added_at = node.get_object ().get_string_member ("added_at");
        completed_at = node.get_object ().get_string_member ("completed_at");
        updated_at = node.get_object ().get_string_member ("updated_at");
        section_id = node.get_object ().get_string_member ("section_id");
        project_id = node.get_object ().get_string_member ("project_id");
        parent_id = node.get_object ().get_string_member ("parent_id");
        priority = (int32) node.get_object ().get_int_member ("priority");
        child_order = (int32) node.get_object ().get_int_member ("child_order");
        checked = node.get_object ().get_boolean_member ("checked");
        is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        day_order = (int32) node.get_object ().get_int_member ("day_order");
        due.update_from_json (Services.Database.get_default ().get_due_parameter (node.get_object ().get_string_member ("due")));
        collapsed = node.get_object ().get_boolean_member ("collapsed");
        pinned = node.get_object ().get_boolean_member ("pinned");
        labels = get_labels_from_json (node);
    }

    public Item.from_caldav_xml (GXml.DomElement element) {
        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        string data = prop.get_elements_by_tag_name ("cal:calendar-data").get_element (0).text_content;
        string etag = prop.get_elements_by_tag_name ("d:getetag").get_element (0).text_content;

        ICal.Component ical = new ICal.Component.from_string (data);

        id = ical.get_uid ();
        content = ical.get_summary ();

        if (ical.get_description () != null) {
            description = ical.get_description ();
        }

        if (Util.find_string_value ("PRIORITY", data) != "") {
            int _priority = int.parse (Util.find_string_value ("PRIORITY", data));
            if (_priority <= 0) {
                priority = Constants.PRIORITY_4;
            } else if (_priority >= 1 && _priority <= 4) {
                priority = Constants.PRIORITY_1;
            } else if (_priority == 5) {
                priority = Constants.PRIORITY_2;
            } else if (_priority > 5 && _priority <= 9) {
                priority = Constants.PRIORITY_3;
            } else {
                priority = Constants.PRIORITY_4;
            }
        }

        if (!ical.get_due ().is_null_time ()) {
            due.date = Util.ical_to_date_time_local (ical.get_due ()).to_string ();
        }

        parent_id = Util.find_string_value ("RELATED-TO", data);

        if (ical.get_status () == ICal.PropertyStatus.COMPLETED) {
            checked = true;
            string completed = Util.find_string_value ("COMPLETED", data);
            if (completed != "") {
                completed_at = Util.get_default ().get_format_date (
                    Util.ical_to_date_time_local (new ICal.Time.from_string (completed))
                ).to_string ();
            } else {
                completed_at = Util.get_default ().get_format_date (new GLib.DateTime.now_local ()).to_string ();
            }
        } else {
            checked = false;
            completed_at = "";
        }

        var categories = Util.find_string_value ("CATEGORIES", data);
        if (categories != "") {
            labels = get_caldav_categories (categories);
        }

        pinned = Util.find_boolean_value ("X-PINNED", data);
        extra_data = Util.generate_extra_data (Util.get_task_id_from_url (element), etag, ical.as_ical_string ());
    }

    public void update_from_caldav_xml (GXml.DomElement element) {
        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        string data = prop.get_elements_by_tag_name ("cal:calendar-data").get_element (0).text_content;
        string etag = prop.get_elements_by_tag_name ("d:getetag").get_element (0).text_content;

        ICal.Component ical = new ICal.Component.from_string (data);

        id = ical.get_uid ();
        content = ical.get_summary ();

        if (ical.get_description () != null) {
            description = ical.get_description ();
        }

        if (Util.find_string_value ("PRIORITY", data) != "") {
            int _priority = int.parse (Util.find_string_value ("PRIORITY", data));
            if (_priority <= 0) {
                priority = Constants.PRIORITY_4;
            } else if (_priority >= 1 && _priority <= 4) {
                priority = Constants.PRIORITY_1;
            } else if (_priority == 5) {
                priority = Constants.PRIORITY_2;
            } else if (_priority > 5 && _priority <= 9) {
                priority = Constants.PRIORITY_3;
            } else {
                priority = Constants.PRIORITY_4;
            }
        }

        if (!ical.get_due ().is_null_time ()) {
            due.date = Util.ical_to_date_time_local (ical.get_due ()).to_string ();
        }

        parent_id = Util.find_string_value ("RELATED-TO", data);

        if (ical.get_status () == ICal.PropertyStatus.COMPLETED) {
            checked = true;
            string completed = Util.find_string_value ("COMPLETED", data);
            if (completed != "") {
                completed_at = Util.get_default ().get_format_date (
                    Util.ical_to_date_time_local (new ICal.Time.from_string (completed))
                ).to_string ();
            } else {
                completed_at = Util.get_default ().get_format_date (new GLib.DateTime.now_local ()).to_string ();
            }
        } else {
            checked = false;
            completed_at = "";
        }

        var categories = Util.find_string_value ("CATEGORIES", data);
        check_labels (get_labels_maps_from_caldav (categories));

        pinned = Util.find_boolean_value ("X-PINNED", data);
        extra_data = Util.generate_extra_data (Util.get_task_id_from_url (element), etag, ical.as_ical_string ());
    }

    private Gee.ArrayList<Objects.Label> get_caldav_categories (string categories) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();

        //  string _categories = categories.replace ("\\,", ";");
        string[] categories_list = categories.split (",");
        foreach (unowned string category in categories_list) {
            //  string category = str.replace (";", ",");
            Objects.Label label = Services.Database.get_default ().get_label_by_name (category, true, BackendType.CALDAV);
            if (label != null) {
                return_value.add (label);
            }
        }

        return return_value;
    }

    public void check_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        foreach (var entry in new_labels.entries) {
            if (get_label (entry.key) == null) {
                add_label_if_not_exists (entry.value);
            }
        }
        
        foreach (var label in _get_labels ()) {
            if (!new_labels.has_key (label.id)) {
                delete_item_label (label.id);
            }
        }
    }

    public Gee.ArrayList<Objects.Label> get_labels_from_json (Json.Node node) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        foreach (unowned Json.Node element in node.get_object ().get_array_member ("labels").get_elements ()) {
            Objects.Label label = Services.Database.get_default ().get_label_by_name (element.get_string (), true, project.backend_type);
            return_value.add (label);
        }
        return return_value;
    }

    public Gee.HashMap<string, Objects.Label> get_labels_maps_from_json (Json.Node node) {
        Gee.HashMap<string, Objects.Label> return_value = new Gee.HashMap<string, Objects.Label> ();
        foreach (unowned Json.Node element in node.get_object ().get_array_member ("labels").get_elements ()) {
            Objects.Label label = Services.Database.get_default ().get_label_by_name (element.get_string (), true, project.backend_type);
            return_value [label.id] = label;
        }
        return return_value;
    }

    public Gee.HashMap<string, Objects.Label> get_labels_maps_from_caldav (string categories) {
        Gee.HashMap<string, Objects.Label> return_value = new Gee.HashMap<string, Objects.Label> ();

        string[] categories_list = categories.split (",");
        foreach (unowned string category in categories_list) {
            Objects.Label label = Services.Database.get_default ().get_label_by_name (category, true, BackendType.CALDAV);
            if (label != null) {
                return_value [label.id] = label;
            }
        }

        return return_value;
    }

    public void set_section (Objects.Section section) {
        _section = section;
    }

    public void set_parent (Objects.Item item) {
        _parent = item;
    }

    public void set_project (Objects.Project project) {
        _project = project;
    }

    public override string get_add_json (string temp_id, string uuid) {
        return get_update_json (uuid, temp_id);
    }

    public string get_check_json (string uuid, string type) {
        builder.reset ();

        builder.begin_object ();
            builder.set_member_name ("commands");

            builder.begin_array ();
                builder.begin_object ();

                // Set type
                builder.set_member_name ("type");
                builder.add_string_value (type);

                builder.set_member_name ("uuid");
                builder.add_string_value (uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_string_value (id);

                    builder.end_object ();
                builder.end_object ();
            builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void update_local () {
        Services.Database.get_default ().update_item (this, "");
    }

    public void update (string update_id = "") {
        if (update_timeout_id != 0) {
            Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;

            if (project.backend_type == BackendType.LOCAL) {
                Services.Database.get_default ().update_item (this, update_id);
            } else if (project.backend_type == BackendType.TODOIST) {
                Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                    Services.Todoist.get_default ().update.end (res);
                    Services.Database.get_default ().update_item (this, update_id);
                });
            } else if (project.backend_type == BackendType.CALDAV) {
                Services.CalDAV.get_default ().add_task.begin (this, true, (obj, res) => {
                    HttpResponse response = Services.CalDAV.get_default ().add_task.end (res);

                    if (response.status) {
                        Services.Database.get_default ().update_item (this, update_id);
                    }
                });
            } 

            return GLib.Source.REMOVE;
        });
    }

    public void update_async_timeout (string update_id = "") {
        if (update_timeout_id != 0) {
            Source.remove (update_timeout_id);
        }
        
        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;
            loading = true;

            if (project.backend_type == BackendType.LOCAL) {
                Services.Database.get_default ().update_item (this, update_id);
                loading = false;
            } else if (project.backend_type == BackendType.TODOIST) {
                Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                    Services.Todoist.get_default ().update.end (res);
                    Services.Database.get_default ().update_item (this, update_id);
                    loading = false;
                });
            } else if (project.backend_type == BackendType.CALDAV) {
                Services.CalDAV.get_default ().add_task.begin (this, true, (obj, res) => {
                    HttpResponse response = Services.CalDAV.get_default ().add_task.end (res);

                    if (response.status) {
                        Services.Database.get_default ().update_item (this, update_id);
                    }
                    
                    loading = false;
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public void update_async (string update_id = "") {
        loading = true;

        if (project.backend_type == BackendType.LOCAL) {
            Services.Database.get_default ().update_item (this, update_id);
            loading = false;
        } else if (project.backend_type == BackendType.TODOIST) {
            Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                Services.Todoist.get_default ().update.end (res);
                Services.Database.get_default ().update_item (this, update_id);
                loading = false;
            });
        } else if (project.backend_type == BackendType.CALDAV) {
            Services.CalDAV.get_default ().add_task.begin (this, true, (obj, res) => {
                HttpResponse response = Services.CalDAV.get_default ().add_task.end (res);

                if (response.status) {
                    Services.Database.get_default ().update_item (this, update_id);
                }
                
                loading = false;
            });
        } 
    }

    public Objects.Reminder? add_reminder_if_not_exists (Objects.Reminder reminder) {
        Objects.Reminder? return_value = null;
        lock (_reminders) {
            return_value = get_reminder (reminder);
            if (return_value == null) {
                Services.Database.get_default ().insert_reminder (reminder);
                add_reminder (return_value);
            }
            return return_value;
        }
    }

    private Objects.Reminder? get_reminder (Objects.Reminder reminder) {
        Objects.Reminder? return_value = null;
        lock (_reminders) {
            foreach (var _reminder in _reminders) {
                if (reminder.due.datetime.compare (_reminder.due.datetime) == 0) {
                    return_value = _reminder;
                    break;
                }
            }
        }
        return return_value;
    }

    private void add_reminder (Objects.Reminder reminder) {
        _reminders.add (reminder);
        reminder_added (reminder);
    }

    public void delete_reminder (Objects.Reminder reminder) {
        Services.Database.get_default ().delete_reminder (reminder);
    }

    // Labels
    public Objects.Label add_label_if_not_exists (Objects.Label label) {
        Objects.Label? return_value = null;
        return_value = get_label (label.id);
        if (return_value == null) {
            return_value = label;
            Services.Database.get_default ().item_label_added (return_value);
            add_item_label (return_value);
        }
        
        return return_value;
    }

    public Objects.Label? get_label (string id) {
        Objects.Label? return_value = null;
        
        foreach (var label in labels) {
            if (label.id == id) {
                return_value = label;
                break;
            }
        }

        return return_value;
    }

    public void add_item_label (Objects.Label label) {
        if (labels == null) {
            labels = new Gee.ArrayList<Objects.Label> ();
        }

        labels.add (label);
        item_label_added (label);
    }

    public Objects.Label? delete_item_label (string id) {
        Objects.Label? return_value = null;
        return_value = get_label (id);

        if (return_value != null) {
            Services.Database.get_default ().item_label_deleted (return_value);
            item_label_deleted (return_value);
            
            labels.remove (return_value);
        }

        return return_value;
    }

    public string to_move_json (string type, string move_id) {
        builder.reset ();
        
        builder.begin_object ();
        
        builder.set_member_name ("id");
        builder.add_string_value (id);

        builder.set_member_name ("type");
        builder.add_string_value (type);

        builder.set_member_name (type);
        if (Services.Database.get_default ().curTempIds_exists (move_id)) {
            builder.add_string_value (Services.Database.get_default ().get_temp_id (move_id));
        } else {
            builder.add_string_value (move_id);
        }
        
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public string get_move_item (string uuid, string type, string move_id) {
        builder.reset ();

        builder.begin_object ();
            builder.set_member_name ("commands");

            builder.begin_array ();
                builder.begin_object ();

                builder.set_member_name ("type");
                builder.add_string_value ("item_move");

                builder.set_member_name ("uuid");
                builder.add_string_value (uuid);

                builder.set_member_name ("args");
                    builder.begin_object ();

                    builder.set_member_name ("id");
                    builder.add_string_value (id);

                    builder.set_member_name (type);
                    builder.add_string_value (move_id);
                    
                    builder.end_object ();
                builder.end_object ();
            builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public override string get_update_json (string uuid, string? temp_id = null) {
        builder.reset ();

        var builder = new Json.Builder ();
        builder.begin_object ();
            builder.set_member_name ("commands");
            builder.begin_array ();
                builder.begin_object ();

                builder.set_member_name ("type");
                builder.add_string_value (temp_id == null ? "item_update" : "item_add");

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

                    if (temp_id != null) {
                        builder.set_member_name ("project_id");
                        builder.add_string_value (project_id);
                        
                        if (parent_id != "") {
                            builder.set_member_name ("parent_id");
                            builder.add_string_value (parent_id);
                        }

                        if (section_id != "") {
                            builder.set_member_name ("section_id");
                            builder.add_string_value (section_id);
                        }
                    }

                    builder.set_member_name ("content");
                    builder.add_string_value (content);

                    builder.set_member_name ("description");
                    builder.add_string_value (description);

                    builder.set_member_name ("priority");
                    if (priority == 0) {
                        builder.add_int_value (Constants.PRIORITY_4);
                    } else {
                        builder.add_int_value (priority);
                    }

                    if (has_due) {
                        builder.set_member_name ("due");
                        builder.begin_object ();

                        builder.set_member_name ("date");
                        builder.add_string_value (due.date);

                        builder.end_object ();
                    } else {
                        builder.set_member_name ("due");
                        builder.add_null_value ();
                    }

                    builder.set_member_name ("labels");
                        builder.begin_array ();
                        foreach (Objects.Label label in labels) {
                            builder.add_string_value (label.name);
                        }
                        builder.end_array ();
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
        builder.reset ();
        
        builder.begin_object ();
        
        builder.set_member_name ("id");
        builder.add_string_value (id);

        builder.set_member_name ("project_id");
        if (Services.Database.get_default ().curTempIds_exists (project_id)) {
            builder.add_string_value (Services.Database.get_default ().get_temp_id (project_id));
        } else {
            builder.add_string_value (project_id);
        }

        if (section_id != "") {
            builder.set_member_name ("section_id");
            if (Services.Database.get_default ().curTempIds_exists (section_id)) {
                builder.add_string_value (Services.Database.get_default ().get_temp_id (section_id));
            } else {
                builder.add_string_value (section_id);
            }
        }

        if (parent_id != "") {
            builder.set_member_name ("parent_id");
            if (Services.Database.get_default ().curTempIds_exists (parent_id)) {
                builder.add_string_value (Services.Database.get_default ().get_temp_id (parent_id));
            } else {
                builder.add_string_value (parent_id);
            }
        }

        builder.set_member_name ("content");
        builder.add_string_value (Util.get_default ().get_encode_text (content));

        builder.set_member_name ("description");
        builder.add_string_value (Util.get_default ().get_encode_text (description));

        builder.set_member_name ("priority");
        if (priority == 0) {
            builder.add_int_value (Constants.PRIORITY_4);
        } else {
            builder.add_int_value (priority);
        }

        if (has_due) {
            builder.set_member_name ("due");
            builder.begin_object ();

            builder.set_member_name ("date");
            builder.add_string_value (due.date);

            builder.end_object ();
        } else {
            builder.set_member_name ("due");
            builder.add_null_value ();
        }

        builder.set_member_name ("labels");
        builder.begin_array ();
        foreach (Objects.Label label in labels) {
            builder.add_string_value (label.id);
        }
        builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public string to_vtodo () {
        ICal.Component ical = new ICal.Component.vtodo ();

        ical.set_uid (id);
        ical.set_summary (content);
        ical.set_description (description);

        if (pinned) {
            var pinned_property = new ICal.Property (ICal.PropertyKind.X_PROPERTY);
            pinned_property.set_x_name ("X-PINNED");
            pinned_property.set_x (pinned.to_string ());
            ical.add_property (pinned_property);
        }

        if (has_due) {
            //  var task_tz = ical.get_due ().get_timezone ();
            ICal.Time new_icaltime = Util.datetimes_to_icaltime (due.datetime, due.datetime, null);
            ical.set_due (new_icaltime);
        }

        if (parent_id != "") {
            ical.add_property (new ICal.Property.relatedto (parent_id));
        }
 
        if (checked) {
            ical.set_status (ICal.PropertyStatus.COMPLETED);
            ical.add_property (new ICal.Property.percentcomplete (100));
            ical.add_property (new ICal.Property.completed (new ICal.Time.today ()));
        } else {
            ical.set_status (ICal.PropertyStatus.NEEDSACTION);
        }
        
        var _priority = 0;
        if (priority == Constants.PRIORITY_4) {
            _priority = 0;
        } else if (priority == Constants.PRIORITY_1) {
            _priority = 1;
        } else if (priority == Constants.PRIORITY_2) {
            _priority = 5;
        } else if (priority == Constants.PRIORITY_3) {
            _priority = 9;
        } else {
            _priority = 0;
        }

        ical.add_property (new ICal.Property.priority (_priority));

        if (labels.size > 0) {
            ical.add_property (new ICal.Property.categories (get_labels_names (labels)));
        }
        
        stdout.printf ("%s\n", ical.as_ical_string ());

        return "%s%s%s".printf (
            "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Planify App (https://github.com/alainm23/planify)\n",
            ical.as_ical_string (),
            "END:VCALENDAR\n"
        );
    }

    public Objects.Item add_item_if_not_exists (Objects.Item new_item, bool insert=true) {
        Objects.Item? return_value = null;
        lock (_items) {
            return_value = get_item (new_item.id);
            if (return_value == null) {
                new_item.set_parent (this);
                add_item (new_item);
                Services.Database.get_default ().insert_item (new_item, insert);
                return_value = new_item;
            }
            return return_value;
        }
    }

    public Objects.Item? get_item (string id) {
        Objects.Item? return_value = null;
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

    public void add_item (Objects.Item item) {
        _items.add (item);
    }

    public void copy_clipboard () {
        Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
        clipboard.set_text ("[%s]%s%s\n------------------------------------------\n%s".printf (checked ? "x" : " ", get_format_date (this), content, description));
        Services.EventBus.get_default ().send_notification (
            Util.get_default ().create_toast (_("Task copied to clipboard"))
        );
    }

    public Objects.Item generate_copy () {
        var new_item = new Objects.Item ();
        new_item.id = Util.get_default ().generate_id (new_item);
        new_item.content = content;
        new_item.description = description;
        new_item.pinned = pinned;
        new_item.due = due;
        new_item.priority = priority;

        return new_item;
    }

    public void duplicate () {
        var new_item = generate_copy ();
        new_item.content = "[%s] %s".printf (_("Duplicate"), content);

        if (project.backend_type == BackendType.TODOIST) {
            Services.Todoist.get_default ().add.begin (new_item, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);
                if (response.status) {
                    new_item.id = response.data;
                    insert_duplicate (new_item);
                }
            });
        } else {
            new_item.id = Util.get_default ().generate_id (new_item);
            insert_duplicate (new_item);
        }
    }

    public void insert_duplicate (Objects.Item new_item) {
        if (new_item.section_id != "") {
            Services.Database.get_default ().get_section (new_item.section_id)
                .add_item_if_not_exists (new_item);
        } else {
            Services.Database.get_default ().get_project (new_item.project_id)
                .add_item_if_not_exists (new_item);
        }
    }

    private string get_format_date (Objects.Item item) {
        if (!item.has_due) {
            return " ";
        }

        return " (" + Util.get_default ().get_relative_date_from_date (item.due.datetime) + ") ";
    }

    public void delete_item () {
        if (project.backend_type == BackendType.CALDAV) {
            Services.Database.get_default ().delete_item (this);
        } else if (project.backend_type == BackendType.TODOIST) {
            Services.Todoist.get_default ().delete.begin (this, (obj, res) => {
                if (Services.Todoist.get_default ().delete.end (res).status) {
                    Services.Database.get_default ().delete_item (this);
                }
            });
        } else if (project.backend_type == BackendType.CALDAV) {
            Services.CalDAV.get_default ().delete_task.begin (this, (obj, res) => {
                if (Services.CalDAV.get_default ().delete_task.end (res).status) {
                    Services.Database.get_default ().delete_item (this);
                }
            });
        }
    }

    public string get_labels_names (Gee.ArrayList<Objects.Label> labels) {
        string return_value = "";
            
        foreach (Objects.Label label in labels) {
            return_value += label.name.replace (",", "\\,") + ",";
        }

        if (return_value.length > 0) {
            return_value = return_value.substring (0, return_value.length - 1);
        }

        return return_value;
    }
}
