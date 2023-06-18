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

public class Dialogs.Item : Adw.Window {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button;
    private Widgets.Entry content_entry;
    private Widgets.HyperTextView description_textview;

    public bool is_creating {
        get {
            return item.id == "";
        }
    }

    public Item (Objects.Item item) {
        Object (
            item: item,
            transient_for: (Gtk.Window) Planner.instance.main_window,
            deletable: true,
            resizable: true,
            modal: false,
            width_request: 600,
            height_request: 400
        );
    }

    public Item.for_item (Objects.Item _item) {
        var item = new Objects.Item ();
        item.project_id = _item.project_id;
        item.section_id = _item.section_id;

        Object (
            item: item,
            transient_for: (Gtk.Window) Planner.instance.main_window,
            deletable: true,
            resizable: true,
            modal: false,
            width_request: 600,
            height_request: 400
        );
    }

    public Item.for_project (Objects.Project project) {
        var item = new Objects.Item ();
        item.project_id = project.id;

        Object (
            item: item,
            transient_for: (Gtk.Window) Planner.instance.main_window,
            deletable: true,
            resizable: true,
            modal: false,
            width_request: 600,
            height_request: 400
        );
    }

    public Item.for_parent (Objects.Item _item) {
        var item = new Objects.Item ();
        item.project_id = _item.project_id;
        item.section_id = _item.section_id;
        item.parent_id = _item.id;
        
        Object (
            item: item,
            transient_for: (Gtk.Window) Planner.instance.main_window,
            deletable: true,
            resizable: true,
            modal: false,
            width_request: 600,
            height_request: 400
        );
    }

    public Item.for_section (Objects.Section section) {
        var item = new Objects.Item ();
        item.section_id = section.id;
        item.project_id = section.project.id;

        Object (
            item: item,
            transient_for: (Gtk.Window) Planner.instance.main_window,
            deletable: true,
            resizable: true,
            modal: true,
            width_request: 600,
            height_request: 400
        );
    }

    construct {
        var view_headerbar = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true,
            decoration_layout = ":"
        };
        
        view_headerbar.add_css_class ("flat");
        view_headerbar.add_css_class ("default-decoration");

        var view_content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            valign = Gtk.Align.START
        };
        view_content_box.append (view_headerbar);
        view_content_box.append (build_view_widget ());

        var sidebar_headerbar = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null)
        };
        sidebar_headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        sidebar_headerbar.add_css_class ("default-decoration");

        var sidebar_content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 225
        };
        sidebar_content_box.append (sidebar_headerbar);
        sidebar_content_box.append (new Gtk.Label ("Sidebar"));
        sidebar_content_box.add_css_class ("sidebar");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };        
        content_box.append (view_content_box);
        
        content = content_box;
        update_request ();
    }

    private Gtk.Widget build_view_widget () {
        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER
        };

        checked_button.add_css_class ("priority-color");

        content_entry = new Widgets.Entry () {
            hexpand = true,
            valign = Gtk.Align.START,
            placeholder_text = _("Task Name")
        };
        content_entry.editable = !item.completed;
        content_entry.add_css_class (Granite.STYLE_CLASS_FLAT);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.START,
            hexpand = true,
            margin_start = 12,
            margin_end = 12
        };

        content_box.append (checked_button);
        content_box.append (content_entry);

        description_textview = new Widgets.HyperTextView (_("Add a description")) {
            height_request = 64,
            left_margin = 39,
            right_margin = 6,
            top_margin = 12,
            bottom_margin = 12,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true
        };

        description_textview.remove_css_class ("view");

        var widget = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            valign = Gtk.Align.START,
            margin_start = 12,
            margin_end = 12
        };
        widget.append (content_box);
        widget.append (description_textview);

        return widget;
    }

    public void update_request () {
        Util.get_default ().set_widget_priority (item.priority, checked_button);
        checked_button.active = item.completed;

        //  if (item.completed && Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
        //      content_label.add_css_class ("line-through");
        //  } else if (item.completed && !Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
        //      content_label.remove_css_class ("line-through");
        //  }

        content_entry.text = item.content;
        description_textview.set_text (item.description);
                
        //  item_summary.update_request ();
        //  schedule_button.update_from_item (item);
        //  priority_button.update_from_item (item);
        //  pin_button.update_request ();
        
        //  if (!edit) {
        //      item_summary.check_revealer ();
        //  }
    }
}