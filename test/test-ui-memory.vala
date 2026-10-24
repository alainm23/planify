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
            settle_frames ();
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
        for (int i = 0; i < 60; i++) {
            var item = new Objects.Item ();
            item.id = "ui-memory-task-%d".printf (i);
            item.project_id = project.id;
            Services.Store.instance ().insert_item (item);
        }
        Test.add_func ("/ui/memory/cancel_section_loading", test_cancel_section_loading);
        Test.add_func ("/ui/memory/cancel_project_loading", test_cancel_project_loading);
        Test.add_func ("/ui/memory/navigation_releases_previous_page", test_navigation_releases_previous_page);
        return Test.run ();
    }
}
