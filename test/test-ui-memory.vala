/* Regression coverage for cancelled project/section widget construction. */
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

    private void settle_frames () {
        var loop = new MainLoop ();
        Timeout.add (400, () => {
            loop.quit ();
            return Source.REMOVE;
        });
        loop.run ();
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

    private void collect_all_widgets (Gtk.Widget widget, Gee.ArrayList<TrackedWidget> tracked) {
        tracked.add (new TrackedWidget (widget));
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            collect_all_widgets (child, tracked);
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

    public int main (string[] args) {
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
        var label = new Objects.Label ();
        label.id = "ui-memory-label";
        label.name = "Test label";
        label.source_id = project.source_id;
        Services.Store.instance ().insert_label (label);
        for (int i = 0; i < 60; i++) {
            var item = new Objects.Item ();
            item.id = "ui-memory-task-%d".printf (i);
            item.project_id = project.id;
            item.pinned = i == 0;
            Services.Store.instance ().insert_item (item);
            item.add_label_if_not_exists (label);
        }
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
