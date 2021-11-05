/*
* Copyright (c) 2017 Daniel Foré (http://danielfore.com)
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
*/

public class MainWindow : Hdy.Window {
    private Widgets.Sidebar sidebar;
    private Gtk.Stack main_stack;

    private uint configure_id = 0;
    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            icon_name: "com.github.alainm23.planner",
            title: _("Planner")
        );
    }

    static construct {
        Hdy.init ();
    }
    
    construct {
        var sidebar_header = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = true,
            hexpand = true
        };
        unowned Gtk.StyleContext sidebar_header_context = sidebar_header.get_style_context ();
        sidebar_header_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var main_header = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = true,
            hexpand = true,
            margin_start = 3,
            margin_end = 3
        };

        var search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search")
        };

        unowned Gtk.StyleContext search_entry_context = search_entry.get_style_context ();
        search_entry_context.add_class ("border-radius-6");

        var sidebar_image = new Gtk.Image () {
            gicon = new ThemedIcon ("view-sidebar-start-symbolic"),
            pixel_size = 16
        };
        
        var sidebar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        sidebar_button.add (sidebar_image);

        unowned Gtk.StyleContext sidebar_button_context = sidebar_button.get_style_context ();
        sidebar_button_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var add_image = new Widgets.DynamicIcon ();
        add_image.size = 16;
        add_image.icon_name = "planner-search";
        
        var add_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        
        add_button.add (add_image);

        unowned Gtk.StyleContext add_button_context = add_button.get_style_context ();
        add_button_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var header_end_grid = new Gtk.Grid ();
        header_end_grid.add (search_entry);

        main_header.pack_start (sidebar_button);
        main_header.pack_end (header_end_grid);

        var header_group = new Hdy.HeaderGroup ();
        header_group.add_header_bar (sidebar_header);
        header_group.add_header_bar (main_header);

        unowned Gtk.StyleContext main_header_context = main_header.get_style_context ();
        main_header_context.add_class (Gtk.STYLE_CLASS_FLAT);
        
        sidebar = new Widgets.Sidebar ();

        var sidebar_content = new Gtk.Grid () {
            width_request = 225,
            vexpand = true,
            hexpand = false
        };
        sidebar_content.attach (sidebar_header, 0, 0);
        sidebar_content.attach (sidebar, 0, 1);

        var main_grid = new Gtk.Grid ();
        main_grid.attach (main_header, 0, 0);
        main_grid.attach (new Gtk.Label ("Tasklist"), 0, 1);

        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("view");

        var flap_view = new Hdy.Flap () {
            locked = true,
            fold_policy = Hdy.FlapFoldPolicy.NEVER
        };
        flap_view.content = main_grid;
        flap_view.separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
        flap_view.flap = sidebar_content;

        var welcome_view = new Views.Welcome ();

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.transition_type = Gtk.StackTransitionType.NONE;

        main_stack.add_named (welcome_view, "welcome-view");
        main_stack.add_named (flap_view, "main-view");

        add (main_stack);

        Planner.settings.bind ("pane-position", sidebar_content, "width_request", GLib.SettingsBindFlags.DEFAULT);

        welcome_view.activated.connect ((index) => {
            Planner.settings.set_enum ("backend-type", index + 1);
            init_backend ();
        });

        Timeout.add (main_stack.transition_duration, () => {
            init_backend ();
            return GLib.Source.REMOVE;
        });

        sidebar_button.clicked.connect (() => {
            if (flap_view.reveal_flap) {
                flap_view.reveal_flap = false;
                sidebar_image.gicon = new ThemedIcon ("view-sidebar-end-symbolic");
            } else {
                flap_view.reveal_flap = true;
                sidebar_image.gicon = new ThemedIcon ("view-sidebar-start-symbolic");
            }
        });
    }

    private void init_backend () {
        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");
        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            // Init Database
            Planner.database = Services.Database.get_default ();
            Planner.database.init_database ();

            if (backend_type == BackendType.TODOIST) {
                Planner.todoist = Services.Todoist.get_default ();
                Planner.todoist.init ();

                // Init Signals
                Planner.todoist.oauth_closed.connect ((welcome) => {
                    if (welcome) {
                        main_stack.visible_child_name = "welcome-view";
                    }
                });
            }

            // Init Widgets
            main_stack.visible_child_name = "main-view";
            sidebar.init (backend_type);
        } else if (backend_type == BackendType.CALDAV) {

        } else {
            main_stack.visible_child_name = "welcome-view";
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;
            
            Gdk.Rectangle rect;
            get_allocation (out rect);
            Planner.settings.set ("window-size", "(ii)", rect.width, rect.height);

            int root_x, root_y;
            get_position (out root_x, out root_y);
            Planner.settings.set ("window-position", "(ii)", root_x, root_y);

            return GLib.Source.REMOVE;
        });

        return base.configure_event (event);
    }
}