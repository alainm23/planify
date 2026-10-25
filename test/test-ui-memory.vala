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

        // Standalone coverage ends at lazy creation, actions, and popover reuse.
        // Full descendant release is tested unchanged in the dependency overlay.
        row.clean_up ();
        popup = null;
        note = null;
        menu = null;
        window.child = null;
        listbox = null;
        row = null;
        window.destroy ();
        window = null;
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
        Test.add_func ("/ui/memory/task_action_menu_is_lazy_and_reused", test_task_action_menu_is_lazy_and_reused);
        return Test.run ();
    }
}
