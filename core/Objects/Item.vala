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
    public string calendar_event_uid { get; set; default = ""; }
    public string deadline_date { get; set; default = ""; }  

    string _section_id = "";
    public string section_id {
        get { return _section_id; }
        set {
            _section_id = value;
            _section = null;
        }
    }
    
    string _project_id = "";
    public string project_id {
        get { return _project_id; }
        set {
            _project_id = value;
            _project = null;
        }
    }
    
    string _parent_id = "";
    public string parent_id {
        get { return _parent_id; }
        set {
            _parent_id = value;
            _parent = null;
        }
    }
    public string extra_data { get; set; default = ""; }
    public ItemType item_type { get; set; default = ItemType.TASK; }
    public string responsible_uid { get; set; default = ""; }


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

    string _short_content;
    public string short_content {
        get {
            _short_content = Util.get_default ().get_short_name (content);
            return _short_content;
        }
    }

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
            return due != null && due.datetime != null;
        }
    }

    public bool has_time {
        get {
            if (due.datetime == null) {
                return false;
            }

            return Utils.Datetime.has_time (due.datetime);
        }
    }

    GLib.DateTime _completed_date;
    public GLib.DateTime completed_date {
        get {
            _completed_date = Utils.Datetime.get_date_from_string (completed_at);
            return _completed_date;
        }
    }

    public bool has_parent {
        get {
            return _parent_id != null && _parent_id != "";
        }
    }

    public bool has_section {
        get {
            return _section_id != null && _section_id != "";
        }
    }

    bool _show_item = true;
    public bool show_item {
        set {
            _show_item = value;
            show_item_changed ();
        }

        get {
            return _show_item;
        }
    }

    string _ical_url = "";
    public string ical_url {
        get {
            var json_object = Services.Todoist.get_default ().get_object_by_string (extra_data);

            if (json_object.has_member ("ics")) {
                _ical_url = "%s/%s".printf (project.calendar_url, json_object.get_string_member ("ics")); // TODO: Should the stored data be migrated?
            }else {
                _ical_url = Services.Todoist.get_default ().get_string_member_by_object (extra_data, "ical_url");
            }
            return _ical_url;
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

    GLib.DateTime _deadline_datetime;
    public GLib.DateTime deadline_datetime {
        get {
            if (!has_deadline) {
                return null;
            }
            _deadline_datetime = new GLib.DateTime.from_iso8601 (deadline_date, new GLib.TimeZone.local ());
            return _deadline_datetime;
        }
    }

    public bool has_deadline {
        get {
            return deadline_date != "";
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

    Objects.Item ? _parent;
    public Objects.Item parent {
        get {
            if (_parent == null && _parent_id != null && _parent_id != "") {
                _parent = Services.Store.instance ().get_item (_parent_id);
            }
            return _parent;
        }
    }

    Objects.Project ? _project;
    public Objects.Project project {
        get {
            if (_project == null && _project_id != null && _project_id != "") {
                _project = Services.Store.instance ().get_project (_project_id);
            }
            return _project;
        }
    }

    Objects.Section ? _section;
    public Objects.Section section {
        get {
            if (_section == null && _section_id != null && _section_id != "") {
                _section = Services.Store.instance ().get_section (_section_id);
            }
            return _section;
        }
    }

    Gee.ArrayList<Objects.Item> _items;
    public Gee.ArrayList<Objects.Item> items {
        get {
            _items = Services.Store.instance ().get_subitems (this);
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

    Gee.ArrayList<Objects.Item> _items_uncomplete;
    public Gee.ArrayList<Objects.Item> items_uncomplete {
        get {
            _items_uncomplete = Services.Store.instance ().get_subitems_uncomplete (this);
            return _items_uncomplete;
        }
    }

    Gee.ArrayList<Objects.Reminder> _reminders;
    public Gee.ArrayList<Objects.Reminder> reminders {
        get {
            _reminders = Services.Store.instance ().get_reminders_by_item (this);
            return _reminders;
        }
    }

    Gee.ArrayList<Objects.Attachment> _attachments;
    public Gee.ArrayList<Objects.Attachment> attachments {
        get {
            _attachments = Services.Store.instance ().get_attachments_by_item (this);
            return _attachments;
        }
    }

    public signal void item_label_added (Objects.Label label);
    public signal void item_label_deleted (Objects.Label label);
    public signal void item_added (Objects.Item item);
    public signal void reminder_added (Objects.Reminder reminder);
    public signal void reminder_deleted (Objects.Reminder reminder);
    public signal void show_item_changed ();
    public signal void collapsed_change ();
    public signal void attachment_added (Objects.Attachment attachment);
    public signal void attachment_deleted (Objects.Attachment attachment);
    public signal void pin_updated ();

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
        child_order = (int32) node.get_object ().get_int_member ("child_order");

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

        if (!node.get_object ().get_null_member ("responsible_uid")) {
            responsible_uid = node.get_object ().get_string_member ("responsible_uid");
        } else {
            responsible_uid = "";
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
        child_order = (int32) node.get_object ().get_int_member ("child_order");

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

        if (!node.get_object ().get_null_member ("responsible_uid")) {
            responsible_uid = node.get_object ().get_string_member ("responsible_uid");
        } else {
            responsible_uid = "";
        }
    }

    public Item.from_import_json (Json.Node node, Gee.ArrayList<Objects.Label> _labels = new Gee.ArrayList<Objects.Label> ()) {
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

        if (_labels.size <= 0) {
            labels = get_labels_from_json (node);
        } else {
            labels = get_labels_from_labels_json (node, _labels);
        }
    }

    public Item.from_vtodo (string data, string _ical_url, string _project_id) {
        project_id = _project_id;
        patch_from_vtodo (data, _ical_url);
    }

    public void update_from_vtodo (string data, string _ical_url) {
        patch_from_vtodo (data, _ical_url, true);
    }

    public void patch_from_vtodo (string data, string _ical_url, bool is_update = false) {
        ICal.Component ical = ICal.Parser.parse_string (data);
        ICal.Component ? ical_vtodo = ical.get_first_component (ICal.ComponentKind.VTODO_COMPONENT);

        id = ical.get_uid ();
        content = ical.get_summary ();

        if (ical.get_description () != null) {
            description = ical.get_description ();
        }

        ICal.Property ? priority_property = ical_vtodo.get_first_property (ICal.PropertyKind.PRIORITY_PROPERTY);
        if (priority_property != null) {
            int _priority = priority_property.get_priority ();
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
            due.date = Utils.Datetime.ical_to_date_time_local (ical.get_due ()).to_string ();
        }

        ICal.Property ? rrule_property = ical_vtodo.get_first_property (ICal.PropertyKind.RRULE_PROPERTY);
        if (rrule_property != null) {
            Utils.Datetime.recurrence_to_due (rrule_property.get_rrule (), due);
        }

        ICal.Property ? related_to_property = ical_vtodo.get_first_property (ICal.PropertyKind.RELATEDTO_PROPERTY);
        if (related_to_property != null) {
            parent_id = related_to_property.get_relatedto ();
        } else {
            parent_id = "";
        }

        if (ical.get_status () == ICal.PropertyStatus.COMPLETED) {
            checked = true;
            ICal.Property ? completed_property = ical_vtodo.get_first_property (ICal.PropertyKind.COMPLETED_PROPERTY);
            if (completed_property != null) {
                completed_at = Utils.Datetime.get_date_only (
                    Utils.Datetime.ical_to_date_time_local (completed_property.get_completed ())
                ).to_string ();
            } else {
                completed_at = Utils.Datetime.get_date_only (new GLib.DateTime.now_local ()).to_string ();
            }
        } else {
            checked = false;
            completed_at = "";
        }

        ICal.Property ? sort_order_property = ical_vtodo.get_first_property (ICal.PropertyKind.from_string ("X-APPLE-SORT-ORDER"));
        if (sort_order_property != null) {
            var sort_order_str = sort_order_property.get_value_as_string ();
            if (sort_order_str != null) {
                child_order = int.parse (sort_order_str);
            }
        } else {
            // Items without an X-APPLE-SORT-ORDER must use the time in seconds
            // since 2001-01-01-00:00:00 (978307200L) as their sort order
           ICal.Property ? created_property = ical_vtodo.get_first_property (ICal.PropertyKind.CREATED_PROPERTY);
            if (created_property != null) {
                var create_time = (long) created_property.get_created ().as_timet ();
                child_order = (int)(create_time - 978307200L);
            } else {
                // TODO should probably emit a warning that manual sorting will not work?
            }
        }

        ICal.Property ? pinned_property = ical_vtodo.get_first_property (ICal.PropertyKind.from_string ("X-PINNED"));
        if (pinned_property != null) {
            var pinned_str = pinned_property.get_value_as_string ();
            if (pinned_str != null) {
                pinned = bool.parse (pinned_str);
            }
        } else {
            pinned = false;
        }

        extra_data = Util.generate_extra_data (_ical_url, "", ical.as_ical_string ());

        #if WITH_EVOLUTION
        ECal.Component ecal = new ECal.Component.from_icalcomponent (ical_vtodo);

        if (is_update) {
            check_labels (get_labels_maps_from_caldav (ecal.get_categories_list ()));
        } else {
            labels = get_caldav_categories (ecal.get_categories_list ());
        }
        #endif
        // TODO: Reimplement without ECAL
    }

    private Gee.ArrayList<Objects.Label> get_caldav_categories (GLib.SList<string> categories_list) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();

        foreach (string category in categories_list) {
            Objects.Label label = Services.Store.instance ().get_label_by_name (category, true, project.source_id);
            if (label == null) {
                label = new Objects.Label ();
                label.id = Util.get_default ().generate_id (label);
                label.name = category;
                label.color = Util.get_default ().get_random_color ();
                label.source_id = project.source_id;
                Services.Store.instance ().insert_label (label);
            }

            return_value.add (label);
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
            Objects.Label label = Services.Store.instance ().get_label_by_name (element.get_string (), true, project.source_id);
            return_value.add (label);
        }
        return return_value;
    }

    public Gee.ArrayList<Objects.Label> get_labels_from_labels_json (Json.Node node, Gee.ArrayList<Objects.Label> labels_list) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        foreach (unowned Json.Node element in node.get_object ().get_array_member ("labels").get_elements ()) {
            Objects.Label label = get_label_by_name (element.get_string (), labels_list);
            return_value.add (label);
        }
        return return_value;
    }

    private Objects.Label ? get_label_by_name (string name, Gee.ArrayList<Objects.Label> labels_list) {
        foreach (var label in labels_list) {
            if (label.name.down () == name.down ()) {
                return label;
            }
        }

        return null;
    }

    public Gee.HashMap<string, Objects.Label> get_labels_maps_from_json (Json.Node node) {
        Gee.HashMap<string, Objects.Label> return_value = new Gee.HashMap<string, Objects.Label> ();
        foreach (unowned Json.Node element in node.get_object ().get_array_member ("labels").get_elements ()) {
            Objects.Label label = Services.Store.instance ().get_label_by_name (element.get_string (), true, project.source_id);
            return_value[label.id] = label;
        }
        return return_value;
    }

    public Gee.HashMap<string, Objects.Label> get_labels_maps_from_caldav (GLib.SList<string> categories_list) {
        Gee.HashMap<string, Objects.Label> return_value = new Gee.HashMap<string, Objects.Label> ();

        foreach (string category in categories_list) {
            Objects.Label label = Services.Store.instance ().get_label_by_name (category, true, project.source_id);
            if (label == null) {
                label = new Objects.Label ();
                label.id = Util.get_default ().generate_id (label);
                label.name = category;
                label.color = Util.get_default ().get_random_color ();
                label.source_id = project.source_id;
                Services.Store.instance ().insert_label (label);
            }

            return_value[label.id] = label;
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
        Services.Store.instance ().update_item (this, "");
    }

    public void update (string update_id = "") {
        if (update_timeout_id != 0) {
            GLib.Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;

            if (project.source_type == SourceType.LOCAL) {
                Services.Store.instance ().update_item (this, update_id);
            } else if (project.source_type == SourceType.TODOIST) {
                Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                    Services.Todoist.get_default ().update.end (res);
                    Services.Store.instance ().update_item (this, update_id);
                });
            } else if (project.source_type == SourceType.CALDAV) {
                var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
                caldav_client.add_item.begin (this, true, (obj, res) => {
                    HttpResponse response = caldav_client.add_item.end (res);

                    if (response.status) {
                        Services.Store.instance ().update_item (this, update_id);
                    }
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public void update_async_timeout (string update_id = "") {
        if (update_timeout_id != 0) {
            GLib.Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;
            loading = true;

            if (project.source_type == SourceType.LOCAL) {
                Services.Store.instance ().update_item (this, update_id);
                loading = false;
            } else if (project.source_type == SourceType.TODOIST) {
                Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                    Services.Todoist.get_default ().update.end (res);
                    Services.Store.instance ().update_item (this, update_id);
                    loading = false;
                });
            } else if (project.source_type == SourceType.CALDAV) {
                var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
                caldav_client.add_item.begin (this, true, (obj, res) => {
                    HttpResponse response = caldav_client.add_item.end (res);

                    if (response.status) {
                        Services.Store.instance ().update_item (this, update_id);
                    }

                    loading = false;
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public void update_async (string update_id = "") {
        loading = true;

        if (project.source_type == SourceType.LOCAL) {
            Services.Store.instance ().update_item (this, update_id);
            loading = false;
        } else if (project.source_type == SourceType.TODOIST) {
            Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                Services.Todoist.get_default ().update.end (res);
                Services.Store.instance ().update_item (this, update_id);
                loading = false;
            });
        } else if (project.source_type == SourceType.CALDAV) {
            var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
            caldav_client.add_item.begin (this, true, (obj, res) => {
                HttpResponse response = caldav_client.add_item.end (res);

                if (response.status) {
                    Services.Store.instance ().update_item (this, update_id);
                }

                loading = false;
            });
        }
    }

    public void update_pin (bool _pinned) {
        pinned = _pinned;
        _update_pin ();
    }

    private void _update_pin () {
        if (project.source_type == SourceType.CALDAV) {
            loading = true;
            var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
            caldav_client.add_item.begin (this, true, (obj, res) => {
                HttpResponse response = caldav_client.add_item.end (res);

                if (response.status) {
                    Services.Store.instance ().update_item_pin (this);
                }

                loading = false;
            });
        } else {
            Services.Store.instance ().update_item_pin (this);
        }
    }

    public Objects.Reminder ? add_reminder_if_not_exists (Objects.Reminder reminder, bool insert_db = true) {
        Objects.Reminder ? return_value = null;
        lock (_reminders) {
            return_value = get_reminder (reminder);
            if (return_value == null) {
                if (insert_db) {
                    Services.Store.instance ().insert_reminder (reminder);
                } else {
                    reminder_added (reminder);
                }

                _add_reminder (reminder);
            }
            return return_value;
        }
    }

    private Objects.Reminder ? get_reminder (Objects.Reminder reminder) {
        Objects.Reminder ? return_value = null;
        lock (_reminders) {
            foreach (var _reminder in _reminders) {
                if (reminder.datetime.compare (_reminder.datetime) == 0) {
                    return_value = _reminder;
                    break;
                }
            }
        }
        return return_value;
    }

    private void _add_reminder (Objects.Reminder reminder) {
        _reminders.add (reminder);
    }

    public Objects.Attachment ? add_attachment_if_not_exists (Objects.Attachment attachment) {
        Objects.Attachment ? return_value = null;
        lock (_attachments) {
            return_value = get_attachment (attachment);
            if (return_value == null) {
                Services.Store.instance ().insert_attachment (attachment);
                add_attachment (attachment);
            }

            return return_value;
        }
    }

    private Objects.Attachment ? get_attachment (Objects.Attachment attachment) {
        Objects.Attachment ? return_value = null;
        lock (_attachments) {
            foreach (var _attachment in _attachments) {
                if (_attachment.file_path == attachment.file_path) {
                    return_value = _attachment;
                    break;
                }
            }
        }

        return return_value;
    }

    private void add_attachment (Objects.Attachment attachment) {
        _attachments.add (attachment);
    }

    // Labels
    public Objects.Label add_label_if_not_exists (Objects.Label label) {
        Objects.Label ? return_value = null;
        return_value = get_label (label.id);
        if (return_value == null) {
            return_value = label;
            Services.Store.instance ().item_label_added (return_value);
            add_item_label (return_value);
        }

        return return_value;
    }

    public Objects.Label ? get_label (string id) {
        Objects.Label ? return_value = null;

        foreach (var label in labels) {
            if (label.id == id) {
                return_value = label;
                break;
            }
        }

        return return_value;
    }

    public bool has_label (string id) {
        if (get_label (id) == null) {
            return false;
        }

        return true;
    }

    public bool has_labels () {
        return labels.size > 0;
    }

    public void add_item_label (Objects.Label label) {
        if (labels == null) {
            labels = new Gee.ArrayList<Objects.Label> ();
        }

        labels.add (label);
        item_label_added (label);
    }

    public Objects.Label ? delete_item_label (string id) {
        Objects.Label ? return_value = null;
        return_value = get_label (id);

        if (return_value != null) {
            Services.Store.instance ().item_label_deleted (return_value);
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

    public override string get_update_json (string uuid, string ? temp_id = null) {
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

        builder.set_member_name ("child_order");
        builder.add_int_value (child_order);

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

        if (has_deadline) {
            builder.set_member_name ("deadline");
            builder.begin_object ();

            builder.set_member_name ("date");
            builder.add_string_value (Utils.Datetime.get_todoist_datetime_format (deadline_datetime));

            builder.end_object ();
        } else {
            builder.set_member_name ("deadline");
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
        ical.set_dtstamp (new ICal.Time.current_with_zone (ICal.Timezone.get_utc_timezone ()));
        ical.set_summary (content);
        ical.set_description (description);

        if (pinned) {
            var pinned_property = new ICal.Property (ICal.PropertyKind.X_PROPERTY);
            pinned_property.set_x_name ("X-PINNED");
            pinned_property.set_x (pinned.to_string ());
            ical.add_property (pinned_property);
        }

        if (has_due) {
            ICal.Time new_icaltime = Utils.Datetime.datetimes_to_icaltime (
                due.datetime,
                Utils.Datetime.has_time (due.datetime) ? due.datetime : null,
                null
            );

            ical.set_due (new_icaltime);

            if (due.is_recurring) {
                var rrule = new ICal.Recurrence ();

                if (due.recurrency_type == RecurrencyType.MINUTELY) {
                    rrule.set_freq (ICal.RecurrenceFrequency.MINUTELY_RECURRENCE);
                } else if (due.recurrency_type == RecurrencyType.HOURLY) {
                    rrule.set_freq (ICal.RecurrenceFrequency.HOURLY_RECURRENCE);
                } else if (due.recurrency_type == RecurrencyType.EVERY_DAY) {
                    rrule.set_freq (ICal.RecurrenceFrequency.DAILY_RECURRENCE);
                } else if (due.recurrency_type == RecurrencyType.EVERY_WEEK) {
                    rrule.set_freq (ICal.RecurrenceFrequency.WEEKLY_RECURRENCE);

                    Array<short> values = new Array<short> ();
                    short val;

                    if (due.recurrency_weeks != null && due.recurrency_weeks.split (",").length > 0) {
                        if (due.recurrency_weeks.contains ("1")) {
                            val = (short) 2;
                            values.append_val (val);
                        }

                        if (due.recurrency_weeks.contains ("2")) {
                            val = (short) 3;
                            values.append_val (val);
                        }

                        if (due.recurrency_weeks.contains ("3")) {
                            val = (short) 4;
                            values.append_val (val);
                        }

                        if (due.recurrency_weeks.contains ("4")) {
                            val = (short) 5;
                            values.append_val (val);
                        }

                        if (due.recurrency_weeks.contains ("5")) {
                            val = (short) 6;
                            values.append_val (val);
                        }

                        if (due.recurrency_weeks.contains ("6")) {
                            val = (short) 7;
                            values.append_val (val);
                        }

                        if (due.recurrency_weeks.contains ("7")) {
                            val = (short) 1;
                            values.append_val (val);
                        }
                    }

                    rrule.set_by_day_array (values);
                } else if (due.recurrency_type == RecurrencyType.EVERY_MONTH) {
                    rrule.set_freq (ICal.RecurrenceFrequency.MONTHLY_RECURRENCE);
                } else if (due.recurrency_type == RecurrencyType.EVERY_YEAR) {
                    rrule.set_freq (ICal.RecurrenceFrequency.YEARLY_RECURRENCE);
                }

                rrule.set_interval ((short) due.recurrency_interval);

                if (due.recurrency_count > 0) {
                    rrule.set_count (due.recurrency_count);
                }

                if (due.recurrency_end != "") {
                    ICal.Time until_icaltime = Utils.Datetime.datetimes_to_icaltime (
                        due.end_datetime,
                        null,
                        null
                    );

                    rrule.set_until (until_icaltime);
                }

                var rrule_property = new ICal.Property.rrule (rrule);
                ical.add_property (rrule_property);
            }
        }

        if (parent_id != "") {
            ical.add_property (new ICal.Property.relatedto (parent_id));
        }

        if (checked) {
            ical.set_status (ICal.PropertyStatus.COMPLETED);
            ical.add_property (new ICal.Property.percentcomplete (100));
            // RFC requires Date-Time (https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.2.1)
            // Nextcloud also accepted .today () which didn't include the Timezone, but Radicale and probably other CalDAV implementations want Date-Time
            ical.add_property (new ICal.Property.completed (new ICal.Time.current_with_zone (null)));
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

        var child_order_property = new ICal.Property (ICal.PropertyKind.X_PROPERTY);
        child_order_property.set_x_name ("X-APPLE-SORT-ORDER");
        child_order_property.set_x (child_order.to_string ());
        ical.add_property (child_order_property);

        return "%s%s%s".printf (
            "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Planify App (https://github.com/alainm23/planify)\n",
            ical.as_ical_string (),
            "END:VCALENDAR\n"
        );
    }

    public Objects.Item add_item_if_not_exists (Objects.Item new_item, bool insert = true) {
        Objects.Item ? return_value = null;
        lock (_items) {
            return_value = get_item (new_item.id);
            if (return_value == null) {
                new_item.set_parent (this);
                add_item (new_item);
                Services.Store.instance ().insert_item (new_item, insert);
                return_value = new_item;
            }
            return return_value;
        }
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

    public void add_item (Objects.Item item) {
        _items.add (item);
    }

    public void copy_clipboard () {
        Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
        clipboard.set_text ("[%s]%s%s\n------------------------------------------\n%s".printf (checked ? "x" : " ", get_format_date (this), content, description));
        Services.EventBus.get_default ().send_toast (
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

    public Objects.Item duplicate () {
        var new_item = new Objects.Item ();
        new_item.content = content;
        new_item.description = description;
        new_item.due = due.duplicate ();
        new_item.pinned = pinned;
        new_item.priority = priority;
        new_item.labels = labels;
        new_item.item_type = item_type;
        return new_item;
    }

    private string get_format_date (Objects.Item item) {
        if (!item.has_due) {
            return " ";
        }

        return " (" + Utils.Datetime.get_relative_date_from_date (item.due.datetime) + ") ";
    }

    public void delete_item () {
        if (project.source_type == SourceType.LOCAL) {
            Services.Store.instance ().delete_item (this);
        } else if (project.source_type == SourceType.TODOIST) {
            loading = true;
            Services.Todoist.get_default ().delete.begin (this, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().delete.end (res);
                loading = false;

                if (response.status) {
                    Services.Store.instance ().delete_item (this);
                } else {
                    Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                }
            });
        } else if (project.source_type == SourceType.CALDAV) {
            delete_caldav.begin ();
        }
    }

    private async void delete_caldav () {
        loading = true;
        var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
        
        try {
            yield delete_subitems_caldav (this, caldav_client);
            
            var response = yield caldav_client.delete_item (this);
            
            if (!response.status) {
                throw new IOError.FAILED (response.error);
            }
            
            Services.Store.instance ().delete_item (this);
        } catch (Error e) {
            Services.EventBus.get_default ().send_error_toast (0, e.message);
        }
        
        loading = false;
    }

    private async void delete_subitems_caldav (Objects.Item item, Services.CalDAV.CalDAVClient caldav_client) throws Error {
        foreach (Objects.Item subitem in Services.Store.instance ().get_subitems (item)) {
            yield delete_subitems_caldav (subitem, caldav_client);
            
            var response = yield caldav_client.delete_item (subitem);

            if (!response.status) {
                throw new IOError.FAILED (response.error);
            }
            
            Services.Store.instance ().delete_item (subitem);
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

    public void set_recurrency (Objects.DueDate duedate) {
        if (due.is_recurrency_equal (duedate)) {
            return;
        }

        if (duedate.recurrency_type == RecurrencyType.MINUTELY ||
            duedate.recurrency_type == RecurrencyType.HOURLY) {
            if (!has_due) {
                due.date = Utils.Datetime.get_todoist_datetime_format (
                    new DateTime.now_local ()
                );
            }
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_DAY ||
                   duedate.recurrency_type == RecurrencyType.EVERY_MONTH ||
                   duedate.recurrency_type == RecurrencyType.EVERY_YEAR) {
            if (!has_due) {
                due.date = Utils.Datetime.get_todoist_datetime_format (
                    Utils.Datetime.get_today_format_date ()
                );
            }
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_WEEK) {
            if (duedate.has_weeks) {
                GLib.DateTime due_selected = Utils.Datetime.get_today_format_date ();
                if (has_due) {
                    due_selected = due.datetime;
                }

                int day_of_week = due_selected.get_day_of_week ();
                int next_day = Utils.Datetime.get_next_day_of_week_from_recurrency_week (due_selected, duedate);
                GLib.DateTime due_date = null;

                if (day_of_week == next_day) {
                    due_date = due_selected;
                } else {
                    due_date = Utils.Datetime.next_recurrency_week (due_selected, duedate);
                }

                due.date = Utils.Datetime.get_todoist_datetime_format (due_date);
            } else {
                if (!has_due) {
                    due.date = Utils.Datetime.get_todoist_datetime_format (
                        Utils.Datetime.get_today_format_date ()
                    );
                }
            }
        }

        due.is_recurring = duedate.is_recurring;
        due.recurrency_type = duedate.recurrency_type;
        due.recurrency_interval = duedate.recurrency_interval;
        due.recurrency_weeks = duedate.recurrency_weeks;
        due.recurrency_count = duedate.recurrency_count;
        due.recurrency_end = duedate.recurrency_end;

        update_async ("");
    }

    public void update_next_recurrency (Services.Promise<GLib.DateTime> ? promise) {
        var next_recurrency = Utils.Datetime.next_recurrency (due.datetime, due);
        due.date = Utils.Datetime.get_todoist_datetime_format (
            next_recurrency
        );

        if (due.end_type == RecurrencyEndType.AFTER) {
            due.recurrency_count = due.recurrency_count - 1;
        }

        if (project.source_type == SourceType.LOCAL) {
            Services.Store.instance ().update_item (this);
            promise.resolve (next_recurrency);
        } else if (project.source_type == SourceType.TODOIST) {
            loading = true;
            Services.Todoist.get_default ().update.begin (this, (obj, res) => {
                var response = Services.Todoist.get_default ().update.end (res);
                loading = false;

                if (response.status) {
                    Services.Store.instance ().update_item (this);
                    promise.resolve (next_recurrency);
                }
            });
        } else if (project.source_type == SourceType.CALDAV) {
            loading = true;
            var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
            caldav_client.add_item.begin (this, true, (obj, res) => {
                var response = caldav_client.add_item.end (res);
                loading = false;

                if (response.status) {
                    Services.Store.instance ().update_item (this);
                    promise.resolve (next_recurrency);
                }
            });
        }
    }

    public void move (Objects.Project project, string _section_id, bool notify = true) {
        if (project.source_type == SourceType.LOCAL) {
            _move (project.id, _section_id, notify);
        } else if (project.source_type == SourceType.TODOIST) {
            loading = true;
            sensitive = false;
            
            string move_id = project.id;
            string move_type = "project_id";
            if (_section_id != "") {
                move_type = "section_id";
                move_id = _section_id;
            }

            Services.Todoist.get_default ().move_item.begin (this, move_type, move_id, (obj, res) => {
                var response = Services.Todoist.get_default ().move_item.end (res);
                loading = false;

                if (response.status) {
                    _move (project.id, _section_id, notify);
                } else {
                    Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                }
            });
        } else if (project.source_type == SourceType.CALDAV) {
            loading = true;
            sensitive = false;
            
            move_caldav_recursive.begin (project, _section_id, notify);
        }
    }

    private async void move_caldav_recursive (Objects.Project project, string _section_id, bool notify = true) {
        var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
        
        try {
            var response = yield caldav_client.move_item (this, project);
            
            if (!response.status) {
                throw new IOError.FAILED (response.error);
            }

            string old_parent_id = this.parent_id;
            if (old_parent_id != "") {
                parent_id = "";
                response = yield caldav_client.add_item (this, true);
                
                if (!response.status) {
                    throw new IOError.FAILED (response.error);
                }

                Services.EventBus.get_default ().item_moved (this, project_id, section_id, old_parent_id);
            }
            
            yield move_all_subitems_caldav (this, project, caldav_client);
            
            _move (project.id, _section_id, notify);
        } catch (Error e) {
            Services.EventBus.get_default ().send_error_toast (0, e.message);
        }
        
        loading = false;
        show_item = true;
    }

    private async void move_all_subitems_caldav (Objects.Item item, Objects.Project project, Services.CalDAV.CalDAVClient caldav_client) throws Error {
        foreach (Objects.Item subitem in Services.Store.instance ().get_subitems (item)) {
            var response = yield caldav_client.move_item (subitem, project);

            if (!response.status) {
                throw new IOError.FAILED (response.error);
            }
            
            yield move_all_subitems_caldav (subitem, project, caldav_client);
        }
    }

    private void _move (string _project_id, string _section_id, bool notify = true) {
        string old_project_id = this.project_id;
        string old_section_id = this.section_id;
        string old_parent_id = this.parent_id;

        this.project_id = _project_id;
        this.section_id = _section_id;
        this.parent_id = "";

        Services.Store.instance ().move_item (this, old_project_id, old_section_id, old_parent_id);
        Services.EventBus.get_default ().item_moved (this, old_project_id, old_section_id, old_parent_id);
        Services.EventBus.get_default ().drag_n_drop_active (old_project_id, false);
        
        if (notify) {
            Services.EventBus.get_default ().send_toast (
                Util.get_default ().create_toast (_("Task moved to %s".printf (project.name)))
            );
        }
    }

    public bool was_archived () {
        return was_archived_internal (new Gee.HashSet<string> ());
    }

    private bool was_archived_internal (Gee.Set<string> visited) {
        // Prevent infinite recursion with circular references
        if (visited.contains (id)) {
            return false;
        }

        visited.add (id);

        if (has_parent && _parent_id != id) { // Check for direct self-reference
            var parent_item = parent;
            if (parent_item != null) {
                return parent_item.was_archived_internal (visited);
            }
        }

        if (has_section) {
            var section_item = section;
            if (section_item != null) {
                return section_item.was_archived ();
            }
        }

        var project_item = project;
        if (project_item != null) {
            return project_item.is_archived;
        }

        return false;
    }

    public bool exists_project (Objects.Project project) {
        return _project_id == project.id;
    }

    public string to_markdown (int level = 0) {
        string text = "%*s- %s%s%s\n".printf (level * 2, "", checked ? "[x]" : "[ ]", Utils.Datetime.get_markdown_format_date (this), content);

        foreach (Objects.Item item in items) {
            text += item.to_markdown (level + 1);
        }

        return text;
    }

    public void update_date (GLib.DateTime ? datetime) {
        due.date = datetime == null ? "" : Utils.Datetime.get_todoist_datetime_format (datetime);
        update_due (due);
    }

    public void update_due (Objects.DueDate duedate) {
        due.date = duedate.date;
        due.is_recurring = duedate.is_recurring;
        due.recurrency_type = duedate.recurrency_type;
        due.recurrency_interval = duedate.recurrency_interval;
        due.recurrency_weeks = duedate.recurrency_weeks;
        due.recurrency_count = duedate.recurrency_count;
        due.recurrency_end = duedate.recurrency_end;


        if (Services.Settings.get_default ().get_boolean ("automatic-reminders-enabled") && has_time) {
            remove_all_relative_reminders ();

            var reminder = new Objects.Reminder ();
            reminder.mm_offset = Util.get_reminders_mm_offset ();
            reminder.reminder_type = ReminderType.RELATIVE;
            add_reminder (reminder);
        }

        if (due.date == "") {
            due.reset ();
            remove_all_relative_reminders ();
        }

        if (!has_time) {
            remove_all_relative_reminders ();
        }

        update_async ("");
    }

    public void add_reminder (Objects.Reminder reminder) {
        reminder.item_id = id;

        if (project.source_type == SourceType.TODOIST) {
            Services.Todoist.get_default ().add.begin (reminder, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);
                loading = false;

                if (response.status) {
                    reminder.id = response.data;
                } else {
                    reminder.id = Util.get_default ().generate_id (reminder);
                }

                add_reminder_if_not_exists (reminder);
            });
        } else {
            reminder.id = Util.get_default ().generate_id (reminder);
            add_reminder_if_not_exists (reminder);
        }
    }

    public void add_reminder_events (Objects.Reminder reminder) {
        Services.Store.instance ().reminder_added (reminder);
        Services.Store.instance ().reminders.add (reminder);
        reminder.item.reminder_added (reminder);
        _add_reminder (reminder);
    }

    private void remove_all_relative_reminders () {
        foreach (Objects.Reminder reminder in reminders) {
            if (reminder.reminder_type == ReminderType.RELATIVE) {
                reminder.delete ();
            }
        }
    }

    public async HttpResponse complete_item (bool old_checked) {
        HttpResponse response = new HttpResponse ();

        if (project.source_type == SourceType.LOCAL) {
            Services.Store.instance ().complete_item (this, old_checked);
            response.status = true;

            return response;
        }

        loading = true;

        if (project.source_type == SourceType.TODOIST) {
            response = yield Services.Todoist.get_default ().complete_item (this);
        } else {
            var caldav_client = Services.CalDAV.Core.get_default ().get_client (project.source);
            response = yield caldav_client.complete_item (this);
        }

        loading = false;

        if (response.status) {
            bool complete_subitems = project.source_type != SourceType.CALDAV;
            Services.Store.instance ().complete_item (this, old_checked, complete_subitems);
            if (project.source_type == SourceType.CALDAV) {
                foreach (Objects.Item subitem in Services.Store.instance ().get_subitems (this)) {
                    subitem.checked = checked;
                    subitem.completed_at = completed_at;
                    subitem.complete_item.begin (old_checked);
                }
            }
        }

        return response;
    }

    public void update_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        bool update = false;

        foreach (var entry in new_labels.entries) {
            if (get_label (entry.key) == null) {
                add_label_if_not_exists (entry.value);
                update = true;
            }
        }

        foreach (var label in _get_labels ()) {
            if (!new_labels.has_key (label.id)) {
                delete_item_label (label.id);
                update = true;
            }
        }

        if (!update) {
            return;
        }

        update_async ();
    }

    public void to_string () {
        print ("_________________________________\n");
        print ("ID: %s\n", id);
        print ("Content: %s\n", content);
        print ("Description: %s\n", description);
        print ("Project ID: %s\n", project_id);
        print ("Section ID: %s\n", section_id);
        print ("Parent ID: %s\n", parent_id);
        print ("Priority: %d (%s)\n", priority, priority_text);
        print ("Checked: %s\n", checked ? "true" : "false");
        print ("Pinned: %s\n", pinned ? "true" : "false");
        print ("Has Due: %s\n", has_due ? "true" : "false");
        if (has_due) {
            print ("Due Date: %s\n", due.date);
        }
        print ("Child Order: %d\n", child_order);
        print ("Added At: %s\n", added_at);
        print ("Completed At: %s\n", completed_at);
        print ("Labels: %d\n", labels.size);
        foreach (var label in labels) {
            print ("  - %s\n", label.name);
        }
        print ("---------------------------------\n");
    }
}
