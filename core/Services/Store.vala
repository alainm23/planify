/*
* Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
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

public class Services.Store : GLib.Object {
    static GLib.Once<Services.Store> _instance;
    public static unowned Services.Store instance () {
        return _instance.once (() => {
            return new Services.Store ();
        });
    }
    
    public signal void source_added (Objects.Source source);
    public signal void source_deleted (Objects.Source source);
    public signal void source_updated (Objects.Source source);

    public signal void project_added (Objects.Project project);
    public signal void project_updated (Objects.Project project);
    public signal void project_deleted (Objects.Project project);
    public signal void project_archived (Objects.Project project);
    public signal void project_unarchived (Objects.Project project);

    public signal void label_added (Objects.Label label);
    public signal void label_updated (Objects.Label label);
    public signal void label_deleted (Objects.Label label);

    public signal void section_deleted (Objects.Section section);
    public signal void section_moved (Objects.Section section, string old_project_id);
    public signal void section_archived (Objects.Section section);
    public signal void section_unarchived (Objects.Section section);
    
    public signal void item_deleted (Objects.Item item);
    public signal void item_added (Objects.Item item, bool insert = true);
    public signal void item_updated (Objects.Item item, string update_id);
    public signal void item_archived (Objects.Item item);
    public signal void item_unarchived (Objects.Item item);

    public signal void item_label_added (Objects.Label label);
    public signal void item_label_deleted (Objects.Label label);

    public signal void reminder_added (Objects.Reminder reminder);
    public signal void reminder_deleted (Objects.Reminder reminder);

    public signal void attachment_deleted (Objects.Attachment attachment);
    
    Gee.ArrayList<Objects.Source> _sources = null;
    public Gee.ArrayList<Objects.Source> sources {
        get {
            if (_sources == null) {
                _sources = Services.Database.get_default ().get_sources_collection ();
            }

            return _sources;
        }
    }

    Gee.ArrayList<Objects.Project> _projects = null;
    public Gee.ArrayList<Objects.Project> projects {
        get {
            if (_projects == null) {
                _projects = Services.Database.get_default ().get_projects_collection ();
            }
            return _projects;
        }
    }

    Gee.ArrayList<Objects.Section> _sections = null;
    public Gee.ArrayList<Objects.Section> sections {
        get {
            if (_sections == null) {
                _sections = Services.Database.get_default ().get_sections_collection ();
            }
            return _sections;
        }
    }

    Gee.ArrayList<Objects.Item> _items = null;
    public Gee.ArrayList<Objects.Item> items {
        get {
            if (_items == null) {
                _items = Services.Database.get_default ().get_items_collection ();
            }
            return _items;
        }
    }

    Gee.ArrayList<Objects.Label> _labels = null;
    public Gee.ArrayList<Objects.Label> labels {
        get {
            if (_labels == null) {
                _labels = Services.Database.get_default ().get_labels_collection ();
            }
            return _labels;
        }
    }

    Gee.ArrayList<Objects.Reminder> _reminders = null;
    public Gee.ArrayList<Objects.Reminder> reminders {
        get {
            if (_reminders == null) {
                _reminders = Services.Database.get_default ().get_reminders_collection ();
            }

            return _reminders;
        }
    }

    Gee.ArrayList<Objects.Attachment> _attachments = null;
    public Gee.ArrayList<Objects.Attachment> attachments {
        get {
            if (_attachments == null) {
                _attachments = Services.Database.get_default ().get_attachments_collection ();
            }

            return _attachments;
        }
    }

    construct {
        label_deleted.connect ((label) => {
            if (_labels.remove (label)) {
                debug ("Label Removed: %s", label.name);
            }
        });

        source_deleted.connect ((source) => {
            if (_sources.remove (source)) {
                debug ("Source Removed: %s", source.header_text);
            }
        });

        project_deleted.connect ((project) => {
            if (_projects.remove (project)) {
                debug ("Prodeleteject Removed: %s", project.name);
            }
        });

        section_deleted.connect ((section) => {
            if (_sections.remove (section)) {
                debug ("Section Removed: %s", section.name);
            }
        });

        item_deleted.connect ((item) => {
            if (_items.remove (item)) {
                debug ("item Removed: %s", item.content);
            }
        });

        reminder_deleted.connect ((reminder) => {
            if (_reminders.remove (reminder)) {
                debug ("Reminder Removed: %s", reminder.id.to_string ());
            }
        });

        attachment_deleted.connect ((attachment) => {
            if (_attachments.remove (attachment)) {
                debug ("Attachment Removed: %s", attachment.id.to_string ());
            }
        });
    }

    public bool is_database_empty () {
        return projects.size <= 0;
    }

    public bool is_sources_empty () {
        return sources.size <= 0;
    }


    public Gee.ArrayList<Objects.BaseObject> get_collection_by_type (Objects.BaseObject base_object) {
        if (base_object is Objects.Project) {
            return projects;
        } else if (base_object is Objects.Section) {
            return sections;
        } else if (base_object is Objects.Item) {
            return items;
        } else if (base_object is Objects.Label) {
            return labels;
        }

        return new Gee.ArrayList<Objects.BaseObject> ();
    }

    /*
    *  Sources
    */

    public void insert_source (Objects.Source source) {
        if (Services.Database.get_default ().insert_source (source)) {
            sources.add (source);
            source_added (source);
        }
    }

    public void delete_source (Objects.Source source) {
        if (Services.Database.get_default ().delete_source (source)) {
            foreach (Objects.Project project in get_projects_by_source (source.id)) {
                delete_project (project);
            }

            source.deleted ();
        }
    }

    public void update_source (Objects.Source source) {
        if (Services.Database.get_default ().update_source (source)) {
            source.updated ();
            source_updated (source);
        }
    }

    public Objects.Source get_source (string id) {
        Objects.Source? return_value = null;
        lock (_sources) {
            foreach (var source in sources) {
                if (source.id == id) {
                    return_value = source;
                    break;
                }
            }

            return return_value;
        }
    }

    /*
     *  Projects
     */

    public void insert_project (Objects.Project project) {
        if (Services.Database.get_default ().insert_project (project)) {
            projects.add (project);

            if (project.parent == null) {
                project_added (project);
            } else {
                project.parent.subproject_added (project);
            }
        }
    }

    public Gee.ArrayList<Objects.Project> get_projects_by_source (string source_id) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.source_id == source_id) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public void delete_project (Objects.Project project) {
        if (Services.Database.get_default ().delete_project (project)) {
            foreach (Objects.Section section in get_sections_by_project (project)) {
                delete_section (section);
            }
        
            foreach (Objects.Item item in get_items_by_project (project)) {
                delete_item (item);
            }
        
            foreach (Objects.Project subproject in get_subprojects (project)) {
                delete_project (subproject);
            }
        
            project.deleted ();
        }
    }

    public void archive_project (Objects.Project project) {
        if (Services.Database.get_default ().archive_project (project)) {
            foreach (Objects.Item item in project.items) {
                archive_item (item, project.is_archived);
            }

            foreach (Objects.Section section in project.sections) {
                section.is_archived = project.is_archived;
                archive_section (section);
            }

            if (project.is_archived) {
                project.archived ();
                project_archived (project);
            } else {
                project.unarchived ();
                project_unarchived (project);
            }
        }
    }

    public void update_project (Objects.Project project) {
        if (Services.Database.get_default ().update_project (project)) {
            project.updated ();
            project_updated (project);
        }
    }

    public void update_project_id (string current_id, string new_id) {
        if (Services.Database.get_default ().update_project_id (current_id, new_id)) {
            Objects.Project? project = get_project (current_id);
            if (project != null) {
                project.id = new_id;
            }

            if (Services.Database.get_default ().update_project_section_id (current_id, new_id)) {
                foreach (var section in sections) {
                    if (section.project_id == current_id) {
                        section.project_id = new_id;
                    }
                }

                if (Services.Database.get_default ().update_project_item_id (current_id, new_id)) {
                    foreach (var item in items) {
                        if (item.project_id == current_id) {
                            item.project_id = new_id;
                        }
                    }
                }
            }
        }
    }

    public Objects.Project get_inbox_project () {
        Objects.Project? return_value = null;

        lock (_projects) {
            foreach (var project in projects) {
                if (project.is_inbox_project) {
                    return_value = project;
                    break;
                }
            }
    
            return return_value;
        }
    }

    public Objects.Project get_project (string id) {
        Objects.Project? return_value = null;
        lock (_projects) {
            foreach (var project in projects) {
                if (project.id == id) {
                    return_value = project;
                    break;
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Project> get_subprojects (Objects.Project _project) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.parent_id == _project.id) {
                    return_value.add (project);
                }
            }
        }
        
        return return_value;
    }

    public Gee.ArrayList<Objects.Project> get_projects_by_backend_type (BackendType backend_type) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.backend_type == backend_type && !project.is_inbox_project) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public int next_project_child_order (Objects.Source source) {
        int child_order = 0;

        lock (_projects) {
            foreach (var project in projects) {
                if (project.source_id == source.id && !project.is_deleted) {
                    child_order++;
                }
            }

            return child_order;
        }
    } 

    /*
    *  Sections
    */

    public void insert_section (Objects.Section section) {
        if (Services.Database.get_default ().insert_section (section)) {
            sections.add (section);
            section.project.section_added (section);
        }
    }

    public void update_section (Objects.Section section) {
        if (Services.Database.get_default ().update_section (section)) {
            section.updated ();
        }
    }

    public void delete_section (Objects.Section section) {
        if (Services.Database.get_default ().delete_section (section)) {
            foreach (Objects.Item item in section.items) {
                delete_item (item);
            }
    
            section.deleted ();
        }
    }

    public void move_section (Objects.Section section, string old_project_id) {
        if (Services.Database.get_default ().move_section (section, old_project_id)) {
            if (Services.Database.get_default ().move_section_items (section)) {
                foreach (Objects.Item item in section.items) {
                    item.project_id = section.project_id;
                }

                section_moved (section, old_project_id);
            }
        }
    }

    public void update_section_id (string current_id, string new_id) {
        if (Services.Database.get_default ().update_section_id (current_id, new_id)) {
            foreach (var section in sections) {
                if (section.id == current_id) {
                    section.id = new_id;
                }
            }

            if (Services.Database.get_default ().update_section_item_id (current_id, new_id)) {
                foreach (var item in items) {
                    if (item.section_id == current_id) {
                        item.section_id = new_id;
                    }
                }
            }
        }
    }

    public void archive_section (Objects.Section section) {
        if (Services.Database.get_default ().archive_section (section)) {
            foreach (Objects.Item item in section.items) {
                archive_item (item, section.is_archived);
            }
    
            if (section.is_archived) {
                section.archived ();
                section_archived (section);
            } else {
                section.unarchived ();
                section_unarchived (section);
            }
        }
    }

    public Gee.ArrayList<Objects.Section> get_sections_by_project (Objects.Project project) {
        Gee.ArrayList<Objects.Section> return_value = new Gee.ArrayList<Objects.Section> ();
        lock (_sections) {
            foreach (var section in sections) {
                if (section.project_id == project.id) {
                    return_value.add (section);
                }
            }
        }

        return return_value;
    }

    public Gee.ArrayList<Objects.Section> get_sections_archived_by_project (Objects.Project project) {
        Gee.ArrayList<Objects.Section> return_value = new Gee.ArrayList<Objects.Section> ();
        lock (_sections) {
            foreach (var section in sections) {
                if (section.project_id == project.id && section.was_archived ()) {
                    return_value.add (section);
                }
            }
        }

        return return_value;
    }

    public Objects.Section get_section (string id) {
        Objects.Section? return_value = null;
        lock (_sections) {
            foreach (var section in sections) {
                if (section.id == id) {
                    return_value = section;
                    break;
                }
            }

            return return_value;
        }
    }

    /*
     *  Items
     */

     public void insert_item (Objects.Item item, bool insert = true) {
        if (Services.Database.get_default ().insert_item (item, insert)) {
            add_item (item, insert);
        }
     }

     public void add_item (Objects.Item item, bool insert = true) {
        items.add (item);
        item_added (item, insert);

        if (insert) {
            if (item.parent_id != "") {
                item.parent.item_added (item);
            } else {
                if (item.section_id == "") {
                    item.project.item_added (item);
                } else {
                    item.section.item_added (item);
                }
            }
        }

        Services.EventBus.get_default ().update_items_position (item.project_id, item.section_id);
    }

    public void update_item (Objects.Item item, string update_id = "") {
        if (Services.Database.get_default ().update_item (item, update_id)) {
            item.updated (update_id);
            item_updated (item, update_id);
        }
    }
    
    public void delete_item (Objects.Item item) {
        if (Services.Database.get_default ().delete_item (item)) {
            foreach (Objects.Item subitem in item.items) {
                delete_item (subitem);
            }

            item.deleted ();
        }
    }

    public void move_item (Objects.Item item) {
        if (Services.Database.get_default ().move_item (item)) {
            foreach (Objects.Item subitem in item.items) {
                subitem.project_id = item.project_id;
                move_item (subitem);
            }
            
            item.updated ();
            item_updated (item, "");
        }
    }

    public void checked_toggled (Objects.Item item, bool old_checked) {
        if (Services.Database.get_default ().checked_toggled (item, old_checked)) {
            foreach (Objects.Item subitem in item.items) {
                subitem.checked = item.checked;
                subitem.completed_at = item.completed_at;
                checked_toggled (subitem, old_checked);
            }

            item.updated ();
            item_updated (item, "");

            Services.EventBus.get_default ().checked_toggled (item, old_checked);
        }
    }

    public void archive_item (Objects.Item item, bool is_archived) {
        if (is_archived) {
            item.archived ();
            item_archived (item);
        } else {
            item.unarchived ();
            item_unarchived (item);
        }

        foreach (Objects.Item subitem in item.items) {
            archive_item (subitem, is_archived);
        }
    }

    public void update_item_id (string current_id, string new_id) {
        if (Services.Database.get_default ().update_item_id (current_id, new_id)) {
            foreach (var item in items) {
                if (item.id == current_id) {
                    item.id = new_id;
                }
            }

            if (Services.Database.get_default ().update_item_child_id (current_id, new_id)) {
                foreach (var item in items) {
                    if (item.parent_id == current_id) {
                        item.parent_id = new_id;
                    }
                }
            }
        }
    }

    public int next_item_child_order (string project_id, string section_id) {
        int child_order = 0;

        lock (_items) {
            foreach (var item in items) {
                if (item.project_id == project_id && item.section_id == section_id) {
                    child_order++;
                }
            }

            return child_order;
        }
    }
    
    public Objects.Item get_item (string id) {
        Objects.Item? return_value = null;
        lock (_items) {
            foreach (var item in items) {
                if (item.id == id) {
                    return_value = item;
                    break;
                }
            }

            return return_value;
        }
    }

    public Objects.Item get_item_by_ics (string ics) {
        Objects.Item? return_value = null;
        lock (_items) {
            foreach (var item in items) {
                if (item.ics == ics) {
                    return_value = item;
                    break;
                }
            }

            return return_value;
        }
    } 

    public Gee.ArrayList<Objects.Item> get_item_by_baseobject (Objects.BaseObject object) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (var item in items) {
                if (object is Objects.Project) {
                    if (item.project_id == object.id && item.section_id == "" && !item.has_parent) {
                        return_value.add (item);
                    }
                }
                
                if (object is Objects.Section) {
                    if (item.section_id == object.id && !item.has_parent) {
                        return_value.add (item);
                    }
                }
            }
        }

        return return_value;
    }

    public Gee.ArrayList<Objects.Item> get_items_checked () {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_checked_by_project (Objects.Project project) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.project_id == project.id && item.checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_subitems (Objects.Item i) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (var item in items) {
                if (item.parent_id == i.id) {
                    return_value.add (item);
                }
            }
        }

        return return_value;
    }

    public Gee.ArrayList<Objects.Item> get_items_by_project (Objects.Project project) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.exists_project (project)) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_date (GLib.DateTime date, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (valid_item_by_date (item, date, checked)) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_no_date (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (!item.has_due && item.checked == checked) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_repeating (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.has_due && item.due.is_recurring && item.checked == checked && !item.was_archived ()) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_date_range (GLib.DateTime start_date, GLib.DateTime end_date, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (valid_item_by_date_range (item, start_date, end_date, checked)) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_month (GLib.DateTime date, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (valid_item_by_month (item, date, checked)) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_pinned (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.pinned && item.checked == checked && !item.was_archived ()) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_priority (int priority, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.priority == priority && item.checked == checked && !item.was_archived ()) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_completed () {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.checked && !item.was_archived ()) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_label (Objects.Label label, bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.has_label (label.id) && item.checked == checked && !item.was_archived ()) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_unlabeled (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.labels.size <= 0 && item.checked == checked && !item.was_archived ()) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_by_scheduled (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.has_due &&
                    !item.was_archived () &&
                    item.checked == checked &&
                    item.due.datetime.compare (new GLib.DateTime.now_local ()) > 0) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_items_no_parent (bool checked = true) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (!item.was_archived () &&
                    item.checked == checked &&
                    !item.has_parent) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public bool valid_item_by_date (Objects.Item item, GLib.DateTime date, bool checked = true) {
        if (!item.has_due || item.was_archived ()) {
            return false;
        }

        return (item.checked == checked && Utils.Datetime.is_same_day (item.due.datetime, date));
    }

    public bool valid_item_by_date_range (Objects.Item item, GLib.DateTime start_date, GLib.DateTime end_date, bool checked = true) {
        if (!item.has_due || item.was_archived ()) {
            return false;
        }

        var date = Utils.Datetime.get_format_date (item.due.datetime);
        var start = Utils.Datetime.get_format_date (start_date);
        var end = Utils.Datetime.get_format_date (end_date);

        return (item.checked == checked && date.compare (start) >= 0 && date.compare (end) <= 0);
    }

    public bool valid_item_by_month (Objects.Item item, GLib.DateTime date, bool checked = true) {
        if (!item.has_due || item.was_archived ()) {
            return false;
        }

        return (item.checked == checked && item.due.datetime.get_month () == date.get_month () &&
            item.due.datetime.get_year () == date.get_year ());
    }

    public Gee.ArrayList<Objects.Item> get_items_by_overdeue_view (bool checked = true) {
        GLib.DateTime date_now = new GLib.DateTime.now_local ();
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.has_due &&
                    !item.was_archived () &&
                    item.checked == checked &&
                    item.due.datetime.compare (date_now) < 0 &&
                    !Utils.Datetime.is_same_day (item.due.datetime, date_now)) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public bool valid_item_by_overdue (Objects.Item item, GLib.DateTime date, bool checked = true) {
        if (!item.has_due || item.was_archived ()) {
            return false;
        }

        return (item.checked == checked &&
            item.due.datetime.compare (new GLib.DateTime.now_local ()) < 0 &&
            !Utils.Datetime.is_same_day (item.due.datetime, new GLib.DateTime.now_local ()));
    }

    /*
    *   Labels
    */

    public void insert_label (Objects.Label label) {
        if (Services.Database.get_default ().insert_label (label)) {
            labels.add (label);
            label_added (label);
        }
    }

    public void delete_label (Objects.Label label) {
        if (Services.Database.get_default ().delete_label (label)) {
            label.deleted ();
        }
    }

    public void update_label (Objects.Label label) {
        if (Services.Database.get_default ().update_label (label)) {
            label.updated ();
            label_updated (label);
        }
    }

    public Gee.ArrayList<Objects.Label> get_labels_by_item_labels (string labels) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();

        foreach (string id in labels.split (";")) {
            Objects.Label? label = get_label (id);
            if (label != null) {
                return_value.add (label);
            }
        }

        return return_value;
    }

    public string get_labels_ids (Gee.ArrayList<Objects.Label> labels) {
        string return_value = "";
            
        foreach (Objects.Label label in labels) {
            return_value += label.id + ";";
        }

        if (return_value.length > 0) {
            return_value = return_value.substring (0, return_value.length - 1);
        }

        return return_value;
    }

    public Gee.ArrayList<Objects.Item> get_items_has_labels () {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (Objects.Item item in items) {
                if (item.has_labels () && !item.completed && !item.was_archived ()) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    public bool label_exists (string id) {
        bool return_value = false;
        lock (_labels) {
            foreach (var label in _labels) {
                if (label.id == id) {
                    return_value = true;
                    break;
                }
            }

            return return_value;
        }
    }

    public Objects.Label get_label (string id) {
        Objects.Label? return_value = null;
        lock (_labels) {
            foreach (var label in labels) {
                if (label.id == id) {
                    return_value = label;
                    break;
                }
            }

            return return_value;
        }
    }

    public Objects.Label? get_label_by_name (string name, bool lowercase = false, string source_id) {
        lock (_labels) {
            string compare_name = lowercase ? name.down () : name;

            foreach (var label in labels) {
                string label_name = lowercase ? label.name.down () : label.name;
                if (label.source_id == source_id && label_name == compare_name) {
                    return label;
                }
            }

            return null;
        }
    }

    public Gee.ArrayList<Objects.Label> get_labels_by_backend_type (BackendType backend_type) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        lock (_labels) {
            foreach (var label in labels) {
                if (backend_type == BackendType.ALL ? true : label.backend_type == backend_type) {
                    return_value.add (label);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Label> get_labels_by_source (string source_id) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        lock (_labels) {
            foreach (var label in labels) {
                if (label.source_id == source_id) {
                    return_value.add (label);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Label> get_all_labels_by_search (string search_text) {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        lock (_labels) {
            foreach (var label in labels) {
                if (search_text.down () in label.name.down ()) {
                    return_value.add (label);
                }
            }

            return return_value;
        }
    }

    /*
    *   Quick Find
    */

    public Gee.ArrayList<Objects.Project> get_all_projects_by_search (string search_text) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (search_text.down () in project.name.down () && !project.is_archived) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Section> get_all_sections_by_search (string search_text) {
        Gee.ArrayList<Objects.Section> return_value = new Gee.ArrayList<Objects.Section> ();
        lock (_projects) {
            foreach (var section in sections) {
                if (search_text.down () in section.name.down () && !section.was_archived ()) {
                    return_value.add (section);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Project> get_all_projects_by_todoist () {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.backend_type == BackendType.TODOIST) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Project> get_all_projects_by_backend_type (BackendType backend_type) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.backend_type == backend_type) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Project> get_all_projects_archived () {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();
        lock (_projects) {
            foreach (var project in projects) {
                if (project.is_archived) {
                    return_value.add (project);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Label> get_all_labels_by_todoist () {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        lock (_labels) {
            foreach (var label in labels) {
                if (label.backend_type == BackendType.TODOIST) {
                    return_value.add (label);
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Item> get_all_items_by_search (string search_text) {
        Gee.ArrayList<Objects.Item> return_value = new Gee.ArrayList<Objects.Item> ();
        lock (_items) {
            foreach (var item in items) {
                if (!item.checked && !item.was_archived () && (search_text.down () in item.content.down () ||
                    search_text.down () in item.description.down ())) {
                    return_value.add (item);
                }
            }

            return return_value;
        }
    }

    // Reminders
    public void insert_reminder (Objects.Reminder reminder) {
        if (Services.Database.get_default ().insert_reminder (reminder)) {
            reminder_added (reminder);
            reminders.add (reminder);
            reminder.item.reminder_added (reminder);
        }
    }

    public void delete_reminder (Objects.Reminder reminder) {
        if (Services.Database.get_default ().delete_reminder (reminder)) {
            reminder.deleted ();
            reminder.item.reminder_deleted (reminder);
        }
    }

    public Gee.ArrayList<Objects.Reminder> get_reminders_by_item (Objects.Item item) {
        Gee.ArrayList<Objects.Reminder> return_value = new Gee.ArrayList<Objects.Reminder> ();
        lock (_reminders) {
            foreach (var reminder in reminders) {
                if (reminder.item_id == item.id) {
                    return_value.add (reminder);
                }
            }

            return return_value;
        }
    }

    public Objects.Reminder get_reminder (string id) {
        Objects.Reminder? return_value = null;
        lock (_reminders) {
            foreach (var reminder in reminders) {
                if (reminder.id == id) {
                    return_value = reminder;
                    break;
                }
            }
            
            return return_value;
        }
    }

    // Atrachments
    public void insert_attachment (Objects.Attachment attachment) {
        if (Services.Database.get_default ().insert_attachment (attachment)) {
            attachments.add (attachment);
            attachment.item.attachment_added (attachment);
        }
    }

    public void delete_attachment (Objects.Attachment attachment) {
        if (Services.Database.get_default ().delete_attachment (attachment)) {
            attachment.deleted ();
            attachment.item.attachment_deleted (attachment);
        }
    }

    public Gee.ArrayList<Objects.Attachment> get_attachments_by_item (Objects.Item item) {
        Gee.ArrayList<Objects.Attachment> return_value = new Gee.ArrayList<Objects.Attachment> ();
        lock (_attachments) {
            foreach (var attachment in attachments) {
                if (attachment.item_id == item.id) {
                    return_value.add (attachment);
                }
            }

            return return_value;
        }
    }
}