/* Focused standalone regressions extracted from #2770. Strict descendant
 * lifetime coverage runs separately with cleanup and calendar dependencies. */
namespace PlanifyUITests {
    private Objects.Project project;

    private void drain_pending () {
        while (MainContext.default ().pending ()) {
            MainContext.default ().iteration (false);
        }
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

    private void test_pinned_card_keyboard_focus () {
        var pins = new Widgets.PinnedItemsBox (project);
        var window = new Gtk.Window () { child = pins, default_width = 500, default_height = 500 };
        window.present ();
        settle_frames ();
        window.set_focus (null);
        var card = pins.items_map["ui-memory-task-0"];
        assert_true (card.pin_mode);
        assert_true (card.parent is Adw.WrapBox);
        assert_true (card.child_focus (Gtk.DirectionType.TAB_FORWARD));
        assert_true (window.focus_widget != null && window.focus_widget.is_ancestor (card));
        window.set_focus (null);
        assert_true (card.grab_focus ());
        assert_true (window.focus_widget != null && window.focus_widget.is_ancestor (card));
        pins.clean_up ();
        window.child = null;
        window.destroy ();

        // Ordinary board cards still focus their row inside a Gtk.ListBox.
        var row = new Layouts.ItemBoard (Services.Store.instance ().get_item ("ui-memory-task-1"));
        var listbox = new Gtk.ListBox ();
        listbox.append (row);
        window = new Gtk.Window () { child = listbox };
        window.present ();
        settle_frames ();
        assert_true (row.grab_focus ());
        assert_true (window.focus_widget == row);
        row.clean_up ();
        window.destroy ();
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
        Test.add_func ("/ui/memory/pinned_card_keyboard_focus", test_pinned_card_keyboard_focus);
        Test.add_func ("/ui/memory/cancel_section_loading", test_cancel_section_loading);
        Test.add_func ("/ui/memory/cancel_project_loading", test_cancel_project_loading);
        Test.add_func ("/ui/memory/navigation_releases_previous_page", test_navigation_releases_previous_page);
        return Test.run ();
    }
}
