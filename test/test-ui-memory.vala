/* Regression coverage for view transitions and task-widget lifetimes. */
namespace PlanifyUITests {
    private Objects.Project project;

    private void drain_pending () {
        while (MainContext.default ().pending ()) {
            MainContext.default ().iteration (false);
        }
    }

    private void test_cancel_section_loading () {
        var row = new Layouts.SectionRow.for_project (project);
        var released = GLib.WeakRef (row);
        row.clean_up ();
        drain_pending ();
        assert_cmpint (row.items_map.size, CompareOperator.EQ, 0);
        row = null;
        assert_null (released.get ());
    }

    private void test_cancel_project_loading () {
        var view = new Views.Project (project);
        var released = GLib.WeakRef (view);
        view.clean_up ();
        view = null;
        drain_pending ();
        assert_null (released.get ());
    }

    private void run_for (uint milliseconds) {
        var loop = new MainLoop ();
        Timeout.add (milliseconds, () => {
            loop.quit ();
            return Source.REMOVE;
        });
        loop.run ();
    }

    private void settle_frames () {
        run_for (400);
    }

    private Gtk.Widget? find_type (Gtk.Widget widget, Type kind) {
        if (widget.get_type ().is_a (kind)) return widget;
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            var match = find_type (child, kind);
            if (match != null) return match;
        }
        return null;
    }

    private void wait_for_type (Gtk.Widget widget, Type kind) {
        var deadline = get_monotonic_time () + 3 * TimeSpan.SECOND;
        while (find_type (widget, kind) == null && get_monotonic_time () < deadline) run_for (25);
        assert_true (find_type (widget, kind) != null);
        run_for (100);
    }

    private void assert_widgets_released (Gee.ArrayList<TrackedWidget> tracked) {
        var deadline = get_monotonic_time () + 3 * TimeSpan.SECOND;
        while (tracked.any_match ((widget) => widget.reference.get () != null) &&
               get_monotonic_time () < deadline) run_for (25);
        foreach (var widget in tracked) {
            if (widget.reference.get () != null) {
                Test.message ("Retained widget: %s", widget.type_name);
                Test.fail ();
            }
        }
    }

    private void select_view_style (Views.Project page, ProjectViewStyle style) {
        var toggles = (Adw.ToggleGroup) find_type (page, typeof (Adw.ToggleGroup));
        assert_nonnull (toggles);
        toggles.active_name = style.to_string ();
        assert_true (project.view_style == style);
    }

    private void test_rapid_list_board_switching () {
        project.view_style = ProjectViewStyle.LIST;
        var page = new Views.Project (project);
        var window = new Gtk.Window () { child = page, default_width = 1100, default_height = 800 };
        window.present ();
        wait_for_type (page, typeof (Views.List));
        for (int cycle = 0; cycle < 8; cycle++) {
            var tracked = new Gee.ArrayList<TrackedWidget> ();
            var old_kind = project.view_style == ProjectViewStyle.LIST ? typeof (Views.List) : typeof (Views.Board);
            var next = project.view_style == ProjectViewStyle.LIST ? ProjectViewStyle.BOARD : ProjectViewStyle.LIST;
            collect_all_widgets (find_type (page, old_kind), tracked);
            select_view_style (page, next);
            if (cycle % 2 == 0) {
                // Reverse twice before the 250ms layout replacement timer fires.
                run_for (40);
                select_view_style (page, next == ProjectViewStyle.LIST ? ProjectViewStyle.BOARD : ProjectViewStyle.LIST);
                run_for (40);
                select_view_style (page, next);
            }
            wait_for_type (page, next == ProjectViewStyle.LIST ? typeof (Views.List) : typeof (Views.Board));
            assert_null (find_type (page, old_kind));
            assert_widgets_released (tracked);
        }

        var tracked = new Gee.ArrayList<TrackedWidget> ();
        collect_all_widgets (page, tracked);
        select_view_style (page, ProjectViewStyle.BOARD);
        run_for (40);
        page.clean_up ();
        window.child = null;
        page = null;
        window.destroy ();
        window = null;
        // A pending timer must not rebuild a layout after cleanup.
        settle_frames ();
        assert_widgets_released (tracked);
    }

    private void test_sidebar_list_grid_switching () {
        var settings = Services.Settings.get_default ().settings;
        settings.set_boolean ("filters-list-view", true);
        var sidebar = new Layouts.Sidebar ();
        var window = new Gtk.Window () { child = sidebar, default_width = 350, default_height = 800 };
        window.present ();
        wait_for_type (sidebar, typeof (Layouts.FilterPaneRow));
        for (int cycle = 0; cycle < 6; cycle++) {
            var tracked = new Gee.ArrayList<TrackedWidget> ();
            var old_kind = cycle % 2 == 0 ? typeof (Layouts.FilterPaneRow) : typeof (Layouts.FilterPaneChild);
            // Track filter controls, excluding persistent source/project rows in the sidebar.
            collect_filter_widgets (sidebar, old_kind, tracked);
            settings.set_boolean ("filters-list-view", cycle % 2 != 0);
            wait_for_type (sidebar, cycle % 2 == 0 ? typeof (Layouts.FilterPaneChild) : typeof (Layouts.FilterPaneRow));
            assert_null (find_type (sidebar, old_kind));
            assert_widgets_released (tracked);
        }
        settings.set_boolean ("filters-list-view", false);
        run_for (40);
        var released = GLib.WeakRef (sidebar);
        sidebar.clean_up ();
        window.child = null;
        sidebar = null;
        window.destroy ();
        window = null;
        settle_frames ();
        assert_null (released.get ());
        settings.set_boolean ("filters-list-view", true);
    }

    private void collect_filter_widgets (Gtk.Widget widget, Type kind, Gee.ArrayList<TrackedWidget> tracked) {
        if (widget.get_type ().is_a (kind)) {
            collect_all_widgets (widget, tracked);
            return;
        }
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            collect_filter_widgets (child, kind, tracked);
        }
    }

    private void test_navigation_releases_previous_page () {
        var app = Planify.instance;
        try {
            assert_true (app.register ());
        } catch (Error e) {
            error ("Cannot register test application: %s", e.message);
        }
        Services.Settings.get_default ().settings.set_string ("local-inbox-project-id", project.id);
        Services.Settings.get_default ().settings.set_boolean ("backup-automatic", false);
        var window = new MainWindow (app);
        app.main_window = window;
        window.present ();
        settle_frames ();

        project.view_style = ProjectViewStyle.LIST;
        for (int cycle = 0; cycle < 3; cycle++) {
            var page = window.add_project_view (project);
            var released = GLib.WeakRef (page);
            settle_frames ();
            window.add_today_view ();
            page = null;
            // Eviction is queued after the page transition; allow frame scheduling to settle
            // even when other tests or profiling consume CPU.
            var deadline = get_monotonic_time () + 3 * TimeSpan.SECOND;
            while (released.get () != null && get_monotonic_time () < deadline) {
                settle_frames ();
            }
            assert_null (released.get ());
        }

        // Exercise another navigation before the pending page change finishes.
        window.add_project_view (project);
        window.add_today_view ();
        window.add_project_view (project);
        settle_frames ();
        window.add_today_view ();
        settle_frames ();
        window.destroy ();
    }

    private class TrackedWidget : Object {
        public GLib.WeakRef reference;
        public string type_name;

        public TrackedWidget (Gtk.Widget widget) {
            reference = GLib.WeakRef (widget);
            type_name = widget.get_type ().name ();
        }
    }

    private void collect_task_widgets (Gtk.Widget widget, Gee.ArrayList<TrackedWidget> tracked) {
        if (widget is Views.Scheduled.ScheduledSection || widget is Layouts.ItemRow) {
            tracked.add (new TrackedWidget (widget));
        }
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            collect_task_widgets (child, tracked);
        }
    }

    private void test_scheduled_releases_sections_and_rows () {
        var date = new DateTime.now_local ();
        foreach (var item in Services.Store.instance ().items) {
            item.due.datetime = date;
        }
        var tracked = new Gee.ArrayList<TrackedWidget> ();
        Views.Scheduled.ScheduledSection? section = new Views.Scheduled.ScheduledDay (date);
        collect_task_widgets (section, tracked);
        section.clean_up ();
        section = null;
        section = new Views.Scheduled.ScheduledMonth (date);
        collect_task_widgets (section, tracked);
        section.clean_up ();
        section = null;
        settle_frames ();
        // Both section types must exercise populated task lists.
        assert_cmpint (tracked.size, CompareOperator.GT, 2);
        foreach (var widget in tracked) {
            if (widget.reference.get () != null) {
                Test.message ("Retained widget: %s", widget.type_name);
                Test.fail ();
            }
        }
    }

    private void test_editor_and_progress_widgets_release () {
        var textview = new Widgets.TextView ();
        var textview_ref = GLib.WeakRef (textview);
        textview = null;
        assert_null (textview_ref.get ());

        var editor = new Widgets.EditableTextView ();
        var editor_ref = GLib.WeakRef (editor);
        editor = null;
        assert_null (editor_ref.get ());

        var menu = new Widgets.ContextMenu.MenuPicker ("Sort");
        menu.add_item ("Name", "name");
        var menu_ref = GLib.WeakRef (menu);
        menu = null;
        assert_null (menu_ref.get ());

        var progress = new Widgets.CircularProgressBar ();
        var progress_ref = GLib.WeakRef (progress);
        progress = null;
        assert_null (progress_ref.get ());
    }

    private void collect_all_widgets (Gtk.Widget widget, Gee.ArrayList<TrackedWidget> tracked, bool include_tooltips = true) {
        if (!include_tooltips && widget.get_type ().name () == "GtkTooltipWindow") {
            return;
        }
        tracked.add (new TrackedWidget (widget));
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            collect_all_widgets (child, tracked, include_tooltips);
        }
    }

    private void test_date_picker_releases_descendants () {
        var picker = new Widgets.DateTimePicker.DateTimePicker ();
        var tracked = new Gee.ArrayList<TrackedWidget> ();
        collect_all_widgets (picker, tracked);
        picker.clean_up ();
        // Cleanup can be reached more than once during parent disposal.
        picker.clean_up ();
        picker = null;
        settle_frames ();
        foreach (var widget in tracked) {
            if (widget.reference.get () != null) {
                Test.message ("Retained widget: %s", widget.type_name);
                Test.fail ();
            }
        }
    }

    private void check_project_children_release (ProjectViewStyle style) {
        project.view_style = style;
        var view = new Views.Project (project);
        var tracked = new Gee.ArrayList<TrackedWidget> ();
        settle_frames ();
        collect_all_widgets (view, tracked);
        view.clean_up ();
        view = null;
        settle_frames ();
        foreach (var widget in tracked) {
            if (widget.reference.get () != null) {
                Test.message ("Retained widget: %s", widget.type_name);
                Test.fail ();
            }
        }
    }

    private void test_project_releases_populated_children () {
        check_project_children_release (ProjectViewStyle.LIST);
        check_project_children_release (ProjectViewStyle.BOARD);
    }

    private void test_task_action_menu_is_lazy_and_reused () {
        var item = Services.Store.instance ().get_item ("ui-memory-task-0");
        var row = new Layouts.ItemRow (item);
        var menu = (Gtk.MenuButton) find_type (row, typeof (Gtk.MenuButton));
        assert_nonnull (menu);
        assert_null (menu.popover);
        assert_true (find_type (row, typeof (Widgets.ContextMenu.MenuSwitch)) == null);

        var listbox = new Gtk.ListBox ();
        listbox.append (row);
        var window = new Gtk.Window () { child = listbox, default_width = 700, default_height = 600 };
        window.present ();
        row.edit = true;
        settle_frames ();
        menu.popup ();
        run_for (100);
        Gtk.Popover? popup = menu.popover;
        assert_nonnull (popup);
        var note = (Widgets.ContextMenu.MenuSwitch) find_type (popup, typeof (Widgets.ContextMenu.MenuSwitch));
        assert_nonnull (note);
        note.clicked ();
        assert_true (item.item_type == ItemType.NOTE);
        menu.popdown ();
        settle_frames ();
        menu.popup ();
        assert_true (menu.popover == popup);
        note.clicked ();
        assert_true (item.item_type == ItemType.TASK);
        menu.popdown ();
        settle_frames ();

        var tracked = new Gee.ArrayList<TrackedWidget> ();
        // GTK's shared tooltip window can be attached after hovering over editor controls.
        collect_all_widgets (row, tracked, false);
        row.clean_up ();
        popup = null;
        note = null;
        menu = null;
        window.child = null;
        listbox = null;
        row = null;
        window.destroy ();
        window = null;
        assert_widgets_released (tracked);
    }

    private void test_scheduled_range_releases_children () {
        var today = Utils.Datetime.get_date_only (new DateTime.now_local ());
        var original_dates = new Gee.HashMap<string, string> ();
        foreach (var item in Services.Store.instance ().items) {
            original_dates[item.id] = item.due.date;
            item.due.datetime = today.add_days (1);
        }
        var range = new Views.Scheduled.ScheduledRange (today, today.add_days (3));
        assert_true (find_type (range, typeof (Layouts.ItemRow)) != null);
        var tracked = new Gee.ArrayList<TrackedWidget> ();
        collect_all_widgets (range, tracked);
        range.clean_up ();
        range = null;
        assert_widgets_released (tracked);
        foreach (var item in Services.Store.instance ().items) item.due.date = original_dates[item.id];
    }

    public int main (string[] args) {
        if (Environment.get_variable ("PLANIFY_UI_SCENARIO") == "extended") {
            if (!Gtk.init_check ()) return 77;
            Adw.init ();
            return PlanifyUIScenarios.run ();
        }
        Test.init (ref args);
        if (!Gtk.init_check ()) {
            return 77;
        }
        Adw.init ();
        string data_home = Environment.get_variable ("XDG_DATA_HOME");
        assert_true (data_home != null && data_home.has_suffix ("/ui-memory/test-core-data"));
        string app_dir = data_home + "/io.github.alainm23.planify";
        DirUtils.create_with_parents (app_dir, 0700);
        FileUtils.remove (app_dir + "/database.db");
        Services.Database.get_default ().init_database ();
        assert_cmpint (Services.Store.instance ().items.size, CompareOperator.EQ, 0);
        var app = Planify.instance;
        assert_cmpint (Services.Store.instance ().sources.size, CompareOperator.EQ, 0);
        var source = new Objects.Source ();
        source.id = "ui-memory-source";
        source.source_type = SourceType.LOCAL;
        source.data = new Objects.SourceData ();
        Services.Store.instance ().insert_source (source);
        project = new Objects.Project ();
        project.id = "ui-memory-project";
        project.name = project.id;
        project.source_id = Services.Store.instance ().sources[0].id;
        Services.Store.instance ().insert_project (project);
        Services.Settings.get_default ().settings.set_string ("local-inbox-project-id", project.id);
        Services.Settings.get_default ().settings.set_boolean ("backup-automatic", false);
        var section = new Objects.Section ();
        section.id = "ui-memory-section";
        section.name = "Test section";
        section.project_id = project.id;
        Services.Store.instance ().insert_section (section);
        var label = new Objects.Label ();
        label.id = "ui-memory-label";
        label.name = "Test label";
        label.source_id = project.source_id;
        Services.Store.instance ().insert_label (label);
        for (int i = 0; i < 60; i++) {
            var item = new Objects.Item ();
            item.id = "ui-memory-task-%d".printf (i);
            item.project_id = project.id;
            item.section_id = i % 2 == 0 ? section.id : "";
            if (i == 3 || i == 4) {
                item.section_id = section.id;
                item.parent_id = "ui-memory-task-%d".printf (i - 1);
            }
            item.pinned = i == 0;
            Services.Store.instance ().insert_item (item);
            item.add_label_if_not_exists (label);
        }
        Test.add_func ("/ui/memory/scheduled_range_releases_children", test_scheduled_range_releases_children);
        Test.add_func ("/ui/memory/task_action_menu_is_lazy_and_reused", test_task_action_menu_is_lazy_and_reused);
        Test.add_func ("/ui/memory/rapid_list_board_switching", test_rapid_list_board_switching);
        Test.add_func ("/ui/memory/sidebar_list_grid_switching", test_sidebar_list_grid_switching);
        Test.add_func ("/ui/memory/project_releases_populated_children", test_project_releases_populated_children);
        Test.add_func ("/ui/memory/date_picker_releases_descendants", test_date_picker_releases_descendants);
        Test.add_func ("/ui/memory/editor_and_progress_widgets_release", test_editor_and_progress_widgets_release);
        Test.add_func ("/ui/memory/scheduled_releases_sections_and_rows", test_scheduled_releases_sections_and_rows);
        Test.add_func ("/ui/memory/cancel_section_loading", test_cancel_section_loading);
        Test.add_func ("/ui/memory/cancel_project_loading", test_cancel_project_loading);
        Test.add_func ("/ui/memory/navigation_releases_previous_page", test_navigation_releases_previous_page);
        return Test.run ();
    }
}
