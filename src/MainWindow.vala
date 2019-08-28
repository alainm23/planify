 /*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class MainWindow : Gtk.Window {
    private Widgets.Pane pane;
    public MainWindow (Application application) {
        Object (
            application: application,
            icon_name: "com.github.alainm23.planner",
            title: _("Planner")
        );
    }

    construct {
        var sidebar_header = new Gtk.HeaderBar ();
        sidebar_header.decoration_layout = "close:";
        sidebar_header.has_subtitle = false;
        sidebar_header.show_close_button = true;
        sidebar_header.get_style_context ().add_class ("sidebar-header");
        sidebar_header.get_style_context ().add_class ("titlebar");
        sidebar_header.get_style_context ().add_class ("default-decoration");
        sidebar_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var listview_header = new Gtk.HeaderBar ();
        listview_header.has_subtitle = false;
        listview_header.decoration_layout = ":";
        listview_header.show_close_button = true;
        listview_header.get_style_context ().add_class ("listview-header");
        listview_header.get_style_context ().add_class ("titlebar");
        listview_header.get_style_context ().add_class ("default-decoration");
        listview_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        
        // Menu
        var username = GLib.Environment.get_user_name ();
        var iconfile = @"/var/lib/AccountsService/icons/$username";

        var user_avatar = new Granite.Widgets.Avatar.from_file (iconfile, 16);
        user_avatar.margin_start = 2;

        var username_label = new Gtk.Label ("%s".printf (GLib.Environment.get_real_name ()));
        username_label.halign = Gtk.Align.CENTER;
        username_label.valign = Gtk.Align.CENTER;
        username_label.margin_bottom = 1;
        username_label.use_markup = true;

        // Search Button
        var search_button = new Gtk.Button.from_icon_name ("system-search-symbolic", Gtk.IconSize.MENU);
        search_button.can_focus = false;
        //search_button.tooltip_text = _("See calendar of events");
        search_button.valign = Gtk.Align.CENTER;
        search_button.halign = Gtk.Align.CENTER;
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        // Search Button
        var settings_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", Gtk.IconSize.MENU);
        settings_button.can_focus = false;
        //settings_button.tooltip_text = _("See calendar of events");
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.halign = Gtk.Align.CENTER;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var profile_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        profile_box.hexpand = true;
        profile_box.get_style_context ().add_class ("pane");
        profile_box.pack_start (user_avatar, false, false, 0);
        profile_box.pack_start (username_label, false, false, 0);
        profile_box.pack_end (settings_button, false, false, 0);
        profile_box.pack_end (search_button, false, false, 0);

        //sidebar_header.custom_title = profile_box;
        //sidebar_header.pack_end (sync_button);
        //sidebar_header.pack_end (notification_button);
        //sidebar_header.pack_end (calendar_button);
        //sidebar_header.pack_end (search_button);

        var header_paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        header_paned.pack1 (sidebar_header, false, false);
        header_paned.pack2 (listview_header, true, false);

        var listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("sidebar");

        var scrolledwindow = new Gtk.ScrolledWindow (null, null);
        scrolledwindow.expand = true;
        scrolledwindow.add (listbox);
        
        var pane = new Widgets.Pane ();
        
        var welcome_view = new Views.Welcome ();
        var inbox_view = new Views.Inbox ();
        var today_view = new Views.Today ();
        var upcoming_view = new Views.Upcoming ();

        var stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
        
        stack.add_named (welcome_view, "welcome_view");
        stack.add_named (inbox_view, "inbox_view");
        stack.add_named (today_view, "today_view");
        stack.add_named (upcoming_view, "upcoming_view");

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.pack1 (pane, false, false);
        paned.pack2 (stack, true, false);

        set_titlebar (header_paned);
        add (paned);

        // This must come after setting header_paned as the titlebar
        header_paned.get_style_context ().remove_class ("titlebar");
        get_style_context ().add_class ("rounded");
        Application.settings.bind ("pane-position", header_paned, "position", GLib.SettingsBindFlags.DEFAULT);
        Application.settings.bind ("pane-position", paned, "position", GLib.SettingsBindFlags.DEFAULT);

        pane.activated.connect ((type, id) => {
            if (type == "action") {
                if (id == 0) {
                    stack.visible_child_name = "inbox_view";
                } else if  (id == 1) {
                    stack.visible_child_name = "today_view";
                } else {
                    stack.visible_child_name = "upcoming_view";
                }
            }
        });

        Timeout.add (150, () => {
            if (Application.database.is_database_empty ()) {
                stack.visible_child_name = "welcome_view";
                //headerbar.visible_ui = true;
                //Application.database.start_create_projects ();
            } else {
                //stack.visible_child_name = "welcome_view";
                //headerbar.visible_ui = false;
            }
             
            return false;
        }); 
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        Gtk.Allocation rect;
        get_allocation (out rect);
        Application.settings.set_value ("window-size",  new int[] { rect.height, rect.width });

        int root_x, root_y;
        get_position (out root_x, out root_y);
        Application.settings.set_value ("window-position",  new int[] { root_x, root_y });

        return base.configure_event (event);
    }
}